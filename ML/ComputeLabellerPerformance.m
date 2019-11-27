clear all
close all
clc

% This script computes the sample and event level performance between
% human labellers.

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
    'l2_b', 'olr_b', 'conf_mat_b', 'kappa_b', 'kappa_class_b', 'nm_events_b'};

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