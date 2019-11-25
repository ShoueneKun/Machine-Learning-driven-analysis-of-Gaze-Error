function LabelStruct = RemoveEvents(LabelStruct, ProcessData, isX)
    curThres = 3;
    EventProps = getEventProps(LabelStruct, ProcessData);
    
    % Remove events lesser than curThres samples
    loc = (EventProps.n2 - EventProps.n1) <= curThres;
    LabelStruct(loc) = [];
    
    LabelData.LabelStruct = LabelStruct;
    LabelData.T = ProcessData.T;
    Labels = GenerateLabelsfromStruct(LabelData);
    
    %% Merge fixations
    for i = 1:(length(LabelStruct) - 1)
       
        n1 = LabelStruct(i).LabelLoc(2);
        n2 = LabelStruct(i + 1).LabelLoc(1);
        th = AngleBetweenVectors(ProcessData.ETG.EIHvector(n1, :), ProcessData.ETG.EIHvector(n2, :));
        Dur = ProcessData.T(n2) - ProcessData.T(n1);
       
       if LabelStruct(i).Label == 1 && LabelStruct(i + 1).Label == 1
           % If the current and future labels are fixations, set them up
           % for merging.
           if th < 0.5 || Dur < 150/1000
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
    loc = EventProps.Label == 3 & (EventProps.Dur < 0.006 | EventProps.Dur > 0.150);
    
    %% Delete improbable events
    LabelStruct(loc) = [];
    
    %% Fix Saccades start and ends
    temp = LabelStruct;
    if ~isX
        [LabelStruct, ~] = cleanSaccades(LabelStruct, ProcessData);
    end
    
    EventProps = getEventProps(LabelStruct, ProcessData);
    loc = (EventProps.n2 - EventProps.n1) <= curThres;
    LabelStruct(loc) = [];
end

function [LabelStruct, changeFlag] = cleanSaccades(LabelStruct, ProcessData)
%CLEANSACCADES This function fixes Saccade start and end time by
%compressing or expanding the Saccade. Saccade expansion is part of future
%work as it doesn't immediately affect the dataset.
%   Saccade compression is not by shrinking evenly from each side untill we
%   observe that the total Angular displacement hasn't changed. To ensure
%   nuances from each individual labeller is maintained, we do not change
%   Saccades unless they have a significant reduction.
Thresh = 0.970;
T = ProcessData.T;
changeFlag = zeros(length(LabelStruct), 1);

for k = 1:length(LabelStruct)
   if LabelStruct(k).Label == 3
        %% Shrink Saccades
        n1 = LabelStruct(k).LabelLoc(1); n2 = LabelStruct(k).LabelLoc(2);
        v1 = ProcessData.ETG.EIHvector(n1, :); v2 = ProcessData.ETG.EIHvector(n2, :);
        distSac = AngleBetweenVectors(v1, v2);

        % Shrink front
        movAmt = 1; temp_distSac = distSac;
        while temp_distSac > Thresh*distSac 
            v1 = ProcessData.ETG.EIHvector(n1 + movAmt, :);
            temp_distSac = AngleBetweenVectors(v1, v2);
            movAmt = movAmt + 1;
        end
        if movAmt > 3
            LabelStruct(k).LabelLoc(1) = n1 + movAmt - 1;
            LabelStruct(k-1).LabelLoc(2) = LabelStruct(k-1).LabelLoc(2) + movAmt - 1;
            LabelStruct(k).LabelTime(1) = T(LabelStruct(k).LabelLoc(1));
            LabelStruct(k-1).LabelTime(2) = T(LabelStruct(k-1).LabelLoc(2));
            changeFlag(k) = 1;
        end

        % Shrink back
        v1 = ProcessData.ETG.EIHvector(n1, :); v2 = ProcessData.ETG.EIHvector(n2, :);
        distSac = AngleBetweenVectors(v1, v2);
        
        movAmt = 1; temp_distSac = distSac;
        while temp_distSac > Thresh*distSac
            v2 = ProcessData.ETG.EIHvector(n2 - movAmt, :);
            temp_distSac = AngleBetweenVectors(v1, v2);
            movAmt = movAmt + 1;
        end
        if movAmt > 3
            % Move it only if the amount of shifting is a lot.
            % Otherwise, it's best to maintain the nauances for
            % each labeller. This is like saying, at best, the
            % labellers could be out of phase by 3 samples in one
            % direction. That is, 10 ms.
            LabelStruct(k).LabelLoc(2) = n2 - movAmt + 1;
            LabelStruct(k+1).LabelLoc(1) = LabelStruct(k+1).LabelLoc(1) - movAmt + 1;
            LabelStruct(k).LabelTime(2) = T(LabelStruct(k).LabelLoc(2));
            LabelStruct(k+1).LabelTime(1) = T(LabelStruct(k+1).LabelLoc(1));
            changeFlag(k) = 1;
        end
   end
end
end