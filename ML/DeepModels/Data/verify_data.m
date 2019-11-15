clearvars
close all
clc

load('Data.mat')

for i = 1:length(Chunks)
    for j = 1:length(Chunks(i))
        data = Chunks{i}{j};
        if any(isnan(data), 'all') || any(isinf(data), 'all')
            keyboard
        end
    end
end

for i = 1:length(TrainData)
    data = TrainData{i};
    if any(isnan(data), 'all') || any(isinf(data), 'all')
        keyboard
    end
end

for i = 1:length(Targets)
    data = Targets{i};
    if any(isnan(data), 'all') || any(isinf(data), 'all')
        keyboard
    end
end

for i = 1:length(Weights)
    data = Weights{i};
    if any(isnan(data), 'all') || any(isinf(data), 'all')
        keyboard
    end
end