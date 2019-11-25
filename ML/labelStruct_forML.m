clearvars
close all
clc

%%
% WARNING:
% This step is not reversible. Save a backup before proceeding.

%%

Path2Repo = '/home/rakshit/Documents/MATLAB/gaze-in-wild';
txt = fscanf(fopen(fullfile(Path2Repo, 'path.json'), 'rb'), '%s');
path_struct = jsondecode(txt);

global Path2ProcessData Path2LabelData

Path2ProcessData = fullfile(path_struct.path2data, 'ProcessData');
Path2LabelData = fullfile(path_struct.path2data, 'Labels');

D = dir(fullfile(pwd, 'outputs_notest', '*.mat'));
isCleaned = 1;

for i = 1:length(D)
    fprintf('Processing file --> %s \n', D(i).name)
    strFile = fullfile(D(i).folder, D(i).name);
    matfileInfo = who('-file', strFile);
    if ismember('isCleaned', matfileInfo)
        % If the files have been cleaned, do not remove any more events
        disp('File cleaned. Continue.')
       continue 
    else
        % Remove impossible events from the classifier outputs
        load(strFile)
        
        strParse = sscanf(D(i).name, 'PrIdx_%d_TrIdx_%d_Lbr_%d_WinSize_%d');
        PrIdx = strParse(1); TrIdx = strParse(2); X_id = strParse(3); WinSize = strParse(4);
        
        processData_file = fullfile(Path2ProcessData, sprintf('PrIdx_%d_TrIdx_%d.mat', PrIdx, TrIdx));
        load(processData_file)
        
        if length(Y) ~= length(ProcessData.T)
            try
                Y = padarray(Y, length(ProcessData.T) - length(Y), 0, 'post');
            catch
               disp('Test output was kept to be divisble by 4 for compatibility with ML models.')
               disp('Something went wrong.')
            end
        end
        
        LabelStruct = GenerateLabelStruct(Y, 1:length(Y));
        LabelStruct = RemoveEvents(LabelStruct, ProcessData, 1);
        
        LabelData = [];
        LabelData.T = ProcessData.T(:);
        LabelData.LabelStruct = LabelStruct;
        LabelData.Labels = Y;
        LabelData.PrIdx = PrTest;
        LabelData.TrIdx = TrTest;
        LabelData.LbrIdx = X_id;
        LabelData.WinSize = WinSize;
        save(strFile, 'LabelData', 'isCleaned', '-append')
    end
end