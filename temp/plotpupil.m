clearvars
close all
clc

load('c:/Users/Rudra/Downloads/PrIdx_1_TrIdx_1.mat')
ProcessData.ETG.pupil_radius_eye0 = 0.5*ProcessData.ETG.pupil_radius_eye0;
ProcessData.ETG.pupil_radius_eye1 = 0.5*ProcessData.ETG.pupil_radius_eye1;

figure;
ax1 = subplot(2, 2, 1); hold(ax1, 'on');
plot(ProcessData.T, ProcessData.ETG.pupil_radius_eye0)
plot(ProcessData.T, ProcessData.ETG.pupil_radius_eye1)
legend({'Left', 'Right'})
grid(ax1, 'on')
xlabel(ax1, 'Time')
ylabel(ax1, 'Pupil radius (mm)'); hold(ax1, 'off');

ax2 = subplot(2, 2, 2); hold(ax2, 'on');
histogram(ProcessData.ETG.pupil_radius_eye0, 'facealpha', 0.5, 'Normalization', 'probability')
histogram(ProcessData.ETG.pupil_radius_eye1, 'facealpha', 0.5, 'Normalization', 'probability')
legend({'Left', 'Right'})
grid(ax2, 'on')
xlabel('Pupil radius (mm)')
ylabel('Probability'); hold(ax2, 'off');

val = 5000;
range = val:val+ProcessData.SR;
ax3 = subplot(2, 2, 3); hold(ax3, 'on');
plot(ProcessData.T(range), ProcessData.ETG.pupil_radius_eye0(range))
plot(ProcessData.T(range), ProcessData.ETG.pupil_radius_eye1(range))
legend({'Left', 'Right'})
grid(ax3, 'on')
xlabel(ax3, 'Time')
ylabel(ax3, 'Pupil radius (mm)'); hold(ax3, 'off');

rat = ProcessData.ETG.pupil_radius_eye0./ProcessData.ETG.pupil_radius_eye1;
ax4 = subplot(2, 2, 4); hold(ax4, 'on');
plot(ProcessData.T, rat)
title('Ratio (Left/Right)')
grid(ax4, 'on')
xlabel(ax4, 'Time')
ylabel(ax4, 'Pupil radius (mm)'); hold(ax4, 'off');

dF = ProcessData.SR/length(ProcessData.ETG.pupil_radius_eye0);
f = -ProcessData.SR/2:dF:ProcessData.SR/2-dF;           % hertz
spc = abs(fftshift(fft(ProcessData.ETG.pupil_radius_eye0/sum(ProcessData.ETG.pupil_radius_eye0))));
figure;
plot(f, log(spc))
grid on
xlabel('Frequency (Hz)')
ylabel('Log units')