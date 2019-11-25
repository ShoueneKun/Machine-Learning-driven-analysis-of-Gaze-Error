clear all
close all
clc
warning('off', 'all')
Path2Project = '/home/rakshit/Documents/MATLAB/event_detection_mark_1/';
addpath([Path2Project, '/SupportFunctions'])

global Dataset_Path2Data
Dataset_Path2Data = '/run/user/1000/gvfs/smb-share:server=mvrlsmb.cis.rit.edu,share=performlab/Natural statistics';

Path2ProcessData = '/home/rakshit/Documents/Event Detection Dataset files/ProcessData/';
Path2LabelData = 'home/rakshit/Documents/Event Detection Dataset files/LabelData/';
Path2TempData = '/home/rakshit/Documents/Event Detection Dataset files/TempData/';
Path2Checkers = '/home/rakshit/Documents/Event Detection Dataset files/Checkers/';

ParticipantInfo = GetParticipantInfo();

loc = cellfun(@isempty, {ParticipantInfo.Name}); ParticipantInfo(loc) = [];
PrPresent = find(~ismember({ParticipantInfo.Name}, {'Asher', 'Brendan'}));

for i = 7%length(PrPresent)
    PrIdx = PrPresent(i);

    TrPresent = ParticipantInfo(PrIdx).Trials;
    for j = 1%:length(TrPresent)
        TrIdx = TrPresent(j);
        fprintf('Processing Pr: %d, Tr: %d\n', PrIdx, TrIdx)

        Start_h = ParticipantInfo(PrIdx).Start_h(TrIdx);
        Start_m = ParticipantInfo(PrIdx).Start_m(TrIdx);
        Start_s = ParticipantInfo(PrIdx).Start_s(TrIdx);

        load(fullfile(Path2ProcessData, sprintf('PrIdx_%d_TrIdx_%d.mat', PrIdx, TrIdx)))
        
        if exist(fullfile(Path2Checkers,  sprintf('ExtractedCheckers_PrIdx_%d_TrIdx_%d.mat', PrIdx, TrIdx)), 'file') == 2
            clear Left_Checkers Scene_Checkers
            
            disp('Checkers extracted before')
            load(fullfile(Path2Checkers,  sprintf('ExtractedCheckers_PrIdx_%d_TrIdx_%d.mat', PrIdx, TrIdx)))
            disp('Loaded previously found checkers')
            checkers_extracted = 1;
        else
            checkers_extracted = 0;
        end
        
        if ProcessData.DepthPresent
            Path2Data = sprintf('%s/%s/%d/', Dataset_Path2Data, ParticipantInfo(PrIdx).Name, TrIdx);

            Path2SceneVideo = fullfile(Path2Data, 'Gaze', 'world.mp4');
            Path2Left = fullfile(Path2Data, 'RGB-Left');
            
            if ~(exist('Left_Checkers', 'var') && exist('Scene_Checkers', 'var') && checkers_extracted)
                Left_Checkers = extract_checkers(Path2Left, [7, 10]);
                Scene_Checkers = extract_checkers(Path2SceneVideo, [7, 10]);
                save(fullfile(Path2Checkers, ['ExtractedCheckers_PrIdx_', num2str(PrIdx), '_TrIdx_', num2str(TrIdx), '.mat']), 'Left_Checkers', 'Scene_Checkers')
            else
                checkers_extracted = 1;
            end
            
            fprintf('Finished Pr: %d. Tr: %d\n', PrIdx, TrIdx)
                        
            T_Scene = readNPY(fullfile(Path2Data, 'Gaze', 'world_timestamps.npy'));
            T_Scene = Start_h*3600 + Start_m*60 + Start_s + T_Scene - T_Scene(1);
            
            if ParticipantInfo(PrIdx).OldStyle
                % Use timing file
                temp = csvread(fullfile(Path2Data, 'timing.txt'));
                T_Left = temp(:, 2)*3600 + temp(:, 3)*60 + temp(:, 4) + temp(:, 5)*10^-6;
            else
                if ~ParticipantInfo(PrIdx).useTimingInfo(TrIdx)
                    temp = readtable(fullfile(Path2Data, 'PosData'));
                    Timing_Info = datevec(datetime(temp.Timestamp/(10^9), 'ConvertFrom', 'posixtime', 'TimeZone', 'America/New_York'));
                    T_Left = Timing_Info(:,4)*3600 + Timing_Info(:,5)*60 + Timing_Info(:,6);
                else
                    temp = csvread(fullfile(Path2Data, 'timing.txt'));
                    T_Left = temp(:, 2)*3600 + temp(:, 3)*60 + temp(:, 4) + temp(:, 5)*10^-6;              
                end
            end
            
            if length(T_Left) == length(Left_Checkers) + 1
                T_Left(1) = [];
            elseif length(T_Left) < length(Left_Checkers)
                keyboard
            elseif length(T_Left) == length(Left_Checkers)
                disp('Timing matches')
            else
                keyboard
            end

            loc = ~cellfun(@isempty, Scene_Checkers);
            Scene_Checkers(~loc) = [];
            T_Scene(~loc) = [];
            checkerPoints_scene = zeros(54, 2, sum(loc));
            for k = 1:sum(loc)
                if size(Scene_Checkers{k}, 1) == 54
                    checkerPoints_scene(:, :, k) = Scene_Checkers{k};
                end
            end
            checkerPoints_scene = mean(checkerPoints_scene, 1);
            checkerPoints_scene = permute(checkerPoints_scene, [3, 1, 2]);
            checkerPoints_scene = squeeze(checkerPoints_scene);

            loc = ~cellfun(@isempty, Left_Checkers);
            Left_Checkers(~loc) = [];
            T_Left(~loc) = [];
            checkerPoints_left = zeros(54, 2, sum(loc));
            for k = 1:sum(loc)
                if size(Left_Checkers{k}, 1) == 54
                    checkerPoints_left(:, :, k) = Left_Checkers{k};
                end
            end
            checkerPoints_left = mean(checkerPoints_left, 1);
            checkerPoints_left = permute(checkerPoints_left, [3, 1, 2]);
            checkerPoints_left = squeeze(checkerPoints_left);
             
            minT = max([T_Left(1), T_Scene(2)]); maxT = min([T_Left(end), T_Scene(end)]);
           
            fig = figure;
            plot(T_Left, checkerPoints_left, 'r')
            hold on;
            plot(T_Scene, checkerPoints_scene, 'b')
            title(sprintf('Left2Scene. PrIdx: %d, TrIdx: %d', PrIdx, TrIdx))
            legend('Left_x', 'Left_y', 'Scene_x', 'Scene_y')
            xlim([minT, maxT])
            h = imrect;
            pos = wait(h);
            
            loc_Scene = T_Scene < (pos(1) + pos(3)) & T_Scene > pos(1);
            loc_Left = T_Left < (pos(1) + pos(3)) & T_Left > pos(1);
      
            T_off = zeros(size(checkerPoints_scene, 2), 1);
            for k = 1:size(checkerPoints_scene, 2)
                s1 = abs(findVelocity(T_Scene(loc_Scene), checkerPoints_scene(loc_Scene, k))); s1 = s1 - min(s1); s1 = s1/max(s1);
                s2 = abs(findVelocity(T_Left(loc_Left), checkerPoints_left(loc_Left, k))); s2 = s2 - min(s2); s2 = s2/max(s2);
                T_off(k) = findTimeShift(s1, T_Scene(loc_Scene), s2, T_Left(loc_Left), 0);
            end
            T_off = mean(T_off);
            
            % Confirm if they are aligned
            figure;
            plot(T_Left + T_off, checkerPoints_left, 'r'); hold on;
            plot(T_Scene, checkerPoints_scene, 'b')
            keyboard
            
            fprintf('PrIdx: %d. TrIdx: %d. Offset: %f\n', PrIdx, TrIdx, T_off)
            save(fullfile(Path2Checkers, ['ExtractedCheckers_PrIdx_', num2str(PrIdx), '_TrIdx_', num2str(TrIdx), '.mat']), 'T_off', '-append')
            close(fig)
        else
            disp('Depth not recorded. Ignore.')
        end
    end
end