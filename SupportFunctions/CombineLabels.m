function [out, W] = CombineLabels(Labels, dim)
%% Combine labels
out = zeros(length(Labels), 1);
W = zeros(length(Labels), 1);

loc = sum(Labels == 0, 2) == size(Labels, dim); % Cases where they are all 0

for i = 1:length(Labels)
    temp = Labels(i, :);
    [out(i), W(i)] = mode(temp(temp~=0));
    W(i) = W(i)/sum(temp~=0);
end

% mode ends up making nan values when all 0. Replace those conditions with
% 0. How annoying.
out(loc) = 0;
W(loc) = 1;
end

%% Note
% This script essentially assumes that every labeller has labelled the
% data. This may very well not be true and will affect the number of data
% points produced.