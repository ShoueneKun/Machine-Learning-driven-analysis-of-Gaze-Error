clear all
close all
clc

addpath(genpath('/home/rakshit/Documents/MATLAB/event_detection_mark_1/'))

SR = 0.3;
WinSizes = 0:3:21;

% [11, 31, 12, 13, 14, 15, 24, 34, 44, 54];
Clx_Names = {'RF'; 'fRF'; ...
    'GRU_1'; 'GRU_2'; 'biRNN_3'; 'GRU_4';
    'GRU_onlyDirection'; 'GRU_onlyEyes'; 'GRU_onlyAbs'; 'fRNN_3'};

load('PerformanceMatrix.mat')
load('kappaResults.mat')

humanLbx = [1, 2, 3, 5, 6];

%% Compile Zemblys results
ZemPerf.PrIdx = cell2mat(PrIdx(:));
ZemPerf.TrIdx = cell2mat(TrIdx(:));
ZemPerf.WinSize = cell2mat(WinSize(:));
ZemPerf.kappa_class = cell2mat(evtKappa(:));
ZemPerf.ref_lbr = cell2mat(ref_LbrIdx(:));
ZemPerf.test_lbr = cell2mat(test_LbrIdx(:));
ZemPerf.kappa = cell2mat(allKappa(:));

ZemPerf = struct2table(ZemPerf);
loc = ZemPerf.TrIdx ~= 2;
ZemPerf.kappa_class(loc, 2) = NaN;

%% Sample based performance
Clx_plot = [1, 0, 0, 0, 1, 0, 0, 0, 0, 1];
list_WinSizes = 0:3:21;

Num_WinSizes = 8;
A = cell2mat(HumanSample_Perf(:, 1)); B = cell2mat(HumanSample_Perf(:, 6));
WinSizes = repmat(0:3:21, [length(A), 1]); WinSizes = {WinSizes(:)}; 
colors = repmat({'Human'}, [length(A)*Num_WinSizes, 1]);
A = {repmat(A, [Num_WinSizes, 1])}; 
B = {repmat(B, [Num_WinSizes, 1])};

for i = 1:length(Clx_plot)
   if Clx_plot(i) 
        for j = 1:Num_WinSizes
            data = cell2mat(Classifier_SampleResults(:, i, j));
            WinSizes{end+1, 1} = list_WinSizes(j)*ones(length(data), 1);
            if j > 1 && ~strcmp(Clx_Names{i}, 'RF')
                % The value here will be NaN
                A{end+1, 1} = A{end, 1};
                B{end+1, 1} = B{end, 1};
            else
                A{end+1, 1} = [data.kappa].'; 
                B{end+1, 1} = [data.kappa_class]';
            end
            colors = [colors; repmat(Clx_Names(i), [length(data), 1])];
        end
   end
end
A = cell2mat(A); B = cell2mat(B);
WinSizes = cell2mat(WinSizes);

g(1,1) = gramm('x', (2*WinSizes+1)/0.3, 'y', A, 'color', colors);
g(1,2) = gramm('x', (2*WinSizes+1)/0.3, 'y', B(:, 1), 'color', colors);
g(1,3) = gramm('x', (2*WinSizes+1)/0.3, 'y', B(:, 2), 'color', colors);
g(1,4) = gramm('x', (2*WinSizes+1)/0.3, 'y', B(:, 3), 'color', colors);

g(1,1).stat_summary('type', 'sem'); g(1,1).set_title('Overall Kappa'); 
g(1,1).set_names('x', 'WinSize (ms)', 'y', 'Kappa');
g(1,1).no_legend()

g(1,2).stat_summary('type', 'sem'); g(1,2).set_title('G. Fixation Kappa'); 
g(1,2).set_names('x', 'WinSize (ms)', 'y', 'Kappa');
g(1,2).no_legend()

g(1,3).stat_summary('type', 'sem'); g(1,3).set_title('G. Pursuit Kappa'); 
g(1,3).set_names('x', 'WinSize (ms)', 'y', 'Kappa');
g(1,3).no_legend()

g(1,4).stat_summary('type', 'sem'); g(1,4).set_title('Saccade Kappa'); 
g(1,4).set_names('x', 'WinSize (ms)', 'y', 'Kappa');
g(1,4).no_legend()

figure('Position',[100 100 800 550]);
g.axe_property('XGrid', 'on', 'YGrid', 'on', 'PlotBoxAspectRatio',[1 1 1]); 
g.set_title('Sample based performance'); g.draw();
grid on

%% Plot event F1 measures
clear g

figure('Position',[0 0 1080 1080]);

