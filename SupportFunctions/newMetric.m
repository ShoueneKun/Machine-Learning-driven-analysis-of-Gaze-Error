function K = newMetric(labelData_ref, labelData_test, grouporder, threshold)
%% newMetrics
% This function computes the new idea for event matching. 
% Author: George Yang.
% FUTURE: Use grouporder to only consider those class numbers.
    LabelStruct_ref = labelData_ref.LabelStruct;
    LabelStruct_test = labelData_test.LabelStruct;
    Labels_ref = labelData_ref.Labels;
    Labels_test = labelData_test.Labels;
    N = length(LabelStruct_ref);
    M = length(LabelStruct_test);
    conf_mat_f = zeros(4,4); % overall confusion matrix for forward direction
    conf_mat_b = zeros(4,4); % overall confusion matrix for backward direction
    unmatch_f = [0 0 0 0];
    unmatch_b = [0 0 0 0];
    % forward path
    for i=1:N
        Idx = LabelStruct_ref(i).LabelLoc;
        labels_test = Labels_test(Idx(1):Idx(2));
        e_type_ref = LabelStruct_ref(i).Label; % event type in reference
        n_fix = sum(labels_test==1);
        n_pur = sum(labels_test==2);
        n_sac = sum(labels_test==3);
        n_unl = sum(labels_test==0);
        ranking = [1 n_fix; 2 n_pur; 3 n_sac; 4 n_unl];
        sorted = sortrows(ranking, 2, 'descend');
        % update the confusion matrix for forward direction if larggest
        % overlapped sample type is more than second sample type at certain ratio
        if sorted(1,2)>sorted(2,2)*threshold
            if e_type_ref==0
                continue
            end
            conf_mat_f(e_type_ref,sorted(1,1)) = conf_mat_f(e_type_ref,sorted(1,1)) +1;
        else
            unmatch_f(e_type_ref) = unmatch_f(e_type_ref)+1;
        end
    end
    % backward path
    for j=1:M
        Idx = LabelStruct_test(j).LabelLoc;
        labels_ref = Labels_ref(Idx(1):Idx(2));
        e_type_test = LabelStruct_test(j).Label; % event type in testing
        n_fix = sum(labels_ref==1);
        n_pur = sum(labels_ref==2);
        n_sac = sum(labels_ref==3);
        n_unl = sum(labels_ref==0);
        ranking = [1 n_fix; 2 n_pur; 3 n_sac; 4 n_unl];
        sorted = sortrows(ranking,2,'descend');
        % update the confusion matrix for forward direction if larggest
        % overlapped sample type is more than second sample type at certain ratio
        if sorted(1,2)>sorted(2,2)*threshold
            if e_type_test==0
                continue
            end
            conf_mat_b(e_type_test,sorted(1,1)) = conf_mat_b(e_type_test,sorted(1,1)) +1;
        else
            unmatch_b(e_type_test) = unmatch_b(e_type_test)+1;
        end
    end
    conf_mat_f = conf_mat_f(grouporder, grouporder);
    conf_mat_b = conf_mat_b(grouporder, grouporder);

    k_f = kappa(conf_mat_f); k_b = kappa(conf_mat_b);
    kpc_f = computeKappa_perClass(conf_mat_f); kpc_b = computeKappa_perClass(conf_mat_b);
    % RK: Individual pursuit scores can be NaN. The average won't work in those cases.
    K = nanmean([k_b, k_f]); Kpc = nanmean([kpc_b(:), kpc_f(:)], 2);
    K = [K, Kpc'];
    agreement = 1 - abs(k_f - k_b);
    agreement_pc = 1 - abs(kpc_f - kpc_b);
    agreement = [agreement, agreement_pc];
    K = [K, agreement];
end