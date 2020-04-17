function ret = fillGap(cur,thresh)
%% flipGap
% Fill in gaps of size less than threshhold in list. This is done to ensure
% there are is a single point of transition between events.
% Author: Micheal Lipton

startLoc = -1;
endLoc = -1;
for i = 1:numel(cur)
   if cur(i) == 0
       %Assign start locatio if unassigned
       if startLoc == -1
           startLoc = i;
           continue;
       end
   end

   %Start location exists and a non-zero was found
   if startLoc ~= -1 && cur(i) ~= 0
           endLoc = i-1;
           tdiff = endLoc - startLoc+1;
           if tdiff <= thresh
               %Odd differences need to be handles specially
               isOdd = mod(tdiff,2);
               try
                   %Fill left
                   if startLoc == 1
                       % To ensure the code doesn't break, make sure this
                       % section never reaches with startLoc = 1
                       startLoc = 2;
                   end
                   if isOdd
                       %Roll the dice on whether the middle is set to the
                       %left or right value
                       if rand() > .5
                           cur(startLoc+floor(tdiff/2)) = cur(endLoc+1);
                       else
                           cur(startLoc+floor(tdiff/2)) = cur(startLoc-1);
                       end
                   end
                   cur(startLoc:startLoc+floor(tdiff/2)-1) = repmat(cur(startLoc-1),[floor(tdiff/2),1])';
                   %Fill right
                   cur(endLoc - floor(tdiff/2)+1:endLoc) = repmat(cur(endLoc+1),[floor(tdiff/2),1])';
               catch
%                    disp('something went wrong in fillGap function.');
%                    keyboard;
               end
           else
               %Print differences for debugging
               %tdiff
           end
           %Reset locations regardless if fill happened or not
           startLoc = -1;
           endLoc = -1;
   end
end
ret = cur;
end