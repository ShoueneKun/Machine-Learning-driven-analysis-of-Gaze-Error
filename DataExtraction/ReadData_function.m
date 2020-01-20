function [] = ReadData_function(PrIdx, TrIdx)
    global Path2ProcessData Path2LabelData Path2TempData Path2Data
    global ParticipantInfo
    global Dataset_Path2Data Path2Checkers

    plotProcessFigures = 0;
    regenerate_depth = 0;
    processSignals = 1;
    
    fprintf('Processing Pr: %d. Tr: %d\n', PrIdx, TrIdx)
    %% Load Scene Parameters and Stereo Parameters
    % Scene Parameters
    load('/home/rakshit/Documents/MATLAB/event_detection_mark_1/CameraCalibration/SceneCameraParameters.mat', 'SceneCameraParams')
    load('/home/rakshit/Documents/MATLAB/event_detection_mark_1/CameraCalibration/StereoCameraParameters.mat', 'StereoCameraParams')
    if exist(fullfile(Path2Checkers, sprintf('ExtractedCheckers_PrIdx_%d_TrIdx_%d.mat', PrIdx, TrIdx)), 'file')
        clear T_off
        load(fullfile(Path2Checkers, sprintf('ExtractedCheckers_PrIdx_%d_TrIdx_%d.mat', PrIdx, TrIdx)),...
            'T_off', 'Left_Checkers', 'Scene_Checkers')
    end
    CheckerSize_mm = 69.85;
    worldPts = generateCheckerboardPoints([7, 10], CheckerSize_mm);

    str_ParamData = ['Params_PrIdx_', num2str(PrIdx), '_TrIdx_', num2str(TrIdx), '.mat'];
    str_ProcessData = ['PrIdx_', num2str(PrIdx), '_TrIdx_', num2str(TrIdx), '.mat'];
    str_CheckerData = sprintf('ExtractedCheckers_PrIdx_%d_TrIdx_%d.mat', PrIdx, TrIdx);
    useTimingFile = ParticipantInfo(PrIdx).useTimingInfo(TrIdx);

    Start_h = ParticipantInfo(PrIdx).Start_h(TrIdx);
    Start_m = ParticipantInfo(PrIdx).Start_m(TrIdx);
    Start_s = ParticipantInfo(PrIdx).Start_s(TrIdx);

    if exist([Path2ProcessData, str_ProcessData], 'file')
        load([Path2ProcessData, str_ProcessData], 'ProcessData')
        disp('ProcessData loaded!')
    else
        disp('ProcessData does not exist')
        str_Date = datestr(datetime());
        save([Path2ProcessData, str_ProcessData], 'str_Date');
    end

    if exist([Path2TempData, str_ParamData], 'file')
        disp('TempData loaded!')
        load([Path2TempData, str_ParamData])
        CheckersExtracted = 1;
    else
        disp('TempData does not exist')
        save([Path2TempData, str_ParamData], 'str_Date');
        CheckersExtracted = 0;
    end

    if ~exist('depth_extracted', 'var')
        depth_extracted = 0;
        disp('Depth has not been extracted')
    elseif exist('depth_extracted', 'var') && ~isfield(ProcessData, 'SceneDepth')
        disp('Did not find SceneDepth in ProcessData. Regenerating Depth.')
        depth_extracted = 0;
        regenerate_depth = 1;
    elseif exist('depth_extracted', 'var') && isfield(ProcessData, 'SceneDepth') && depth_extracted
        % Change the flags here if you want to regenerate the depth values, no
        % matter what. 
        disp('Depth has been processed')
        regenerate_depth = 0;
        depth_extracted = 1;
    end

    if ~exist('RandT_extracted', 'var')
        RandT_extracted = 0;
        disp('3D ZED2ETG Transformation does not exist. Regenerating it.')
    end

    ETG.SceneResolution = [1920, 1080];
    %% Read ZED Data

    if ParticipantInfo(PrIdx).OldStyle
        Timing_Info = csvread(strcat(Path2Data, 'timing.txt'));
        ZED_original_T = Timing_Info(:,2)*3600 + Timing_Info(:,3)*60 + Timing_Info(:,4) + Timing_Info(:,5)*10^-6;
        temp = readtable(strcat(Path2Data, 'PosData.txt'));
        ZED.PosData = [temp.tx, temp.ty, temp.tz];
        ZED.RotData = [temp.rx, temp.ry, temp.rz];
        
        ZED.Frames = [1:length(ZED_original_T)] - 1;
        
        if length(ZED_original_T) > length(ZED.PosData)
            ZED_original_T(1) = [];
            ZED.Frames(1) = [];
        elseif length(ZED_original_T) < length(ZED.PosData)
            keyboard
        end
    else
        ZED.Pos_Info = readtable(strcat(Path2Data, 'PosData.txt'));
        ZED.PosData = table2array(ZED.Pos_Info(:, 2:4));
        ZED.RotData = table2array(ZED.Pos_Info(:, 5:8));
        
        if ~useTimingFile
            % Timing values are in Unix nanosecond time
            Timing_Info = datevec(datetime(table2array(ZED.Pos_Info(:, 1))/(10^9), 'ConvertFrom', 'posixtime', 'TimeZone', 'America/New_York'));
            ZED_original_T = Timing_Info(:,4)*3600 + Timing_Info(:,5)*60 + Timing_Info(:,6);
        else
            Timing_Info = csvread(strcat(Path2Data, 'timing.txt'));
            ZED_original_T = Timing_Info(:,2)*3600 + Timing_Info(:,3)*60 + Timing_Info(:,4) + Timing_Info(:,5)*10^-6;
        end
        
        ZED.Frames = [1:length(ZED_original_T)] - 1;
        
        if length(ZED_original_T) > length(ZED.PosData)
            ZED_original_T(1) = [];
            ZED.Frames(1) = [];
        elseif length(ZED_original_T) < length(ZED.PosData)
            keyboard
        end
    end

    % Linearize data also returns an updated timing sequence which is linear in
    % nature. Do not use it to replace the original time because that will
    % create complications in analysis.
    [ZED.Frames, ~] = linearizeData(ZED_original_T, ZED.Frames, 'nearest');
    [ZED.PosData, ~] = linearizeData(ZED_original_T, ZED.PosData, 'makima');
    [ZED.RotData, ZED.T] = linearizeData(ZED_original_T, ZED.RotData, 'makima');
    ZED.Frames = round(ZED.Frames);

    if ~ParticipantInfo(PrIdx).OldStyle
        start_vec = normr([0, 0, -1]); 
        % Because right handed, Y-up, for the ZED means Z is negative.
        ZED.RotData = medfilt1(ZED.RotData, 5, [], 1, 'omitnan', 'truncate');
        ZED.headvector = quatrotate(ZED.RotData, start_vec);
        ZED.headvector = cleanHeadData(ZED.T - ZED.T(1), ZED.headvector, 0);
        ZED.head_vel = findHeadVelocity(ZED.T - ZED.T(1), ZED.headvector);
    else
        start_vec = normr([0, 0, -1]);
        % Because right handed, Y-up, for the ZED means Z is negative.
        RotData = zeros(length(ZED.RotData), 4);
        for i = 1:length(RotData)
            % Not sure if rotation vector or eulers. Check and confirm for
            % OldStyle subjects. Confirmed: Rotation vector.
            RotData(i, :) = rotm2quat(rotationVectorToMatrix(ZED.RotData(i, :)));
        end
        ZED.RotData = RotData;
        ZED.headvector = quatrotate(RotData, start_vec);
        ZED.headvector = cleanHeadData(ZED.T - ZED.T(1), ZED.headvector, 0);
        ZED.head_vel = findHeadVelocity(ZED.T - ZED.T(1), ZED.headvector);
    end
        
    %% Read IMU Data

    IMU_Data = readtable(strcat(Path2Data, 'IMU/IMUData.txt'));
    IMU.Calib = table2array(IMU_Data(:, 1));
    IMU.Data = IMU_Data(:, 2:end);

    % Generate time
    IMU_original_T = IMU_Data.Hour*3600 + IMU_Data.Minute*60 + IMU_Data.Second + IMU_Data.Microsecond*10^-6;

    %% Read ETG Data

    Gaze_Data = readtable([Path2Data, 'Gaze/exports/gaze_positions.csv'], ...
        'Format', [repmat('%f', 1, 5), '%s', repmat('%f', 1, 15)]);
    Pupil_Data = readtable([Path2Data, 'Gaze/exports/pupil_positions.csv']);

    fid = fopen(fullfile(Path2Data, 'Gaze' ,'Eye1', 'timing.txt'), 'r');
    Eye1_Timing = cell2mat(textscan(fid, '%f,%f')); fclose(fid);
    fid = fopen(fullfile(Path2Data, 'Gaze' ,'Eye0', 'timing.txt'), 'r');
    Eye0_Timing = cell2mat(textscan(fid, '%f,%f')); fclose(fid);

    Fix_Data = readtable([Path2Data, 'Gaze/exports/fixations.csv'], 'Delimiter', ',');
    Blink_Data = readtable([Path2Data, 'Gaze/exports/blinks.csv']);

    ETG_T = Gaze_Data.timestamp;
    ETG_labels = zeros(length(ETG_T), 1);
    for i = 1:height(Fix_Data)
        t1 = Fix_Data.start_timestamp(i); t2 = Fix_Data.start_timestamp(i) + Fix_Data.duration(i)/1000;
        ETG_labels(ETG_T >= t1 & ETG_T <= t2) = 1;
    end

    for i = 1:height(Blink_Data)
        t1 = Blink_Data.start_timestamp(i); t2 = Blink_Data.end_timestamp(i);
        ETG_labels(ETG_T >= t1 & ETG_T <= t2) = 4;
    end

    %% Extract Pupil related data
    eye0_Idx = find(~Pupil_Data.id);
    eye1_Idx = find(Pupil_Data.id);

    t_eye0 = Pupil_Data.timestamp(eye0_Idx); t_eye1 = Pupil_Data.timestamp(eye1_Idx);
    dia_eye0 = Pupil_Data.diameter_3d(eye0_Idx); dia_eye1 = Pupil_Data.diameter_3d(eye1_Idx);
    conf_eye0 = Pupil_Data.confidence(eye0_Idx); conf_eye1 = Pupil_Data.confidence(eye1_Idx);
    pupil_radius_eye0 = Pupil_Data.diameter_3d(eye0_Idx); pupil_radius_eye1 = Pupil_Data.diameter_3d(eye1_Idx);
    
    locForFix_eye0 = isoutlier(dia_eye0, 'gesd', 'ThresholdFactor', 0.8, 'SamplePoints', t_eye0) | conf_eye0 <= 0.3;
    locForFix_eye1 = isoutlier(dia_eye1, 'gesd', 'ThresholdFactor', 0.8, 'SamplePoints', t_eye1) | conf_eye1 <= 0.3;

    ETG.pupil_radius_eye0 = interp1(t_eye0(~locForFix_eye0), pupil_radius_eye0(~locForFix_eye0), ETG_T, 'makima', 'extrap').';
    ETG.pupil_radius_eye1 = interp1(t_eye1(~locForFix_eye1), pupil_radius_eye1(~locForFix_eye1), ETG_T, 'makima', 'extrap').';
    
    locForFix_eye0 = logical(interp1(t_eye0, double(locForFix_eye0), ETG_T, 'nearest', 'extrap'));
    locForFix_eye1 = logical(interp1(t_eye1, double(locForFix_eye1), ETG_T, 'nearest', 'extrap'));

    %% Find Head velocity
    quat = [IMU.Data.Qw, IMU.Data.Qx, IMU.Data.Qy, IMU.Data.Qz];
    quat = quatnormalize(quat);
    quat = quatinv(quat); % IMU relative to earth

    % Rotate head coordinate system such that end of calib equates to
    % unit quat. This will ensure a simpler rotation operation later on.
    n = find(IMU.Calib, 1, 'first');
    quat = quatmultiply(quat, quatinv(quat(n, :)));
    
    IMU.T = linspace(min(IMU_original_T), max(IMU_original_T), numel(IMU_original_T));
    IMU.T = IMU.T(:);
    
    % Interpolate calibration flag to the new time stamps
    IMU.Calib = interp1(IMU_original_T, IMU.Calib, IMU.T, 'nearest');
    
    % Find locations when time is non-monotonic.
    loc = [0; diff(IMU_original_T(:))] <= 0;
    quat(loc, :) = [];
    IMU_original_T(loc) = [];

    % Use slerp to interpolate Quaternion signals
    quat = quat_interp_slerp(IMU_original_T, quat, IMU.T);
    IMU.HeadPose = quat;
    
    % Initial arbitary vector. [0, 0, 1] ensures that rotation occurs only
    % around 1 axis. Do not use [1, 0, 0] because it creates improper
    % rotational values.
    start_vec = normr([0, 0, 1]);
    IMU.headvector = quatrotate(quat, start_vec);

    IMU.headvector = cleanHeadData(IMU.T - IMU.T(1), IMU.headvector, 1);
    IMU.head_vel = findHeadVelocity(IMU.T - IMU.T(1), IMU.headvector);

    %% Assign left and right eye image frame number
    ETG_T = Start_h*3600 + Start_m*60 + Start_s + Gaze_Data.timestamp - Gaze_Data.timestamp(1);

    temp = Gaze_Data.timestamp;
    temp0 = Eye0_Timing(:, 2);
    temp1 = Eye1_Timing(:, 2);

    out0 = zeros(length(ETG_T), 1);
    out1 = out0;

    parfor i = 1:length(ETG_T)
        out0(i) = findClosest(temp0, temp(i)) - 1;
        out1(i) = findClosest(temp1, temp(i)) - 1;
    end

    ETG.LeftEyeFrameNo = out0;
    ETG.RightEyeFrameNo = out1;

    %% POR, confidence and Scene frame
    ETG.POR = [Gaze_Data.norm_pos_x, Gaze_Data.norm_pos_y];

    % Converting POR to MATLAB coordinates
    ETG.POR(:, 2) = 1 - ETG.POR(:, 2);

    ETG.Confidence = Gaze_Data.confidence;
    ETG.SceneFrameNo = Gaze_Data.index;

    EIHvector_0 = [Gaze_Data.gaze_normal0_x, Gaze_Data.gaze_normal0_y, Gaze_Data.gaze_normal0_z];
    EIHvector_1 = [Gaze_Data.gaze_normal1_x, Gaze_Data.gaze_normal1_y, Gaze_Data.gaze_normal1_z];

    %% Find Gaze velocity
    % Interpolate over missing samples, values where the eye points inward
    % and general stability.
    temp_T = ETG_T;
    loc_nan_zero_0 = isnan(EIHvector_0);
    loc_nan_zero_0 = logical(sum(loc_nan_zero_0, 2)) | logical(sum(EIHvector_0 == 0, 2) == 3) | locForFix_eye0;
    EIHvector_0(loc_nan_zero_0, :) = []; temp_T(loc_nan_zero_0) = []; 
    EIHvector_0 = interp1(temp_T, EIHvector_0, ETG_T, 'pchip', 'extrap'); % Interpolate over bad samples
    EIHvector_0(EIHvector_0 > 1) = 1; EIHvector_0(EIHvector_0 < -1) = -1;

    temp_T = ETG_T;
    loc_nan_zero_1 = isnan(EIHvector_1); 
    loc_nan_zero_1 = logical(sum(loc_nan_zero_1, 2)) | logical(sum(EIHvector_1 == 0, 2) == 3) | locForFix_eye1;
    EIHvector_1(loc_nan_zero_1, :) = []; temp_T(loc_nan_zero_1) = []; 
    EIHvector_1 = interp1(temp_T, EIHvector_1, ETG_T, 'pchip', 'extrap'); % Interpolate over bad samples
    EIHvector_1(EIHvector_1 > 1) = 1; EIHvector_1(EIHvector_1 < -1) = -1;

    % Remove unused variables from workspace to reduce confusion
    ETG.EIHvector_0 = EIHvector_0; clear EIHvector_0;
    ETG.EIHvector_1 = EIHvector_1; clear EIHvector_1;

    %% Combine left and right gaze vectors
    % Before this step, it is essential to have interpolate the vectors.
    % Missing values will cause sporadic jumps in the velocity signal.

    % Extrapolate to a steady and linear time series
    [ETG.EIHvector_0, ~] = linearizeData(ETG_T, ETG.EIHvector_0, 'pchip');
    [ETG.EIHvector_1, ~] = linearizeData(ETG_T, ETG.EIHvector_1, 'pchip');
    [ETG.POR, ~] = linearizeData(ETG_T, ETG.POR, 'pchip');
    [ETG.Confidence, ~] = linearizeData(ETG_T, ETG.Confidence, 'pchip');
    [ETG.SceneFrameNo, ~] = linearizeData(ETG_T, ETG.SceneFrameNo, 'nearest');
    [ETG.LeftEyeFrameNo, ~] = linearizeData(ETG_T, ETG.LeftEyeFrameNo, 'nearest');
    [ETG.RightEyeFrameNo, ~] = linearizeData(ETG_T, ETG.RightEyeFrameNo, 'nearest');
    [ETG.labels, ~] = linearizeData(ETG_T, ETG_labels, 'nearest');
    [ETG.pupil_radius_eye0, ~] = linearizeData(ETG_T, ETG.pupil_radius_eye0, 'spline');
    [ETG.pupil_radius_eye1, ETG.T] = linearizeData(ETG_T, ETG.pupil_radius_eye1, 'spline');
    % It's better to replace with a very small number for numerical
    % stability
    ETG.Confidence(ETG.Confidence <= 0) = 0.00001; ETG.Confidence(ETG.Confidence > 1) = 1;

    % Combine to produce Cyclopean gaze vector
    ETG.EIHvector = (ETG.EIHvector_0 + ETG.EIHvector_1)/2;
    ETG.EIHvector = normr(ETG.EIHvector);
    ETG.EIHvector(ETG.EIHvector > 1) = 1; ETG.EIHvector(ETG.EIHvector < -1) = -1;

    ETG.EIHvector_raw = ETG.EIHvector;

    % Find EIH velocity using raw data
    ETG.EIH_rawvel = findGazeVelocity(ETG.T, ETG.EIHvector_raw, 0, 0);

    % Clean and find EIH velocity
    ETG.EIHvector = cleanGazeData(ETG.T, ETG.EIHvector_raw, 1);
    ETG.EIH_vel = findGazeVelocity(ETG.T, ETG.EIHvector, 1, 0);

    %% Find time shifts
    % Find Calibration sequence flags
    VOR_start_imu = max(find(IMU.Calib, 1, 'first') - 150, 1);
    VOR_stop_imu = find(IMU.Calib, 1, 'last') + 150;

    Sgn1 = IMU.head_vel(VOR_start_imu: VOR_stop_imu);
    t1 = IMU.T(VOR_start_imu: VOR_stop_imu);

    % Find the equivalent flag time in ETG data
    VOR_start_etg = findClosest(ETG.T, IMU.T(VOR_start_imu));
    VOR_stop_etg = findClosest(ETG.T, IMU.T(VOR_stop_imu));

    Sgn2 = ETG.EIH_vel(VOR_start_etg:VOR_stop_etg);
    t2 = ETG.T(VOR_start_etg: VOR_stop_etg);

    % Find the equivalent flag time in ZED data
    VOR_start_zed = findClosest(ZED.T, IMU.T(VOR_start_imu));
    VOR_stop_zed = findClosest(ZED.T, IMU.T(VOR_stop_imu));

    Sgn3 = ZED.head_vel(VOR_start_zed:VOR_stop_zed);
    t3 = ZED.T(VOR_start_zed: VOR_stop_zed);

    % Find time shift between eye tracker and IMU using Cross-correlation
    t_off_etg = findTimeShift(Sgn1, t1, Sgn2, t2, 0);
   
    figure;
    plot(t1, Sgn1); hold on;
    plot(t2 + ProcessData.ETG_toff, Sgn2)
    xlabel('Time')
    
    flagno = 0;
    if isfield(ProcessData, 'ETG_toff')
        % If ETG_toff exists in the current process data, it would have
        % been extracted before. Verify that time shift cross correlation
        % and ETG_toff have the same value. If not, manual intervention
        % required.
        if abs(t_off_etg - ProcessData.ETG_toff) < 0.010
            % Time shifts are within 10 milliseconds. It's fine. Proceed.
