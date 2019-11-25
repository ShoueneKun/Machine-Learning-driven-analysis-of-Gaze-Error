clear all
close all
clc

Path2Repo = '/home/rakshit/Documents/MATLAB/gaze-in-wild';
addpath(genpath(fullfile(Path2Repo, 'SupportFunctions')))

global Path2ProcessData Path2LabelData

txt = fscanf(fopen(fullfile(Path2Repo, 'path.json'), 'rb'), '%s');
path_struct = jsondecode(txt);

Path2ProcessData = fullfile(path_struct.path2data, 'ProcessData');
Path2LabelData = fullfile(path_struct.path2data, 'Labels');

%% Read out Saccades from the entire dataset

Dataset = ReadDataset('saccade', 300);

%% Main Sequence by person
clear g
PrPresent = unique(Dataset.PrIdx);
numCols = 5; numRows = ceil(length(PrPresent)/numCols);

for i = 1:length(PrPresent)
    loc = Dataset.PrIdx == PrPresent(i);
    TrPresent = unique(Dataset.TrIdx(loc));
    [data, ID] = deal([]);
    
    for j = 1:length(TrPresent)
        loc = Dataset.PrIdx == PrPresent(i) & Dataset.TrIdx == TrPresent(j);
        temp = struct2table(cell2mat(Dataset.Data(loc)'));
        data = [data; temp];
        ID = [ID; TrPresent(j)*ones(height(temp), 1)];
    end
    
    [a, b] = ind2sub([numRows, numCols], i);
    g(a, b) = gramm('x', data.EIH_AngDisp, 'y', data.EIH_maxVel, 'color', ID);
    g(a, b).stat_glm(); 
    g(a, b).set_title(sprintf('PrIdx: %d', PrPresent(i)));
end
g.set_title('Main Sequence by person')
figure('Position', [50, 50, 1200, 600]);
g.draw();

%% Main Sequence by trial

clear g
TrPresent = unique(Dataset.TrIdx);
numCols = 2; numRows = ceil(length(TrPresent)/numCols);

for i = 1:length(TrPresent)
    loc = Dataset.TrIdx == TrPresent(i);
    PrPresent = unique(Dataset.PrIdx(loc));
    [data, ID] = deal([]);
    
    for j = 1:length(PrPresent)
        loc = Dataset.PrIdx == PrPresent(j) & Dataset.TrIdx == TrPresent(i);
        temp = struct2table(cell2mat(Dataset.Data(loc)'));
        data = [data; temp];
        ID = [ID; PrPresent(j)*ones(height(temp), 1)];
    end
    
    [a, b] = ind2sub([numRows, numCols], i);
    g(a, b) = gramm('x', data.EIH_AngDisp, 'y', data.EIH_maxVel);
    g(a, b).stat_smooth(); 
    g(a, b).set_title(sprintf('TrIdx: %d', TrPresent(i)));
end
g.set_title('Main Sequence by task')
figure('Position', [50, 50, 1200, 600]);
g.draw();