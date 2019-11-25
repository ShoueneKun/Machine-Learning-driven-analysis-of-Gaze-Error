function Out = GatherData(ProcessData, LabelData, str, SR)
    LabelStruct = LabelData.LabelStruct;
    switch str
        case 'all'
            cond = 0;
        case 'fixation'
            cond = 1;
        case 'pursuit'
            cond = 2;
        case 'saccade'
            cond = 3;
        case 'blink'
            cond = 4;
        case 'following'
            cond = 5;
    end
    Out = struct();

    m = 1;
    if any([LabelStruct.Label] == cond)
        for i = 1:length(LabelStruct)

            if LabelStruct(i).Label == cond

                % Update to using time instead. Safer and more secure.
                x = LabelStruct(i).LabelTime(1);
                y = LabelStruct(i).LabelTime(2);

                loc = findClosest(ProcessData.T(:), x):findClosest(ProcessData.T(:), y);

                maxT = max(ProcessData.T(loc));
                minT = min(ProcessData.T(loc));
                Out(m).T = linspace(minT, maxT, (maxT - minT)*SR);

                % ETG Data
                try
                    Out(m).EIH_Vel = interp1(ProcessData.T(loc), ProcessData.ETG.EIH_vel(loc), Out(m).T, 'spline');
                    Out(m).EIH_ElVel = interp1(ProcessData.T(loc), ProcessData.ETG.El_Vel(loc), Out(m).T, 'spline');
                    Out(m).EIH_AzVel = interp1(ProcessData.T(loc), ProcessData.ETG.Az_Vel(loc), Out(m).T, 'spline');
                    Out(m).EIH_Vec = interp1(ProcessData.T(loc), ProcessData.ETG.EIHvector(loc, :), Out(m).T, 'spline');
                catch
                   keyboard 
                end
                % IMU Data
                Out(m).Head_Vel = interp1(ProcessData.T(loc), ProcessData.IMU.Head_Vel(loc), Out(m).T, 'spline');
                Out(m).Head_ElVel = interp1(ProcessData.T(loc), ProcessData.IMU.El_Vel(loc), Out(m).T, 'spline');
                Out(m).Head_AzVel = interp1(ProcessData.T(loc), ProcessData.IMU.Az_Vel(loc), Out(m).T, 'spline');
                Out(m).Head_Vec = interp1(ProcessData.T(loc), ProcessData.IMU.HeadVector(loc, :), Out(m).T, 'spline');

                % Other stuff
                Out(m).Confidence = interp1(ProcessData.T(loc), ProcessData.ETG.Confidence(loc), Out(m).T, 'spline');
                Out(m).POR = interp1(ProcessData.T(loc), ProcessData.ETG.POR(loc), Out(m).T, 'spline');
                a1 = atand(Out(m).Head_Vel(:)./Out(m).EIH_Vel(:)); %a1 = a1(~isoutlier(a1, 'quartiles', 'ThresholdFactor', 1.2));
                a2 = atand(Out(m).Head_AzVel(:)./Out(m).EIH_AzVel(:)); %a2 = a2(~isoutlier(a2, 'quartiles', 'ThresholdFactor', 1.2));
                a3 = atand(Out(m).Head_ElVel(:)./Out(m).EIH_ElVel(:)); %a3 = a3(~isoutlier(a3, 'quartiles', 'ThresholdFactor', 1.2));

                Out(m).Slope_abs = a1(:);
                Out(m).Slope_az = a2(:);
                Out(m).Slope_el = a3(:);
                
                dt = diff(Out(m).T);
                % Angular EIH acceleration
                Out(m).EIH_AbsAngAcc = diff(Out(m).EIH_Vel)./dt;
                Out(m).EIH_AzAngAcc = diff(Out(m).EIH_AzVel)./dt;
                Out(m).EIH_ElAngAcc = diff(Out(m).EIH_ElVel)./dt;
                
                % Angular EIH displacement
                Out(m).EIH_AbsAngDisp = Out(m).EIH_Vel.*[dt(1), dt]; 
                Out(m).EIH_AzAngDisp = Out(m).EIH_AzVel.*[dt(1), dt];
                Out(m).EIH_ElAngDisp = Out(m).EIH_ElVel.*[dt(1), dt];

                Out(m).EIH_AngDisp = AngleBetweenVectors(ProcessData.ETG.EIHvector(loc(1), :), ...
                    ProcessData.ETG.EIHvector(loc(end), :));
                Out(m).Head_AngDisp = AngleBetweenVectors(ProcessData.IMU.HeadVector(loc(1), :),...
                    ProcessData.IMU.HeadVector(loc(end), :));
                
                % Max velocity
                Out(m).EIH_maxVel = max(ProcessData.ETG.EIH_vel(loc));
                Out(m).Head_maxVel = max(ProcessData.IMU.Head_Vel(loc));

                Out(m).Dur = maxT - minT;
                try
                    if ProcessData.DepthPresent
                        % Depth Data
                        Out(m).Depth = interp1(ProcessData.T(loc), ProcessData.SceneDepth(loc), Out(m).T, 'spline');
                        Out(m).PosData = interp1(ProcessData.T(loc), ProcessData.ZED.PosData(loc, :), Out(m).T, 'spline');
                    else
                        Out(m).Depth = nan(length(Out(m).T), 1);
                        Out(m).PosData = nan(length(Out(m).T), 3);
                    end
                catch
                    Out(m).Depth = nan(length(Out(m).T), 1);
                    Out(m).PosData = nan(length(Out(m).T), 3); 
                end
                Out(m).T = Out(m).T - min(Out(m).T);
                Out(m).Conf = nanmean(ProcessData.ETG.Confidence(loc));
                m = m + 1;
            end
        end
    else
        Out = [];
    end
end