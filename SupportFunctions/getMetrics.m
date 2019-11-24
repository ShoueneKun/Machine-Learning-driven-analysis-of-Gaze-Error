function [Metrics, evt] = getMetrics(pd, gt_mat, remove_labels, grouporder)
    %% EventMetrics - Returns all event level metrics except ZemPerf
    % This file automatically removes labels listed in
    % remove_labels. It returns sample based metrics on
    % the label values present in grouporder
    if size(pd, 1) ~= size(gt_mat, 1)
        keyboard
    end
    % Ensure format is column in vector
    if size(gt_mat, 2) == 1
        gt = gt_mat(:); pd = pd(:);
        [Metrics, evt] = test_seq(pd, gt, remove_labels, grouporder);
         evt(1:5) = [];
    else
        M = size(gt_mat, 2);
        % The number of arrays to be tested against
        evt = [];
        for k = 1:M
            gt = gt_mat(:, k); pd = pd(:);
            [Metrics(k, 1), temp] = test_seq(pd, gt, remove_labels, grouporder);
            evt = [evt; temp];
        end
    end
end

function [op, evt] = test_seq(pd, gt, remove_labels, grouporder)
    if ~isempty(remove_labels)
        for i = 1:length(remove_labels)
            loc = gt == remove_labels(i) | pd == remove_labels(i);
            gt(loc) = []; pd(loc) = [];
        end
    end
    C = confusionmat(gt, pd, 'order', grouporder);
    op = confusionmatStats(C);
    op.kappa = kappa(C);
    op.kappa_class = zeros(length(grouporder), 1);
    for i = 1:length(grouporder)
        C = confusionmat(gt == grouporder(i), pd == grouporder(i), 'order', [0, 1]);
        op.kappa_class(i, 1) = kappa(C);
    end
    if ~isempty(gt) && ~isempty(pd)
        T = linspace(0, length(gt)/300, length(gt));
        s1.LabelStruct = GenerateLabelStruct(gt, T); s1.Labels = gt(:); s1.T = T; s1.PrIdx = 0; s1.TrIdx = 0; s1.LbrIdx = 0;
        s2.LabelStruct = GenerateLabelStruct(pd, T); s2.Labels = pd(:); s2.T = T; s2.PrIdx = 0; s2.TrIdx = 0; s2.LbrIdx = 0;
        evt = generateMetricsRusults(s1, s2, [15, 21], grouporder);
        evt(1: 5) = [];
    else
        evt = [];
    end
end
