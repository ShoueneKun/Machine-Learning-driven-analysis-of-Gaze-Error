clear all
close all
clc

deg = 2;
T = readtable('ETGCalib_ecc.csv');

%% 

figure;
ax = subplot(1, 1, 1);
hold(ax, 'on')
ax.Color = [1, 1, 1];
scatterhist(T.Ecc, T.AngErr, 'Direction', 'out', 'Kernel', 'off')
xlabel('Eccentricity in degrees \circ')
ylabel('Angular error in degrees \circ')


%% Using GRAMM

figure('Position', [100, 100, 550, 550])

% Create X histogram on the top
g(1,1) = gramm('x', T.Ecc);
g(1,1).set_layout_options('Position',[0 0.8 0.8 0.2],... %Set the position in the figure (as in standard 'Position' axe property)
    'legend',false,... % No need to display legend for side histograms
    'margin_height',[0.02 0.05],... %We set custom margins, values must be coordinated between the different elements so that alignment is maintained
    'margin_width',[0.1 0.02],...
    'redraw',false); %We deactivate automatic redrawing/resizing so that the axes stay aligned according to the margin options
g(1,1).set_names('x','', 'size', 20);
g(1,1).stat_bin('geom','line','fill','all','nbins',30); %histogram
g(1,1).axe_property('XTickLabel',''); % We deactivate tht ticks

%Create a scatter plot
g(2,1)=gramm('x', T.Ecc, 'y', T.AngErr);
g(2,1).set_names('x','Eccentricity','y','Angular Error', 'size', 20);
% g(2,1).geom_point('alpha', 0.3); %Scatter plot
g(2,1).stat_bin2d('nbins', [20, 20], 'geom', 'image')
g(2,1).set_point_options('base_size',10);
% g(2,1).stat_bin2d('nbins', [50, 50], 'geom', 'image');
g(2,1).set_layout_options('Position',[0 0 0.8 0.8],...
    'legend_pos',[0.83 0.75 0.2 0.2],... %We detach the legend from the plot and move it to the top right
    'margin_height',[0.1 0.02],...
    'margin_width',[0.1 0.02],...
    'redraw',false);
g(2,1).axe_property('Ygrid','on');

%Create y data histogram on the right
g(3,1)=gramm('x', T.AngErr);
g(3,1).set_layout_options('Position',[0.8 0 0.2 0.8],...
    'legend',false,...
    'margin_height',[0.1 0.02],...
    'margin_width',[0.02 0.05],...
    'redraw',false);
g(3,1).set_names('x','', 'size', 20);
g(3,1).stat_bin('geom','line','fill','all','nbins',30); %histogram
g(3,1).coord_flip();
g(3,1).axe_property('XTickLabel','');

%Set global axe properties
g.axe_property('TickDir','out','XGrid','on','GridColor',[0.5 0.5 0.5], 'FontSize', 14);
g.set_title('ETG Performance', 'FontSize', 20);
g.set_color_options('map','d3_10');
g.draw();
