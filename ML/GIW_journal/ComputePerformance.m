clear all
close all
clc

%% Relevant paths
Path2Repo = '/home/rakshit/Documents/MATLAB/gaze-in-wild';
addpath(genpath(fullfile(Path2Repo, 'SupportFunctions')))
txt = fscanf(fopen(fullfile(Path2Repo, 'path.json'), 'rb'), '%s');
path_struct = jsondecode(txt);

global Path2ProcessData Path2LabelData

Path2ProcessData = fullfile(path_struct.path2data, 'ProcessData');
Path2LabelData = fullfile(path_struct.path2data, 'Labels');

ParticipantInfo = GetParticipantInfo();
loc = cellfun(@isempty, {ParticipantInfo.Name});
ParticipantInfo(loc) = [];
PrPresent = 1:length(ParticipantInfo);
loc = ismember({ParticipantInfo.Name}, {'7'});
ParticipantInfo(loc) = [];
PrPresent(loc) = [];

%%
LabelerIdx = [1, 2, 3, 5, 6];
TrialTypes = [1, 2, 3, 4];

LabelSet = cell(length(LabelerIdx), length(PrPresent), length(TrialTypes));
Cond = zeros(length(LabelerIdx), length(PrPresent), length(TrialTypes));

for i = 1:length(LabelerIdx)
    Lbr = LabelerIdx(i);
    for j = 1:length(PrPresent)
        PrIdx = PrPresent(j);
        for TrIdx = 1:length(TrialTypes)
            strProcessData = sprintf('PrIdx_%d_TrIdx_%d.mat', PrIdx, TrIdx);
            strLabelData = sprintf('PrIdx_%d_TrIdx_%d_Lbr_%d.mat', PrIdx, TrIdx, Lbr);
            if i == 1 && exist(fullfile(Path2ProcessData, strProcessData), 'file')
               % First instance. This will ensure all trials have some
               % value. If filled with 0s, then remove during permutation.
               load(fullfile(Path2ProcessData, strProcessData), 'ProcessData')
               N = length(ProcessData.T);
               LabelSet(:, j, TrIdx) = {zeros(N, 1)};
            end
            if exist(fullfile(Path2LabelData, strLabelData), 'file')
                load(fullfile(Path2LabelData, strLabelData), 'LabelData')
                LabelSet(i, j, TrIdx) = {LabelData.Labels};
                Cond(i, j, TrIdx) = TrIdx;
            else
                fprintf('No labels for Pr: %d. Tr: %d. Lbr: %d\n', PrIdx, TrIdx, Lbr) 
            end
        end
    end
end

%% Find sample stats for each Pr
% Important note. While finding statistics all trials are concatenated into
% a single sequence for each labeller.

