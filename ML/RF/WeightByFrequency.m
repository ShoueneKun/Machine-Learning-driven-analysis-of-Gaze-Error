function [Op1, Op2, Op3, W] = WeightByFrequency(Ip1, Ip2, Ip3)
[~, a1] = size(Ip1); [~, a2] = size(Ip2);

[temp, ~, ic] = unique([Ip1, Ip2], 'rows');
Op1 = temp(:, 1:a1); Op2 = temp(:, (a1+1):(a1+a2));

W = accumarray(ic, 1);
Op3 = accumarray(ic, Ip3);
Op3 = Op3./W;
end