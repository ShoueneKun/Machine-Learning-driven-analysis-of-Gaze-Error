function out = cleanHeadData(T, in, PlotOn)

%% Add functionality to treat NaN values
in = correctSamples(T, in);

%% Process data
in = normr(in);

SR = 1./mean(diff(T));
cutoff = 0.5*SR - 4;
lpFilt = designfilt('lowpassfir', 'PassbandFrequency', cutoff-2, ...
'StopbandFrequency', cutoff+2, 'PassbandRipple', 0.1, ...
'StopbandAttenuation', 80, 'DesignMethod', 'kaiserwin', 'SampleRate', SR);

in(:, 1) = filtfilt(lpFilt, in(:, 1));
in(:, 2) = filtfilt(lpFilt, in(:, 2));
in(:, 3) = filtfilt(lpFilt, in(:, 3));

out = normr(in);

if PlotOn
    figure; 
    plot(T, in, '--'); hold on;
    plot(T, out, '-');
    title('Head vector filtering')
    xlabel('Time'); ylabel('Unit vector');
    legend('Original', 'filtered')
end
end