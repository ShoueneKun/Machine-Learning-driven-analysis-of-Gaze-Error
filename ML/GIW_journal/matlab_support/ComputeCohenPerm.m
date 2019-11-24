function [vals, pr, rc, f, cmats, kappa_class, evt] = ComputeCohenPerm(LabelMat)
%% ComputeCohenPerm
% This function computes the Cohen's Kappa along every single permutation
% between the various labellers present. The permutation values can be used
% to infer average human performance.

% loc = sum(LabelMat, 1) == 0;
% LabelMat(:, loc) = [];

global kappaTalk
kappaTalk = 0;

numLabellers = size(LabelMat, 2);
grouporder = [1, 2, 3];

[X, Y] = meshgrid(1:numLabellers, 1:numLabellers);
totalPos = [X(:), Y(:)];
loc = logical(diff(totalPos, [], 2));
totalPos(~loc, :) = [];

vals = zeros(length(totalPos), 1);
[pr, rc, f, kappa_class] = deal(zeros(length(totalPos), 3));
evt = [];
cmats = cell(length(totalPos), 1);
for i = 1:size(totalPos, 1)
    Seq1 = LabelMat(:, totalPos(i, 1)); Seq2 = LabelMat(:, totalPos(i, 2));
    % Remove blinks and unlabelled sequences from consideration. This is
    % because they do not add anything of value. It is important to remove
    % these samples from both the sequences.
    
    loc = Seq1 == 0 | Seq1 == 4 | Seq2 == 0 | Seq2 == 4;
    Seq1(loc) = []; Seq2(loc) = [];
    if ~isempty(Seq1) && ~isempty(Seq2)
%         C_stats = confusionmatStats(Seq1, Seq2);
        try
            % Find event metrics. Generate fake LabelData
            T = linspace(0, length(Seq1)/300, length(Seq1));
            s1.LabelStruct = GenerateLabelStruct(Seq1, T); s1.Labels = Seq1(:); s1.T = T; s1.PrIdx = 0; s1.TrIdx = 0; s1.LbrIdx = 0;
            s2.LabelStruct = GenerateLabelStruct(Seq2, T); s2.Labels = Seq2(:); s2.T = T; s2.PrIdx = 0; s2.TrIdx = 0; s2.LbrIdx = 0;
            temp = generateMetricsRusults(s1, s2, [15, 21], grouporder); temp(1:4) = [];
            evt = [evt; temp];
            
            CMat = confusionmat(Seq1, Seq2, 'order', grouporder);
            C_stats = confusionmatStats(CMat);
            vals(i) = kappa(C_stats.confusionMat);
            pr(i, :) = C_stats.precision';
            rc(i, :) = C_stats.recall';
            f(i, :) = C_stats.Fscore';
            cmats{i, 1} = CMat./repmat(sum(CMat, 2), [1, 3]);
            for k = 1:length(grouporder)
                C = confusionmat(Seq1 == grouporder(k), Seq2 == grouporder(k), 'order', [0, 1]);
                kappa_class(i, k) = kappa(C);
            end
            if vals(i) < 0.5
                fprintf('Not compatible: %d, %d\n', totalPos(i, 1), totalPos(i, 2))
            end
        catch
           keyboard 
        end
    end
end
pr(pr == 0) = nan;
rc(rc == 0) = nan;
vals(vals == 0) = nan;
f(f == 0) = nan;
kappa_class(kappa_class == 0) = nan;
cmats(cellfun(@isempty, cmats)) = [];
cmats = cell2mat(permute(cmats, [3, 2, 1]));
end