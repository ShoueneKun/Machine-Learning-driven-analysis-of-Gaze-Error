classdef event_metric_support
    methods(Static)
        %% Items in the event list: 
        % start position, end position, event type, transition type(from
        % previous type to current type), processed or not.
        function event = to_event(LabelStruct)
            labelloc = cell2mat({LabelStruct.LabelLoc}');
            event.startIdx = labelloc(:,1);
            event.endIdx = labelloc(:,2);
            labels = cell2mat({LabelStruct.Label}');
            event.label = labels;
            N = length(labels);
            transType = strings(N,1);
            transType(1) = strcat(num2str(labels(1)),num2str(labels(1)));
            for i=2:N
                transition = strcat(num2str(labels(i-1)),num2str(labels(i)));
                transType(i) = transition;
            end
            event.transType = transType;
            event.handled = false(N,1);
            % convert event struct to dataset datatype for convience
            event = struct2dataset(event);
        end
        %% Loop through each event and find transition points for the start
        % and end points then create tuples to store the matching
        % information: found(0 or 1), offsets (int), index in reference 
        % sequence, trans_type in ref seq, trans_type in test seq 
        function measures = matching(events1,events2,winsize)
            transit_pos1 = events1.startIdx;
            transit_pos2 = events2.startIdx;
            transit_pos2e = events2.endIdx;
            N =length(transit_pos1);
            matching_idx = nan(N,2);
            found = false(N,2);
            shift = nan(N,2);
            tranType1 = events1.transType;
            tranType2 = strings(N,2);
            winsize_s = winsize(1);
            winsize_ns = winsize(2);
            for i=1:N
                if tranType1(i)=='13'||tranType1(i)=='31'||tranType1(i)=='23'||tranType1(i)=='32'||tranType1(i)=='33'
                    winsize = winsize_s; % window size for saccade related transitions
                else 
                    winsize = winsize_ns; % window size for non-saccade related trasitions
                end
                % window boundaries for start and end points 
                lower_s = max(events1.startIdx(i) - fix(winsize/2),1);
                upper_s = min(events1.startIdx(i) + fix(winsize/2), events1.endIdx(N));
                lower_e = max(events1.endIdx(i) - fix(winsize/2),1);
                upper_e = min(events1.endIdx(i) + fix(winsize/2), events1.endIdx(N));
                % find match point for the start of the current event
                for j=1:length(events2)
                    if transit_pos2(j)>=lower_s && transit_pos2(j)<=upper_s
                        % return the first matching transition point for the start found in the window
                        type_s = char(events2.transType(j));               % transition type at start point for testing
                        type_rs = char(tranType1(i));                      % transition type at start point for reference
                        if type_rs(2) == type_s(2)
                            found(i,1) = true;
                            shift(i,1) = transit_pos2(j)-events1.startIdx(i);
                            tranType2(i,1) = events2.transType(j);
                            matching_idx(i,1) = j;
                            break;
                        end
                    end
                end
                % find match point for the end of the current event
                for k=1:length(events2)
                    if transit_pos2e(k)>=lower_e && transit_pos2e(k)<=upper_e
                        type_te = char(events2.transType(k));
                        type_re = char(tranType1(i));
                        if type_re(2) == type_te(2)
                            found(i,2) = true;
                            shift(i,2) = transit_pos2e(k)-events1.endIdx(i);
                            tranType2(i,2) = events2.transType(min(k+1,length(events2)));
                            matching_idx(i,2) = k;
                            break;
                        end
                    end
                end
            end
            measures.found = found(:,1) & found(:,2);        % matching information for each event, match == both start and end match
            measures.founds = found(:,1);                    % matched at start
            measures.founde = found(:,2);                    % matched at end
            measures.shift = shift;
            measures.startIdx = transit_pos1;
            measures.endIdx = events1.endIdx;
            measures.matchingIdx = matching_idx;
            measures.tranType_ref = tranType1;
            measures.tranType_test = tranType2;
            measures = struct2table(measures);

        end
        %% Globally align the two label sequences.
        function [seq_ref,seq_test] = globalAlignment(measure,seq_ref,seq_test)
            N = length(seq_ref);
            shifted = false(N,1);
            for i=1:height(measure)
                % make alignment at start point
                if measure.founds(i) && ~shifted(max(measure.startIdx(i)-1,1))
                    shift = measure.shift(i,1);
                    offset = fix(shift/2);
                    rmd = rem(shift,2);
                    ttr = char(measure.tranType_ref(i));
                    ttt = char(measure.tranType_test(i,1));
                    if shift>0         % ref leading
                        seq_ref(measure.startIdx(i) : measure.startIdx(i)+offset-1) = str2double(ttr(1));
                        seq_test(max(measure.startIdx(i)+shift-offset-rmd,1) : measure.startIdx(i)+shift) = str2double(ttt(2));    
                    elseif shift<0      % ref lagging
                        seq_ref(measure.startIdx(i)+offset:measure.startIdx(i)) = str2double(ttr(2));
                        seq_test(measure.startIdx(i)+shift :measure.startIdx(i)+shift-offset-rmd-1) = str2double(ttt(1));
                    end
                    shifted(measure.startIdx(i)) = true;
                end
                % make alignment at end point
                if measure.founde(i)
                    shift = measure.shift(i,2);
                    offset = fix(shift/2);
                    rmd = rem(shift,2);
                    ttr_s = char(measure.tranType_ref(i));                 % tranType in reference at start
                    ttr_e = char(measure.tranType_ref(min(i+1,height(measure))));        % tranType in reference at end
                    ttt = char(measure.tranType_test(i,2));                % tranType in testing at end
                    if shift>0         % ref leading
                        if shift==1
                            seq_test(max(1,measure.endIdx(i)+1)) = str2double(ttt(2));
                        else
                            seq_ref(measure.endIdx(i) : measure.endIdx(i)+offset-1) = str2double(ttr_s(2));
                            seq_test(max(1,measure.endIdx(i)+shift-offset-rmd) : measure.endIdx(i)+shift) = str2double(ttt(2));
                        end
                    elseif shift<0      % ref lagging
                        seq_ref(max(1,measure.endIdx(i)+offset):measure.endIdx(i)) = str2double(ttr_e(2));
                        seq_test(max(1,measure.endIdx(i)+shift):measure.endIdx(i)+shift-offset-1-rmd) = str2double(ttt(1));
                    end
                    shifted(measure.endIdx(i)) =true;
                end
            end
        end
        %% unlabeled region processing
        function [label_seq1,label_seq2] = fillUnlabeled(label_seq1,label_seq2)
           for i=1:length(label_seq1)
               if label_seq1(i)==0 && label_seq2(i)~=0
                   label_seq1(i) = label_seq2(i);
               elseif label_seq2(i)==0 && label_seq1(i)~=0
                   label_seq2(i) = label_seq1(i);
               end
           end
        end
        %% calculate the distances from the matched transition points %%
        % Matched events means both the start and end
        % point are found in the given window.
        function [scores,num_cor,percent_detach] = process_matched(measure,events_ref,labels_ref,labels_test)
            % scores contains score for each matched event, score(eventIndex,eventType,L2distance,OverlapRatio)
            scores = {};
            % number of correctly classified events in each class
            num_fix = 0;
            num_pur = 0;
            num_sac = 0;
            num_blk = 0;
            num_opk = 0;
            % counter for unmatched events which the labels are same during
            % the reference segment
            fix_detach = 0;
            pur_detach = 0;
            sac_detach = 0;
            for i = 1:height(measure)
                % Add constrain here to make sure the index of the testing
                % matching events are continous (one event in the referenece
                % should match with one event in the testing) or do the
                % calculation from both directins
                if measure.found(i) == 1
                    event_type = char(measure.tranType_ref(i));
                    event_type = str2double(event_type(2));
                    switch event_type
                        case 1
                            num_fix = num_fix+1;
                        case 2
                            num_pur = num_pur+1;
                        case 3
                            num_sac = num_sac+1;
                        case 4
                            num_blk = num_blk+1;
                        case 5
                            num_opk = num_opk+1;
                    end
                    % Timing offsets (shifts) and Overlap Ratio calculation
                    l2_dis = l2dis(measure.shift(i,1),measure.shift(i,2));  
                    upper_tran_ref = events_ref.endIdx(i);                  % end point in reference sequence
                    upper_tran_test = upper_tran_ref + measure.shift(i,2);  % end point in testing sequence
                    lower_tran_test = measure.startIdx(i) + measure.shift(i,1);% start point in reference
                    olr = overlap_ratio(measure.startIdx(i),lower_tran_test,upper_tran_ref,upper_tran_test);
                    score = {i,event_type,l2_dis,olr};                      % first element is index of events in ref
                    scores = [scores;score];
                else
                    start_ = measure.startIdx(i);
                    end_ = measure.endIdx(i);
                    if labels_ref(start_:end_)==labels_test(start_:end_)
                        switch labels_ref(start_)
                            case 1
                                fix_detach = fix_detach+1;
                            case 2
                                pur_detach = pur_detach+1;
                            case 3
                                sac_detach = sac_detach+1;
                        end
                        
                    end
                end
            end
            num_cor = [num_fix,num_pur,num_sac,num_blk,num_opk];            % number of correctly classified
            num_detach = [fix_detach,pur_detach,sac_detach];                % number of unmatched events but same type on sample level
            numF = sum(events_ref.label(:) == 1);
            numP = sum(events_ref.label(:) == 2);
            numS = sum(events_ref.label(:) == 3);
            percent_detach = [num_detach(1)/numF,num_detach(2)/numP,num_detach(3)/numS];
        end

        %% change the label so that direct differencing can be done
        % to report transition types
        function label_changed = changeLabel(label_seq)
            label_changed = label_seq;
           for i=1:length(label_seq)
               if label_seq(i)==4
                   label_changed(i)=10;
               elseif label_seq(i)==3
                   label_changed(i)=100;
               elseif label_seq(i)==2
                   label_changed(i)=1000;
               elseif label_seq(i)==5
                   label_changed(i)=10000;
               end
           end
        end
        %% report events statistics
        function reportEvents(events,person,trial,labeler)
            numU = sum(events.label(:) == 0);   
            numF = sum(events.label(:) == 1);
            numP = sum(events.label(:) == 2);
            numS = sum(events.label(:) == 3);
            numB = sum(events.label(:) == 4);
            numO = sum(events.label(:) == 5);
            fprintf('Reporting on Person %d, Trial %d Labeler %d\n',person,trial,labeler);
            disp(['Number of detected gaze fixtions: ', num2str(numF)]);
            disp(['Number of detected gaze pursuits: ', num2str(numP)]);
            disp(['Number of detected gaze shifts: ', num2str(numS)]);
            disp(['Number of detected blinks: ', num2str(numB)]);
            disp(['Number of detected optokinetic fixtions: ', num2str(numO)]);
            disp(['Number of detected unlabeled events: ', num2str(numU)]);
            disp(['Total number of detected events: ',num2str(numF+numP+numS+numO+numB)]);
        end
        %% calculate the numbers in the confusion matrix
        function conf_table = cal_confmax(seq_ref,seq_test,T,num_cor)
            diff_seq = seq_ref - seq_test;
            label_struct = GenerateLabelStruct(diff_seq,T);
            diff_events = event_metric_support.to_event(label_struct);
            FB = sum(diff_events.label(:) == -9);
            FS = sum(diff_events.label(:) == -99);
            FP = sum(diff_events.label(:) == -999);
            BS = sum(diff_events.label(:) == -90);
            BP = sum(diff_events.label(:) == -990);
            SP = sum(diff_events.label(:) == -900);
            BF = sum(diff_events.label(:) == 9);
            SB = sum(diff_events.label(:) == 90);
            SF = sum(diff_events.label(:) == 99);
            PS = sum(diff_events.label(:) == 900);
            PB = sum(diff_events.label(:) == 990);
            PF = sum(diff_events.label(:) == 999);
            FO = sum(diff_events.label(:) == -9999);
            BO = sum(diff_events.label(:) == -9990);
            SO = sum(diff_events.label(:) == -9900);
            PO = sum(diff_events.label(:) == -9000);
            OF = sum(diff_events.label(:) == 9999);
            OB = sum(diff_events.label(:) == 9990);
            OS = sum(diff_events.label(:) == 9900);
            OP = sum(diff_events.label(:) == 9000);
            num_misclass = FB+FS+FP+FO+BS+BP+BF+BO+SF+SB+SP+SO+PF+PB+PS+PO+OF+OP+OS+OB;
            disp(['Number of events with disagreement: ', num2str(num_misclass)]);
            % add numbers to the matrix 
%             disp('Confusion matrix (Row/Reference, Column/Testing):');
            mat = [num_cor(1) FP FS FB FO;
                   PF num_cor(2) PS PB PO;
                   SF SP num_cor(3) SB SO;
                   BF BP BS num_cor(4) BO;
                   OF OP OS OB num_cor(5)];
            conf_table = array2table(mat,'RowNames',{'F','P','S','B','O'},'VariableNames',{'F','P','S','B','O'});
        end
    end
    %properties
end
