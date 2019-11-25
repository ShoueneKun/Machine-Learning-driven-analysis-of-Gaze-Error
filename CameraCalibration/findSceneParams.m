close all
clc

N = 500;
CheckerSize_mm = 69.85;

Path2Data = '/run/user/1000/gvfs/smb-share:server=mvrlsmb.cis.rit.edu,share=performlab/Natural statistics/';
Path2Project = '/home/rakshit/Documents/MATLAB/event_detection_mark_1/';
addpath(genpath(Path2Project))
load('SceneCameraParameters.mat', 'SceneCameraParams')

initParams = SceneCameraParams;
clear SceneCameraParams

PrInfo = GetParticipantInfo();
PrInfo(cellfun(@isempty, {PrInfo.Name})) = [];
PrNotInclude = {'Asher', 'Brendan'};
ParamsForAll = cell(length(PrInfo), 4);

strFile = fullfile(Path2Project, 'Hardware Evaluation', ...
    'SceneParams', 'SceneParam.mat');

for PrIdx = 1:length(PrInfo)
    if ~isempty(PrInfo(PrIdx).Name) && ~ismember(PrInfo(PrIdx).Name, PrNotInclude)
        D = dir(fullfile(Path2Data, PrInfo(PrIdx).Name));
        D(ismember({D.name}, {'.', '..'})) = [];
        
        for Tr = 1:length(D)
            TrIdx = str2double(D(Tr).name);
            fprintf('Person: %s. Trial: %s\n', PrInfo(PrIdx).Name, D(Tr).name)
            Path2Scene = fullfile(Path2Data, PrInfo(PrIdx).Name, D(Tr).name, 'Gaze', 'world.mp4');
            C = zeros(1080, 1920, 1, N, 'uint8');
            VidObj = vision.VideoFileReader(Path2Scene, 'VideoOutputDataType', 'uint8');
            m = 1;
            k = 1; 
            while m <= N
                if rem(m, 10) == 0
                    [I, ~] = step(VidObj);
                    C(:, :, 1, k) = rgb2gray(I);
                    k = k + 1;
                end
                m = m+1;
            end
            worldPoints = generateCheckerboardPoints([10, 7], CheckerSize_mm);
            [imagePoints, boardSize, ~] = detectCheckerboardPoints(C);
            
            [cameraParams, imagesUsed, estimationErrors] = estimateCameraParameters(imagePoints, worldPoints,...
                'InitialRadialDistortion', initParams.RadialDistortion, ...
                'ImageSize', [1080, 1920]);
            
            ParamsForAll{PrIdx, TrIdx, 1} = cameraParams;
            
            imagesUsed = find(imagesUsed);
            dist2Checker = zeros(length(imagesUsed), 1);
            for i = 1:length(imagesUsed)
                [~, T] = extrinsics(imagePoints(:, :, imagesUsed(i)), worldPoints, cameraParams);
                dist2Checker(i) = T(3);
            end
            keyboard
            dist2Checker(dist2Checker == 0) = [];
            ParamsForAll{PrIdx, TrIdx, 2} = mean(dist2Checker);
        end
    elseif ~isempty(PrInfo(PrIdx).Name)
        fprintf('Not computing scene camera parameters for %s\n', PrInfo(PrIdx).Name)
    end
end
save(strFile, ParamsForAll)