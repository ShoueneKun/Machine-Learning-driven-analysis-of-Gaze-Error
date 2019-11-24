clear all
close all
clc

%% Add relevant paths
addpath(genpath('D:\Projects\Event Detection\event_detection_mark_1'))

global Path2Dataset Path2ProcessData Path2LabelData
Path2Dataset = 'Z:\Natural statistics\';
Path2ProcessData = 'D:\Projects\Event Detection\dataset\ProcessData\';
Path2LabelData = 'D:\Projects\Event Detection\dataset\Labels\';

% window size for the metric, size=10 for 50ms window
winsize = 10;
% make a list of directory to ProcessData
D_pd = dir([Path2ProcessData, 'PrIdx_*_TrIdx_*.mat']);

% for i = 1:length(D_pd)
%     str_pd = fullfile(D_pd(i).folder, D_pd(i).name);
%     % Load ProcessData into workspace
%     load(str_pd, 'ProcessData')
%     % Indices of the ProcessData
%     data = sscanf(D_pd(i).name, 'PrIdx_%d_TrIdx_%d.mat');
%     PrIdx = data(1); TrIdx = data(2);
%     % make a list of label data
%     str_ld = fullfile(Path2LabelData, sprintf('PrIdx_%d_TrIdx_%d_Lbr_*.mat', PrIdx, TrIdx));
%     D_ld = dir(str_ld);
%     if size(D_ld, 1) >= 1
%         for j = 1:length(D_ld)
%             % Load relevant LabelData into workspace
%             load(fullfile(D_ld(j).folder, D_ld(j).name), 'LabelData');
%         end
%     end
% end

%% read person index and task index from keyboard
prompt = 'What is the person index?';
PrIdx = input(prompt);
prompt = 'What is the trial(task) index?';
TrIdx = input(prompt);
str_ld = fullfile(Path2LabelData, sprintf('PrIdx_%d_TrIdx_%d_Lbr_*.mat', PrIdx, TrIdx));
D_ld = dir(str_ld);
%% display available label data from different lablers
disp('Available labeler''s data: ');
for i=1:length(D_ld)
    num = sscanf(D_ld(i).name,'PrIdx_%d_TrIdx_%d_Lbr_%d.mat');
    disp(num(end));
end
%% select the reference label sequence and test label sequence from keyboard
prompt = 'Enter the index of reference labeler: ';
ref = input(prompt);
label_ref = load(fullfile(D_ld(ref).folder, D_ld(ref).name), 'LabelData');
label_ref = label_ref.LabelData;
prompt = 'Enter the index of testing labeler: ';
test = input(prompt);
label_test = load(fullfile(D_ld(test).folder, D_ld(test).name), 'LabelData');
label_test = label_test.LabelData;
%% fill the unlabeled gap in the middle of gaze events
ref_filled = fillGap(label_ref.Labels,5);
test_filled = fillGap(label_test.Labels,5);
%% calculate the direct difference between two label sequences
direct_diff = ref_filled - test_filled;
%% construct events tuples and measures (matching information) from LabelStructs
LabelStruct_ref = GenerateLabelStruct(ref_filled,label_ref.T);
LabelStruct_test = GenerateLabelStruct(test_filled,label_test.T);
events_ref = event_metric_support.to_event(LabelStruct_ref);
events_test = event_metric_support.to_event(LabelStruct_test);
measures_ref2test = event_metric_support.matching(events_ref,events_test,winsize);
measures_test2ref = event_metric_support.matching(events_test,events_ref,winsize);
%% report events statistics for both sequence and calculate scores
event_metric_support.reportEvents(events_ref);
event_metric_support.reportEvents(events_test);
%calculate L2 distance and overlap ratio
[scores,events_ref,num_cor] = event_metric_support.process_matched(measures_ref2test,events_ref,events_test);
%% perform global alignment and fill unlabeled region
ref_aligned = event_metric_support.globalAlignment(measures_ref2test,ref_filled);
test_aligned = event_metric_support.globalAlignment(measures_test2ref,test_filled);
[ref_fu,test_fu] = event_metric_support.fillUnlabeled(ref_aligned,test_aligned);
%% change the label
ref_changed = event_metric_support.changeLabel(ref_fu);
test_changed = event_metric_support.changeLabel(test_fu);
%% calculate differences between two processed label sequences
diff = ref_changed - test_changed;
mat = event_metric_support.cal_confmax(ref_changed,test_changed,label_ref,num_cor);
diff_struct = GenerateLabelStruct(diff,label_ref.T);
num_single_diff = 0;
for i=1:length(diff_struct)
    if diff_struct(i).LabelLoc(1)==diff_struct(i).LabelLoc(2)
        num_single_diff = num_single_diff+ 1;
        diff_struct(i).LabelLoc(1)
    end
end
%num_single_diff