function [LabelData_ref,LabelData_test] = findOverlap(LabelData_ref,LabelData_test,T)
% Make sure the comparison happens on the overlap region between the labeled
% regions of reference label sequence and test label sequence.
% Also combine the Optokinetic fixation with gaze fixation.
%% takes in labelData and return processed labelData
% labelStruct_ref = LabelData_ref.LabelStruct;
% labelStruct_test = LabelData_test.LabelStruct;
% start_ref = labelStruct_ref(2).LabelLoc(1);
% start_test = labelStruct_test(2).LabelLoc(1);
% end_ref = labelStruct_ref(end).LabelLoc(1)-1;
% end_test = labelStruct_test(end).LabelLoc(1)-1;
% Label_ref = LabelData_ref.Labels(max(start_ref,start_test):min(end_ref,end_test));
% Label_test = LabelData_test.Labels(max(start_ref,start_test):min(end_ref,end_test));
Label_ref = LabelData_ref.Labels;
Label_test = LabelData_test.Labels;
% convert label==5 to label==1
loc1_O = Label_ref == 5;
loc2_O = Label_test == 5;
Label_ref(loc1_O) = 1;
Label_test(loc2_O) = 1;
% remove unlabeled samples and blink samples
loc1 = Label_ref == 0 | Label_ref == 4;
loc2 = Label_test == 0 | Label_test == 4;
loc = loc1 | loc2;

Label_ref = Label_ref(~loc);
Label_test = Label_test(~loc);
T = T(~loc);

LabelData_ref.Labels = Label_ref;
LabelData_test.Labels = Label_test;

LabelStruct_ref = GenerateLabelStruct(Label_ref,T);
LabelStruct_test = GenerateLabelStruct(Label_test,T);

LabelData_ref.LabelStruct = LabelStruct_ref;
LabelData_test.LabelStruct = LabelStruct_test;
end