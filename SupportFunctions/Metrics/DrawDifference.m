function DrawDifference(Ax, LabelStruct, yMax)
% visualize the difference between two label sequences, green part means
% aggrement, red part means disagreement.
if ~isempty(LabelStruct)
    for i = 1:length(LabelStruct)
        if LabelStruct(i).Label==0
            PatchColor = [0 1 0];
        else
            PatchColor = [1 0 0];
        end
        Dim = [LabelStruct(i).LabelTime(1), LabelStruct(i).LabelTime(2), 0, yMax];
        DrawPatch(Ax, Dim, PatchColor);
    end
end
end