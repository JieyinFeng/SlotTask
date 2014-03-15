% Slot Task:
%  1. show "SELECT FRUIT" slot machine that has 4 choices
%  2. take choice input from button box
%     NO LONGER 2.1 show warning if same choice is made twice, go back to 1 (500ms)
%  4. Show "spin" slot machine for 500ms
%  5. show results slot machine for 1000ms
%  WIN BLOCK
%    5.1 plays cha-ching and show "WIN" slot machine 1/4 of time
%    5.2 no noise and "NO WIN" slot machine 3/4 of time
%  NOREWARD
%    5.1 play "click" and show "|||||" slot machine 1/4 of the time
%    5.2 no noise and show "XXXXXX" slot machine 3/4 of the time
% 6. show total score for 1 second (+1 for every win, always 0 for no NOREWARD) 
%
%
%  Based on description in  
%  "Lateralization and gender differences in the dopaminergic response 
%                to unpredictable reward in the human ventral striatum"
%
%  Chantal Martin-Soelch, Joanna Szczepanik,
%    Allison Nugent, Krystle Barhaghi, Denise Rallis, Peter Herscovitch,
%    Richard E. Carson  and Wayne C. Drevets 
%
%			http://onlinelibrary.wiley.com/doi/10.1111/j.1460-9568.2011.07642.x/full
%  usage:
%    http://arnold/dokuwiki/doku.php?id=howto:experiments:slottask
%
% TODO/DONE
%  [x] write task skeleton
%  [x] insert pictures
%     [ ] are alarm and money okay?
%  [ ] establish scoring (how to do 1/4 breakdown)
%  [ ] fix instructions
%  [ ] What information needs to be saved?
%  [ ] buffers two sounds
%  [ ] add warning to chooseFruit if participant takes too long
%
% 20131024 - WF
%  - start coding, copy of CogEmoFaceReward  
%  - have slot pictures
% 20130216 - WF
%  - use private functions from MEGClockTask
% 20130219 - WF
%  - use waittilltime/waittill to get percision timing on flips

