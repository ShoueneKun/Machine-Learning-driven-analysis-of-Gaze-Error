%% Generate labels from label structure
% The purpose is to generate labels from a given label structure. Part of
% routine maintaince code.
% Author: Rakshit Kothari
% WARNING: This code may cause a shift or reduction by 1 timestep because
% it uses minima distance to map label location points.

function Labels = GenerateLabelsfromStruct(LabelData)

LabelStruct = LabelData.LabelStruct;
Labels = zeros(length(LabelData.T), 1);

for i = 1:length(LabelStruct)
    if LabelStruct(i).Label ~= 0
        
        % get the start and end points with time stamps
        x = LabelStruct(i).LabelTime(1);
        y = LabelStruct(i).LabelTime(2);
        
        % get the start and end points with indices
        loc1 = findClosest(LabelData.T(:), x);
        loc2 = findClosest(LabelData.T(:), y);
        Labels(loc1:loc2) = LabelStruct(i).Label; 
    end
end

Labels = fillGap(Labels, 3);
end