clear all
close all
clc

global Dataset_Path2Data
global Path2Data
global Path2LabelData
global Path2ProcessData
addpath([pwd, '/SupportFunctions'])

%% Enter remote directory address
Dataset_Path2Data = '/run/user/1000/gvfs/smb-share:server=mvrlsmb.cis.rit.edu,share=performlab/Natural statistics/';

%% Enter Label director address
Path2LabelData = '/home/rakshit/Documents/Event Detection Dataset files/LabelData/';
Path2ProcessData = '/home/rakshit/Documents/Event Detection Dataset files/ProcessData/';
Path2results = '/home/rakshit/drive_rit/Data_EventMetrics_backup';

%% Internal purposes
% Dataset_Path2Data = fullfile('/media', 'rakshit', 'My Passport', 'HDD Backup', 'Dataset', 'Natural statistics');

%% Select your identity
ListLabellers = sprintf('1. S.L.\n2. B.M.\n3. K.M.\n4. R.K.\n5. R.D.\n6. N.N.\n[14, ]');
LbrIdx = input(sprintf(['Who are you?\n' ListLabellers]));

ParticipantInfo = GetParticipantInfo();

%% Prepare dataset
D_pd = dir(fullfile(Path2ProcessData, 'PrIdx_*_TrIdx_*.mat'));
D_ld = dir(fullfile(Path2LabelData, ['PrIdx_*_TrIdx_*_Lbr_', num2str(LbrIdx), '.mat']));
ProgStr = GenerateProgress(D_pd, D_ld, LbrIdx);
disp(ProgStr)
ch = input('Select the trial you wish to label: ');
load(fullfile(D_pd(ch).folder, D_pd(ch).name))

%% Plotting ML algo performance?
ch = input('Viewing results?');
if ch
    str_ld = fullfile(Path2results, sprintf('PrIdx_%d_TrIdx_%d_Lbr_%d_WinSize_0.mat', ProcessData.PrIdx, ProcessData.TrIdx, LbrIdx));
else
    str_ld = fullfile(Path2LabelData, sprintf('PrIdx_%d_TrIdx_%d_Lbr_%d.mat', ProcessData.PrIdx, ProcessData.TrIdx, LbrIdx));
end

%% Read Data

if exist(str_ld, 'file')
    load(str_ld)
else
    LabelData.T = ProcessData.T;
    LabelData.perComplete = 0;
    LabelData.Labels = [];
    LabelData.LabelStruct = [];
end

% Ensure the sampling rates match. If not, resample labels.
LabelData = matchSamplingRates(LabelData, ProcessData);
Path2Data = fullfile(Dataset_Path2Data, ParticipantInfo(ProcessData.PrIdx).Name, num2str(ProcessData.TrIdx));

%% Run the labeller program
[LabelData.Labels, LabelData.LabelStruct, mod_head_data, mod_headrot_list] = Labeller(ProcessData, LabelData);
closereq

LabelData.T = ProcessData.T; % Copy over the timing information
LabelData.PrIdx = ProcessData.PrIdx;
LabelData.TrIdx = ProcessData.TrIdx;
LabelData.LbrIdx = LbrIdx;
LabelData.perComplete = 100*sum(LabelData.Labels~=0)/length(LabelData.Labels);

disp('saved')
save(str_ld, 'LabelData')

% %% Save modified ProcessData
% ProcessData.IMU.HeadVector = mod_head_data{1};
% ProcessData.IMU.Head_Vel = mod_head_data{2};
% ProcessData.IMU.Az_Vel = mod_head_data{3};
% ProcessData.IMU.El_Vel = mod_head_data{4};
% save(fullfile(Path2ProcessData, 'Fixed', sprintf('PrIdx_%d_TrIdx_%d.mat', ProcessData.PrIdx, ProcessData.TrIdx)), 'ProcessData')

% csvwrite(fullfile(Path2ProcessData, sprintf('%d-%d.csv',ProcessData.PrIdx, ProcessData.TrIdx)), mod_headrot_list)