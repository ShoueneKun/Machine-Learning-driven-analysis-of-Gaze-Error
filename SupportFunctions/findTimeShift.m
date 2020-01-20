function out = findTimeShift(s1, t1, s2, t2, plotOn)

tStart = max([t1(1), t2(1)]); tStop = min([t1(end), t2(end)]);
SampRate = 500;
t = tStart:1/SampRate:tStop;

s1 = interp1(t1, s1, t, 'linear');
s2 = interp1(t2, s2, t, 'linear');
s1 = s1/sum(s1); % Normalize by sum
s2 = s2/sum(s2);
% 
%% Signal 1
Fs1 = 1/mean(diff(t));
freq1 = linspace(-Fs1/2, Fs1/2, length(s1)); v1_F = fftshift(fft(s1));
v1_fft = abs(v1_F);

%% Signal 2
Fs2 = 1/mean(diff(t));
freq2 = linspace(-Fs2/2, Fs2/2, length(s2)); v2_F = fftshift(fft(s2));
v2_fft = abs(v2_F);

%% Plot fouriers and find time shift

if plotOn
    figure; hold on;
    plot(freq1, v1_fft, 'LineWidth', 2);
    plot(freq2, v2_fft, 'LineWidth', 2);
end
%% Interpolate to common TS and find correlation

if plotOn
    figure; hold on;
    plot(t, s1, 'LineWidth', 2);
    plot(t, s2, 'LineWidth', 2);
end
% perform XCOrr by parts
[C, lag] = xcorr(s1, s2);
[~, loc] = max(abs(C));
out = (loc - find(lag == 0))/SampRate;

end