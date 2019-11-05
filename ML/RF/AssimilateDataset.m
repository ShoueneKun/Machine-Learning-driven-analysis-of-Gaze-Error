clear all
close all
clc

path2repo = '/home/rakshit/Documents/MATLAB/GIW';
txt = fscanf(fopen(fullfile(path2repo, 'path.json'), 'rb'), '%s');
path_struct = jsondecode(txt);

global Path2ProcessData Path2LabelData

Path2ProcessData = fullfile(path_struct.path2data, 'ProcessData');
Path2LabelData = fullfile(path_struct.path2data, 'Labels');

ParticipantInfo = GetParticipantInfo();

D_pd = dir(fullfile(Path2ProcessData, 'PrIdx_*_TrIdx_*.mat'));

comb_pre = 0:3:24; comb_post = 0:3:24;
comb_win = [comb_pre(:), comb_post(:)];

ExpData = table([], [], [], [], [], [], [], [], [], [], 'VariableNames', ...
    {'Time', 'EIH_Vec', 'Head_Vec', 'EIH_Vel', 'Head_Vel', 'EIH_AzVel',...
    'EIH_ElVel', 'Head_AzVel', 'Head_ElVel', 'Labels'});
ExpData = table2struct(ExpData);

%% Generate standard dataset

SR = 300;

CombLabels = 1;
    
m = 1;
for i = 1:length(D_pd)
    str_pd = fullfile(D_pd(i).folder, D_pd(i).name);
    data = sscanf(D_pd(i).name, 'PrIdx_%d_TrIdx_%d.mat');
    PrIdx = data(1); TrIdx = data(2);
    str_ld = fullfile(Path2LabelData, sprintf('PrIdx_%d_TrIdx_%d_Lbr_*.mat', PrIdx, TrIdx));
    D_ld = dir(str_ld);
    
    if ~ismember(PrIdx, [1, 2, 3, 8, 9, 12, 16, 17, 22])
        fprintf('Skipping Pr: %d\n', PrIdx)
        continue
    end

    Age = ParticipantInfo(PrIdx).Age;

    % Load ProcessData into work directory
    dataStr = load(str_pd, 'ProcessData');
    ProcessData = dataStr.ProcessData;

    if size(D_ld, 1) >= 1

        % Labels exist for this ProcessData mat file
        for j = 1:length(D_ld)
            dataStr = load(fullfile(D_ld(j).folder, D_ld(j).name), 'LabelData');
            LabelData = dataStr.LabelData;
            data = sscanf(D_ld(j).name, 'PrIdx_%d_TrIdx_%d_Lbr_%d.mat');

            if length(LabelData.T) ~= length(ProcessData.T)
                disp("Sampling rate mismatch detected.")
                disp("Assumings labels are lined up correctly")
                LabelData.T = ProcessData.T;
            end

            T = linspace(min(ProcessData.T), max(ProcessData.T), SR*(max(ProcessData.T) - min(ProcessData.T)));
            T = T(:);

            Labels = GenerateLabelsfromStruct(LabelData);
            Labels = fillGap(Labels, 5);
            ExpData(m).Time = T;
            ExpData(m).EIH_Vec = interp1(ProcessData.T, ProcessData.ETG.EIHvector, T, 'spline');
            ExpData(m).Head_Vec = interp1(ProcessData.T, ProcessData.IMU.HeadVector, T, 'spline');
            ExpData(m).EIH_Vel = interp1(ProcessData.T, ProcessData.ETG.EIH_vel(:), T, 'spline');
            ExpData(m).Head_Vel = interp1(ProcessData.T, ProcessData.IMU.Head_Vel(:), T, 'spline');
            ExpData(m).EIH_AzVel = interp1(ProcessData.T, ProcessData.ETG.Az_Vel(:), T, 'spline');
            ExpData(m).EIH_ElVel = interp1(ProcessData.T, ProcessData.ETG.El_Vel(:), T, 'spline');
            ExpData(m).Head_AzVel = interp1(ProcessData.T, ProcessData.IMU.Az_Vel(:), T, 'spline');
            ExpData(m).Head_ElVel = interp1(ProcessData.T, ProcessData.IMU.El_Vel(:), T, 'spline');
            ExpData(m).Conf = interp1(ProcessData.T, ProcessData.ETG.Confidence(:), T, 'spline');
            ExpData(m).Labels = fillGap(interp1(ProcessData.T, Labels(:), T, 'nearest'), 10);
            
            Identity_Info(m, :) = data(:)';
            
            ExpData(m).Conf(ExpData(m).Conf < 0) = 0; ExpData(m).Conf(ExpData(m).Conf > 1) = 1;
                
            %% For Diagnositcs
