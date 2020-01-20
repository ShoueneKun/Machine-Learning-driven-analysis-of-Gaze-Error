clear all
close all
clc

addpath(fullfile(pwd, 'SupportFunctions'))

global Dataset_Path2Data
Dataset_Path2Data = '/run/user/1000/gvfs/smb-share:server=mvrlsmb.cis.rit.edu,share=performlab/Natural statistics';

%% Local paths
global Path2ProcessData Path2LabelData Path2TempData Path2Data Path2Checkers
Path2ProcessData = '/home/rakshit/Documents/Event Detection Dataset files/ProcessData/';
Path2LabelData = 'home/rakshit/Documents/Event Detection Dataset files/LabelData/';
Path2TempData = '/home/rakshit/Documents/Event Detection Dataset files/TempData/';
Path2Checkers = '/home/rakshit/Documents/Event Detection Dataset files/Checkers/';

global ParticipantInfo
ParticipantInfo = GetParticipantInfo();

loc = cellfun(@isempty, {ParticipantInfo.Name}); ParticipantInfo(loc) = [];
PrPresent = find(~ismember({ParticipantInfo.Name}, {'7'}));

for i = 1:length(PrPresent)
    PrIdx = PrPresent(i);

    TrPresent = ParticipantInfo(PrIdx).Trials;
    for j = 1:length(TrPresent)
        TrIdx = TrPresent(j);
        Path2Data = sprintf('%s/%s/%d/', Dataset_Path2Data, ParticipantInfo(PrIdx).Name, TrIdx);
        
        ReadData_function(PrIdx, TrIdx)
    end
end
