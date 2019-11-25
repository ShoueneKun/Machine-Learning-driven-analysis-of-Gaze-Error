clear all
close all
clc

Path2Repo = '/home/rakshit/Documents/MATLAB/gaze-in-wild';
addpath(genpath(fullfile(Path2Repo, 'SupportFunctions')))

global Path2ProcessData Path2LabelData

txt = fscanf(fopen(fullfile(Path2Repo, 'path.json'), 'rb'), '%s');
path_struct = jsondecode(txt);

Path2ProcessData = fullfile(path_struct.path2data, 'ProcessData');
Path2LabelData = fullfile(path_struct.path2data, 'Labels');

Dataset_pur = ReadDataset('pursuit', 300);
Dataset_fix = ReadDataset('fixation', 300);
Dataset_fol = ReadDataset('following', 300);
Dataset_sac = ReadDataset('saccade', 300);


%% Get head and eye vectors
Dataset = vertcat(Dataset_fix, Dataset_fol, Dataset_pur, Dataset_sac); 
clearvars -except Dataset
Dataset = cell2mat(Dataset.Data.'); 
HeadVec = cell2mat({Dataset.Head_Vec}.'); EyeVec = cell2mat({Dataset.EIH_Vec}.');

%% Plot spherical heat map for head and eye poses
N = 27;
[x, y, z] = sphere(N);
[~, I] = pdist2([-x(:), z(:), y(:)], HeadVec, 'cosine', 'Smallest', 1);
counts = sum(full(ind2vec(I, length(x(:)))), 2);
counts = log10(counts) - min(counts(:)); counts = uint16(double(intmax('uint16'))*counts/max(counts(:)));

colors = ind2rgb(reshape(counts', [N+1, N+1]), jet(double(intmax('uint16')))); 
colors = squeeze(colors);
figure;
surf(x, y, z, colors, 'FaceColor', 'interp')
title('Head orientation spherical heatmap')
xlabel('X axis'); ylabel('Y axis'); zlabel('Z axis')
axis equal

[~, I] = pdist2([-x(:), z(:), y(:)], EyeVec, 'cosine', 'Smallest', 1);
counts = sum(full(ind2vec(I, length(x(:)))), 2);
counts = log10(counts) - min(counts(:)); counts = uint16(double(intmax('uint16'))*counts/max(counts(:)));

colors = ind2rgb(reshape(counts', [N+1, N+1]), jet(double(intmax('uint16')))); 
colors = squeeze(colors);
figure;
surf(x, y, z, colors, 'FaceColor', 'interp')
title('Eye orientation spherical heatmap')
xlabel('X axis'); ylabel('Y axis'); zlabel('Z axis')
axis equal

%%
[az_h, el_h, ~] = cart2sph(-HeadVec(:, 1), HeadVec(:, 3), HeadVec(:, 2));
[az_e, el_e, ~] = cart2sph(-EyeVec(:, 1), EyeVec(:, 3), EyeVec(:, 2));

figure;
subplot(1, 2, 1); histogram2(wrapTo180(az_h*180/pi - 90), el_h*180/pi, -180:180, -90:90, ...
    'Normalization', 'probability', 'FaceColor', 'flat')
subplot(1, 2, 2); histogram2(wrapTo180(az_e*180/pi - 90), el_e*180/pi, -180:180, -90:90, ...
    'Normalization', 'probability', 'FaceColor', 'flat')

%%
% Add fake data to make sure 2D hist looks right
% [fakeX, fakeY] = meshgrid(-180:0.5:180, -180:0.5:180);

XData = wrapTo180([az_h(:)*180/pi; az_e(:)*180/pi] - 90);
YData = wrapTo180([el_h(:)*180/pi; el_e(:)*180/pi]);
grp = [repmat({'Head'}, [length(el_h), 1]); repmat({'Eyes'}, [length(el_e), 1])];

clear g
figure('Position',[100 100 550 550]);

%Create x data histogram on top
g(1,1)=gramm('x', XData, 'color', grp);
g(1,1).set_layout_options('Position',[0 0.8 0.8 0.2],... %Set the position in the figure (as in standard 'Position' axe property)
    'legend',false,... % No need to display legend for side histograms
    'margin_height',[0.02 0.05],... %We set custom margins, values must be coordinated between the different elements so that alignment is maintained
    'margin_width',[0.1 0.02],...
    'redraw',false); %We deactivate automatic redrawing/resizing so that the axes stay aligned according to the margin options
g(1,1).set_names('x','');
g(1,1).facet_grid([], grp);
g(1,1).stat_bin('geom','stacked_bar','fill','all',...
    'edges',-180:2:180, 'normalization', 'probability'); %histogram
g(1,1).axe_property('XTickLabel','')
% g(1,1).axe_property('XTick', -160:40:160);

%Create a scatter plot
g(2,1)=gramm('x', XData, 'y', YData, 'color', grp);
g(2,1).set_names('x','Azimuthal','y','Elevation','color', grp);
g(2,1).facet_grid([], grp);
g(2,1).stat_bin2d('edges', {-180:2:180, -180:2:180}, 'geom', 'image');
g(2,1).set_point_options('base_size',2);
g(2,1).set_layout_options('Position',[0 0 0.8 0.8],...
    'legend_pos',[0.83 0.75 0.2 0.2],... %We detach the legend from the plot and move it to the top right
    'legend',false,...
    'margin_height',[0.1 0.02],...
    'margin_width',[0.1 0.02],...
    'redraw',false, ...
    'title',false);
g(2,1).axe_property('Ygrid','on');
g(2,1).set_color_options('map', 'lch', 'lightness_range', [100, 0]);

%Create y data histogram on the right
g(3,1)=gramm('x',YData,'color', grp);
g(3,1).set_layout_options('Position',[0.8 0 0.2 0.8],...
    'legend',false,...
    'margin_height',[0.1 0.02],...
    'margin_width',[0.02 0.05],...
    'redraw',false);
g(3,1).set_names('x','');
g(3,1).stat_bin('geom','stacked_bar','fill','all',...
    'edges',-180:2:180, 'normalization', 'probability');
g(3,1).coord_flip();
g(3,1).axe_property('XTickLabel','');

%Set global axe properties
g.axe_property('TickDir','out','XGrid','on','GridColor',[0.5 0.5 0.5]);
g.set_title('Head and eye orientation');
% g.set_color_options('map','lch');
g.draw();