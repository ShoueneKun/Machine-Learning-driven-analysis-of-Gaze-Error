function [Val, Len, StartEnd_Idx] = RunLength(In)

%% RunLength
% Author: Rakshit Kothari,Zhizhuo Yang (add comments)

NumberChange = [diff(In(:))~=0; 1]; % logical array indicate label changes
Locs = find(NumberChange);% indices of change points
Val = zeros(length(Locs), 1); % label value
Len = zeros(length(Locs), 1); % length of one event
StartEnd_Idx = zeros(length(Locs), 2);

for i = 1:length(Locs)
    if i == 1
        firstIdx = 1;
        secondIdx = Locs(i);
        Val(i) = mean(In(firstIdx:secondIdx));
        Len(i) = secondIdx;
        StartEnd_Idx(i,:) = [firstIdx, secondIdx];
    else
        firstIdx = Locs(i - 1) + 1;
        secondIdx = Locs(i);
        Val(i) = mean(In(firstIdx:secondIdx));
        Len(i) = secondIdx - firstIdx + 1;
        StartEnd_Idx(i,:) = [firstIdx, secondIdx];
    end  
end
end