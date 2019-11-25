function Dataset = ReadDataset(str, SR)
global Path2ProcessData Path2LabelData

ParticipantInfo = GetParticipantInfo();
loc = cellfun(@isempty, {ParticipantInfo.Name});
ParticipantInfo(loc) = [];
% loc = ismember({ParticipantInfo.Name}, {'Asher', 'Brendan', 'Natalie', 'Laikan', 'Colleen'});
% ParticipantInfo(loc) = [];
D_pd = dir(fullfile(Path2ProcessData, 'PrIdx_*_TrIdx_*.mat'));

Dataset = struct('PrIdx', [], 'TrIdx', [], 'LbrIdx', [], 'Data', []);

m = 1;

for i = 1:length(D_pd)
    str_pd = fullfile(D_pd(i).folder, D_pd(i).name);
    data = sscanf(D_pd(i).name, 'PrIdx_%d_TrIdx_%d.mat');
    PrIdx = data(1); TrIdx = data(2);
    str_ld = fullfile(Path2LabelData, sprintf('PrIdx_%d_TrIdx_%d_Lbr_*.mat', PrIdx, TrIdx));
    D_ld = dir(str_ld);
    
    Age = ParticipantInfo(PrIdx).Age;
    
    % Load ProcessData into work directory
    load(str_pd, 'ProcessData')
    
    if size(D_ld, 1) >= 1
       % Labels exist for this ProcessData mat file
        for j = 1:length(D_ld)
            load(fullfile(D_ld(j).folder, D_ld(j).name), 'LabelData')
            
            data = sscanf(D_ld(j).name, 'PrIdx_%d_TrIdx_%d_Lbr_%d.mat');
            
            temp = GatherData(ProcessData, LabelData, str, SR);
            if ~isempty(temp)
                Dataset(m).PrIdx = PrIdx;
                Dataset(m).TrIdx = TrIdx;
                Dataset(m).LbrIdx = data(3);
                Dataset(m).Age = Age;
                Dataset(m).Data = temp;
                m = m + 1;
            else
                disp(['Data of type not present in PrIdx: ', num2str(PrIdx),...
                    ', TrIdx: ', num2str(TrIdx), ', Lbr: ', num2str(data(3))])
            end
        end
    else
       % Labels do not exist
       disp(['No labels for Person: ', num2str(PrIdx), ' Trial: ', num2str(TrIdx)])
    end
end
Dataset = struct2table(Dataset);
end
