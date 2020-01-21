function [Rot_AxAng, Rot_Mats] = RotateVectors(v1, v2)
% ROTATEVECTORS Rotate vector 1 to vector 2
% Finds the Axis Angle rotation required to transform vector 1 to vector 2.
% The order is very important.
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

    u = normr(cross(normr(v2), normr(v1)));
    a = dot(normr(v2), normr(v1), 2);
    b = cross(normr(v2), normr(v1), 2);
    b = sqrt(sum(b.^2, 2));
    rot = atan2(b, a);
    Rot_AxAng = [u, rot];
    Rot_Mats = axang2rotm(Rot_AxAng);
end

