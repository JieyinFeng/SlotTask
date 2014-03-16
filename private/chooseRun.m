function [desiredBlock, varargout ]=chooseRun(desiredBlock,blocklist,trialblock)
  % desiredBlock is the block to run
  % blocklist is a vector of completed trials in each block (expect like [trialsPerBlock, 0, 0, 0 ... ]
  % trialblock is list of each trials block number (used to contruct blk lenghts)

  % total number of blocks
  totblocks = length(blocklist);

  % col vect (size of # of blocks) of expected trial lengths
  % derived from the repeats in trialblock (block # per trail, from experiment column one)
  blklens=diff([ 0 find(diff(trialblock))' length(trialblock) ]);

  % if we ask for a second output, give the trial number (designed for incomplete runs)
  % by default, we want to start at trial 1
  if length(nargout) > 0; varargout{1} = 1; end
  

  % if we've just been pushing up and enter
  % make sure we know all are complete
  iscomplete=length(find(blocklist==blklens))==totblocks;
  if(iscomplete)
      fprintf('** ALL BLOCKS ARE COMPLETE!\n');
  end

  % ask if we are sure about reruning
  if(blocklist(desiredBlock) == blklens(desiredBlock) )
     redoRun=[];
     while isempty(redoRun)
         redoRun = input(['do you want to redo the FINISHED block #', num2str(desiredBlock), ' ? (y or n) '],'s');
         if ~(strcmpi(redoRun, 'y') || strcmpi(redoRun, 'n')  )
             redoRun=[];
         elseif(iscomplete && strcmpi(redoRun,'n'))
           desiredBlock = 0;
           return
           %error('no more blocks/runs -- experiment is complete!')
         end
     end
     % clear this so it passes other tests
     if(strcmpi(redoRun,'y'))
      blocklist(desiredBlock)=0;
     end
  end
  desiredBlockComplete = blocklist(desiredBlock) == blklens(desiredBlock);
  % increment desired block until we find one that's incomplete or we hit the end
  while desiredBlock < totblocks && desiredBlockComplete
    desiredBlock=desiredBlock+1;
  end

  % if block has 0 trials in blocklist, run it
  if blocklist(desiredBlock)==0
    return
  end

  % if block is full but next one is empty -- just go to the next one
  if desiredBlock<totblocks &&  desiredBlockComplete && blocklist(desiredBlock+1) == 0
   fprintf('you asked to run block %d but it''s already done\nmoving to %d which has not been attempted yet\n',desiredBlock,desiredBlock+1)
   desiredBlock=desiredBlock+1;
   return
  end

  %% something has gone wrong. For some reason one or more blocks are incomplete

  % show the situation
  %fprintf('%d is incomplete (%d/%d)\n', desiredBlock, blocklist(desiredBlock),trialsPerBlock)
  incomplete=find(blocklist~=blklens);
  for incidx=incomplete
    fprintf('%d: %d/%d\n',incidx, blocklist(incidx),blklens(incidx))
  end

  % ask what to do
  redoRun=[];
  while isempty(redoRun)
      redoRun = input(['Do you want to redo run ', num2str(desiredBlock), ' ? (y or n) '],'s');
      if ~(strcmpi(redoRun, 'y') || strcmpi(redoRun, 'n')  || ( strcmpi(redoRun, 'continue') && length(nargout)>0 )  )
          redoRun=[];
      end
  end

  % if we are redoing the run we are all done
  % otherwise we need to ask what run to do
  
  if strcmpi(redoRun, 'n')
     chooseRun = input(['Specify the run to be completed (1 - ', num2str(totblocks), ') '], 's');
     if str2double(chooseRun) > totblocks || str2double(chooseRun) < 1
         error(['Must specify run 1 - ', num2str(totblocks)]);
     end
     desiredBlock = str2double(chooseRun);
  end

  if strcmpi(redoRun,'continue') && length(nargout) > 0
    if blocklist(desiredBlock) == 0, blocklist(desiredBlock)=1; end
    varargout{1} = blocklist(desiredBlock)
  end
  
end