%             ProcessData.PotentialLabelShift = t_off_etg - ProcessData.ETG_toff;
            disp('ETG and IMU timing aligned')
        else
            figure;
            plot(t1, Sgn1); hold on;
            plot(t2 + t_off_etg, Sgn2)
            xlabel('Time')
            keyboard
        end
        if exist('T_off', 'var')
            % Time offset using checkerboard corners presents
            tempZEDtime = ZED.T + ProcessData.ETG_toff + T_off;
        elseif ~exist('T_off', 'var') && ProcessData.DepthPresent
            error('Checkers not extracted. Depth is presented.')
        elseif exist('T_off', 'var') && ~ProcessData.DepthPresent
            disp('Strange case. Checkers present but no depth.')
            tempZEDtime = ZED.T + ProcessData.ETG_toff + T_off;
        elseif ~ProcessData.DepthPresent
            % Depth data not present. Assume a lag of 0.05s. This number is
            % approximately the median of observed lags for all participants.
            if 0%input('Use old, potentially corrupt signal?')
                tempZEDtime = ZED.T + ProcessData.ZED_toff;
            else
                tempZEDtime = ZED.T + ProcessData.ETG_toff + 0.05;
            end
        end
        
        figure;
        plot(ETG.T + ProcessData.ETG_toff, ETG.EIH_vel); hold on;
        plot(IMU.T, IMU.head_vel)
        plot(tempZEDtime, ZED.head_vel)
        xlabel('Time')
        legend('ETG', 'IMU', 'ZED')
        title('Looks good?')
        if 1%input('Looks good?')
            ETG.T = ETG.T + ProcessData.ETG_toff;
            flagno = 1;
        else
            flagno = 0;
        end
    elseif ~isfield(ProcessData, 'ETG_toff') || flagno == 1
        figure; hold on;
        plot(t1 - max([t1(1), t2(1), t3(1)]), Sgn1, 'LineWidth', 1.5)
        plot(t2 - max([t1(1), t2(1), t3(1)]), Sgn2, 'LineWidth', 1.5); 
        plot(t3 - max([t1(1), t2(1), t3(1)]), Sgn3, 'LineWidth', 1.5); hold off
        legend('IMU', 'ETG', 'ZED')
        grid on
        title(sprintf('ETG offset: %f, ZED offset: %f', t_off_etg,...
            ProcessData.ETG_toff + T_off))

        % Enter timing shift based on suggestion. Shift ETG signal.
        T_manual_offset = input('Enter ETG timing offset: ');
        ETG.T = ETG.T + T_manual_offset; ProcessData.ETG_toff = T_manual_offset;
        tempZEDtime = ProcessData.ETG_toff + T_off;
        
        % Verify the sources have lined up
        % Confirm they look good
        figure; hold on;
        plot(ETG.T, ETG.EIH_vel)
        plot(IMU.T, IMU.head_vel)
        plot(tempZEDtime, ZED.head_vel)
        xlabel('Time')
        legend('ETG', 'IMU', 'ZED')
        grid on
        keyboard
    end
    
    % Let ZED.T be the original corrupted time stamp. Signals were produced
    % based on this time stamp. For more information on this process,
    % contact the author: Rakshit Kothari.
    ZED.T = ZED.T + ProcessData.ZED_toff;
    close all

    % Find VOR frames in shifted ETG scene images. Note that the time
    % t_start hasn't changed. That's because all timings are shifted to IMU
    % time stamp, which is approximately 100ms shifted due to Arduino
    % overhead.
    t_start = IMU.T(find(IMU.Calib, 1, 'first'));
    t_stop = IMU.T(find(IMU.Calib, 1, 'last'));
    VOR_start_etg = findClosest(ETG.T, t_start);
    VOR_stop_etg = findClosest(ETG.T, t_stop);

