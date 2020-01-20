clear all
close all
clc

Path2LabelData = '/run/user/1000/gvfs/smb-share:server=mvrlsmb.cis.rit.edu,share=performlab/FinalSet/Labels';
D = dir(fullfile(Path2LabelData, '*.mat'));

[noFixations, noSaccades, noPursuits, noBlinks, timeDur] = deal(zeros(length(D), 1));

PrList = zeros(length(D), 1);
for i = 1:length(D)
    load(fullfile(D(i).folder, D(i).name))

    temp = {LabelData.LabelStruct.LabelTime};
    temp = cell2mat(temp(:));
    nM = sscanf(D(i).name, 'PrIdx_%d_TrIdx_%d_Lbr_%d.mat');
    PrIdx = nM(1); TrIdx = nM(2); Lbr = nM(3);
    
    PrList(i) = PrIdx;
    
    eventType = [LabelData.LabelStruct.Label];
    noFixations(i) = sum(eventType == 1 | eventType == 5);
    noSaccades(i) = sum(eventType == 3);
    noPursuits(i) = sum(eventType == 2);
    noBlinks(i) = sum(eventType == 4);
    timeDur(i) = sum(temp(eventType ~= 0, 2) - temp(eventType ~= 0, 1));
end

loc = ismember(PrList, [4, 5, 21, 7]);

eventRatio = [sum(noFixations(~loc)), sum(noSaccades(~loc)), sum(noPursuits(~loc))];
fprintf('Fixations: %d, Saccades: %d, Pursuits: %d \n', eventRatio(1), eventRatio(2), eventRatio(3))
fprintf('Total labelling time: %d\n', sum(timeDur(~loc)))