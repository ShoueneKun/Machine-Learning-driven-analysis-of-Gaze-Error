function LabelStruct = GenerateLabelStruct(in, T)
%% Generate updated label structure based on labels
% We generate a label structure again because the labeller essentially
% overwrites labels based on overwritten events.

if ~isempty(in) && ~isempty(T)
    in = in(:); % Ensure it's a column vector

    [Val, ~, StartEnd_Idx] = RunLength(in);
    LabelStruct = struct('LabelTime',[], 'LabelLoc', [], 'Label', []);

    for i = 1:size(StartEnd_Idx, 1)
        try
            LabelStruct(i).LabelLoc =  StartEnd_Idx(i,:);
            LabelStruct(i).LabelTime = [T(StartEnd_Idx(i,1)), T(StartEnd_Idx(i,2))];
            LabelStruct(i).Label = Val(i);
        catch
           keyboard 
        end
    end
else
    % Input data is corrupt
    LabelStruct.LabelLoc = [];
    LabelStruct.LabelTime = [];
    LabelStruct.Label = [];
end