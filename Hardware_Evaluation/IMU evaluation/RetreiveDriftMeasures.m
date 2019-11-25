clear all
close all
clc

Path2Repo = '/home/rakshit/Documents/MATLAB/gaze-in-wild'

txt = fscanf(fopen('path.json', 'rb'), '%s');
path_struct = jsondecode(txt);

global Path2ProcessData Path2LabelData

Path2ProcessData = fullfile(path_struct.path2data, 'ProcessData');
Path2LabelData = fullfile(path_struct.path2data, 'Labels');


D = dir(fullfile(Path2ProcessData, '*.mat'));

DriftVals = zeros(length(D), 4);
for i = 1:length(D)
    load(fullfile(D(i).folder, D(i).name))
    DriftVals(i, 1) = ProcessData.PrIdx;
    DriftVals(i, 2) = ProcessData.TrIdx;
    DriftVals(i, 3) = ProcessData.HeadDrift_deg;
    DriftVals(i, 4) = ProcessData.HeadDrift_rate;
    DriftVals(i, 5) = ProcessData.DepthPresent;
end

save('DriftVals.mat', 'DriftVals')