Clx_Names = {'RF', 'biRNN-3', 'fRNN-3'};
Clx_plot = [11, 14, 54];

A = [HumanEvt_Perf.fixF1, HumanEvt_Perf.purF1, HumanEvt_Perf.sacF1];
colors = repmat({'Human'}, [length(A)*Num_WinSizes, 1]);
WinSizes = repmat(0:3:21, [length(A), 1]); WinSizes = {WinSizes(:)}; 
A = {repmat(A, [Num_WinSizes, 1])};

for i = 1:length(Clx_plot)
    for j = 1:Num_WinSizes
        if j > 1 && ~strcmp(Clx_Names{i}, 'RF')
            % The value here will be NaN
            A{end+1, 1} = A{end, 1};
        else
            loc = Classifier_EvtResults.test_LbrIdx == Clx_plot(i) & Classifier_EvtResults.WinSize == list_WinSizes(j);
            A{end+1,1} = [Classifier_EvtResults.fixF1(loc), Classifier_EvtResults.purF1(loc), Classifier_EvtResults.sacF1(loc)];
%             colors = [colors; repmat(Clx_Names(i), [sum(loc), 1])];
%             WinSizes{end+1, 1} = list_WinSizes(j)*ones(sum(loc), 1);
        end
        colors = [colors; repmat(Clx_Names(i), [sum(loc), 1])];
        WinSizes{end+1, 1} = list_WinSizes(j)*ones(sum(loc), 1);
    end
end

A = cell2mat(A); WinSizes = cell2mat(WinSizes);

g(1,1) = gramm('x', (2*WinSizes+1)/0.3, 'y', A(:, 1), 'color', colors);
g(1,2) = gramm('x', (2*WinSizes+1)/0.3, 'y', A(:, 2), 'color', colors);
g(1,3) = gramm('x', (2*WinSizes+1)/0.3, 'y', A(:, 3), 'color', colors);

g(1,1).stat_summary('type', 'sem'); g(1,1).set_title('G. Fixation F1'); g(1,1).set_names('x', 'WinSize (ms)', 'y', 'F1');
g(1,2).stat_summary('type', 'sem'); g(1,2).set_title('G. Pursuit F1'); g(1,2).set_names('x', 'WinSize (ms)', 'y', 'F1');
g(1,3).stat_summary('type', 'sem'); g(1,3).set_title('Saccade F1'); g(1,3).set_names('x', 'WinSize (ms)', 'y', 'F1');

%% Plot L2
Clx_Names = {'RF', 'biRNN-3', 'fRNN-3'};
Clx_plot = [11, 14, 54];

A = HumanEvt_Perf.l2(:, [1, 3, 5]);
colors = repmat({'Human'}, [length(A)*Num_WinSizes, 1]);
WinSizes = repmat(0:3:21, [length(A), 1]); WinSizes = {WinSizes(:)}; 
A = {repmat(A, [Num_WinSizes, 1])};

for i = 1:length(Clx_plot)
    for j = 1:Num_WinSizes
        if j > 1 && ~strcmp(Clx_Names{i}, 'RF')
            % The value here will be NaN
            A{end+1, 1} = A{end, 1};
        else
            loc = Classifier_EvtResults.test_LbrIdx == Clx_plot(i) & Classifier_EvtResults.WinSize == list_WinSizes(j);
            A{end+1,1} = Classifier_EvtResults.l2(loc, [1, 3, 5]);
        end
        colors = [colors; repmat(Clx_Names(i), [sum(loc), 1])];
        WinSizes{end+1, 1} = list_WinSizes(j)*ones(sum(loc), 1);
    end
end

A = cell2mat(A); WinSizes = cell2mat(WinSizes);

g(2,1) = gramm('x', (2*WinSizes+1)/0.3, 'y', A(:, 1)/0.3, 'color', colors);
g(2,2) = gramm('x', (2*WinSizes+1)/0.3, 'y', A(:, 2)/0.3, 'color', colors);
g(2,3) = gramm('x', (2*WinSizes+1)/0.3, 'y', A(:, 3)/0.3, 'color', colors);

g(2,1).stat_summary('type', 'sem'); g(2,1).set_title('G. Fixation L2'); g(2,1).set_names('x', 'WinSize (ms)', 'y', 'offset (ms)');
g(2,2).stat_summary('type', 'sem'); g(2,2).set_title('G. Pursuit L2'); g(2,2).set_names('x', 'WinSize (ms)', 'y', 'offset (ms)');
g(2,3).stat_summary('type', 'sem'); g(2,3).set_title('Saccade L2'); g(2,3).set_names('x', 'WinSize (ms)', 'y', 'offset (ms)');

