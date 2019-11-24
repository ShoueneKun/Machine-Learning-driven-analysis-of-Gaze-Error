%% calculate overlap ratio
function olr = overlap_ratio(l1,l2,u1,u2)
a = sort([l1 l2 u1 u2]);
olr = (a(3)-a(2)+1)/(a(4)-a(1)+1);
end