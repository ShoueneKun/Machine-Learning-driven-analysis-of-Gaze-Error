function EventProps = getEventProps(LabelStruct, ProcessData)
%getEventProps finds relevant information per event.
%   Returns important information such as starting and ending gaze vectors,
%   duration, time interval etc.
N = length(LabelStruct);
[Label, t1, t2, n1, n2, Dur] = deal(zeros(N, 1));
[v1, v2] = deal(zeros(N, 3));
for i = 1:N
    try
        Label(i) = LabelStruct(i).Label;
        t1(i) = LabelStruct(i).LabelTime(1); t2(i) = LabelStruct(i).LabelTime(2);
        n1(i) = LabelStruct(i).LabelLoc(1); n2(i) = LabelStruct(i).LabelLoc(2);
        v1(i, :) = ProcessData.ETG.EIHvector(n1(i), :); 
        v2(i, :) = ProcessData.ETG.EIHvector(n2(i), :);
        Dur(i) = t2(i) - t1(i);
    catch
        keyboard
    end
end

EventProps = table(Label, t1, t2, n1, n2, v1, v2, Dur);
end

