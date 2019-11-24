function [fixF1,purF1,sacF1]=eventF1(labelStr_ref,labelStr_test)
%% event level F1 score using open sourced code from the author
%  takes in labelStruct and return event level F1 scores for each class separately
addpath(genpath('f1_function_library'));                 % add dirs to path
fixation_ref = [];
pursuit_ref = [];
saccade_ref = [];
fixation_test = [];
pursuit_test = [];
saccade_test = [];
for i=1:length(labelStr_ref)
    if labelStr_ref(i).Label==1 || labelStr_ref(i).Label==5
        fixation_ref = [fixation_ref;labelStr_ref(i).LabelLoc];
    elseif labelStr_ref(i).Label==2
        pursuit_ref = [pursuit_ref;labelStr_ref(i).LabelLoc];
    elseif labelStr_ref(i).Label==3
        saccade_ref = [saccade_ref;labelStr_ref(i).LabelLoc];
    end
end
for i=1:length(labelStr_test)
    if labelStr_test(i).Label==1 || labelStr_test(i).Label==5
        fixation_test = [fixation_test;labelStr_test(i).LabelLoc];
    elseif labelStr_test(i).Label==2
        pursuit_test = [pursuit_test;labelStr_test(i).LabelLoc];
    elseif labelStr_test(i).Label==3
        saccade_test = [saccade_test;labelStr_test(i).LabelLoc];
    end
end
% compute F1 from these events
fixF1 = computeF1FromEvents(fixation_ref,fixation_test);
purF1 = computeF1FromEvents(pursuit_ref,pursuit_test);
sacF1 = computeF1FromEvents(saccade_ref,saccade_test);