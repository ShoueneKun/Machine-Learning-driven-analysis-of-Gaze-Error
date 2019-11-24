function [eventScores] = generateMetricsRusults(labelData_ref,labelData_test, win_size, grouporder)
    %% generateMetricsRusults
    %% Generate event level performance measurements using various event level error metrics
    % only compare the common section shared by two label
    % sequences and combine Optokinetic fixation and gaze fixation
    T = labelData_ref.T;
    [labelData_ref,labelData_test] = findOverlap(labelData_ref,labelData_test,T);
    % remove 1-sample events as outliers
    labelData_ref = RemoveOutliers(labelData_ref);
    labelData_test = RemoveOutliers(labelData_test);
    labelStruct_ref = labelData_ref.LabelStruct;
    labelStruct_test = labelData_test.LabelStruct;
    %% New metric
    res = newMetric(labelData_ref, labelData_test, grouporder, 1.5);

    %% EVENT-LEVEL METRICS %%
    % calculate Word Error Rate
    wer = WER(labelStruct_ref,labelStruct_test);
    % calculate event level F1 scores
    [fixF1,purF1,sacF1]=eventF1(labelStruct_ref,labelStruct_test);
    % generate results using ELCCM
    [l2dis,olr,conf_mat,percent_detach] = ELCCM(labelData_ref,labelData_test,win_size); % ref to test
    [l2dis_b,olr_b,conf_mat_b,percent_detach_b] = ELCCM(labelData_test,labelData_ref,win_size); % test to ref
    % disp(conf_mat);
    conf_mat = table2array(conf_mat); conf_mat_b = table2array(conf_mat_b);
    k = kappa(conf_mat(grouporder, grouporder));
    disp(['refLbrIdx: ',num2str(labelData_ref.LbrIdx),'  testLbrIdx: ',num2str(labelData_test.LbrIdx),'  Kappa:',num2str(k)]);
    if isfield(labelData_test,'WinSize')
        winsize = labelData_test.WinSize;
    else
        winsize = NaN;
    end
    % create one row storing one comparison result to be added to the results
    eventScores = {labelData_ref.PrIdx, labelData_ref.TrIdx, labelData_ref.LbrIdx, labelData_test.LbrIdx,...
        winsize, wer, fixF1, purF1, sacF1, l2dis, olr, conf_mat, kappa(conf_mat), computeKappa_perClass(conf_mat),...
        percent_detach, l2dis_b, olr_b, conf_mat_b, kappa(conf_mat_b), computeKappa_perClass(conf_mat_b), percent_detach_b, ...
        res};
end