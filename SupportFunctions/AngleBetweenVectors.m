function out = AngleBetweenVectors(v1, v2)
%% AngleBetweenVectors
% This function calculates the angle between two given vectors or array of vectors.
% It is assumed the rows are vectors.
    if size(v1, 2)~=3
        error('Input should have 3 columns')
    elseif size(v1, 1)==3
        v1 = v1';
        v2 = v2';
        disp('Input should have 3 columns')
    end

    if size(v1, 1)~=size(v2, 1)
        if size(v2, 1) == 1
            v2 = repmat(v2, [size(v1, 1), 1]);
        elseif size(v1, 1) == 1
            v1 = repmat(v1, [size(v2, 1), 1]);
        else
            error('Check input')
        end
    end

    v1 = normr(v1);
    v2 = normr(v2);

    D = dot(v1, v2, 2);
    C = cross(v1, v2, 2);
    C = sqrt(sum(C.^2, 2));
    out = atan2d(C, D);
end