%     % Find VOR frames in IMU
%     VOR_start_imu = findClosest(IMU.T, t_start);
%     VOR_stop_imu = findClosest(IMU.T, t_stop);

%     % Find VOR frames in ZED Depth and Left images
%     VOR_start_zed = findClosest(ZED.T, t_start);
%     VOR_stop_zed = findClosest(ZED.T, t_stop);

    %% Assume ETG has been correctly rotated in the past
    figure;
    plot(ETG.EIHvector*RotMat_etg)
    title('Confirm alignment')
    
    if exist('RotMat_etg', 'var') && 1%input('Use old alignment?')
        ETG.EIHvector = ETG.EIHvector*RotMat_etg;
        ETG.EIHvector_raw = ETG.EIHvector_raw*RotMat_etg;
        ETG.EIHvector_0 = ETG.EIHvector_0*RotMat_etg;
        ETG.EIHvector_1 = ETG.EIHvector_1*RotMat_etg;
    else
        % Manually rotate ETG to reflect [0, 0, 1]
        % Correct ETG coordinate system
        R_org = rotationVectorToMatrix([0, 0, pi]);
        
        [~, EyeCorrect_mat] = RotateVectors(ETG.EIHvector(VOR_start_etg, :)*R_org, [0, 0, 1]);
        ETG.EIHvector = ETG.EIHvector*R_org*EyeCorrect_mat;
        ETG.EIHvector_raw = ETG.EIHvector_raw*EyeCorrect_mat;
        ETG.EIHvector_0 = ETG.EIHvector_0*R_org*EyeCorrect_mat;
        ETG.EIHvector_1 = ETG.EIHvector_1*R_org*EyeCorrect_mat;
        RotMat_etg = R_org*EyeCorrect_mat;
        
        figure;
        plot(ETG.EIHvector)
        title('Confirm alignment')
        
        
        save([Path2TempData, str_ParamData], 'RotMat_etg', '-append')
    end

    %% Automated correction using grid search
    % Provide an initial estimate for rotating IMU to ETG coordinate
    % system. Assume ETG has been appropriately rotated. Grid search
    % method. Unfortunately this method takes a very long time since
    % multiple solutions possible. For future: lsqnonlin 
    
