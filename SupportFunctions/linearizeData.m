function [out, T] = linearizeData(T, in, method)
%% linearizeData
% This function removes inconsistency in the timing values and ensures they
% become linearized. It constrains monotonicity by removing temporally
% redundant values.

% Author: Rakshit Kothari

% 0 needs to be appended to ensure the offending sample gets removed. In
% case if they have the exact same time stamp, the one in the future gets
% removed.
loc = logical([0; diff(T(:)) <= 0]);
in(loc, :) = [];
T(loc) = [];

T_temp = linspace(min(T), max(T), numel(T));
out = interp1(T, in, T_temp, method);
T = T_temp(:);
end