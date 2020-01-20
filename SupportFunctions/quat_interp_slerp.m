function [q_new] = quat_interp_slerp(t, q, t_new)
%quat_interp_slerp Use slerp to interpolate one sequence of quaternions
%   Instead of regular interpolation, use slerp to interpolate head pose
[q1, q2] = deal(zeros(length(t_new), 4));
rat_q1_q2 = zeros(length(t_new), 1);
parfor i = 1:length(t_new)
    n2 = find((t - t_new(i)) > 0, 1, 'first');
    n1 = find((t - t_new(i)) < 0, 1, 'last');
    if isempty(n1)
        n1 = n2;
        rat_q1_q2(i) = 1;
    elseif isempty(n2)
        n2 = n1;
        rat_q1_q2(i) = 0;
    else
        rat_q1_q2(i) = (t_new(i) - t(n1))/(t(n2) - t(n1));
    end
    q1(i, :) = q(n1, :);
    q2(i, :) = q(n2, :);
end
q_new = quatinterp(q1, q2, rat_q1_q2);
end