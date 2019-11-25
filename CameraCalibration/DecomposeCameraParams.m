clear all
close all
clc

load('StereoCameraParameters.mat')

%% Scene camera
% K = SceneCameraParams.IntrinsicMatrix';
% p = SceneCameraParams.PrincipalPoint;
% 
% K_inv = inv(K);
% 
% pts_ImagePlane = [0, 0, 1; 1920, 0, 1; 0, 1080, 1; 1920, 1080, 1; [p, 1]]';
% pts_World = K_inv*pts_ImagePlane;
% 
% for i = 1:size(pts_World, 2) - 1
%     a = pts_World(:, i);
%     C = pts_World(:, end);
% 
%     theta_horz(i) = abs(2*atand(a(1) - C(1))); disp(['Horz: ', num2str(theta_horz(i))])
%     theta_vert(i) = abs(2*atand(a(2) - C(2))); disp(['Vert: ', num2str(theta_vert(i))])
% end

%% Stereo camera 1
K = StereoCameraParams.CameraParameters2.IntrinsicMatrix;
p = StereoCameraParams.CameraParameters2.PrincipalPoint;

K_inv = inv(K);

pts_ImagePlane = [0, 0, 1; 1920, 0, 1; 0, 1080, 1; 1920, 1080, 1; [p, 1]]';
pts_World = K_inv*pts_ImagePlane;

for i = 1:size(pts_World, 2) - 1
    a = pts_World(:, i);
    C = pts_World(:, end);

    theta_horz(i) = abs(2*atand(a(1) - C(1))); disp(['Horz: ', num2str(theta_horz(i))])
    theta_vert(i) = abs(2*atand(a(2) - C(2))); disp(['Vert: ', num2str(theta_vert(i))])
    theta_diag(i) = abs(2*atand(sqrt(a(1)^2 + a(2)^2))); disp(['Diag: ', num2str(theta_diag(i))])
end