%% SlotTask
function SlotTask(sid,blk,varargin)
  clear -GLOBAL opts subject;
  global opts subject;
  subject.subj_id=sid;
  subject.run_num=blk;
  
  % defines opts structure     
  % sets screen resolution
  % and some debug options
  opts=getopts(varargin); 
  
  

  %% start recording data
  % sets txtfid, subject.*, start, etc 
  subject=getSubjInfo('SlotPETMRI',subject,opts,blk);
  % give a sorter name to the col2idx function
  colIDX=subject.expercol2idx;
  start=(subject.run_num-1)*opts.trialsPerBlock +1;
  
  % log all output of matlab
  diaryfile = fullfile('logs/', [num2str(subject.subj_id) '_' num2str(GetSecs()) '_tcdiary.log']);
  diary(diaryfile);

  % save mat output to a textfile too
  fprintf('saving to %s\n', subject.txtfile);
  txtfid      =fopen(subject.txtfile,'a'); % append so we only have one text file but all blocks

  % tabulate total score for each trial
  canreward = cellfun(@(x) strcmp(x,'WINBLOCK'), opts.blocktypes(subject.experiment(:,colIDX('Block') ) ));

  disp([ length(canreward) ...
  length(subject.experiment(:,colIDX('WIN')) ])

  subject.experiment(:,colIDX('Score')) = cumsum(subject.experiment(:,colIDX('WIN')) .* canreward');


  %% launch presentation   
  try
  
     %% setup screen
     % Removes the blue screen flash and minimize extraneous warnings.
     % http://psychtoolbox.org/FaqWarningPrefs
     if (~opts.DEBUG)
       %Screen('Preference', 'SuppressAllWarnings', 1);
  	   Screen('Preference', 'Verbosity', 2); % remove cli startup message 
       Screen('Preference', 'VisualDebugLevel', 3); % remove  visual logo
     end
     
     %backgroundcolor=[ 204 204 204];
     backgroundcolor=[ 256 256 256];
     % Find out how many screens and use smallset screen number
     % Open a new window.
     [ w, windowRect ] = Screen('OpenWindow', max(Screen('Screens')),backgroundcolor, [0 0 opts.screen] );
     
     % screen info
     FlipInterval = Screen('GetFlipInterval',w); %monitor refresh rate.
     slack = FlipInterval/2; %used for minimizing accumulation of lags due to vertical refresh
      
     %permit transparency
     Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
     
     % Set text display options. We skip on Linux.
     %if ~IsLinux
         Screen('TextFont', w, 'Arial');
         Screen('TextSize', w, 22);
     %end
  
     % Set colors.
     black = BlackIndex(w);
     %white = WhiteIndex(w);
     
     % Enable unified mode of KbName, so KbName accepts identical key names on
     % all operating systems:
     KbName('UnifyKeyNames');

     % Set keys.
     %spaceKey  = KbName('SPACE');
     % escKey  = KbName('ESCAPE');
     
     % RA can push space, subject can push button box
     acceptableKeyPresses = [ KbName('space') KbName('1!') KbName('2@') KbName('3#') KbName('4$') ];

     
    
     %% preload textures
     % grab file (assumed to exist), read iamge, add alpha information
     % save in slotimg struct
     % e.g. slotimg.CHOOSE='slotimgs/CHOOSE.png'
     for slotimgnames={'CHOOSE','BLUR','WIN','NOWIN','XXX','HASH','EMPTY'}
        stimfilename=strcat('imgs/',slotimgnames{1},'.png');
        [imdata, colormap, alpha]=imread(stimfilename);
        imdata(:, :, 4) = alpha(:, :); 
        slotimg.(slotimgnames{1}) = Screen('MakeTexture', w, imdata);
     end


     %% setup sound -- default to no sounds
     if(opts.sound)
         % http://docs.psychtoolbox.org/PsychPortAudio
         % http://wiki.stdout.org/matlabcookbook/Presenting%20auditory%20stimuli/Playing%20sounds/

         %InitializePsychSound;
         [wavedata, sndFreq] = audioread('snd/incorrect.wav');
         wavedata=wavedata';
         nrchannels = size(wavedata,1);
         % 2nd to last arg should be sndFreq, but portaudio returns error w/it
         %todo fix sounds
         pahandle= PsychPortAudio('Open', [], [], [], [], nrchannels);
         PsychPortAudio('FillBuffer',pahandle,wavedata);
     end
     
     

     %% Instructions     
     Instructions = { ...
        [ 'You will see a slot machine\n' ...
          'Push any button to pull the lever\n'...
          'If you choose correctly, you will win that round\n'...
        ], ...
        [ 'Correct answers are entirely random\n'...
          'There is no pattern\n' ...
          'You need to chose a different button than last time' ...
        ], ...
      }; 
     InstructionsBetween = 'Choose a fruit';
   
     % is the first time loading?
     % we know this by where we are set to start (!=1 if loaded from mat)
     if start==1  
         % show long instructions for first time player
         for instnum = 1:length(Instructions)
             DrawFormattedText(w, Instructions{instnum},'center','center',black);
             Screen('Flip', w);
             waitForResponse;
         end

     
     % subjects know the drill. Give them brief instructions
     % order is already init. and loaded from mat, so don't work about it
     else
         DrawFormattedText(w, ['Welcome Back!\n\n' InstructionsBetween],'center','center',black);
         Screen('Flip', w);
         waitForResponse;
     end
     
     %% wait for scanner start
     DrawFormattedText(w, '^Get Ready^','center','center',black);
     Screen('Flip', w);

     % start when we get ^ for scanner
     StartOfRunTime = waitForResponse('6^');
     
  
   
     
     %% THE BIG LOOP -- block design do for about 24 minutes
     startTrial = (subject.run_num-1)*opts.trialsPerBlock + 1;
     endTrial   = subject.run_num*opts.trialsPerBlock;
     subject.blockTrial(subject.run_num) = 0; %reset block trial
     
     %waittilltime=0;
     
     for trialnum=startTrial:endTrial
        subject.trialnum= trialnum;
        trialpart=1; % for each event (part) we record timing

        %% compute all waittills based on current time
        % todo use
        waittill.start       = 0;
        if(trialnum ~= startTrial)
            % get onset of ITI by inspecting the timing structure
            ITItrialnum = length(subject.timing(1,:,1) ); % last one, 5 or 6
            expectedITIOnset = subject.timing(trialnum-1,ITItrialnum,1);
            % get duration from experiment
            ITIduration = subject.experiment(trialnum-1,colIDX('ITI'))/10^3;

            waittill.start   = expectedITIOnset + ITIduration;
        else
            ITIduration =0;
            waittill.start   = StartOfRunTime;
        end
        
        fprintf('waiting %f to next trial start \nat\t%f\nnow\t%f\n',ITIduration,waittill.start,GetSecs() );


        %% 1. Start the trial (display the slot machine)
        Screen('DrawTexture', w,  slotimg.CHOOSE);
        trialStartTime = Screen('Flip', w, waittill.start-slack);
        
        subject.timing(trialnum,trialpart,:)= [ waittill.start; trialStartTime ];
        trialpart=trialpart+1;
        %waittilltime=trialStartTime;
        
        timing.start=trialStartTime-StartOfRunTime;        
        
        
        %% 2. choose a fruit -- get RT
        % get prevchoice so we can make sure we choose differently
        if(trialnum>1), prevchoice=subject.order(trialnum-1,4);
        else            prevchoice=0; end
        
        % get choice, must be different than previous
        response=prevchoice;
        numattempts=0;
        while(response==prevchoice)
         % todo?? capture original response time
         % this only queries for response, w is passed to draw warning (not
         % impletmeneteD)
         [rspnstime, response] = chooseFruit(trialStartTime,numattempts,w,acceptableKeyPresses);
         %WaitSec(.0001) % so we dont go endlessly thorugh the loop
         numattempts=numattempts+1;
        end
        

      
        %% --. compute timing for the rest of the trial
        % response time just happpend, so now we can set the timing for the
        % rest of the trial
        
        
        %% 3. SHOW SPIN (AKA ISI)
        waittill.spinOnset   = waittill.start        +  rspnstime/10^3;
        
        Screen('DrawTexture', w,  slotimg.BLUR); 
        spinOnset = Screen('Flip', w, waittill.spinOnset -slack);
        
        %update timing
        subject.timing(trialnum,trialpart,:)= [ waittill.spinOnset; spinOnset ];
        trialpart=trialpart+1;
        
        % want NO delay between response time and spinner
        % add RT to starttime
        % then calculate the display time of all other events durning this trial
        % see priveate/getTimingOrder.m
        %
        %'Block','Spin','Result','ITI','WIN'
        waittill.resultOnset = waittill.spinOnset    + subject.experiment(trialnum,colIDX('Spin'));
        waittill.itiOnset    = waittill.itiOnset    + subject.experiment(trialnum,colIDX('Result'));
        
         
        % if this is not a catch trial, 
        % -- we will have stim lengths Result + Receipt > 0
        if( subject.experiment(trialnum,colIDX('Result')) >0)

           
           %% 4. SHOW RESULTS (maybe play a sound)
           % get what image should be shown for this trialnum
           imgtype = scoreTrial(  subject.experiment( trialnum, colIDX('WIN') )  );
           Screen('DrawTexture', w,  slotimg.(imgtype)  ); 
           resultsOnset=Screen('Flip', w,waittill.resultOnset -slack);
           
           subject.timing(trialnum,trialpart,:)= [ waittill.resultOnset; resultsOnset ];
           trialpart=trialpart+1;
           
        end

        %% 5. ITI
        % uncomment to see fixation -- never seen anyway!
        itiOnset = fixation(w,waittill.itiOnset-slack);
        subject.timing(trialnum,trialpart,:)= [ waittill.itiOnset; itiOnset ];
        

        %% TRIALs ENDED -- record everything
        %TODO!! What should be recorded
        % wrap up: show/save info
        % trialnum\tstartime\tresponse\ trialscore total
        numresponse = find(response(acceptableKeyPresses))-1;
        
        %           blocknum    trialnum  startime response responsetime trialscore total
        trialinfo = [ subject.experiment(trialnum,1) trialnum trialStartTime rspnstime numresponse subject.experiment(trialnum,[colIDX('WIN'),colIDX('Score')]) ];
        subject.order(trialnum,:) = trialinfo;

        % update trial in block
        subject.blockTrial(subject.run_num) = subject.blockTrial(subject.run_num) + 1;

        % print header
        if trialnum == 1
            fprintf(txtfid,'blocknum\ttrialnum\tstartime\tresponse\tresponsetime\ttrialscore\ttotal\n');
        end
        

        %% save output to text
        fprintf(txtfid,'%i\t',   subject.order(trialnum,1) );
        fprintf(txtfid,'%i\t',   subject.order(trialnum,2) );
        fprintf(txtfid,'%.03f\t',subject.order(trialnum,3:4) );
        fprintf(txtfid,'%d\t',   subject.order(trialnum,5:6) );
        fprintf(txtfid,'%d',     subject.order(trialnum,7) );
        fprintf(txtfid, '\n');
        
        %% save to mat 
        save(subject.matfile,'trialnum','subject');
        
        %% print timing
        % timing:  (trial,event,[ideal actual])
        timemat = reshape(subject.timing(trialnum,:,:),[6,2]);
        if(trialnum==startTrial)
            prevousend=subject.timing(trialnum,1,1);
        else
            prevousend=subject.timing((trialnum-1),6,1) + subject.experiment(trialnum-1,colIDX('ITI'))/10^3;
        end
        
        todisp= timemat - prevousend;
        todisp = [ todisp todisp(:,2)-todisp(:,1) ];
        eventid = {'start','pull','isi','result','recpt','iti'};
        fprintf(' onset\tideal  \tactual  \tdiff\n')
        for dispidx=1:6
          fprintf(' %s\t%.4f\t%.4f\t%.4f\n',eventid{dispidx},todisp(dispidx,:) )
        end
        
        
        
        
        %% debug, show time of this trial
        if(opts.DEBUG)        
          timing.end= GetSecs() - trialStartTime;
          fprintf('%d: (%f,%f) %f\n',trialnum, timing.start, timing.end,timing.end-timing.start);
        end

     end 


    msgAndCloseEverything(['You''ve finished this block!\nTotal score is ', num2str(subject.experiment(trialnum,colIDX('Score'))) ,' points\n\nThanks for playing!']);
    return

  catch
     Screen('CloseAll');
     psychrethrow(psychlasterror);
  end
  
  % close the screen
  sca

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           support functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [rsptimeMS, keyCode ]=chooseFruit(starttime,numattempts,w,keys)
        % display screen
        if(numattempts>0)
            % draw warning
            fprintf('this is the %d attempt\n',numattempts);
        end
        %%draw 
        while(1)
            % check for escape's
            [ keyIsDown, seconds, keyCode ] = KbCheck;

            if keyIsDown
                if(keyCode(KbName('ESCAPE'))); 
                    msgAndCloseEverything('Early Quit!');
                    error('quit early\n');
                    %msgAndCloseEverything(['Quit on trial ' num2str(trialnum)]);
                    %error('quit early (on %d)\n',trialnum)
                elseif any(keyCode(keys))
                    break
                end
            end     
            
            % TODO:
            % flash warning if response takes too long
            
        end
        
        rsptimeMS =  (seconds - starttime)*10^-3;
    end

    %% display fication cross
    % return when fixation corss was displayed
    % made into a function incase it gets fancier
    function onset = fixation(w,waittilltime)
        %DrawFormattedText(w, '+','center','center',black);
        Screen('DrawTexture', w,  slotimg.EMPTY ); 
        onset= Screen('Flip', w, waittilltime);
    end
  
    function msgAndCloseEverything(message)
       Priority(0); % set priority to normal 
       % send last message
       DrawFormattedText(w, message,...
           'center','center',black);
       fprintf('%s\n',message)
       Screen('Flip', w);
       waitForResponse('space','escok');
       closeEverything()
    end
    function closeEverything()
       % close all files
       diary off;	      %stop diary
       fclose('all');	  %close data file
       Screen('Close');   % kill screen
       Screen('CloseAll');% all of them
       
       ShowCursor;    % Retrun cursor
       %ListenChar(0); % take keyboard input

       sca;           % be sure screen is gone
       
       
       % turn off sound
       if(opts.sound)
         PsychPortAudio('Close');
       end
       
       if(subject.trialnum<subject.run_num*opts.trialsPerBlock)
        error('quit early (on %d/%d)\n',subject.trialnum,subject.run_num*opts.trialsPerBlock)
       end
       
       return
    end
  


   %% wait for a response
   %% wait for a response
    function seconds = waitForResponse(varargin)
      %% sometimes we only want a specfic set of keys
      if(~isempty(varargin))
           usekeys=KbName(varargin{1});
           % add escape to use keys if we say esc is okay
           if(length(varargin)>1 && strcmp(varargin{2},'escok'))
               usekeys=[usekeys KbName('ESCAPE')];
               WaitSecs(.2); % just so we don't esc all the way through
           end
      else
           usekeys=acceptableKeyPresses;

      end
      
      while(1)
          [ keyIsDown, seconds, keyCode ] = KbCheck;
          
          if(keyIsDown)
              if(any(keyCode(usekeys))) 
                  break;
              elseif(keyCode(KbName('ESCAPE')) ); 
                  msgAndCloseEverything(['Quit on trial ' num2str(subject.trialnum)]);
                  error('quit early (on %d)\n',subject.trialnum)
              %else, we don't care--keep looping
              end
          end
          
          WaitSecs(.001);
      end
      Screen('Flip', w); % change the screen so we don't hold down space
      WaitSecs(.2);
    end


   %% score: 1/4 of the time correct
   function imgtype=scoreTrial(win)
      % win is 0 or 1
      %% score is predetermined
      %% we return one of 4 different images
      imgtypes={'NOWIN','WIN','XXX','HASH'};
      % depends on blocktype and win/lose status
      % 1 NOWIN,  2 WIN, 3 XXX, 4 HASH
      typeidx = 1 + 2.*~strcmp(subject.blocktype,'WINBLOCK') + win; 
      imgtype=imgtypes{typeidx};

      %
      %fprintf('%s(%s) -->  %d+%d = %d --> %s\n', ...
      % opts.blocktypes{subject.run_num}, ...
      % subject.blocktype, ...
      % 2.*~strcmp(subject.blocktype,'WINBLOCK'),...
      % win, ...
      % typeidx,...
      % imgtype ...
      %);
    
    
   end
    

end