%% Plot event kappa ELCCM
Clx_Names = {'RF', 'biRNN-3', 'fRNN-3'};
Clx_plot = [11, 14, 54];

A = HumanEvt_Perf.kappa_class;    
colors = repmat({'Human'}, [length(A)*Num_WinSizes, 1]);
WinSizes = repmat(0:3:21, [length(A), 1]); WinSizes = {WinSizes(:)}; 
A = {repmat(A, [Num_WinSizes, 1])};

for i = 1:length(Clx_plot)
    for j = 1:Num_WinSizes
        if j > 1 && ~strcmp(Clx_Names{i}, 'RF')
            % The value here will be NaN
            A{end+1, 1} = A{end, 1};
        else
            loc = Classifier_EvtResults.test_LbrIdx == Clx_plot(i) & Classifier_EvtResults.WinSize == list_WinSizes(j);
            A{end+1,1} = Classifier_EvtResults.kappa_class(loc, :);
        end
        colors = [colors; repmat(Clx_Names(i), [sum(loc), 1])];
        WinSizes{end+1, 1} = list_WinSizes(j)*ones(sum(loc), 1);
    end
end

A = cell2mat(A); WinSizes = cell2mat(WinSizes);

g(3,1) = gramm('x', (2*WinSizes+1)/0.3, 'y', A(:, 1), 'color', colors);
g(3,2) = gramm('x', (2*WinSizes+1)/0.3, 'y', A(:, 2), 'color', colors);
g(3,3) = gramm('x', (2*WinSizes+1)/0.3, 'y', A(:, 3), 'color', colors);

g(3,1).stat_summary('type', 'sem'); g(3,1).set_title('G. Fixation Kappa'); g(3,1).set_names('x', 'WinSize (ms)', 'y', 'kappa');
g(3,2).stat_summary('type', 'sem'); g(3,2).set_title('G. Pursuit Kappa'); g(3,2).set_names('x', 'WinSize (ms)', 'y', 'kappa');
g(3,3).stat_summary('type', 'sem'); g(3,3).set_title('Saccade Kappa'); g(3,3).set_names('x', 'WinSize (ms)', 'y', 'kappa');

%% Plot event Kappa Zemblys
Clx_Names = {'RF', 'biRNN-3', 'fRNN-3'};
Clx_plot = [11, 14, 54];

loc = ZemPerf.WinSize == -1;
A = ZemPerf.kappa_class(loc, :);    
colors = repmat({'Human'}, [length(A)*Num_WinSizes, 1]);
WinSizes = repmat(0:3:21, [length(A), 1]); WinSizes = {WinSizes(:)}; 
A = {repmat(A, [Num_WinSizes, 1])};

for i = 1:length(Clx_plot)
    for j = 1:Num_WinSizes
        if j > 1 && ~strcmp(Clx_Names{i}, 'RF')
            % The value here will be NaN
            A{end+1, 1} = A{end, 1};
        else
            loc = ZemPerf.test_lbr == Clx_plot(i) & ZemPerf.WinSize == list_WinSizes(j);
            A{end+1,1} = ZemPerf.kappa_class(loc, :);
        end
        colors = [colors; repmat(Clx_Names(i), [sum(loc), 1])];
        WinSizes{end+1, 1} = list_WinSizes(j)*ones(sum(loc), 1);
    end
end

A = cell2mat(A); WinSizes = cell2mat(WinSizes);

g(4,1) = gramm('x', (2*WinSizes+1)/0.3, 'y', A(:, 1), 'color', colors);
g(4,2) = gramm('x', (2*WinSizes+1)/0.3, 'y', A(:, 2), 'color', colors);
g(4,3) = gramm('x', (2*WinSizes+1)/0.3, 'y', A(:, 3), 'color', colors);

g(4,1).stat_summary('type', 'sem'); g(4,1).set_title('G. Fixation Kappa*'); g(4,1).set_names('x', 'WinSize (ms)', 'y', 'kappa');
g(4,2).stat_summary('type', 'sem'); g(4,2).set_title('G. Pursuit Kappa*'); g(4,2).set_names('x', 'WinSize (ms)', 'y', 'kappa');
g(4,3).stat_summary('type', 'sem'); g(4,3).set_title('Saccade Kappa*'); g(4,3).set_names('x', 'WinSize (ms)', 'y', 'kappa');

%% Draw event gramm
g.axe_property('XGrid', 'on', 'YGrid', 'on', 'PlotBoxAspectRatio',[1 1 1]);
g.set_layout_options('legend', 0); g.set_title('Event based F1'); g.draw();
grid on;