%             figure;
%             ax = subplot(1, 1, 1);
%             plot(ExpData(m).Time, ExpData(m).EIH_Vel)
%             DrawPatches(ax, LabelData.LabelStruct, 500)
            %%
            m = m + 1;
        end
    else
       % Labels do not exist
       disp(['No labels for Person: ', num2str(PrIdx), ' Trial: ', num2str(TrIdx)])
    end
end
ExpData = orderfields(ExpData, {'Time', 'EIH_Vec', 'Head_Vec', ...
    'EIH_Vel', 'Head_Vel', 'EIH_AzVel', ...
    'EIH_ElVel', 'Head_AzVel' ,'Head_ElVel', ...
    'Conf', 'Labels'});
    %% Generate max label and weights

for p = 1:size(comb_win, 1)
    
    TrainData = {[]};
    Targets = {[]};
    ID = [];
    Weights = {[]};
    
    preWin = comb_win(p, 1);
    postWin = comb_win(p, 2);
    
    PrPresent = unique(Identity_Info(:, 1));
    
    o = 1;
    for i = 1:length(PrPresent)
        loc = Identity_Info(:, 1) == PrPresent(i);
        TrPresent = unique(Identity_Info(loc, 2));
        
        for j = 1:length(TrPresent)
            
            loc2 = loc & (Identity_Info(:, 2) == TrPresent(j));
            LbrPresent = unique(Identity_Info(loc2, 3));
            
            if sum(loc2) > 1 && sum(LbrPresent) > 1
                % Multiple labels
                Data_PrTrLbr = struct2table(ExpData(loc2));

                if CombLabels
                    % While combining labels, the weights should be also be
                    % scaled with the confidence.
                    
                    % Final update: Removing weight scaling with
                    % confidence. Weight should be the agreement ratio
                    % between labellers. This is the simplest way to ensure
                    % human data is treated fairly.
                    
                    [Labels, weights] = CombineLabels(cell2mat(Data_PrTrLbr.Labels'), 2);
                    Data_PrTrLbr = table2array(Data_PrTrLbr(1, :)); % Since all other entries are the same, ignore them.
                  
                    datamat = [cell2mat(Data_PrTrLbr), Labels(:)];
                    [TrainData_PrTrLbr, Targets_PrTrLbr, W_PrTrLbr] = GenerateDataset_RF(datamat, preWin, postWin, weights, 1);
                else
                    % This function treats the data from each labeller
                    % seperately. This is useful for certain situtations
                    % but should be avoided for ML as it causes
                    % over-representation for a particular subject.
                    TrainData_PrTrLbr = cell(size(Data_PrTrLbr, 1), 1);
                    Targets_PrTrLbr = cell(size(Data_PrTrLbr, 1), 1);
                    W_PrTrLbr = cell(size(Data_PrTrLbr, 1), 1);
                    
                    for g = 1:size(Data_PrTrLbr, 1) % Loop through available labellers
                        datamat = cell2mat(table2array(Data_PrTrLbr(g, :)));
                        Conf = cell2mat(Data_PrTrLbr(g, :).Conf);
                        [TrainData_PrTrLbr{g}, Targets_PrTrLbr{g}, W_PrTrLbr{g}] =...
                            GenerateDataset_RF(datamat, preWin, postWin, Conf, 1);
                    end
                    TrainData_PrTrLbr = cell2mat(TrainData_PrTrLbr);
                    Targets_PrTrLbr = cell2mat(Targets_PrTrLbr);
                    W_PrTrLbr = cell2mat(W_PrTrLbr);
                end
                
                TrainData_PrTrLbr = round(TrainData_PrTrLbr, 2);
                
                TrainData(o, 1) = {TrainData_PrTrLbr};
                Targets(o, 1) = {Targets_PrTrLbr};
                Weights(o, 1) = {W_PrTrLbr};
                
                ID(o, :) = [PrPresent(i), TrPresent(j)];
                o = o + 1; 
            else
                % Only 1 labeller
                Data_PrTrLbr = struct2table(ExpData(loc2));
                Conf = Data_PrTrLbr.Conf;
                datamat = table2array(Data_PrTrLbr);
                [TrainData_PrTrLbr, Targets_PrTrLbr, W_PrTrLbr] = GenerateDataset_RF(datamat, preWin, postWin, Conf, 1);
                
                TrainData_PrTrLbr = round(TrainData_PrTrLbr, 2);

                TrainData(o, 1) = {TrainData_PrTrLbr};
                Targets(o, 1) = {Targets_PrTrLbr};
                Weights(o, 1) = {W_PrTrLbr};
                
                ID(o, :) = [PrPresent(i), TrPresent(j)];
                o = o + 1;
            end
        end
    end
    disp(['Condition done: ', num2str(p)])
    save(sprintf('Data_Windows/Data_%d_%d.mat', preWin, postWin), 'TrainData', 'Targets', 'ID', 'Weights','-v7.3')
end
