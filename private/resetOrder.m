% reset order    
%  for the run about to be completed, clear out any prior responses and run totals
%  reset total score
%
% first column in order is blocknum
function order = resetOrder(order,run_num)
  %runTotals(subject.run_num) = 0; %reset total points in this run
  %range=((run_num-1)*trialsPerBlock+1):(run_num*trialsPerBlock);
  range=find(order(:,1)==run_num)
  order(range,:) = zeros(length(range),size(order,2));
end
