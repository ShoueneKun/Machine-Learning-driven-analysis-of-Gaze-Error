function I = PointCloud2Image(PC, R, T, cameraParams)
%% PointCloud2Image
% The purpose of this function is to rotate and translate a given point cloud
% by R and T and backpropagate it into a 2D image.
PC_xyz = double(PC.Location);

x_slice = PC_xyz(:, :, 1);
y_slice = PC_xyz(:, :, 2);
z_slice = PC_xyz(:, :, 3);

loc = isnan(z_slice(:)) | isnan(x_slice(:)) | isnan(y_slice(:));

worldPoints = [x_slice(~loc), y_slice(~loc), z_slice(~loc)];
imagePoints = worldToImage(cameraParams, R, T, worldPoints);

% Remove points which have a NaN value or are out of bound.
loc = sum(isnan(imagePoints), 2) | sum(imagePoints < 1, 2) | imagePoints(:, 1) > 1920 | imagePoints(:, 2) > 1080;

[X, Y] = meshgrid(1:1920, 1:1080);
I = griddata(imagePoints(~loc, 1), imagePoints(~loc, 2), worldPoints(~loc, 3), X(:), Y(:), 'nearest');
I = reshape(I, [1080, 1920]);
end