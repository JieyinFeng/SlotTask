% reset order    
%  for the run about to be completed, clear out any prior responses and run totals
%  reset total score
function order = resetOrder(order,run_num,trialsPerBlock)
  %runTotals(subject.run_num) = 0; %reset total points in this run
  range=((run_num-1)*trialsPerBlock+1):(run_num*trialsPerBlock);
  order(range,:) = zeros(length(range),size(order,2));
end
