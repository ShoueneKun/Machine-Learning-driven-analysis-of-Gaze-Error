function vis_labels(lab_ref,lab_test,lab_ref_a,lab_test_a,T)
%%% visualization of label sequences and their differences
% show both label sequence before and after the global alignment, also
% show the differences before and after alignment.
% tales in label sequences as lists/vectors, convert to struct inside.
figure('Name','label comparison','units','normalized','outerposition',[0 0 1 1]);
ax = [];
ax(1) = subplot(6,1,1);
ax(2) = subplot(6,1,2);
ax(3) = subplot(6,1,3);
ax(4) = subplot(6,1,4);
ax(5) = subplot(6,1,5);
ax(6) = subplot(6,1,6);
% create a mask for 0-label sample on both sequences
mask_0 = lab_ref==0 & lab_test==0;
% calculate the direct differences between two label sequences
direct_diff = lab_ref - lab_test;
lab_ref_struct = GenerateLabelStruct(lab_ref,T);
lab_test_struct = GenerateLabelStruct(lab_test,T);
direct_diff_struct = GenerateLabelStruct(direct_diff(~mask_0),T(~mask_0));
% calculate differences after alignment
diff_a = lab_ref_a - lab_test_a;
lab_ref_a_struct = GenerateLabelStruct(lab_ref_a,T);
lab_test_a_struct = GenerateLabelStruct(lab_test_a,T);
diff_struct = GenerateLabelStruct(diff_a(~mask_0),T(~mask_0));
DrawPatches(ax(1),lab_ref_struct,10);
DrawPatches(ax(2),lab_test_struct,10);
DrawDifference(ax(3),direct_diff_struct,10);
DrawPatches(ax(4),lab_ref_a_struct,10);
DrawPatches(ax(5),lab_test_a_struct,10);
DrawDifference(ax(6),diff_struct,10);
linkaxes(ax,'xy');
end