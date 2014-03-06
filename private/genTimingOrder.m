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
      %blocksize=3 %discritize samples
      mx=round(times.(II).max/10^3); % eg 2
      mn=round(times.(II).min/10^3); % eg 8
      %x=mn:(mx-mn)/numtrials:mx;     % 2 to 8 in 108 peices
      % go from vect 1:numtrials to mn:mx
      % written as function because getting wierd vector length
      xeq= @(x) (mx-mn)/(numtrials-1) .* ( x - 1 ) + mn;
      x=xeq(1:numtrials)
      y=exppdf(x,3);
      
      freq=length(y)/sum(y)*y;

      usefreq=round(sum(reshape(freq,3,length(y)/3)',2));
      % compansate for rounding errors
      ii=1;
      while(sum(usefreq)<numtrials)
         usefreq(ii)=usefreq(ii)+1;
        ii=ii+1;
      end

      samplemat=reshape(x,3,length(x)/3)';
      samples=mean(samplemat,2);
      % repeat samples from each block length
      % as many times as the (exp dist derived) frequency calls for
      % -- should end up with 108 length expdist
      expdist=[];
      for fi=1:length(usefreq)
        f=usefreq(fi);
        %expdist = [ expdist, RandSample(samplemat(fi,:),[1 f]) ];
        expdist = [ expdist, repmat(samples(fi),1,f) ];
      end

      % debug
      subplot(1,2,1)
       plot(x,y); hold on;
       scatter(expdist, ones(1,numtrials).*.05,'jitter','on','jitterAmount',.05)
      subplot(1,2,2)
       hist(expdist)

      % for each block, shuffle the sample
      for bn=1:numblocks
         %% add to the ITI or ISI column in the rows for that block
         b=(bn-1)*numtrials;
         IIidx=col2idx(II);
         range=(1+b):(b+numtrials);
         experiment(range,IIidx) = randsamp(expdist,length(expdist)).*10^3;
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
