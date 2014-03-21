function stimtimes = resetStimtimes( idxs, stimtimes )
%RESETSTIMTIMES clear stimtimes for a block/run
%   clear values for all stimtimes fields within a range of trials
 if(isempty(idxs))
     warning('not resetting any stimes')
    return
 end

  for name=fieldnames(stimtimes)'
      for i = idxs'; 
          stimtimes(i).(name{1})={};
      end;
  end
end

