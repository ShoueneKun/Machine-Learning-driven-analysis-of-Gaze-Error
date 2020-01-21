clear all
close all
clc

addpath(genpath('/home/rakshit/Documents/MATLAB/event_detection_mark_1/SupportFunctions'))
D = dir('PrIdx_*_TrIdx_*.mat');

AngFixed = struct();
DriftDev = struct();

m = 1;
for i = 1:length(D)
    data = sscanf(D(i).name, 'PrIdx_%d_TrIdx_%d.mat');
    Pr = data(1); Tr = data(2);
    fid = sprintf('%d-%d.csv', Pr, Tr);
    
    if exist(fid, 'file') 
        load(fullfile(D(i).folder, D(i).name))
        ProcessData.T = ProcessData.T(:);
        
%         figure; plot(ProcessData.T, ProcessData.IMU.HeadVector)
%         hold on;
        
        data = csvread(fid);
        timeStamps = data(:, 1);
        HVecs = data(:, 2:4);
        [timeStamps, loc] = sort(timeStamps);
        HVecs = normr(HVecs(loc, :));
        
        QVals = zeros(length(timeStamps), 4);
        AngRot = zeros(length(timeStamps), 5);
        p = 1; DriftMeas = []; DevMeas = [];
        for j = 1:length(timeStamps)
            n = findClosest(ProcessData.T, timeStamps(j));
            [axang, r] = RotateVectors(ProcessData.IMU.HeadVector(n, :), HVecs(j, :));
            QVals(j, :) = rotm2quat(r);
            AngRot(j, 1) = axang(4)*180/pi; 
            AngRot(j, 3:5) = rotm2eul(r);
            
            [axang, ~] = RotateVectors(HVecs(j, :), [0, 0, 1]);
            AngRot(j, 2) = axang(4)*180/pi;
            
            if j ~= 1 && prod(HVecs(j, :) == HVecs(j-1, :))
                n1 = findClosest(ProcessData.T, timeStamps(j));
                n2 = findClosest(ProcessData.T, timeStamps(j-1));
                [axang, ~] = RotateVectors(ProcessData.IMU.HeadVector(n1, :),...
                    ProcessData.IMU.HeadVector(n2, :));
               DriftMeas(p) = (180/pi)*axang(4)/(abs(timeStamps(j) - timeStamps(j-1)));
               DevMeas(p) = (180/pi)*axang(4);
               p = p + 1;
            end
        end
        DriftDev(m).PrIdx = ProcessData.PrIdx;
        DriftDev(m).TrIdx = ProcessData.TrIdx;
        DriftDev(m).DriftMeas = DriftMeas;
        DriftDev(m).DevMeas = DevMeas;
        
        AngFixed(m).PrIdx = ProcessData.PrIdx;
        AngFixed(m).TrIdx = ProcessData.TrIdx;
        AngFixed(m).AngRot = AngRot;
        m = m + 1;
        
        % Begining of trials, always assume no rotation
        if timeStamps(1) ~= 0
            timeStamps = [0; timeStamps];
            QVals = [[1,0,0,0]; QVals];
        end
        QVecs = quat_interp_slerp(timeStamps, QVals, ProcessData.T);
        corMat = zeros(3, 3, length(ProcessData.T));
        for j = 1:length(ProcessData.T)
            corMat(:, :, j) = quat2rotm(QVecs(j, :));
        end
        %%
        [IMU.az, IMU.el, ~] = cart2sph(-ProcessData.IMU.HeadVector(:, 1), ...
            ProcessData.IMU.HeadVector(:, 3), ProcessData.IMU.HeadVector(:, 2));
        
        ProcessData.IMU.Head_Vel = findHeadVelocity(ProcessData.T, ProcessData.IMU.HeadVector);
        ProcessData.IMU.Az_Vel = findAngularVelocity(ProcessData.T, IMU.az);
        ProcessData.IMU.El_Vel = findAngularVelocity(ProcessData.T, IMU.el);
        
        % Update Head quaternion
        ProcessData.IMU.HeadPose = quatmultiply(ProcessData.IMU.HeadPose, rotm2quat(corMat));
        ProcessData.IMU.HeadVector = quatrotate(ProcessData.IMU.HeadPose, [0, 0, 1]);
        ProcessData.GIW.GIWvector = RapidRotate(quat2rotm(ProcessData.IMU.HeadPose), ProcessData.ETG.EIHvector, 'mv');
        
        [ProcessData.GIW.az, ProcessData.GIW.el, ~] = ...
            cart2sph(-ProcessData.GIW.GIWvector(:, 1), ProcessData.GIW.GIWvector(:, 3), ProcessData.GIW.GIWvector(:,2));
        
        ProcessData.GIW.GIW_Vel = findGazeVelocity(ProcessData.T(:), ProcessData.GIW.GIWvector, 0, 0);
        ProcessData.GIW.Az_Vel = findAngularVelocity(ProcessData.T(:), ProcessData.GIW.az);
        ProcessData.GIW.El_Vel = findAngularVelocity(ProcessData.T(:), ProcessData.GIW.el);
        strFixed = 1;
        
%         plot(ProcessData.T, ProcessData.IMU.HeadVector)
        
        save(sprintf('Fixed/PrIdx_%d_TrIdx_%d.mat', Pr, Tr), 'ProcessData', 'strFixed')
    else
        fprintf('No correction file found for PrIdx: %d, TrIdx: %d\n', Pr, Tr)
    end
end
