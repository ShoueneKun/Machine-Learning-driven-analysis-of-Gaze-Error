function out = computeKappa_perClass(confMat)
%% computeKappa_perClass
% Computes kappa scores for each class from a confusion matrix
    out = zeros(1, length(confMat));
    Classes = 1:length(confMat);
    for k = 1:length(Classes)
        a = confMat(k, k);
        x = Classes(Classes ~= k); y = k;
        b = sum(confMat(x, y));
        x = k; y = Classes(Classes ~= k);
        c = sum(confMat(x, y));
        x = Classes(Classes ~= k); y = Classes(Classes ~= k);
        d = confMat(x, y); d = sum(d(:));
        if sum(a + b + c + d) ~= sum(confMat(:))
            error('Incorrect calculation')
        end
        CMat = [[a, c]; [b, d]];
        out(k) = kappa(CMat);
    end
    % if the kappa value is 0, that means no ground truth pursuit samples.
    % This situtation cannot be used to judge a classifier.
    out(out == 0) = NaN;
%     if any(out < 0)
%         keyboard
%     end
end