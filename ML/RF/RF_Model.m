clear all
close all
clc
%% This file is to train a Random Forest algorithm with boosting.
% Note that the optokinetic fixations are labelled as part of fixations.
% Hence all samples with label 5 are changed to 1.

path2repo = '/home/rsk3900/gaze-in-wild';
addpath(genpath(fullfile(path2repo, 'SupportFunctions')))
format long g

global kappaTalk
kappaTalk = 0;

strictCond = 1;
PrTest_List = [1, 2, 3, 8, 9, 12, 16, 17, 22];

comb_win = 0:3:24;

for PrTest_idx = 1:length(PrTest_List)
    strictCond = 1;
    PrTest = PrTest_List(PrTest_idx);
%     comb_win = Win_List{PrTest_idx};

    fprintf('LO PrIdx: %d\n', PrTest_List(PrTest_idx))
    parfor i = 1:length(comb_win)

        preWin = comb_win(i);
        postWin = comb_win(i);
        str_Data = sprintf('Data_Windows/Data_%d_%d.mat', preWin, postWin);
        load_data = load(str_Data);
        TrainData = load_data.TrainData;
        Targets = load_data.Targets;
        Weights = load_data.Weights;
        ID = load_data.ID;

        PrTr_Present = unique(ID(:, 1:2), 'rows');

        C_stats = confusionmatStats(1, 1);
        C_stats.k = [];

        %% Divide by person and/or trial type
        if strictCond

            loc = PrTr_Present(:, 1) ~= PrTest;

            TrainingData = cell2mat(TrainData(loc));
            TrainingTargets = cell2mat(Targets(loc)); TrainingTargets(TrainingTargets == 5) = 1;
            TestingData = cell2mat(TrainData(~loc)); 
            TestingTargets = cell2mat(Targets(~loc)); TestingTargets(TestingTargets == 5) = 1;

            TrainingWeights = cell2mat(Weights(loc));
            TestingWeights = cell2mat(Weights(~loc));

            %% Weight down duplicate samples for training only

            % The weight of each duplicate sample is the mean of all it's dups.
            % The counts should be used to multiply the weights of each samples
            % so that you can boost their presence during training.
            [TrainingData, TrainingTargets, TrainingWeights, counts] = WeightByFrequency(TrainingData, TrainingTargets, round(TrainingWeights, 3));
            TrainingWeights = TrainingWeights.*counts;

            % DO NOT remove duplicates for testing. This will result in a
            % skewed performance measure.

            %[TestingData, TestingTargets, TestingWeights, counts] = WeightByFrequency(TestingData, TestingTargets, round(TestingWeights, 3));
            %TestingWeights = TestingWeights.*counts;

            %% Remove samples with low weights
            % Samples which are not valid can be removed using a threshold.
            % Remove from testing aswell because it's not appropriate to test
            % the algorithm on poor quality samples.
            WThres = 0.3;

            % Remove training samples with low weight
            loc = TrainingWeights < WThres;
            TrainingData(loc, :) = [];
            TrainingWeights(loc, :) = [];
            TrainingTargets(loc, :) = [];
            fprintf('Removing %f %% of training samples\n', 100*sum(loc)/length(loc))

    %         Remove testing samples with low weight
            loc = TestingWeights < WThres;
            TestingData(loc, :) = [];
            TestingWeights(loc, :) = [];
            TestingTargets(loc, :) = [];
            fprintf('Removing %f %% of testing samples\n', 100*sum(loc)/length(loc))
        else        
        %% Divide by samples
        % This condition should never be reached.
            TrainData = cell2mat(TrainData);
            Targets = cell2mat(Targets); Targets(Targets == 5) = 1;
            Weights = cell2mat(Weights);

            [~, ia] = unique([TrainData, Targets, Weights], 'rows');
            TrainData = TrainData(ia, :);
            Targets = Targets(ia);
            Weights = Weights(ia);

            [trainIdx, validIdx, testIdx] = divideDataset(Targets, 0, 0.3);

            TrainingData = TrainData(trainIdx, :); 
            TrainingTargets = Targets(trainIdx);
            TestingData = TrainData(testIdx, :);
            TestingTargets = Targets(testIdx);

            TrainingWeights = Weights(trainIdx);
        end

        %% Assign cost matrix
        % Cost matrix values to be set such that misclassification of fix is
        % least and pursuit is highest
        CostMat = tabulate(TrainingTargets);
        CostMat = CostMat(:, end); CostMat = 1 - CostMat/sum(CostMat);
        CostMat = diag(CostMat)*ones(length(CostMat));
        CostMat = CostMat - diag(diag(CostMat));

        % Prior -> Equal priors means it's equally likely for a sample to be
        % fixation, saccade or SP.
        PriorVec = [];
        Model = TreeBagger(40, TrainingData, TrainingTargets, 'MinLeafSize', 30,...
            'NumPredictorsToSample', ceil(sqrt(size(TrainingData, 2))), ...
            'W', TrainingWeights, 'OOBPredictorImportance', 'on', ...
            'Prior', 'uniform', 'PruneCriterion', 'error');

        PredImp = Model.OOBPermutedPredictorDeltaMeanMargin;
        Model = compact(Model);

        Y = str2num(cell2mat(predict(Model, TestingData)));
        temp = confusionmatStats(TestingTargets, Y);

        for fn = fieldnames(temp)'
            C_stats.(fn{1}) = temp.(fn{1});
        end
        C_stats.k = kappa(C_stats.confusionMat);

        disp(['Tree Model for window: ', num2str(preWin)])
        disp(['Recall: ', mat2str(C_stats.sensitivity)])
        disp(['Precision: ', mat2str(C_stats.precision)])
        disp(['K: ', num2str(C_stats.k)])
        saveName = sprintf('%s/Tree_Models/Tree_%d_%d_PrTest_%d.mat', pwd, preWin, postWin, PrTest);
        parsave(saveName, 'Model', Model, 'C_stats', C_stats, 'PredImp', PredImp)
    end
    disp(['Finished PrTest: ', num2str(PrTest_List(PrTest_idx))])
end