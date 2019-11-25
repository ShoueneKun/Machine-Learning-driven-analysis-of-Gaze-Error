%% ZED evaluation
% Plots the measured error vs ground truth measurement.
% Ground truth -> Ruler measurement from camera lens to object center.
% Measurement -> Central pixel location of object.

clearvars
close all
clc

GT = [5.33, 2.38, 2.01, 1.72, 1.5, 1.113, 0.83, 0.69];
Meas = [5.54, 2.55, 2.1 1.8, 1.6, 1.2, 0.87, 0.71];
Err = abs(GT - Meas);

P = polyfit(GT, Err, 1);

x = 0:10;

figure;
scatter(GT, Err); hold on;
plot(x, polyval(P, x))
xlabel('Ground truth (M)')
ylabel('Measurement error (M)')
grid on