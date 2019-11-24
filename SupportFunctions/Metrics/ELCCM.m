%% Event Level Cross-category Metric
%  take in reference and test labelData and generate results 
function [l2dis,olr,conf_mat,percent_detach]= ELCCM(label_ref,label_test,winsize)
%% fill the unlabeled gap in the middle of gaze events
% ref_filled = fillGap(label_ref.Labels,5);
% test_filled = fillGap(label_test.Labels,5);
%% construct events tuples and measures (matching information) from LabelStructs
LabelStruct_ref = label_ref.LabelStruct;
LabelStruct_test = label_test.LabelStruct;
events_ref = event_metric_support.to_event(LabelStruct_ref);
events_test = event_metric_support.to_event(LabelStruct_test);
measures_ref2test = event_metric_support.matching(events_ref,events_test,winsize); % do the metric from ref(usually human) to test
% measures_test2ref = event_metric_support.matching(events_test,events_ref,winsize); % do the metric from test(usually algorithm) to ref
%% report events statistics for both sequence 
% event_metric_support.reportEvents(events_ref,label_ref.PrIdx,label_ref.TrIdx,label_ref.LbrIdx);
% event_metric_support.reportEvents(events_test,label_test.PrIdx,label_test.TrIdx,label_test.LbrIdx);
%% calculate L2 distance and overlap ratio
[scores,num_cor,percent_detach] = event_metric_support.process_matched(measures_ref2test,events_ref,label_ref.Labels,label_test.Labels);
l2_dis = cell2mat(scores(:,3));
event_type = cell2mat(scores(:,2));
l2_dis_mean_f = mean(l2_dis(event_type==1));
l2_dis_std_f = std(l2_dis(event_type==1));
l2_dis_mean_p = mean(l2_dis(event_type==2));
l2_dis_std_p = std(l2_dis(event_type==2));
l2_dis_mean_s = mean(l2_dis(event_type==3));
l2_dis_std_s = std(l2_dis(event_type==3));
l2dis = [l2_dis_mean_f,l2_dis_std_f,l2_dis_mean_p,l2_dis_std_p,l2_dis_mean_s,l2_dis_std_s];
olr = cell2mat(scores(:,4));
olr_mean_f = mean(olr(event_type==1));
olr_std_f = std(olr(event_type==1));
olr_mean_p = mean(olr(event_type==2));
olr_std_p = std(olr(event_type==2));
olr_mean_s = mean(olr(event_type==3));
olr_std_s = std(olr(event_type==3));
olr = [olr_mean_f,olr_std_f,olr_mean_p,olr_std_p,olr_mean_s,olr_std_s];
%% perform global alignment and fill unlabeled region
[ref_aligned,test_aligned] = event_metric_support.globalAlignment(measures_ref2test,label_ref.Labels,label_test.Labels);
% test_aligned = event_metric_support.globalAlignment(measures_test2ref,label_test.Labels);
[ref_fu,test_fu] = event_metric_support.fillUnlabeled(ref_aligned,test_aligned);
%% add a function for visualizing the labels (before and after alignment)
% vis_labels(label_ref.Labels, label_test.Labels,ref_aligned,test_aligned,label_ref.T);
%% change the label
ref_changed = event_metric_support.changeLabel(ref_fu);
test_changed = event_metric_support.changeLabel(test_fu);
%% calculate differences between two processed label sequences
conf_mat = event_metric_support.cal_confmax(ref_changed,test_changed,label_ref.T,num_cor);