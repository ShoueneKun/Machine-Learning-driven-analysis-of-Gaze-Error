%% calculate the closest time stamp, return index and value
% findClosest Calculate the closest matching point for datapt. The
% dimensions need to be along the columns, while the rows need to represent
% samples.
function [out, val] = findClosest(in, datapts)
% if any(size(datapt) == 1)
%     [a, b] = size(in);
%     % convert to column vector
%     if b > a
%         in = in';
%         datapt = datapt';
%     end
% 
%     diffval = in - repmat(datapt, [length(in), 1]);
%     diffval = sqrt(sum(diffval.^2, 2));
%     [val, out] = min(diffval);
% else
%     % Find closest for multiple data points.
%     [val, out] = pdist2(in, datapt, 'euclidean', 'Smallest', 1);
% end
[val, out] = pdist2(in, datapts, 'euclidean', 'Smallest', 1);