% return matrix experiment
% blocknumber ISI ITI WIN
function [experiment, col2idx ] = genTimingOrder(blocktypes,numtrials,times)

  % function to get the index of a trial component within the experiement matrix
  %i.e. label columns :: translates column name into index
  col2idx = @(name) find(cellfun(@(x) any(strmatch(x,name)),{'Block','Spin','ISI','Result','Receipt','ITI','WIN','Score'}));
  % because winblocks are set in options (getOpts)
  % Score column added later in SlotTask.m via
  %   canreward = cellfun(@(x) strcmp(x,'WINBLOCK'), opts.blocktypes(subject.experiment(:,colIDX('Block') ) ));
  %   subject.experiment(:,colIDX('Score')) = cumsum(subject.experiment(:,colIDX('WIN')) .* canreward');
  %

  numblocks = length(blocktypes);
  totTrial  = numblocks*numtrials;
  blockorder = reshape( repmat(1:numblocks,numtrials,1),totTrial,1);
  experiment = [ blockorder   zeros(totTrial,7)  ];

  experiment(:,col2idx('Spin'))   = times.Spin;
  experiment(:,col2idx('Result')) = times.Result;
  experiment(:,col2idx('Receipt'))= times.Receipt;
 

  %% timing
  % for each ITI and ISI
  for II={'ITI','ISI'}
    II=II{1};
    fprintf('generating %s timing...',II);
    

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% exp
    if(times.(II).dist == 'exp')
      mx=round(times.(II).max/10^3); % eg 2
      mn=round(times.(II).min/10^3); % eg 8

      % get an exp curve and
      % scale so that the min value is 1 
      scale=1/1000;
      % changes number of steps, mu=2 starts at 20 reps, 3 starts at 7 reps
      % lower means fewer number of times
      expmu=3; % will not change actual mu ~4
      x=mn:scale:mx;
      y=exppdf(x,expmu);
      y=round(y.*1/min(y));
      p=1;
      expdistidx=[];
      while(sum(y(expdistidx))<numtrials)
       p=p+1;
       expdistidx=[1 floor(length(x)/p .* colon(1,p)  ) ];
      end



      % we added too many. undo by taking one off from each expdist repeat
      idx=1;
      while(sum(y(expdistidx))>numtrials)
         % if we make it to ones that only have one, dont remove
         if(y(expdistidx(idx))-1>1)
            y(expdistidx(idx)) = y(expdistidx(idx)) - 1;
         end
         idx=idx+1;
         if(idx>length(expdistidx))
          idx=1;
         end
      end

      
      % build repeats
      expdist=[];
      for fi=1:length(expdistidx)
       idx=expdistidx(fi);
       val=x(idx);
       rep=y(idx);
       expdist=[expdist repmat(val,1,rep) ];
      end
      
      hist(expdist)

      % for each block, shuffle the sample
      for bn=1:numblocks
         %% add to the ITI or ISI column in the rows for that block
         b=(bn-1)*numtrials;
         IIidx=col2idx(II);
         range=(1+b):(b+numtrials);
         experiment(range,IIidx) = randsample(expdist,length(expdist)).*10^3;
      end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% uniform
    else
      pop=times.(II).min:50:times.(II).max;
      pop=repmat(pop,1,2); % just incase we only have one value in pop
      for bn=1:numblocks
         %% generate random samples in specified range with desired mean
         x=Inf;
         while( mean(x) ~= times.(II).mean ) 
          x=randsample(pop, numtrials,1);
          
          % make sure we didn't cheat
          if(length(find(x==times.(II).mean))>.3*numtrials && ~all(pop==times.(II).mean))
            %fprintf('  skipping weak randomization\n'); 
            x=Inf;
          end
         end

         %% add to the ITI or ISI column in the rows for that block
         b=(bn-1)*numtrials;
         IIidx=col2idx(II);
         range=(1+b):(b+numtrials);
         experiment(range,IIidx) = x; 
      end      
    end

    fprintf('done\n'); % with this II
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% block numbers
  % assign each trial a block (repeated for number of trials)
  numWin = ceil(.25*totTrial);
  getwindist=@() reshape(Shuffle(repmat([0 0 0 1]',[1,numWin])),1,totTrial);
  win_dist = getwindist();
  
  % cap the number of possible wins, resample until we get what we want
  % ... the way this is setup, it should be impossible to do more than 2 wins in a row
  % ... and more than 6 loses in a row
  % so below while loop should never be entered
  maxRepeatWin  = 3;
  maxRepeatLose = 6;
  fprintf('gen win dist...')
  [vals,lens ] = RunLength(win_dist);
  while(max(lens(vals==1)) > maxRepeatWin || ...
        max(lens(vals==0)) > maxRepeatLose )
    
      [ max(lens(vals==1)) ...
        max(lens(vals==0)) ]
      win_dist = getwindist();
      [vals,lens ] = RunLength(win_dist);
  end
  fprintf('done\n');
  
  experiment(:,col2idx('WIN')) = win_dist;
  
  % write out total score
  %canreward = cellfun(@(x) strcmp(x,'WIN'), opts.blocktypes(experiment(1,:)));
  %experiment(:,5) = cumsum(win_dist * canreward);
  

  

end
