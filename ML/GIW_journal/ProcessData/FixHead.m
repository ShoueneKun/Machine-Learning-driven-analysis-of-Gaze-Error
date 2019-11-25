clear all
close all
clc

addpath(genpath('/home/rakshit/Documents/MATLAB/event_detection_mark_1/SupportFunctions'))
D = dir('PrIdx_*_TrIdx_*.mat');
load('HeadModels.mat')

for i = 1:length(D)
    data = sscanf(D(i).name, 'PrIdx_%d_TrIdx_%d.mat');
    Pr = data(1); Tr = data(2);
    fid = sprintf('%d-%d.csv', Pr, Tr);
    
    if exist(fid, 'file') 
        load(fullfile(D(i).folder, D(i).name))
        ProcessData.T = ProcessData.T(:);
        
        data = csvread(fid);
        timeStamps = data(:, 1);
        HVecs = data(:, 2:4);
        
%         ProcessData.IMU.HeadVector = normr(...
%             polyval(Model{Pr, 1}, ProcessData.IMU.HeadVector, Model{Pr, 2}));
        
        %%
        RVals = zeros(length(timeStamps), 3);
        for j = 1:length(timeStamps)
            n = findClosest(ProcessData.T, timeStamps(j));
            [~, r] = RotateVectors(ProcessData.IMU.HeadVector(n, :), HVecs(j, :));
            RVals(j, :) = rotationMatrixToVector(r);
        end
        
        % Begining of trials, always assume no rotation
        if timeStamps(1) ~= 0
            timeStamps = [0; timeStamps];
            RVals = [[0,0,0]; RVals];
        end
        RVecs = interp1(timeStamps, RVals, ProcessData.T, 'linear', 'extrap');
        for j = 1:length(ProcessData.T)
            ProcessData.IMU.HeadVector(j, :) = ProcessData.IMU.HeadVector(j, :)*rotationVectorToMatrix(RVecs(j, :));
        end
        %%
        [IMU.az, IMU.el, ~] = cart2sph(-ProcessData.IMU.HeadVector(:, 1), ...
            ProcessData.IMU.HeadVector(:, 3), ProcessData.IMU.HeadVector(:, 2));
        
        ProcessData.IMU.Head_Vel = findHeadVelocity(ProcessData.T, ProcessData.IMU.HeadVector);
        ProcessData.IMU.Az_Vel = findAngularVelocity(ProcessData.T, IMU.az);
        ProcessData.IMU.El_Vel = findAngularVelocity(ProcessData.T, IMU.el);
        
        [RotEuls_GIW, RotMats_GIW] = RotateVectors([0, 0, 1], ProcessData.IMU.HeadVector);
        ProcessData.GIW.GIWvector = zeros(length(ProcessData.T), 3);
        for j = 1:length(ProcessData.T)
            ProcessData.GIW.GIWvector(j, :) = ProcessData.ETG.EIHvector(j, :)*RotMats_GIW(:, :, j);
        end
        
        [ProcessData.GIW.az, ProcessData.GIW.el, ~] = ...
            cart2sph(-ProcessData.GIW.GIWvector(:, 1), ProcessData.GIW.GIWvector(:, 3), ProcessData.GIW.GIWvector(:,2));
        
        ProcessData.GIW.GIW_Vel = findGazeVelocity(ProcessData.T(:), ProcessData.GIW.GIWvector, 0, 0);
        ProcessData.GIW.Az_Vel = findAngularVelocity(ProcessData.T(:), ProcessData.GIW.az);
        ProcessData.GIW.El_Vel = findAngularVelocity(ProcessData.T(:), ProcessData.GIW.el);
        strFixed = 1;
        
%         figure;
%         ax1 = subplot(1, 3, 1);
%         hold(ax1, 'on')
%         plot(ProcessData.T, ProcessData.ETG.EIHvector, 'LineStyle', '--')
%         plot(ProcessData.T, ProcessData.IMU.HeadVector, 'LineStyle', '-.')
% %         plot(ProcessData.T, ProcessData.GIW.GIWvector, 'LineStyle', '-')
%         ax2 = subplot(1, 3, 2);
%         hold(ax2, 'on')
%         plot(ProcessData.T, ProcessData.ETG.EIH_vel, 'LineStyle', '--')
%         plot(ProcessData.T, ProcessData.IMU.Head_Vel, 'LineStyle', '-.')
% %         plot(ProcessData.T, ProcessData.GIW.GIW_Vel, 'LineStyle', '-')
%         ax3 = subplot(1, 3, 3);
%         plot(ProcessData.T, RotEuls_GIW)
%         linkaxes([ax1, ax2, ax3], 'x')
        save(sprintf('Fixed/PrIdx_%d_TrIdx_%d.mat', Pr, Tr), 'ProcessData', 'strFixed')
    else
        disp('No correction file found')
    end
end