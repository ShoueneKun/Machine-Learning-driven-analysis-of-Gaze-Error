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

X = -200:0.1:200;

%% Read the entire fixation dataset

Dataset_fix = ReadDataset('fixation', 300);
Dataset_fol = ReadDataset('following', 300);
Dataset_pur = ReadDataset('pursuit', 300);

%% Plot head and eye movement slopes

%% Absolute slope
clear g
temp = cell2mat(Dataset_fix.Data'); temp = struct2table(temp);
g(1,1) = gramm('x', temp.EIH_Vel, 'y', temp.Head_Vel);
g(1,1).stat_bin2d('nbins',{0:0.5:900 ; 0:0.5:900},'geom','image');
g(1,1).geom_abline('style', 'r--');
g(1,1).set_title('Fixation'); g(1,1).set_names('x', '|EIH| velocity', 'y', '|Head| velocity');
g(1,1).axe_property('XLim', [0,100], 'YLim', [0,100], 'DataAspectRatio',[1 1 1]);
g(1,1).set_layout_options('legend', 0)

temp = cell2mat(Dataset_fol.Data'); temp = struct2table(temp);
g(1,2) = gramm('x', temp.EIH_Vel, 'y', temp.Head_Vel);
g(1,2).stat_bin2d('nbins',{0:0.5:900 ; 0:0.5:900},'geom','image');
g(1,2).geom_abline('style', 'r--');
g(1,2).set_title('Following'); g(1,2).set_names('x', '|EIH| velocity', 'y', '|Head| velocity');
g(1,2).axe_property('XLim', [0,100], 'YLim', [0,100], 'DataAspectRatio',[1 1 1])
g(1,2).set_layout_options('legend', 0)

temp = cell2mat(Dataset_pur.Data'); temp = struct2table(temp);
g(1,3) = gramm('x', temp.EIH_Vel, 'y', temp.Head_Vel);
g(1,3).stat_bin2d('nbins',{0:0.5:900 ; 0:0.5:900},'geom','image');
g(1,3).geom_abline('style', 'r--');
g(1,3).set_title('Pursuit'); g(1,3).set_names('x', '|EIH| velocity', 'y', '|Head| velocity');
g(1,3).axe_property('XLim', [0,100], 'YLim', [0,100], 'DataAspectRatio',[1 1 1])
g(1,3).set_layout_options('legend', 0)

g.set_title('Eye and Head absolute velocity')
figure('Position', [50, 50, 1200, 600]);
g.draw();

%% Az slope
clear g
temp = cell2mat(Dataset_fix.Data'); temp = struct2table(temp);
g(1,1) = gramm('x', temp.EIH_AzVel, 'y', temp.Head_AzVel);
g(1,1).stat_bin2d('nbins',{-900:0.5:900 ; -900:0.5:900},'geom','image'); %g(1,1).set_point_options('base_size',6);
g(1,1).set_title('Fixation'); g(1,1).set_names('x', 'EIH Az velocity', 'y', 'Head Az velocity')
g(1,1).axe_property('XLim', [-40, 40], 'YLim', [-40, 40], 'DataAspectRatio',[1 1 1])
g(1,1).set_layout_options('legend', 0)

temp = cell2mat(Dataset_fol.Data'); temp = struct2table(temp);
g(1,2) = gramm('x', temp.EIH_AzVel, 'y', temp.Head_AzVel);
g(1,2).stat_bin2d('nbins',{-900:0.5:900 ; -900:0.5:900},'geom','image'); %g(1,2).set_point_options('base_size',6);
g(1,2).set_title('Following'); g(1,2).set_names('x', 'EIH Az velocity', 'y', 'Head Az velocity')
g(1,2).axe_property('XLim', [-40, 40], 'YLim', [-40, 40], 'DataAspectRatio',[1 1 1])
g(1,2).set_layout_options('legend', 0)

temp = cell2mat(Dataset_pur.Data'); temp = struct2table(temp);
g(1,3) = gramm('x', temp.EIH_AzVel, 'y', temp.Head_AzVel);
g(1,3).stat_bin2d('nbins',{-900:0.5:900 ; -900:0.5:900},'geom','image'); %g(1,3).set_point_options('base_size',6);
g(1,3).set_title('Pursuit'); g(1,3).set_names('x', 'EIH Az velocity', 'y', 'Head Az velocity')
g(1,3).axe_property('XLim', [-40, 40], 'YLim', [-40, 40], 'DataAspectRatio',[1 1 1])
g(1,3).set_layout_options('legend', 0)

g.set_title('Eye and Head azimuthal velocity')
figure('Position', [50, 50, 1200, 600]);
g.draw();

%% El slope
clear g
temp = cell2mat(Dataset_fix.Data'); temp = struct2table(temp);
g(1,1) = gramm('x', temp.EIH_ElVel, 'y', temp.Head_ElVel);
g(1,1).stat_bin2d('nbins',{-900:0.5:900 ; -900:0.5:900},'geom','image');
g(1,1).set_title('Fixation')
g(1,1).axe_property('XLim', [-40, 40], 'YLim', [-40, 40], 'DataAspectRatio',[1 1 1])

temp = cell2mat(Dataset_fol.Data'); temp = struct2table(temp);
g(1,2) = gramm('x', temp.EIH_ElVel, 'y', temp.Head_ElVel);
g(1,2).stat_bin2d('nbins',{-900:0.5:900 ; -900:0.5:900},'geom','image');
g(1,2).set_title('Following')
g(1,2).axe_property('XLim', [-40, 40], 'YLim', [-40, 40], 'DataAspectRatio',[1 1 1])

temp = cell2mat(Dataset_pur.Data'); temp = struct2table(temp);
g(1,3) = gramm('x', temp.EIH_ElVel, 'y', temp.Head_ElVel);
g(1,3).stat_bin2d('nbins',{-900:0.5:900 ; -900:0.5:900},'geom','image');
g(1,3).set_title('Pursuit')
g(1,3).axe_property('XLim', [-40, 40], 'YLim', [-40, 40], 'DataAspectRatio',[1 1 1])

g.set_title('Eye and Head elevation velocity')
figure('Position', [50, 50, 1200, 600]);
g.draw();

%% Plot all in one figure
clear g

% fixation and following
temp = cell2mat(Dataset_fix.Data'); temp = struct2table(temp); 
N1 = length(cell2mat(temp.EIH_AzVel')); N2 = length(cell2mat(temp.EIH_ElVel'));

X = [cell2mat(temp.EIH_AzVel'), cell2mat(temp.EIH_ElVel')];
Y = [cell2mat(temp.Head_AzVel'), cell2mat(temp.Head_ElVel')];

id = repmat({'Elevation'}, [length(X), 1]); id(1:length(X)/2) = {'Azimuthal'};

g(1,1) = gramm('x', cell2mat(temp.EIH_Vel'),'y', cell2mat(temp.Head_Vel'));
g(1,1).stat_bin2d('nbins',{0:1.5:900 ; 0:1.5:900},'geom','contour');
% g(1,1).geom_abline('style', 'r--');
g(1,1).set_title('Fixation'); g(1,1).set_names('x', '|EIH| velocity', 'y', '|Head| velocity');
g(1,1).axe_property('XLim', [0,45], 'YLim', [0,45], 'DataAspectRatio',[1 1 1]);

g(2,1) = gramm('x', X, 'y', Y);
g(2,1).facet_grid([], id);
g(2,1).stat_bin2d('nbins',{-900:1.5:900 ; -900:1.5:900}, 'geom', 'contour');
% g(2,1).geom_abline('style', 'r--', 'slope', -1);
g(2,1).axe_property('XLim', [-40, 40], 'YLim', [-40, 40])
g(2,1).set_names('x', 'EIH velocity', 'y', 'Head velocity');

% Following
temp = cell2mat(Dataset_fol.Data'); temp = struct2table(temp);
X = [cell2mat(temp.EIH_AzVel'), cell2mat(temp.EIH_ElVel')];
Y = [cell2mat(temp.Head_AzVel'), cell2mat(temp.Head_ElVel')];
id = repmat({'Elevation'}, [length(X), 1]); id(1:length(X)/2) = {'Azimuthal'};

g(1,2) = gramm('x', cell2mat(temp.EIH_Vel'), 'y', cell2mat(temp.Head_Vel'));
g(1,2).stat_bin2d('nbins',{0:1.5:900 ; 0:1.5:900},'geom','contour');
% g(1,2).geom_abline('style', 'r--');
g(1,2).set_title('Optokinetic fixation'); g(1,2).set_names('x', '|EIH| velocity', 'y', '|Head| velocity');
g(1,2).axe_property('XLim', [0,45], 'YLim', [0,45], 'DataAspectRatio',[1 1 1]);

g(2,2) = gramm('x', X, 'y', Y);
g(2,2).facet_grid([], id);
g(2,2).stat_bin2d('nbins',{-900:1.5:900 ; -900:1.5:900}, 'geom', 'contour');
% g(2,2).geom_abline('style', 'r--', 'slope', -1);
g(2,2).axe_property('XLim', [-40, 40], 'YLim', [-40, 40])
g(2,2).set_names('x', 'EIH velocity', 'y', 'Head velocity');

% Pursuit
temp = cell2mat(Dataset_pur.Data'); temp = struct2table(temp);
X = [cell2mat(temp.EIH_AzVel'), cell2mat(temp.EIH_ElVel')];
Y = [cell2mat(temp.Head_AzVel'), cell2mat(temp.Head_ElVel')];
id = repmat({'Elevation'}, [length(X), 1]); id(1:length(X)/2) = {'Azimuthal'};

g(1,3) = gramm('x', cell2mat(temp.EIH_Vel'), 'y', cell2mat(temp.Head_Vel'));
g(1,3).stat_bin2d('nbins',{0:3:900 ; 0:3:900},'geom','contour');
% g(1,3).geom_abline('style', 'r--');
g(1,3).set_title('Pursuit'); g(1,3).set_names('x', '|EIH| velocity', 'y', '|Head| velocity');
g(1,3).axe_property('XLim', [0,45], 'YLim', [0,45], 'DataAspectRatio',[1 1 1]);
g(1,3).set_layout_options('legend', 1)

g(2,3) = gramm('x', X, 'y', Y);
g(2,3).facet_grid([], id);
g(2,3).stat_bin2d('nbins',{-900:3:900 ; -900:3:900}, 'geom', 'contour');
% g(2,3).geom_abline('style', 'r--', 'slope', -1);
g(2,3).axe_property('XLim', [-40, 40], 'YLim', [-40, 40]);
g(2,3).set_names('column', 'Direction');
g(2,3).set_names('x', 'EIH velocity', 'y', 'Head velocity');

% General options
g(2,:).axe_property('XTick', -30:15:30, 'YTick', -30:15:30);
g.set_layout_options('legend', 0);
g.axe_property('TickLabelInterpreter', 'tex', 'DataAspectRatio',[1 1 1]);
g.set_title('Eye and Head absolute velocity');
figure('Position', [50, 50, 1200, 600]);
g.draw();

%% Plot head-eye phase angle vs magnitude
% temp = cell2mat(Dataset_fix.Data'); temp = struct2table(temp);
% 
% figure;
% 
% X = cell2mat(temp.EIH_AzVel'); Y = cell2mat(temp.Head_AzVel'); Z = X./Y;
% loc = abs(Z) > 5; fprintf('Number of outlier samples: %d\n', sum(loc)/length(loc));
% subplot(1, 2, 1); scatter3(X(~loc), Y(~loc), Z(~loc), 'MarkerFaceAlpha', 0.01,...
%     'MarkerEdgeColor', 'none', 'MarkerFaceColor', [1,0,0])
% 
% X = cell2mat(temp.EIH_ElVel'); Y = cell2mat(temp.Head_ElVel'); Z = X./Y;
% loc = abs(Z) > 5; fprintf('Number of outlier samples: %d\n', sum(loc)/length(loc));
% subplot(1, 2, 2); scatter3(X(~loc), Y(~loc), Z(~loc), 'MarkerFaceAlpha', 0.01,...
%     'MarkerEdgeColor', 'none', 'MarkerFaceColor', [1,0,0])