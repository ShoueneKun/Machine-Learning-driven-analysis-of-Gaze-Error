function LabelStruct = RemoveEvents(LabelStruct, ProcessData, isX)
    curThres = 3;
    EventProps = getEventProps(LabelStruct, ProcessData);
    
    % Remove events lesser than curThres samples
    loc = (EventProps.n2 - EventProps.n1) <= curThres;
    LabelStruct(loc) = [];
    
    LabelData.LabelStruct = LabelStruct;
    LabelData.T = ProcessData.T;
    Labels = GenerateLabelsfromStruct(LabelData);
    Labels = fillGap(Labels, curThres); % Fill empty 0s within 3 samples
    
    LabelStruct = GenerateLabelStruct(Labels, ProcessData.T);
    
    %% Merge fixations
    for i = 1:(length(LabelStruct) - 1)
       
        n1 = LabelStruct(i).LabelLoc(2);
        n2 = LabelStruct(i + 1).LabelLoc(1);
        th = AngleBetweenVectors(ProcessData.ETG.EIHvector(n1, :), ProcessData.ETG.EIHvector(n2, :));
        Dur = ProcessData.T(n2) - ProcessData.T(n1);
       
       if LabelStruct(i).Label == 1 && LabelStruct(i + 1).Label == 1
           % If the current and future labels are fixations, set them up
           % for merging.
           if th < 0.5 || Dur < 75/1000
               % If there hasn't been much movement or the duration elapsed
               % between two fixations is lesser than 150 ms, then merge
               % then under one fixation.
               Labels(n1:n2) = 1;
               disp('Merging fixations')
           end
       end
    end
   
    %% Generate a new Label structure
    LabelStruct = GenerateLabelStruct(Labels, ProcessData.T);

    EventProps = getEventProps(LabelStruct, ProcessData);
    %% Saccade cure
    % Remove Saccades which are less than 6 ms in duration or greater than 
    % 150 ms.
    loc1 = EventProps.Label == 3 & (EventProps.Dur < 0.006 | EventProps.Dur > 0.150);
    
    %% Fixation cure
    loc2 = EventProps.Label == 1 & EventProps.Dur < 50/1000;
    
    %% Delete improbable events
    LabelStruct(loc1 | loc2) = [];
    
    %% Fix Saccades start and ends
    if ~isX
        % Note that this process does not apply to the output from
        % classifiers. This process simply improves the Saccade onset and
        % offset locations made by labellers.
        
        % Reason for correction: Due to filtering, Saccade velocity curve
        % tends to flatten out. Certain labellers used that as a metric to
        % mark the onset and offset. However, ideally a labeller should
        % also take into account the angular displacement - which does not
        % happen in a few cases.
        [LabelStruct, ~] = cleanSaccades(LabelStruct, ProcessData);
    end
    
    EventProps = getEventProps(LabelStruct, ProcessData);
    loc = (EventProps.n2 - EventProps.n1) <= curThres;
    LabelStruct(loc) = [];
end