clearvars
close all
clc

%% Relevant paths
txt = fscanf(fopen('path.json', 'rb'), '%s');
path_struct = jsondecode(txt);

global Path2ProcessData Path2LabelData

Path2ProcessData = fullfile(path_struct.path2data, 'ProcessData');
Path2LabelData = fullfile(path_struct.path2data, 'Labels');

% Get information regarding each participant
ParticipantInfo = GetParticipantInfo();

disp('To plot all figures, set PrIdx = -1')
PrIdx = 1;
TrIdx = 1;
if PrIdx > 0
    D_pd = dir(fullfile(Path2ProcessData, sprintf('PrIdx_%d_TrIdx_%d.mat', PrIdx, TrIdx)));
else
    D_pd = dir(fullfile(Path2ProcessData, 'PrIdx_*_TrIdx_*.mat'));
end

Dataset = struct('PrIdx', [], 'TrIdx', [], 'LbrIdx', [], 'Data', []);

m = 1;
ClxId = 14;

for i = 1:length(D_pd)
    str_pd = fullfile(D_pd(i).folder, D_pd(i).name);
    data = sscanf(D_pd(i).name, 'PrIdx_%d_TrIdx_%d.mat');
    PrIdx = data(1); TrIdx = data(2);
    str_ld = fullfile(Path2LabelData, sprintf('PrIdx_%d_TrIdx_%d_Lbr_*.mat', PrIdx, TrIdx));
%     str_cx = fullfile(Path2Results, sprintf('PrIdx_%d_TrIdx_%d_Lbr_%d_WinSize_0.mat', PrIdx, TrIdx, ClxId));
    D_ld = dir(str_ld);
%     D_cx = dir(str_cx);
    
    Age = ParticipantInfo(PrIdx).Age;
    
    % Load ProcessData into workspace
    clear ProcessData
    load(str_pd, 'ProcessData')
    
    if ~exist('ProcessData', 'var')
        keyboard
    end
    
    if size(D_ld, 1) >= 1
        ax = {};
        figure('Name',num2str(i),'units','normalized','outerposition',[0 0 1 1]);
        % Labels exist for this ProcessData mat file
        for j = 1:(length(D_ld)+1)
            
            % Load relevant LabelData into workspace
            if j <= length(D_ld)
                load(fullfile(D_ld(j).folder, D_ld(j).name), 'LabelData')
                data = sscanf(D_ld(j).name, 'PrIdx_%d_TrIdx_%d_Lbr_%d.mat');
%             else
%                 load(fullfile(D_cx.folder, D_cx.name), 'LabelData')
%                 data(3) = ClxId;
            end
            
            % Generate new axis for this Trial
            ax{j} = subplot(length(D_ld)+1, 1, j); hold on;
            plot(ax{j}, ProcessData.T(:), ProcessData.ETG.Az_Vel(:), 'Color', [0, 0, 1], 'LineStyle', '-')
            plot(ax{j}, ProcessData.T(:), ProcessData.ETG.El_Vel(:), 'Color', [0, 0, 1], 'LineStyle', '--')
            plot(ax{j}, ProcessData.T(:), ProcessData.IMU.Az_Vel(:), 'Color', [1, 0, 0], 'LineStyle', '-')
            plot(ax{j}, ProcessData.T(:), ProcessData.IMU.El_Vel(:), 'Color', [1, 0, 0], 'LineStyle', '--')
            plot(ax{j}, ProcessData.T(:), ProcessData.GIW.GIW_Vel(:), 'Color', [0, 0, 0], 'LineStyle', '-', 'LineWidth', 2)
            legend(ax{j}, {'EIH Az ^\circ/s', 'EIH El ^\circ/s', 'IMU Az ^\circ/s', 'IMU El ^\circ/s', '|GIW| ^\circ/s'}, 'AutoUpdate', 'off')
            
            % Draw patches
            DrawPatches(ax{j}, LabelData.LabelStruct, 500); hold off;
            xlabel(ax{j}, 'Time')
            ylabel(ax{j}, '\circ/S')
            grid(ax{j}, 'on')
            ylim(ax{j}, [0, 500])
            
            title(ax{j}, sprintf('Pr: %d Tr: %d Lbr: %d', data(1), data(2), data(3)))
            numFix = sum([LabelData.LabelStruct.Label] == 1);
            numPur = sum([LabelData.LabelStruct.Label] == 2);
            numSac = sum([LabelData.LabelStruct.Label] == 3);
            fprintf('F: %d, P: %d, S: %d. PrIdx: %d, TrIdx: %d, LbrIdx: %d\n', numFix, numPur, numSac, data(1), data(2), data(3))
        end
        linkaxes(ax{j}, 'xy')
    else
       % Labels do not exist
       disp(['No labels for Person: ', num2str(PrIdx), ' Trial: ', num2str(TrIdx)])
    end
end
