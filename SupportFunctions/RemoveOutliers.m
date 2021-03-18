function labelData = RemoveOutliers(labelData)
%% take in labelData and remove one-sample event outliers, give labelStruct as output
% Replace the 1-sample event with label '0'
label = labelData.Labels;

[Val, Len, StartEnd_Idx] = RunLength(label);
for i=1:length(Val)
    if Len(i) == 1
        label(StartEnd_Idx(i,1):StartEnd_Idx(i,2))=0;
    end
end
% fill the gap (label '0') randomly with preceding or following label
label_processed = fillGap(label,3);
% generate labelStruct
labelStruct = GenerateLabelStruct(label_processed,labelData.T);
labelData.LabelStruct = labelStruct;
labelData.Labels = label_processed;
