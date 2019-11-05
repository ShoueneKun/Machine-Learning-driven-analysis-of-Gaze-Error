function [trainData, Targets, W] = GenerateDataset_RF(ExpData, numPre, numPost, W, forTrain)
%% GenerateDataset - Split sequence into meaning data for Random Forest.
% This function splits the data from trial into moving windows. Note that
% each window is created by shifting each element forward by 1. This can
% create an over representation of certain classes. Hence, all ML should be
% preceeded with a duplicate removal function.

%% Ele information
% 1 -> Time
% 2:4 -> EIH_vector
% 5:7 -> Head_vector
% 8 -> EIH velocity
% 9 -> Head velocity
% 10:11 -> EIH Az & El velocity
% 12:13 -> Head Az & El velocity
% 14 -> Confidence (Weight)
% 15 -> Labels

N = size(ExpData, 1);
temp = zeros(numPre + numPost + 1, size(ExpData, 2), N);

for k = (numPre + 1):(size(ExpData, 1) - numPost)
    x = k - numPre; y = k + numPost;
    temp(:, :, k) = ExpData(x:y, :);
end

T1 = temp(1:numPre, 2:7, :); T2 = temp((2 + numPre):(numPre + numPost + 1), 2:7, :);

v1 = arrayfun(@(x) mean(T1(:,:,x), 1), 1:size(T1, 3), 'UniformOutput', false); v1 = cell2mat(v1');
v2 = arrayfun(@(x) mean(T2(:,:,x), 1), 1:size(T2, 3), 'UniformOutput', false); v2 = cell2mat(v2');

EIH_meanDiff = AngleBetweenVectors(normr(v1(:,1:3)), normr(v2(:, 1:3)));
Head_meanDiff = AngleBetweenVectors(normr(v1(:,4:6)), normr(v2(:, 4:6)));

EIH_std = arrayfun(@(x) std(temp(:, 8, x)), 1:size(temp, 3));
Head_std = arrayfun(@(x) std(temp(:, 9, x)), 1:size(temp, 3));

Targets = temp(numPre + 1, end, :); Targets = Targets(:);

if (numPre == 0 || numPost == 0)
    T = temp(:, [8, 9, 10, 11, 12, 13], :);
    T = reshape(T, [6*(numPre + numPost + 1), size(T,3)]);
    trainData = T'; 
else
    T = temp(:, [8, 9, 10, 11, 12, 13], :);
    T = reshape(T, [6*(numPre + numPost + 1), size(T,3)]);
    trainData = [T', EIH_meanDiff, Head_meanDiff, EIH_std(:), Head_std(:)]; 
    trainData = real(trainData);
end

if forTrain
    % This condition is used to remove or include blinks/unlabelled.
    % Remove entries where even one of the samples has a blink or unlabelled.
    loc = arrayfun(@(x) sum(temp(:, end, x) == 4) > 0 || sum(temp(:, end, x) == 0) > 0, 1:size(temp, 3));
    loc = logical(loc);
    Targets(loc) = [];
    W(loc) = [];
    trainData(loc, :) = [];
else
    % Replace the first preWin and end postWin samples
    trainData(1:numPre, :) = repmat(trainData(numPre + 1, :), [numPre, 1]);
    trainData((end - numPost + 1):end, :) = repmat(trainData(end - numPost, :), [numPost, 1]);
end
end