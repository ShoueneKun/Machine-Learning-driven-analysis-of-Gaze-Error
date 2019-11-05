function DrawPatches(Ax, LabelStruct, yMax)

if ~isempty(LabelStruct)
    for i = 1:length(LabelStruct)
        switch LabelStruct(i).Label
            case 1
                PatchColor = [0 1 0];
            case 2
                PatchColor = [0 0 1];
            case 3
                PatchColor = [1 0 0];
            case 4
                PatchColor = [1 1 0];
            case 5
                PatchColor = [0 1 1];
            case 0
                PatchColor = [0 0 0];
        end
        Dim = [LabelStruct(i).LabelTime(1), LabelStruct(i).LabelTime(2), 0, yMax];
        if LabelStruct(i).Label ~= 0
            % Do not draw patch for case 0
            DrawPatch(Ax, Dim, PatchColor);
        end
    end
end
end