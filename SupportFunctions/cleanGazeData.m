function [out] = cleanGazeData(T, in, PlotOn)

%% Add functionality to treat NaN values
in = correctSamples(T, in);
in = normr(in);

%% Butterworth filtering
% cutoff @50 Hz
SR = 1./mean(diff(T));
cutoff = 58;
if SR <= 2*(cutoff + 10)
    disp('Poor sampling rate. No low pass filtering.')
else
    lpFilt = designfilt('lowpassfir', 'PassbandFrequency', (cutoff-2)/(0.5*SR), ...
    'StopbandFrequency', (cutoff+2)/(0.5*SR), 'PassbandRipple', 0.1, ...
    'StopbandAttenuation', 80, 'DesignMethod', 'kaiserwin');

    in(:, 1) = filtfilt(lpFilt, in(:, 1));
    in(:, 2) = filtfilt(lpFilt, in(:, 2));
    in(:, 3) = filtfilt(lpFilt, in(:, 3));

    in = normr(in);
end
%%
if PlotOn
    
    figure; hold on;
    plot(T, in);
    plot(T, out);
    legend('X_i', 'Y_i', 'Z_i', 'X_o', 'Y_o', 'Z_o')
end
end
