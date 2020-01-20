function [D, Pt3D, I_Depth] = PointDepthFromPointCloud(PC, R, T, cameraParams, por, genDepthImage)
%% PointDepthFromPointCloud
% The purpose of this file to generate a 3D gaze point and a depth image. If sufficient
% points do not exist, then the function with return a black image.
I_Depth = zeros(1080, 1920, 1);    
PC_xyz = double(PC);

x_slice = PC_xyz(:, :, 1);
y_slice = PC_xyz(:, :, 2);
z_slice = PC_xyz(:, :, 3);

loc = isnan(z_slice(:)) | isnan(x_slice(:)) | isnan(y_slice(:));

worldPoints = [x_slice(~loc), y_slice(~loc), z_slice(~loc)];
loc = isnan(worldPoints); loc = logical(sum(loc, 2));
worldPoints(loc, :) = [];

if size(worldPoints, 1) > 100
    % Condition: Atleast 100 points present in the point cloud
    imagePoints = worldToImage(cameraParams, R, T, worldPoints, 'ApplyDistortion', 1);

    % Remove points which are outside the field of view
    loc = sum(imagePoints < 1, 2) | imagePoints(:, 1) > 1920 | imagePoints(:, 2) > 1080;
    loc = loc | logical(sum(isnan(imagePoints), 2));
    % It is possible to have NaN values in imagePoints despite removing
    % them in worldPoints.
    imagePoints(loc, :) = []; worldPoints(loc, :) = [];

    if ~isempty(imagePoints)
        [X, Y] = meshgrid(1:1920, 1:1080);

        if genDepthImage
            I_Depth = griddata(imagePoints(:, 1), imagePoints(:, 2), ...
                worldPoints(:, 3), X(:), Y(:), 'natural');
            I_Depth = reshape(I_Depth, [1080, 1920]);
        end
        Pt3D = worldPoints(findClosest(imagePoints, por), :);
        D = Pt3D(3);
        % FUTURE: A better solution is to generate a plane with 3 closest points and find the intersection.
    else
        D = NaN;
        Pt3D = NaN(1, 3);
    end
else
    D = NaN;
    Pt3D = NaN(1, 3);
end
end