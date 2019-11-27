function [trainData, Targets, Chunks, W] = genSeqSeries(ExpData, W_ip)

%% Ele information
% 1 -> Time
% 2:4 -> EIH_vector
% 5:7 -> Head_vector
% 8:10 -> GIW_vector
% 11 -> EIH velocity
% 12 -> Head velocity
% 13 -> GIW velocity
% 14:15 -> EIH Az & El velocity
% 16:17 -> Head Az & El velocity
% 18:19 -> GIW Az & El velocity
% 20:23 -> Head Pose
% 24 -> Confidence (Weight)
% 25 -> Labels
% Do not use dimension 18 in ExpData. Instead, pass it as an input argument
% because the weights may need to consider multiple labellers.

% Note that all samples with a confidence below 0.1 from Pupil labs are
% removed from training.

featSpace_vec = 2:10;
featSpace_vel = [11, 14:15, 12, 16:17, 13, 18:19];
MaxSeqLen = 1024;
W = W_ip;
labels = fillGap(ExpData(:, 25), 5);

loc = ~(labels == 0 | labels == 4);
[Val, Len, StartEnd_idx] = RunLength(loc);

% Find and remove blinks and unlabelled
loc = Val == 0;
Len(loc) = []; StartEnd_idx(loc, :) = [];
[Len, StartEnd_idx] = breakSequence_overlap(Len, StartEnd_idx, MaxSeqLen);

% Correct Targets
labels = convertLabels(labels(:));
labels_mod = labels;
labels_mod(ExpData(:, 24) < 0.2) = -1;

W_ip(ExpData(:, 24) < 0.2) = 0.00;

% Find all sequences which atleast 20 continuous samples in it
loc = find(Len >= 20);
numSequences = numel(loc);

Chunks  = cell(numSequences, 1);

for i = 1:numSequences
    x = StartEnd_idx(loc(i), 1); y = StartEnd_idx(loc(i), 2);
    if ~prod(labels_mod(x:y) == -1)
        dataBoo = ExpData(x:y, featSpace_vec);
        dataBoo_vel = ExpData(x:y, featSpace_vel);
        if any(abs(dataBoo(:)) > 1 ) || any(isnan(dataBoo(:))) || all(dataBoo(:) == 0)
            lskeyboard
        end
        % Append data to make sure that L + 3 is divisible by 4         
        temp = [dataBoo, dataBoo_vel, W_ip(x:y), labels_mod(x:y)];
        if size(temp, 1) < MaxSeqLen
           temp((1+size(temp, 1)):MaxSeqLen, end) = -1;
        end
        Chunks{i, 1} = temp;
        if any(isnan(Chunks{i, 1}))
            keyboard
        end
    else
        disp('All -1 in this chunk. Remove.')
    end
end
loc = cellfun(@isempty, Chunks);
Chunks(loc) = [];

trainData = ExpData(:, [featSpace_vec, featSpace_vel]);
Targets = labels_mod(:);

function labels = convertLabels(labels)
    % Convert blinks and unlabelled as undefined
    labels(labels == 0 | labels == 4) = -1;
    
    % Convert fixation and Optokinetic fixation as 0
    labels(labels == 1 | labels == 5) = 0; % Optokinetic fix == Gaze fix
    
    % Convert GP as 1
    labels(labels == 2) = 1;
    
    % Convert Saccades as 2
    labels(labels == 3) = 2;