function [Len, StartEnd_Idx] = breakSequence_overlap(Len_in, ind, maxL)
%% breakSequence
% Given a sequence, break it up with overlapping windows to ensure the
% largest sequence length does not exceed maxL.
    if logical(rem(maxL, 2))
        disp('The highest sequence length cannot be odd. Subtracting 1.')
        % The highest sequence length cannot be odd
        maxL = maxL - 1;
    end
    m = 1;
    [Len, StartEnd_Idx] = deal({});
    for i = 1:length(Len_in)
        if  Len_in(i) < maxL
            % If the length of a sequence is shorter than maxL, do not find
            % overlaps.
            Len{m} = Len_in(i); StartEnd_Idx{m} = ind(i, :);
            m = m + 1;
        else
            % Break a sequence into N overlapping parts
            x = ind(i, 1):ind(i, 2);
            % The maximum number of overlaps possible
            M = floor(2*length(x)/maxL);
            for j = 1:M
                a = 0.5*maxL*(j-1) + 1; b = min(a + maxL - 1, length(x));
                StartEnd_Idx{m} = [min(x(a:b)), max(x(a:b))];
                Len{m} = b - a + 1;
                m = m + 1;
            end
        end
    end
    Len = cell2mat(Len(:)); 
    StartEnd_Idx = cell2mat(StartEnd_Idx(:));
end