HumanSample_Perf = cell(length(PrPresent), 6);
HumanEvt_Perf = [];
for i = 1:length(PrPresent)
    LabelMat = cell2mat(squeeze(LabelSet(:, i, :))');
    LabelMat(LabelMat == 5) = 1;
    [HumanSample_Perf{i, 1}, HumanSample_Perf{i, 2},...
        HumanSample_Perf{i, 3}, HumanSample_Perf{i, 4},...
        HumanSample_Perf{i, 5}, HumanSample_Perf{i,6}, temp] = ...
        ComputeCohenPerm(LabelMat);
    HumanEvt_Perf = [HumanEvt_Perf; temp];
end

HumanEvt_Perf = cell2table(HumanEvt_Perf);
HumanEvt_Perf.Properties.VariableNames={'WinSize', 'EER', 'fixF1', 'purF1', ...
    'sacF1', 'l2', 'olr', 'conf_mat', 'kappa', 'kappa_class', 'nm_events', ...
    'l2_b', 'olr_b', 'conf_mat_b', 'kappa_b', 'kappa_class_b', 'nm_events_b', 'DomSamp'};

%% Quick Stats
Kappa_m = nanmean(cell2mat(HumanSample_Perf(:, 1)));
Kappa_std = nanstd(cell2mat(HumanSample_Perf(:, 1)));
pc_m = nanmean(cell2mat(HumanSample_Perf(:, 2)));
pc_std = nanstd(cell2mat(HumanSample_Perf(:, 2)));
rc_m = nanmean(cell2mat(HumanSample_Perf(:, 3)));
rc_std = nanstd(cell2mat(HumanSample_Perf(:, 3)));
f_m = nanmean(cell2mat(HumanSample_Perf(:, 4)));
f_std = nanstd(cell2mat(HumanSample_Perf(:, 4)));
Kappa_class_m = nanmean(cell2mat(HumanSample_Perf(:, 6)));
Kappa_class_std = nanstd(cell2mat(HumanSample_Perf(:, 6)));

%% Normalized conf mat
confmat_m = nanmean(cell2mat(permute(HumanSample_Perf(:, 5), [3, 2, 1])), 3);
confmat_std = nanstd(cell2mat(permute(HumanSample_Perf(:, 5), [3, 2, 1])), [], 3);
%% Save
save('PerformanceMatrix.mat', 'HumanSample_Perf', 'HumanEvt_Perf')

%% Generate LabelSet from classifiers
Path2ClassifiedOp = fullfile(pwd, 'Data_EventMetrics');
LabelerIdx = [11, 31, 12, 13, 14, 15, 24, 34, 44, 54, 63, 64, 65];
WinSize = 0:3:21;

Clx_LabelSet = cell(length(LabelerIdx), length(PrPresent), length(WinSize), length(TrialTypes));

for i = 1:length(LabelerIdx)
    Lbr = LabelerIdx(i);
    for j = 1:length(PrPresent)
        PrIdx = PrPresent(j);
        for TrIdx = 1:length(TrialTypes)
            strProcessData = sprintf('PrIdx_%d_TrIdx_%d.mat', PrIdx, TrIdx);
            for k = 1:length(WinSize)
                Win = WinSize(k);
                strLabelData = sprintf('PrIdx_%d_TrIdx_%d_Lbr_%d_WinSize_%d.mat', PrIdx, TrIdx, Lbr, Win);
                if k == 1 && exist(fullfile(Path2ProcessData, strProcessData), 'file')
                   % First instance. This will ensure all trials have some
                   % value. If filled with 0s, then remove during permutation.
                   load(fullfile(Path2ProcessData, strProcessData), 'ProcessData')
                   N = length(ProcessData.T);
                   Clx_LabelSet(i, j, :, TrIdx) = {zeros(N, 1)};
                end
                if exist(fullfile(Path2ClassifiedOp, strLabelData), 'file')
                    load(fullfile(Path2ClassifiedOp, strLabelData), 'LabelData')
                    Clx_LabelSet(i, j, k, TrIdx) = {LabelData.Labels};
                else
                    fprintf('No labels for Pr: %d. Tr: %d. Lbr: %d. Win: %d\n', PrIdx, TrIdx, Lbr, Win)
                end
            end
        end
    end
end

%% Find classifier sample stats for each Pr
% Human labels are stored in LabelSet. LabelSet -> [Lbr, Pr, Tr]
Classifier_SampleResults = {};
Classifier_EvtResults = [];
for i = 1:length(PrPresent)
    humandata = cell2mat(squeeze(LabelSet(:, i, :))');
    % Samples -> Concatenated labels from every trial
    % humandata -> Variable with informationed stored as [Samples, Lbr]
    humandata(humandata == 5) = 1; % Convert gaze following to fixation
    for j = 1:length(WinSize)
        for k = 1:length(LabelerIdx)
            clxdata = cell2mat(squeeze(Clx_LabelSet(k, i, j, :)));
            clxdata(clxdata == 5) = 1;
            if ~isempty(clxdata)
                [Classifier_SampleResults{i, k, j}, temp] = ...
                    getMetrics(clxdata, humandata, [0, 4], [1, 2, 3]);
                %Append Pr, Tr and Lbx info
                L = size(temp, 1);
                temp = horzcat(repmat([{PrPresent(i)}, {LabelerIdx(k)}, {WinSize(j)}], [L, 1]), temp);
                Classifier_EvtResults = [Classifier_EvtResults; temp];
            end
        end
    end
end

Classifier_EvtResults = cell2table(Classifier_EvtResults);
Classifier_EvtResults.Properties.VariableNames={'ref_LbrIdx', 'test_LbrIdx', 'WinSize', 'EER', 'fixF1', 'purF1', ...
    'sacF1', 'l2', 'olr', 'conf_mat', 'kappa', 'kappa_class', 'nm_events', ...
    'l2_b', 'olr_b', 'conf_mat_b', 'kappa_b', 'kappa_class_b', 'nm_events_b', 'DomSamp'};

% Classifier_SampleResults -> [PrIdx, Clx_id, WinSize]

%% Quick stats
% [11, 31, 12, 13, 14, 15, 24, 34, 44, 54, 63, 64, 65]
% [ 1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13]

Clx_id = 5;
ResultsStruct = cell2mat(squeeze(Classifier_SampleResults(:, Clx_id, 1)));
nanmean([ResultsStruct.kappa_class], 2)

% Clx_id = 11;
% loc = Classifier_EvtResults.test_LbrIdx == Clx_id;
% nanmean(table2array(Classifier_EvtResults(loc, [21])))

%% Saving results
save('PerformanceMatrix.mat', 'Classifier_SampleResults', 'Classifier_EvtResults', '-append')

%% Generate Sample performance for Humans
T = [];
T(1, [1, 3, 5]) = Kappa_class_m;
T(1, [2, 4, 6]) = Kappa_std;
T(2, [1, 3, 5]) = pc_m;
T(2, [2, 4, 6]) = pc_std;
T(3, [1, 3, 5]) = f_m;
T(3, [2, 4, 6]) = f_std;

%% Generate Event performance for Humans

T = [];
T(5, [1, 3, 5]) = nanmean(HumanEvt_Perf.kappa_class(:, 1:3));
T(5, [2, 4, 6]) = nanstd(HumanEvt_Perf.kappa_class(:, 1:3));
T(2, [1, 3, 5]) = nanmean(HumanEvt_Perf.olr(:, [1, 3, 5]));
T(2, [2, 4, 6]) = nanstd(HumanEvt_Perf.olr(:, [1, 3, 5]));
T(3, [1, 3, 5]) = nanmean([HumanEvt_Perf.fixF1, HumanEvt_Perf.purF1, HumanEvt_Perf.sacF1]);
T(3, [2, 4, 6]) = nanstd([HumanEvt_Perf.fixF1, HumanEvt_Perf.purF1, HumanEvt_Perf.sacF1]);
T(1, [1, 3, 5]) = nanmean(HumanEvt_Perf.l2(:, [1, 3, 5]))/0.3;
T(1, [2, 4, 6]) = nanstd(HumanEvt_Perf.l2(:, [1, 3, 5]))/0.3;
T(4, [1, 3, 5]) = nanmean(ZemPerf.kappa_class(ZemPerf.WinSize == -1, :));
T(4, [2, 4, 6]) = nanstd(ZemPerf.kappa_class(ZemPerf.WinSize == -1, :));

%% Generate Sample performance table
T = zeros(4, 4);

% RF
Clx_id = 1;
ResultsStruct = cell2mat(squeeze(Classifier_SampleResults(:, Clx_id, end)));
T(1, 1) = nanmean([ResultsStruct.kappa], 2);

Clx_id = 1;
ResultsStruct = cell2mat(squeeze(Classifier_SampleResults(:, Clx_id, end)));
T(1, 2:end) = nanmean([ResultsStruct.kappa_class], 2);

% biRNN
Clx_id = 5;
ResultsStruct = cell2mat(squeeze(Classifier_SampleResults(:, Clx_id, 1)));
T(2, 1) = nanmean([ResultsStruct.kappa], 2);

Clx_id = 5;
ResultsStruct = cell2mat(squeeze(Classifier_SampleResults(:, Clx_id, 1)));
T(2, 2:end) = nanmean([ResultsStruct.kappa_class], 2);

% fRNN
Clx_id = 10;
ResultsStruct = cell2mat(squeeze(Classifier_SampleResults(:, Clx_id, 1)));
T(3, 1) = nanmean([ResultsStruct.kappa], 2);

Clx_id = 10;
ResultsStruct = cell2mat(squeeze(Classifier_SampleResults(:, Clx_id, 1)));
T(3, 2:end) = nanmean([ResultsStruct.kappa_class], 2);

% Human
T(4, 1) = Kappa_m;
T(4, 2:end) = Kappa_class_m;

%% Generae event performance using rest of the metrics
T = [];

loc = Classifier_EvtResults.test_LbrIdx == 11 & Classifier_EvtResults.WinSize == 21;
T(1, 1:3) = nanmean(table2array(Classifier_EvtResults(loc, [5, 6, 7])));
T(1, 4) = nanmean(Classifier_EvtResults.EER(loc));
loc = ZemPerf.test_lbr == 11 & ZemPerf.WinSize == 21;
T(1, 5:7) = nanmean(ZemPerf.kappa_class(loc, :));
T(1, 8) = nanmean(ZemPerf.kappa(loc));

loc = Classifier_EvtResults.test_LbrIdx == 54;
T(2, 1:3) = nanmean(table2array(Classifier_EvtResults(loc, [5, 6, 7])));
T(2, 4) = nanmean(Classifier_EvtResults.EER(loc));
loc = ZemPerf.test_lbr == 54;
T(2, 5:7) = nanmean(ZemPerf.kappa_class(loc, :));
T(2, 8) = nanmean(ZemPerf.kappa(loc));

loc = Classifier_EvtResults.test_LbrIdx == 14;
T(3, 1:3) = nanmean(table2array(Classifier_EvtResults(loc, [5, 6, 7])));
T(3, 4) = nanmean(Classifier_EvtResults.EER(loc));
loc = ZemPerf.test_lbr == 14;
T(3, 5:7) = nanmean(ZemPerf.kappa_class(loc, :));
T(3, 8) = nanmean(ZemPerf.kappa(loc));

T(4, 1:3) = nanmean(table2array(HumanEvt_Perf(:, [3, 4, 5])));
T(4, 4) = nanmean(HumanEvt_Perf.EER);
loc = ZemPerf.WinSize == -1;
T(4, 5:7) = nanmean(ZemPerf.kappa_class(loc, :));
T(4, 8) = nanmean(ZemPerf.kappa(loc));

%% Generate ELCCM performance table

T = zeros(4, 1+3+3+3+3);

Clx_id = 11;
loc = Classifier_EvtResults.test_LbrIdx == Clx_id & Classifier_EvtResults.WinSize == 21;
T(1, 1) = nanmean(Classifier_EvtResults.kappa(loc));
T(1, 2:4) = nanmean(Classifier_EvtResults.kappa_class(loc, 1:3));
T(1, 5:7) = nanmean(Classifier_EvtResults.l2(loc, [1, 3, 5]))/0.3;
T(1, 8:10) = nanmean(Classifier_EvtResults.olr(loc, [1, 3, 5]));
T(1, 11:13) = nanstd(Classifier_EvtResults.l2(loc, [1, 3, 5]))/0.3;

Clx_id = 54;
loc = Classifier_EvtResults.test_LbrIdx == Clx_id;
T(2, 1) = nanmean(Classifier_EvtResults.kappa(loc));
T(2, 2:4) = nanmean(Classifier_EvtResults.kappa_class(loc, 1:3));
T(2, 5:7) = nanmean(Classifier_EvtResults.l2(loc, [1, 3, 5]))/0.3;
T(2, 8:10) = nanmean(Classifier_EvtResults.olr(loc, [1, 3, 5]));
T(2, 11:13) = nanstd(Classifier_EvtResults.l2(loc, [1, 3, 5]))/0.3;

Clx_id = 14;
loc = Classifier_EvtResults.test_LbrIdx == Clx_id;
T(3, 1) = nanmean(Classifier_EvtResults.kappa(loc));
T(3, 2:4) = nanmean(Classifier_EvtResults.kappa_class(loc, 1:3));
T(3, 5:7) = nanmean(Classifier_EvtResults.l2(loc, [1, 3, 5]))/0.3;
T(3, 8:10) = nanmean(Classifier_EvtResults.olr(loc, [1, 3, 5]));
T(3, 11:13) = nanstd(Classifier_EvtResults.l2(loc, [1, 3, 5]))/0.3;

T(4, 1) = nanmean(HumanEvt_Perf.kappa);
T(4, 2:4) = nanmean(HumanEvt_Perf.kappa_class(:, 1:3));
T(4, 5:7) = nanmean(Classifier_EvtResults.l2(:, [1, 3, 5]))/0.3;
T(4, 8:10) = nanmean(Classifier_EvtResults.olr(:, [1, 3, 5]));
T(4, 11:13) = nanstd(Classifier_EvtResults.l2(loc, [1, 3, 5]))/0.3;

%% Generate sample performance for ablation
% [11, 31, 12, 13, 14, 15, 24, 34, 44, 54, 63, 64, 65]
T = [];
conds = [3, 4, 5, 6, 8, 9];
T = zeros(length(conds), 4);

for i = 1:length(conds)
    Clx_id = conds(i);
    data = cell2mat(squeeze(Classifier_SampleResults(:, Clx_id, :)));
    data = struct2table(data(:));
    T(i, 1) = nanmean(data.kappa);
    T(i, 2:4) = nanmean(cell2mat(data.kappa_class(:)')');
end
tbl1 = T;
%% Generate event performance for ablation

conds = [12, 13, 14, 15, 34, 44];
% T = zeros(length(conds), 1+3*5+1);
T = [];

for i = 1:length(conds)
    Clx_id = conds(i);
    loc = Classifier_EvtResults.test_LbrIdx == Clx_id;
    T(i, 1) = nanmean(Classifier_EvtResults.kappa(loc));
    T(i, 2:4) = nanmean(Classifier_EvtResults.kappa_class(loc, 1:3));
    T(i, 5:7) = nanmean(Classifier_EvtResults.l2(loc, [1, 3, 5]))/0.3;
    T(i, 8:10) = nanstd(Classifier_EvtResults.l2(loc, [1, 3, 5]))/0.3;
    T(i, 11:13) = nanmean(Classifier_EvtResults.olr(loc, [1, 3, 5]));
    T(i, 14:16) = nanmean(table2array(Classifier_EvtResults(loc, 5:7)));
    T(i, 17:19) = nanmean(Classifier_EvtResults.nm_events(loc, :));
    loc = ZemPerf.test_lbr == conds(i);
    T(i, 20) = nanmean(ZemPerf.kappa(loc));
    T(i, 21:23) = nanmean(ZemPerf.kappa_class(loc, :));
end
tbl2 = T;

T = [tbl1'; tbl2'];
