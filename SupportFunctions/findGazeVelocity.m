function [outN] = findGazeVelocity(t, in, filterOn, plotData)
%% FindGazeVelocity - Computes gaze velocity based on central difference algorithm
% Gaze velocity is more stable in the central difference algorithm. It can
% suppress very small Saccades though.
maxV = 700;

in = normr(in);
a_t1 = in(1:end-2, :); a_t2 = in(3:end, :);

%% Using dot(v1, v2)/|v1||v2| = cos(angle)
D = dot(a_t1, a_t2, 2); loc = D > 1 | D < -1; loc_bad_dot = find(loc); loc_good_dot = find(~loc);
temp = cross(a_t1, a_t2, 2);
C = arrayfun(@(idx) norm(temp(idx,:), 2), 1:size(temp,1)); C = C';
loc = C > 1 | C < -1; loc_bad_cross = find(loc); loc_good_cross = find(~loc); 

loc_bad = unique([loc_bad_dot(:); loc_bad_cross(:)]);
loc_good = intersect(loc_good_dot(:), loc_good_cross(:));

for i = 1:length(loc_bad)
   x = loc_bad(i);
   
   % Find closest good sample
   loc = findClosest(loc_good, x);
   y = loc_good(loc);
   D(x) = D(y);
   C(x) = C(y);
end

in_dTheta = atan2d(C, D);

% Constrain the algorithm such that the maximum angular displacement
% between two gaze positions cannot exceed 6 degrees per sample. This is
% because with a maximum gaze velocity of maxV deg/sec, the maximum angular
% distance travelled in 1/120 seconds is given by maxV/120. Angular
% velocities greater than maxV deg/sec are highly unlikely. 
SampRate = 1./mean(t(3:end) - t(1:end-2)); loc = in_dTheta > (maxV/SampRate);
in_dTheta( loc ) = maxV/SampRate;
% v1 = in_dTheta(:)./diff(t(:));
v1 = in_dTheta(:)./(t(3:end) - t(1:end-2));
% out = [0; v1]; 
out = [v1(1); v1; v1(end)]; % Repeat the end values
out(out < 0) = 0;

if ~filterOn
    outN = out;    
else
    out(out > maxV) = maxV;

    %% 1D Bilateral filtering
    outN = out/maxV;
    outN = bfilter1(outN, 20, [4, 0.03]);
    outN = outN*maxV;

%% 1D Bilateral test for multiple values
% 
% Sigma_spatial = linspace(10/10, 10, 4);
% Sigma_signal = linspace(0.025/4, 0.025*2, 4);
% 
% m = 1;
% ax = [];
% figure;
% for i = 1:length(Sigma_spatial)
%     for j = 1:length(Sigma_signal)
%         
%         outN = bfilter1(out/maxV, 15, [Sigma_spatial(i),Sigma_signal(j)]);
%         outN = outN*maxV;
%         
%         ax = [ax; subplot(length(Sigma_spatial), length(Sigma_signal), m)];
%         hold on;
%         plot(t, out, 'r--', 'LineWidth', 1.5)
%         plot(t, outN, 'b-', 'LineWidth', 1)
%         title(sprintf('S_{spa}: %f, S_{sig}: %f', Sigma_spatial(i), Sigma_signal(j)))
%         grid on;
%         
%         m = m + 1;
%     end
% end
% linkaxes(ax, 'xy')
end
if plotData
    figure; hold on;
    plot(t, outN, 'Color', [0 0 1])
    plot(t, out, 'Color', [0 1 0])
    hold off;
    legend('Filtered', 'Original')
end
end