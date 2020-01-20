function out = findHeadVelocity(t, in)
% findHeadVelocity Calculate head velocity from vectors.
% Calculate head velocity based on head vectors. This function does not
% perform any filtering and caps the maximum head velocity to a certain
% value. This function utilizes the 2P algorithm.
% Author: Rakshit Kothari

in = normr(in); t = t(:);
a_t1 = in(1:end-2, :); a_t2 = in(3:end, :);
maxV = 400;

%% Using atand
D = dot(a_t1, a_t2, 2); loc = D > 1 | D < -1; loc_bad_dot = find(loc); loc_good_dot = find(~loc);
temp = cross(a_t1, a_t2, 2);
C = arrayfun(@(idx) norm(temp(idx,:), 2), 1:size(temp,1)); C = C';
loc = C > 1 | C < -1; loc_bad_cross = find(loc); loc_good_cross = find(~loc); 

loc_bad = unique([loc_bad_dot; loc_bad_cross]);
loc_good = intersect(loc_good_dot, loc_good_cross);

for i = 1:length(loc_bad)
   x = loc_bad(i);
   
   % Find closest good sample
   loc = findClosest(loc_good, x);
   y = loc_good(loc);
   D(x) = D(y);
   C(x) = C(y);
end

in_dTheta = atand(C./D);

SampRate = 1./mean(t(3:end) - t(1:end-2)); loc = in_dTheta > (maxV/SampRate);
in_dTheta( loc ) = 0;
out = in_dTheta(:)./(t(3:end) - t(1:end-2));
out = [out(1); out(:); out(end)];
out(out > maxV | out < 0) = nan;
out = correctSamples(t, out);
out(out < 0) = 0; % Just to ensure the interpolation doesn't overshoot data
end