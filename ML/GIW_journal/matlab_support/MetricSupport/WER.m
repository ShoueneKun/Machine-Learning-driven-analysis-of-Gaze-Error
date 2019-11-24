function wer = WER(labelStruct_ref,labelStruct_test)
%% WER Word Error Rate error metric for event classification evaluation
%   takes in labelStruct and gives a single number as output
%   transform the label sequence into event strings, then perform
%   Levenshtein distance calculation on two strings (reference string and testing string)

 ref_str = [labelStruct_ref.Label];
 test_str = [labelStruct_test.Label];
 % convert the arrays to strings
 ref_str = sprintf('%d',ref_str);
 test_str = sprintf('%d',test_str);
 % perform standard edit distance calculation
 wer = EditDistance(ref_str,test_str);
 % normalize the result by the length of the reference sequence
 wer = wer/length(ref_str);
end

