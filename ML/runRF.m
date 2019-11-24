%% RunAllClassifiers
% The purpose of this script is to run all MATLAB based classifiers on data
% with labels.

%% WARNING
% This file will be very slow to run. It takes a long time to load
% classifiers into MATLAB's memory.

%% Load files
clearvars
close all
clc

addpath(genpath(fullfile(pwd, 'RF')))

m = 1;

plotFigures = 0;

classifierType = 'RF';
classifierIdx = '11';

txt = fscanf(fopen(fullfile(cd, '..', 'path.json'), 'rb'), '%s');
path_struct = jsondecode(txt);

Path2ProcessData = fullfile(path_struct.path2data, 'ProcessData');
Path2LabelData = fullfile(path_struct.path2data, 'Labels');
Path2Models = fullfile(pwd, classifierType, [classifierType, '_Models']);

% Get a list of RF models
D_clx = dir(fullfile(Path2Models, '*.mat'));

for Clx_id = 1:length(D_clx)
    str_name = D_clx(Clx_id).name;
    tic
    load(fullfile(Path2Models, str_name))
    disp(['Loaded model in: ', num2str(toc), ' s'])
    strParse = sscanf(str_name, 'Tree_%d_%d_PrTest_%d.mat');
    WinSize = strParse(1);
    PrTest = strParse(3);
    
    % Identify the number of trials
    D_Tr = dir(fullfile(Path2ProcessData, sprintf('PrIdx_%d_TrIdx_*.mat', PrTest)));
    for Tr = 1:length(D_Tr)
        tic
        load(fullfile(D_Tr(Tr).folder, D_Tr(Tr).name))
        disp(['Loaded ProcessData in: ', num2str(toc), ' s'])
        
        % At this point, the ProcessData will be loaded. Identify the number
        % of labellers. If more than one, then George's code needs to run
        % on all of labellers.
        strParse = sscanf(D_Tr(Tr).name, 'PrIdx_%d_TrIdx_%d.mat');
        TrTest = strParse(2);
        D_Lbr = dir(fullfile(Path2LabelData, sprintf('PrIdx_%d_TrIdx_%d_Lbr_*.mat', PrTest, TrTest)));
        
        for LbrIdx = 1:length(D_Lbr)
            tic
            load(fullfile(D_Lbr(LbrIdx).folder, D_Lbr(LbrIdx).name))
            disp(['Loaded LabelData in: ', num2str(toc), ' s'])
            
            strParse = sscanf(D_Lbr(LbrIdx).name, 'PrIdx_%d_TrIdx_%d_Lbr_%d.mat');
            Lbr = strParse(3);
            
            % At this point, the ProcessData and LabelData will be loaded.
            % Now, we must run the classifier.
            %% Predict using model
            ExpData = parseProcessData(ProcessData, LabelData);
            targets = ExpData.Labels;
            [testData, testTargets, W] = GenerateDataset_RF(struct2array(ExpData), WinSize, WinSize, ExpData.Conf, 0);
            
            if strcmp(classifierType, 'RF')
                [Y, scores, stdevs] = predict(Model, testData);
                Y = str2num(cell2mat(Y));
            elseif strcmp(classifierType, 'MLP')
                [~, Y] = max(net(testData'), [], 1);
            end
                
            LabelStruct_X = GenerateLabelStruct(Y, ProcessData.T);
%             LabelStruct_X = RemoveEvents(LabelStruct_X, ProcessData, 1);
                        
            %% Plot figures
            if plotFigures
                LabelStruct = GenerateLabelStruct(testTargets, ProcessData.T);
                
                figure;
                ax1 = subplot(2, 1, 1);
                hold(ax1, 'on')
                plot(ax1, ProcessData.T, ProcessData.ETG.EIH_vel, 'r');
                plot(ax1, ProcessData.T, ProcessData.IMU.Head_Vel, 'b');
                DrawPatches(ax1, LabelStruct, 700)
                title(ax1, 'Ground truth')
                
                ax2 = subplot(2, 1, 2);
                hold(ax2, 'on')
                plot(ax2, ProcessData.T, ProcessData.ETG.EIH_vel, 'r');
                plot(ax2, ProcessData.T, ProcessData.IMU.Head_Vel, 'b');
                DrawPatches(ax2, LabelStruct_X, 700)
                title(ax2, 'Predicted values')
                linkaxes([ax1, ax2], 'x')
            end
            
            
            %% Save results - It will take up space. Preferably use Google drive
            if strcmp(classifierType, 'MLP')
                X_id = 10;
            elseif strcmp(classifierType, 'RF')
                X_id = 11;
            end
            
            %% WARNING! The LabelData is being set to the classifier
            LabelData = [];
            LabelData.T = ProcessData.T;
            LabelData.LabelStruct = LabelStruct_X;
            LabelData.Labels = Y; %GenerateLabelsfromStruct(LabelData);
            LabelData.PrIdx = PrTest;
            LabelData.TrIdx = TrTest;
            LabelData.LbrIdx = X_id;
            LabelData.WinSize = WinSize;
            
            strPerf = fullfile(pwd, 'outputs_notest', sprintf('PrIdx_%d_TrIdx_%d_Lbr_%d_WinSize_%d.mat', PrTest, TrTest, X_id, WinSize));
            save(strPerf, 'LabelData', 'PrTest', 'TrTest', 'Lbr', 'classifierType', 'Y', 'targets')
            strPerf = fullfile(pwd, 'outputs_kfold', sprintf('PrIdx_%d_TrIdx_%d_Lbr_%d_WinSize_%d.mat', PrTest, TrTest, X_id, WinSize));
            save(strPerf, 'LabelData', 'PrTest', 'TrTest', 'Lbr', 'classifierType', 'Y', 'targets')
            
            fprintf('Done. Clx: %d, PrIdx: %d, TrIdx: %d, Lbr: %d\n', Clx_id, PrTest, TrTest, LbrIdx)
        end
    end
end