%     close all
%     t_IMU = IMU.T(VOR_start_imu:VOR_stop_imu);
%     q_IMU = IMU.HeadPose(VOR_start_imu:VOR_stop_imu, :);
%     t_ETG = ETG.T(VOR_start_etg:VOR_stop_etg);
%     v_ETG = ETG.EIHvector(VOR_start_etg:VOR_stop_etg, :);
    
%     xRot = linspace(-pi, pi, 20);
%     yRot = linspace(-pi, pi, 20);
%     zRot = linspace(-pi, pi, 20);
%     [X, Y, Z] = meshgrid(xRot, yRot, zRot);
%     X = X(:); Y = Y(:); Z = Z(:);
% 
%     val = zeros(length(X), 1);
%     parfor  i = 1:length(X)
%        val(i) = autoCorrect(t_IMU, quat2rotm(q_IMU), t_ETG, v_ETG, [X(i), Y(i), Z(i)]);
%     end

    %% Manual adjustment
    if ~exist('RotMat_hv', 'var') && exist('IMUScale', 'var')
        disp('IMU rotation does not exist.')
        [RotMat_imu, RotMat_hv, IMUScale] = IMUCorrection(IMU.T, quat2rotm(IMU.HeadPose), ...
            ETG.T, ETG.EIHvector, eye(3), eye(3), IMUScale, IMU.Calib);
        save([Path2TempData, str_ParamData], 'RotMat_hv', 'RotMat_imu', 'IMUScale', '-append')
    elseif exist('RotMat_hv', 'var') && ~exist('IMUScale', 'var')
        disp('IMU Scaling does not exist')
        [RotMat_imu, RotMat_hv, IMUScale] = IMUCorrection(IMU.T, quat2rotm(IMU.HeadPose), ...
            ETG.T, ETG.EIHvector, RotMat_imu, RotMat_hv, [1, 1, 1], IMU.Calib);
        save([Path2TempData, str_ParamData], 'RotMat_hv', 'RotMat_imu', 'IMUScale', '-append')
    elseif ~exist('RotMat_hv', 'var') && ~exist('IMUScale', 'var')
        disp('Neither rotation nor IMU scaling exists')
        [RotMat_imu, RotMat_hv, IMUScale] = IMUCorrection(IMU.T, quat2rotm(IMU.HeadPose), ...
            ETG.T, ETG.EIHvector, eye(3), eye(3), [1, 1, 1], IMU.Calib);
        save([Path2TempData, str_ParamData], 'RotMat_hv', 'RotMat_imu', 'IMUScale', '-append')
    else
        newR = RapidRotate(quat2rotm(IMU.HeadPose), RotMat_imu, 'mm');
        headCentered = RapidRotate(newR(:, :, find(IMU.Calib, 1, 'first'))', newR, 'mm');
        headCentered(:, :, n:end) = smoothMove(headCentered(:, :, n:end), IMUScale);
        temp_hv = RapidRotate(RapidRotate(RotMat_hv, headCentered, 'mm'), [0, 0, 1], 'mv');
        
        % Check if you need to readjust the rotation matrices
        figure; hold on;
        plot(IMU.T, temp_hv)
        plot(ETG.T, ETG.EIHvector)
        xlabel('Time'); ylabel('Vector components')
        grid on;
        
        if 0%input('Do you want to fine tune the Rotation matrices')
            close all
            [RotMat_imu, RotMat_hv, IMUScale] = IMUCorrection(IMU.T, quat2rotm(IMU.HeadPose), ...
            ETG.T, ETG.EIHvector, RotMat_imu, RotMat_hv, IMUScale, IMU.Calib);
            save([Path2TempData, str_ParamData], 'RotMat_hv', 'RotMat_imu', 'IMUScale', '-append')
        end
    end
    
    %% Update aligned signals
    % Rotate IMU pose such that the axis are aligned to gravity
    newR = RapidRotate(quat2rotm(IMU.HeadPose), RotMat_imu, 'mm');
    
    % Transfer coordinate system to our world coordinate space
    headCentered = RapidRotate(newR(:, :, find(IMU.Calib, 1, 'first'))', newR, 'mm');
    
    % Maintain original, drift corrupted signal. Compensate for forehead
    % profile.
    IMU.HeadPose_cor = rotm2quat(RapidRotate(RotMat_hv, headCentered, 'mm'));
    
    % Remove drift measurement but from the start of calibration. This
    % ensures that we do not compensate for stray motion leading upto head
    % alignment.
    headCentered(:, :, find(IMU.Calib, 1, 'first'): end) = ...
        smoothMove(headCentered(:, :, find(IMU.Calib, 1, 'first'): end), IMUScale);
    
    % Compensate for forehead profile.
    IMU.HeadPose = rotm2quat(RapidRotate(RotMat_hv, headCentered, 'mm'));
    
    % Rotate Z vector with head pose to find head vector through the trial.
%     IMU.headvector = RapidRotate(RapidRotate(RotMat_hv, headCentered, 'mm'), [0, 0, 1], 'mv');
    IMU.headvector = quatrotate(IMU.HeadPose, [0, 0, 1]);
    
    % Filter head vector data with an antialiasing filter at 50Hz
    IMU.headvector = cleanHeadData(IMU.T, IMU.headvector, 0);
    
    % Compute head velocity
    IMU.head_vel = findHeadVelocity(IMU.T, IMU.headvector);

    %% Fix left and right gaze vectors
    % ASSUMPTION: The assumption at this point is that the IMU, ETG and ZED
    % have all been temporally synced.
    %eye1 - left
    %eye0 - right
    %left hand size -> positive

    close all

    if ~isfield(ProcessData, 'dist2chart')
        figure;
        plot(ETG.T(VOR_start_etg: VOR_stop_etg), ETG.EIHvector_0(VOR_start_etg:VOR_stop_etg, :))
        hold on;
        xlabel('Time (s)')
        drawnow
        title('To find distance to Checkerboard')
        [x, ~] = ginput(1);
        close all

        loc = findClosest(ETG.T, x(1));
        I = rgb2gray(imread([Path2Data, 'Gaze/Scene/', num2str(Gaze_Data.index(loc)) '.jpg']));
        checkerpoints = detectCheckerboardPoints(I);
        [~, T] = extrinsics(checkerpoints, worldPts, SceneCameraParams);
        ProcessData.dist2chart = T(3);
    end
    v_calib_0 = ETG.EIHvector_0(VOR_start_etg, :);
    v_calib_1 = ETG.EIHvector_1(VOR_start_etg, :);

    IOD = 62.85;

    if ~isfield(ProcessData, 'R0')
    % Average human IOD measured from American population
        ProcessData.R0 = RotateVectors(v_calib_0, normr([ IOD/2, 0, ProcessData.dist2chart]));
        ProcessData.R1 = RotateVectors(v_calib_1, normr([-IOD/2, 0, ProcessData.dist2chart]));
    end

    % Additional rotation to fix the gaze normals
    ETG.EIHvector_0 = ETG.EIHvector_0*ProcessData.R0;
    ETG.EIHvector_1 = ETG.EIHvector_1*ProcessData.R1;

    %% Find Vergence and verify

    ETG.Vergence = AngleBetweenVectors(ETG.EIHvector_0, ETG.EIHvector_1);

    if plotProcessFigures
        figure
        plot(ETG.T, ETG.Vergence)
        title('Vergence signal')
        
        figure; hold on;
        plot(IMU.T(VOR_start_imu:VOR_stop_imu), IMU.headvector(VOR_start_imu:VOR_stop_imu, :))
        plot(ETG.T(VOR_start_etg:VOR_stop_etg), ETG.EIHvector(VOR_start_etg:VOR_stop_etg, :))
        xlabel('Time'); ylabel('Vector componenets')
        grid on;
        drawnow
    end

    %% Zero center time data
    % It is essential here that the corrupted ZED.T be used. This ensures
    % that the labels won't be shifted.
    t_start = max([ETG.T(1), IMU.T(1), ZED.T(1)]);
    ETG.T = ETG.T - t_start; IMU.T = IMU.T - t_start; ZED.T = ZED.T - t_start;
    tempZEDtime = tempZEDtime - t_start; % This will potentially produce negative values

    %% Find Horizontal and Vertical velocity components
    [IMU.az, IMU.el, ~] = cart2sph(-IMU.headvector(:, 1), IMU.headvector(:, 3), IMU.headvector(:, 2));
    [ETG.az, ETG.el, ~] = cart2sph(-ETG.EIHvector(:, 1), ETG.EIHvector(:, 3), ETG.EIHvector(:,2));

    IMU.az_vel = findAngularVelocity(IMU.T, IMU.az); IMU.el_vel = findAngularVelocity(IMU.T, IMU.el);
    ETG.az_vel = findAngularVelocity(ETG.T, ETG.az); ETG.el_vel = findAngularVelocity(ETG.T, ETG.el);

    %% Review data quality
    if plotProcessFigures
        figure;

        subplot(2, 2, 1); 
        plot(IMU.T, IMU.az_vel); hold on;
        plot(ETG.T, ETG.az_vel); hold off;
        title('Az velocity');
        legend('IMU', 'ETG')
        grid on
        title('Azimuthal velocities')

        subplot(2, 2, 2);
        plot(IMU.T, IMU.el_vel); hold on;
        plot(ETG.T, ETG.el_vel); hold off;
        title('El velocity');
        legend('IMU', 'ETG')
        grid on
        title('Elevation velocities')

        subplot(2, 2, 3);
        plot(IMU.T, 180*IMU.az/pi); hold on;
        plot(ETG.T, 180*ETG.az/pi); hold off;
        title('Az')
        legend('IMU', 'ETG')
        grid on

        subplot(2, 2, 4);
        plot(IMU.T, 180*IMU.el/pi); hold on;
        plot(ETG.T, 180*ETG.el/pi); hold off;
        legend('IMU', 'ETG')
        title('Elevation')
        legend('IMU', 'ETG')
        grid on;

        figure; 
        plot(IMU.T, IMU.head_vel); hold on;
        plot(ETG.T, ETG.EIH_vel)
        grid on
        legend('Head', 'EIH')
        xlabel('Time (S)')
        ylabel('Velocity (\circ /s)')
        title('Velocity')

        figure; 
        plot(IMU.T, IMU.headvector); hold on;
        plot(ETG.T, ETG.EIHvector);
        legend('H_x', 'H_y', 'H_z', 'E_x', 'E_y', 'E_z')
        grid on
        xlabel('Time (S)')
        ylabel('Unit')
        title('Vectors')
    end

    %% Clip data
    % Remove all samples where T < 0
    
    % IMU data
    loc = IMU.T < 0;
    IMU.headvector(loc, :) = []; 
    IMU.head_vel(loc, :) = []; 
    IMU.T(loc, :) = []; 
    IMU.Calib(loc, :) = [];
    IMU.az_vel(loc) = [];
    IMU.el_vel(loc) = [];
    IMU.HeadPose(loc, :) = [];
    IMU.HeadPose_cor(loc, :) = [];

    % ETG data
    loc = ETG.T < 0; shiftvid = ETG.T(find(~loc, 1));
    ETG.EIHvector(loc, :) = [];
    ETG.EIHvector_raw(loc, :) = [];
    ETG.SceneVideo.CurrentTime = shiftvid;
    ETG.EIH_vel(loc, :) = []; 
    ETG.SceneFrameNo(loc) = []; 
    ETG.T(loc, :) = [];
    ETG.az_vel(loc) = [];
    ETG.el_vel(loc) = [];
    ETG.POR(loc, :) = [];
    ETG.Confidence(loc) = [];
    ETG.LeftEyeFrameNo(loc) = [];
    ETG.RightEyeFrameNo(loc) = [];
    ETG.labels(loc) = [];
    ETG.Vergence(loc) = [];
    ETG.EIH_rawvel(loc) = [];
    ETG.EIHvector_0(loc, :) = [];
    ETG.EIHvector_1(loc, :) = [];
    ETG.pupil_radius_eye0(loc) = [];
    ETG.pupil_radius_eye1(loc) = [];
    
    % ZED data
    loc = ZED.T < 0; 
    ZED.T = tempZEDtime;
    shiftvid = ZED.T(find(~loc, 1));
    ZED.T(loc) = []; ZED.LeftVideo.CurrentTime = shiftvid;
    ZED.Frames(loc) = []; ZED.RightVideo.CurrentTime = shiftvid;
    ZED.DepthVideo.CurrentTime = shiftvid;
    ZED.PosData(loc, :) = [];
    ZED.RotData(loc, :) = [];

    disp(['ETG end time: ', num2str(ETG.T(end))])
    disp(['IMU end time: ', num2str(IMU.T(end))])
    disp(['ZED end time: ', num2str(ZED.T(end))])

    %DepthPresent = input('Based on end time, is Depth present?');
    if ZED.T(end) < ETG.T(end)/2 || ZED.T(end) < ETG.T(end)/2
        DepthPresent = 0;
        fprintf('Depth present: %d\n', DepthPresent)
    else
        DepthPresent = 1;
        fprintf('Depth present: %d\n', DepthPresent)
    end
    
    % Find minimum stop time value
    max_T = min([IMU.T(end), ETG.T(end)]);

    % Remove all samples where T > maximum value
    loc = IMU.T > max_T;
    IMU.headvector(loc, :) = []; 
    IMU.head_vel(loc, :) = []; 
    IMU.T(loc, :) = []; 
    IMU.Calib(loc, :) = [];
    IMU.az_vel(loc) = [];
    IMU.el_vel(loc) = [];
    IMU.HeadPose(loc, :) = [];
    IMU.HeadPose_cor(loc, :) = [];

    loc = ETG.T > max_T;
    ETG.EIHvector(loc, :) = [];
    ETG.EIHvector_raw(loc, :) = [];
    ETG.EIH_vel(loc, :) = []; 
    ETG.SceneFrameNo(loc) = []; 
    ETG.T(loc, :) = [];
    ETG.az_vel(loc) = [];
    ETG.el_vel(loc) = [];
    ETG.POR(loc, :) = [];
    ETG.Confidence(loc) = [];
    ETG.LeftEyeFrameNo(loc) = [];
    ETG.RightEyeFrameNo(loc) = [];
    ETG.labels(loc) = [];
    ETG.Vergence(loc) = [];
    ETG.EIH_rawvel(loc) = [];
    ETG.EIHvector_0(loc, :) = [];
    ETG.EIHvector_1(loc, :) = [];
    ETG.pupil_radius_eye0(loc) = [];
    ETG.pupil_radius_eye1(loc) = [];
    
    loc = ZED.T > max_T;
    ZED.T(loc) = [];
    ZED.Frames(loc) = [];
    ZED.PosData(loc, :) = [];
    ZED.RotData(loc, :) = [];
    
    %% Generate ProcessData structure
    if processSignals
        ProcessData.PrIdx = PrIdx;
        ProcessData.TrIdx = TrIdx;
        ProcessData.SR = 300;
        ProcessData.T = linspace(0, max_T, max_T*ProcessData.SR);
        ProcessData.Path2Data = Path2Data;
        ProcessData.DepthPresent = DepthPresent;

        % Process IMU data
        ProcessData.calib_flag = interp1(IMU.T, IMU.Calib, ProcessData.T, 'pchip', 'extrap');
        ProcessData.IMU.Head_Vel = interp1(IMU.T, IMU.head_vel, ProcessData.T, 'pchip', 'extrap');
        ProcessData.IMU.HeadVector = interp1(IMU.T, IMU.headvector, ProcessData.T, 'pchip', 'extrap');
        ProcessData.IMU.El_Vel = interp1(IMU.T, IMU.el_vel, ProcessData.T, 'pchip', 'extrap');
        ProcessData.IMU.Az_Vel = interp1(IMU.T, IMU.az_vel, ProcessData.T, 'pchip', 'extrap');
        ProcessData.IMU.HeadPose = quatnormalize(quat_interp_slerp(IMU.T, IMU.HeadPose, ProcessData.T));
        ProcessData.IMU.HeadPose_cor = quatnormalize(quat_interp_slerp(IMU.T, IMU.HeadPose_cor, ProcessData.T));
        
        % Process ETG data
        ProcessData.ETG.SceneResolution = ETG.SceneResolution;
        ProcessData.ETG.EIH_vel = interp1(ETG.T, ETG.EIH_vel, ProcessData.T, 'pchip', 'extrap');
        ProcessData.ETG.EIHvector = interp1(ETG.T, ETG.EIHvector, ProcessData.T, 'pchip', 'extrap');
        ProcessData.ETG.EIHvector_raw = interp1(ETG.T, ETG.EIHvector_raw, ProcessData.T, 'pchip', 'extrap');
        ProcessData.ETG.El_Vel = interp1(ETG.T, ETG.el_vel, ProcessData.T, 'pchip', 'extrap');
        ProcessData.ETG.Az_Vel = interp1(ETG.T, ETG.az_vel, ProcessData.T, 'pchip', 'extrap');
        ProcessData.ETG.SceneFrameNo = interp1(ETG.T, ETG.SceneFrameNo, ProcessData.T,  'nearest', 'extrap');
        ProcessData.ETG.LeftEyeFrameNo = interp1(ETG.T, ETG.LeftEyeFrameNo, ProcessData.T, 'nearest', 'extrap');
        ProcessData.ETG.RightEyeFrameNo = interp1(ETG.T, ETG.RightEyeFrameNo, ProcessData.T, 'nearest', 'extrap');
        ProcessData.ETG.POR = interp1(ETG.T, ETG.POR, ProcessData.T,  'pchip', 'extrap');
        ProcessData.ETG.Confidence = interp1(ETG.T, ETG.Confidence, ProcessData.T, 'linear', 'extrap');
        ProcessData.ETG.Labels = interp1(ETG.T, ETG.labels, ProcessData.T, 'nearest', 'extrap');
        ProcessData.ETG.LabelStruct_PP = GenerateLabelStruct(ProcessData.ETG.Labels, ProcessData.T);
        ProcessData.ETG.Vergence = interp1(ETG.T, ETG.Vergence, ProcessData.T, 'pchip', 'extrap');
        ProcessData.ETG.EIH_rawvel = interp1(ETG.T, ETG.EIH_rawvel, ProcessData.T, 'pchip', 'extrap');
        ProcessData.ETG.EIHvector_0 = interp1(ETG.T, ETG.EIHvector_0, ProcessData.T, 'pchip', 'extrap');
        ProcessData.ETG.EIHvector_1 = interp1(ETG.T, ETG.EIHvector_1, ProcessData.T, 'pchip', 'extrap');
        ProcessData.ETG.pupil_radius_eye0 = interp1(ETG.T, ETG.pupil_radius_eye0, ProcessData.T, 'pchip', 'extrap');
        ProcessData.ETG.pupil_radius_eye1 = interp1(ETG.T, ETG.pupil_radius_eye1, ProcessData.T, 'pchip', 'extrap');
        
        % Process ZED data
        ProcessData.ZED.FrameNo = interp1(ZED.T, ZED.Frames, ProcessData.T, 'nearest', 'extrap');
        ProcessData.ZED.PosData = interp1(ZED.T, ZED.PosData, ProcessData.T, 'pchip', 'extrap');
        ProcessData.ZED.RotData = quatnormalize(interp1(ZED.T, ZED.RotData, ProcessData.T, 'pchip', 'extrap'));
        ProcessData.ZED.Resolution = [1920, 1080];

        % Camera parameters
        ProcessData.StereoCameraParameters = StereoCameraParams;
        ProcessData.SceneCameraParameters = SceneCameraParams;
    

    %% Experimental: Find GiW

        ProcessData.GIW.GIWvector = RapidRotate(quat2rotm(ProcessData.IMU.HeadPose),...
            ProcessData.ETG.EIHvector, 'mv');
        [ProcessData.GIW.az, ProcessData.GIW.el, ~] = ...
            cart2sph(-ProcessData.GIW.GIWvector(:, 1), ...
            ProcessData.GIW.GIWvector(:, 3), ProcessData.GIW.GIWvector(:,2));
        ProcessData.GIW.Az_Vel = findAngularVelocity(ProcessData.T(:), ProcessData.GIW.az); 
        ProcessData.GIW.El_Vel = findAngularVelocity(ProcessData.T(:), ProcessData.GIW.el);
        ProcessData.GIW.GIW_Vel = findGazeVelocity(ProcessData.T(:), ProcessData.GIW.GIWvector, 0, 0);

        %% Understand Az and El velocities
        if plotProcessFigures
            figure;
            ax1 = subplot(1, 2, 1); hold on;
            plot(ProcessData.T, ProcessData.ETG.Az_Vel, 'r'); 
            plot(ProcessData.T, ProcessData.IMU.Az_Vel, 'b'); 
            plot(ProcessData.T, ProcessData.GIW.Az_Vel, 'g');
            legend('EIH', 'Head', 'GIW')
            xlabel('Time (S)')
            ylabel('Ang velocity \circ/s')

            ax2 = subplot(1, 2, 2); hold on;
            plot(ProcessData.T, ProcessData.ETG.El_Vel, 'r'); 
            plot(ProcessData.T, ProcessData.IMU.El_Vel, 'b'); 
            plot(ProcessData.T, ProcessData.GIW.El_Vel, 'g');
            legend('EIH', 'Head', 'GIW')
            xlabel('Time (S)')
            ylabel('Ang velocity \circ/s')
            linkaxes([ax1, ax2], 'x')
        end

        if ~isfield(ProcessData, 'HeadDrift_deg') || 0%input('Do you want to find Head Ang disp?')
        %% Find Angular displacement between start and end of a trial
            disp('Removing all figures.')
            close all

            % play the scene video file
%             implay(fullfile(Path2Data, 'Gaze', 'world.mp4'), 60.0)
            %%

            figure;
            ax1 = subplot(1, 1, 1);
            plot(ProcessData.ETG.SceneFrameNo, ProcessData.IMU.HeadVector)
            grid(ax1, 'minor')
            xlabel(ax1, 'Frame number')
            ax1.XLim = [ProcessData.ETG.SceneFrameNo(1), ProcessData.ETG.SceneFrameNo(end)];
            ax2 = axes('Position', ax1.Position);
            plot(ProcessData.T, ProcessData.IMU.HeadVector, 'Parent', ax2)
            xlabel(ax2, 'Trial time')
            ax2.XAxisLocation = 'top';
            ax2.Color = 'none';
            ax2.XLim = [ProcessData.T(1), ProcessData.T(end)];
            drawnow
            title('IMU performance. DONT PANIC. No smooth transition. Approximate')
            [x, ~] = ginput(3);

            if (x(2) < x(1)) || (x(3) < x(1))
                % Person does not face the checker. Donot calculate head dispersion
                disp('Head performance not calculated')
                ProcessData.HeadDrift_deg = nan;
                ProcessData.HeadDrift_s = nan;
                ProcessData.HeadDrift_rate = nan;
            else
                loc = findClosest(ProcessData.T(:), x(1));
                HeadVector_cor = quatrotate(ProcessData.IMU.HeadPose_cor, [0, 0, 1]);
                headangdisp = AngleBetweenVectors(ProcessData.IMU.HeadVector(loc, :), ProcessData.IMU.HeadVector);
                headangdisp_cor = AngleBetweenVectors(HeadVector_cor(loc, :), HeadVector_cor);

                % This step essentially finds the smallest head angular displacement after
                % the given time stamp
                loc1 = findClosest(ProcessData.T, x(2)); loc2 = findClosest(ProcessData.T, x(3));
                ProcessData.HeadDrift_deg = min(headangdisp(loc1:loc2));
                ProcessData.HeadDrift_s = 0.5*(x(2)+x(3)) - x(1);
                ProcessData.HeadDrift_rate = ProcessData.HeadDrift_deg/ProcessData.HeadDrift_s;
                
                ProcessData.HeadDrift_deg_cor = min(headangdisp_cor(loc1:loc2));
                ProcessData.HeadDrift_rate_cor = ProcessData.HeadDrift_deg_cor/ProcessData.HeadDrift_s;
                
                fprintf('Head drift: %f deg. Head drift rate: %f deg/s \n', ProcessData.HeadDrift_deg, ProcessData.HeadDrift_rate)
                fprintf('Corrupted Head drift: %f. Head drift rate: %f deg/s \n', ProcessData.HeadDrift_deg_cor, ProcessData.HeadDrift_rate_cor)
            end

        else
            fprintf('Previous drift measurement found to be %.3f\n', ProcessData.HeadDrift_deg)
        end

        %% Save Process Data
        save([Path2ProcessData, str_ProcessData], 'ProcessData', '-append')
    else
        disp('Signals have been processed before')
    end

    %% Estimate transformation between Left and Scene
    clear temp

%     resolution = [1080, 1920];

%     colors = linspecer(54);

    close all
%     plotOn = 0;

%     if plotOn
%         figure;
%         ax = subplot(1, 2, 1);
%         ax1 = subplot(1, 2, 2);
%         grid(ax1, 'on');
%         xlabel(ax1, 'X'); ylabel(ax1, 'Y'); zlabel(ax1, 'Z');
%     end

%     [Xfield, Yfield] = meshgrid(1:1920, 1:1080);

    if DepthPresent
        %% If Depth images are present

        FrameList = [ProcessData.ETG.SceneFrameNo(:), ProcessData.ZED.FrameNo(:)];
        FrameList = unique(FrameList, 'rows');

        [RotMats, TMats] = deal(nan(length(FrameList), 3));
        parfor i = 1:length(FrameList)
            SceneFr = round(FrameList(i, 1)); 
            LeftFr = round(FrameList(i, 2));
            % Since Scene and Left frame numbers are indexed in 0 for
            % MATLAB, add +1 to the frame number.
            if ~isempty(Scene_Checkers{SceneFr}) && ~isempty(Left_Checkers{LeftFr})
                % Checkerboard corners exist in both frames
                pts_Scene = Scene_Checkers{max(SceneFr, 1)}; pts_Left = Left_Checkers{max(LeftFr, 1)};
                pts_Scene = undistortPoints(pts_Scene, ProcessData.SceneCameraParameters); 
                
                % Undistort points
                pts_Left = undistortPoints(pts_Left, ProcessData.StereoCameraParameters.CameraParameters1);
                [Rl, Tl] = extrinsics(pts_Left, worldPts, ProcessData.StereoCameraParameters.CameraParameters1);
                [Rs, Ts] = extrinsics(pts_Scene, worldPts, ProcessData.SceneCameraParameters);
                
                R_Left2Scene = Rl\Rs;
                T_Left2Scene = Ts - Tl*R_Left2Scene;
                RotMats(i, :) = rotationMatrixToVector(R_Left2Scene);
                TMats(i, :) = T_Left2Scene;
            end
        end

        figure;
        subplot(1,2,1)
        plot(RotMats); title('Rotation')
        subplot(1,2,2)
        plot(TMats); title('Translation')
        
        % Remove all measurements post 300 frames from the end of
        % calibration. Use a constant R and T through the entire trial.
        a = ProcessData.ETG.SceneFrameNo(find(ProcessData.calib_flag, 1, 'last'));
        loc = FrameList(:, 1) > (a + 300);
        RotMats(loc, :) = []; TMats(loc, :) = [];
        
        loc = logical(sum(isnan(RotMats), 2));
        RotMats(loc, :) = []; TMats(loc, :) = [];
        
        loc = isoutlier(RotMats); loc = logical(sum(loc, 2)); RotMats(loc, :) = [];
        loc = isoutlier(TMats); loc = logical(sum(loc, 2)); TMats(loc, :) = [];
        R = nanmean(RotMats, 1); T = nanmean(TMats, 1);

        disp(['Confirm. Rotation: ', mat2str(R(:)')])
        disp(['Confirm. Translation: ', mat2str(T(:)')])
        ProcessData.R_ZED2ETG = R;
        ProcessData.T_ZED2ETG = T;        
       
        
        %% Convert Point Cloud for every frame
        
        if ~depth_extracted || regenerate_depth
            plotOn = 0;

            if plotOn

                fig = figure;
                subplot(1,2,1)
                handle_Scene = imshow(zeros(ETG.SceneResolution(2), ETG.SceneResolution(1), 3)); hold on;
                POR_Scene = scatter(0, 0, 40, [0 1 0], 'filled'); hold off;
                title('Scene Image')
                subplot(1,2,2)
                handle_Depth = imshow(zeros(1080, 1920)); hold on;
                POR_Depth = scatter(0, 0, 40, [1 0 0], 'filled');
                title('Depth Image')
            end

            ZED_frameNo = ProcessData.ZED.FrameNo;
            Scene_frameNo = ProcessData.ETG.SceneFrameNo;
            por_Signal = ProcessData.ETG.POR;
            SceneDepth = nan(length(ProcessData.T), 1);

            prev_ZED = nan;
            prev_Scene = nan;

            for i = 1:length(ProcessData.T)    
                por = por_Signal(i, :).*ETG.SceneResolution;
                str_Scene = [Path2Data, 'Gaze/Scene/', num2str(Scene_frameNo(i)), '.jpg'];

                if prev_ZED == ZED_frameNo(i) && prev_Scene == Scene_frameNo(i) 
                    %% This means the PC has already been loaded or generated

                    if plotOn
                        [X, Y] = meshgrid(1:1920, 1:1080);

                        handle_Scene.CData = imread(str_Scene);
                        handle_Depth.CData = normalizeImage(DepthMap);

                        POR_Scene.XData = por(1); POR_Scene.YData = por(2);
                        POR_Depth.XData = por(1); POR_Depth.YData = por(2);
                        drawnow

                        SceneDepth(i) = interp2(X, Y, DepthMap, por(1), por(2), 'linear');
                    else
                        SceneDepth(i) = PointDepthFromPointCloud(PC, rotationVectorToMatrix(R), T, SceneCameraParams, por);
                    end

                    disp(['Not loaded PC. Finished processing frame no: ', num2str(i)])
                else
                    %% This means the PC has to be loaded into memory
                    str_PC = [Path2Data, 'PC/', num2str(ZED_frameNo(i)), '.mat'];
                    str_Depth = [Path2Data, 'Depth/', num2str(ZED_frameNo(i)), '.jpg'];
                    if exist(str_PC, 'file')

                        PC = load(str_PC); PC = PC.PC;

                        % Remove last layer and rotate about X axis of ZED
                        % orientation by 180 degrees to match with our system of
                        % operation
                        if size(PC, 3) > 3
                            PC(:, :, 4:end) = [];
                        end
                        PC(:, :, 2) = -PC(:, :, 2);
                        PC(:, :, 3) = -PC(:, :, 3);
                    elseif exist(str_Depth, 'file')
                        % Generate PC
                        
                        I_Depth = imread(str_Depth);

                        DepthMap = rescaleImageToDepth(I_Depth, -0.03627451, 10);
                        [X, Y] = meshgrid(1:1920, 1:1080);
                        pts_2D = [X(:), Y(:), ones(numel(X), 1)];
                        pts_3D = pts_2D/StereoCameraParams.CameraParameters1.IntrinsicMatrix;
                        pts_3D = pts_3D.*repmat(DepthMap(:)*1000, [1, 3]);
                        PC = reshape(pts_3D, [1080, 1920, 3]);
                    else
                        disp('File does not exist')
                    end

                    if plotOn
                        [X, Y] = meshgrid(1:1920, 1:1080);

                        PC = pointCloud(PC);
                        DepthMap = PointCloud2Image(PC, rotationVectorToMatrix(R), T, SceneCameraParams);

                        handle_Scene.CData = imread(str_Scene);
                        handle_Depth.CData = normalizeImage(DepthMap);
                        POR_Scene.XData = por(1); POR_Scene.YData = por(2);
                        POR_Depth.XData = por(1); POR_Depth.YData = por(2);
                        drawnow
            % 
                        SceneDepth(i) = interp2(X, Y, DepthMap, por(1), por(2), 'linear');
                    else
                        SceneDepth(i) = PointDepthFromPointCloud(PC, rotationVectorToMatrix(R), T, SceneCameraParams, por);
                    end

                    prev_ZED = ZED_frameNo(i);
                    prev_Scene = Scene_frameNo(i);
                    disp(['Finished processing frame no: ', num2str(i)])
                end
            end
            %% Clean Scene Depth
            temp = medfilt1(SceneDepth, 20);
            temp = correctSamples(ProcessData.T(:), temp(:));
            ProcessData.SceneDepth = smooth(temp, 5, 'sgolay');

            depth_extracted = 1;
            
            figure;
            plot(SceneDepth); hold on;
            plot(ProcessData.SceneDepth)
            title('Comparing processed depth data')
            xlabel('Time')
            ylabel('Depth (mm)')
                        
            save([Path2ProcessData, str_ProcessData], 'ProcessData', '-append')
            save([Path2TempData, str_ParamData], 'depth_extracted', '-append')
            fprintf('Finito! PrIdx: %d. TrIdx: %d\n', PrIdx, TrIdx)
        end
%%
        save([Path2ProcessData, str_ProcessData], 'ProcessData', '-append')
        save([Path2TempData, str_ParamData], 'depth_extracted', '-append')
    else
        save([Path2ProcessData, str_ProcessData], 'ProcessData', '-append')
        save([Path2TempData, str_ParamData], 'depth_extracted', '-append')
        disp('Depth not present, no information saved; Depth has been processed before.')
    end
end