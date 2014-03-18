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
%  [?] add warning to chooseFruit if participant takes too long
%
% 20131024 - WF
%  - start coding, copy of CogEmoFaceReward  
%  - have slot pictures
% 20130216 - WF
%  - use private functions from MEGClockTask
% 20140219 - WF
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
  
  % useful anonymous function for '()'
  %paren = @(x, varargin) x(varargin{:});
  
  % so PTB timing isn't truncated
  format longG; 

  %% start recording data
  % sets txtfid, subject.*, start, etc 
  subject=getSubjInfo('SlotPETMRI',subject,opts,blk);
  % give a sorter name to the col2idx function
  colIDX=subject.expercol2idx;

  % get trial indexs for this run (block)
  thisBlockIdx = find(subject.experiment(:,subject.expercol2idx('Block'))==subject.run_num);
  %nTrials    = length(thisBlockIdx);
  startTrial = thisBlockIdx(1);
  endTrial   = thisBlockIdx(end);
  
  % log all output of matlab
  diaryfile = fullfile('logs/', [num2str(subject.subj_id) '_' num2str(GetSecs()) '_tcdiary.log']);
  diary(diaryfile);

  % save mat output to a textfile too
  fprintf('saving to %s\n', subject.txtfile);
  txtfid      =fopen(subject.txtfile,'a'); % append so we only have one text file but all blocks

  % tabulate total score for each trial
  canreward = cellfun(@(x) strcmp(x,'WINBLOCK'), opts.blocktypes(subject.experiment(:,colIDX('Block') ) ));

  subject.experiment(:,colIDX('Score')) = cumsum(subject.experiment(:,colIDX('WIN')) .* canreward');

  % final output, order, has:
  orderidxname = @(name) find(cellfun(@(x) any(strmatch(x,name)),{'Block','Trial','Startime','Response','ResponseTime','Win', 'Total'}));

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
     slack = FlipInterval/10; %used for minimizing accumulation of lags due to vertical refresh
      
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
     acceptableKeyPresses = [  KbName('2@') KbName('3#') KbName('4$') KbName('5!')  KbName('space')];

     
    
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
        [ 'You will be playing an old slot machine\n' ...
          'Push a button to pull the lever\n'...
          'Each fruit can be choosen by the corresponding finger\n'...
          'If you choose correctly, you will win\n'...
        ], ...
        [ 'The slot machine will not always work\n' ...
          'Correct answers are entirely random\n'...
          'There is no pattern\n' ...
          'You need to chose a different button than last time' ...
        ], ...
      }; 
     InstructionsBetween = 'Choose a fruit';
   
     % is the first time loading?
     % we know this by where we are set to start (!=1 if loaded from mat)
     if startTrial==1  
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
     DrawFormattedText(w, '=Get Ready=','center','center',black);
     Screen('Flip', w);

     % start when we get ^ for scanner
     StartOfRunTime = waitForResponse('=+');
     subject.trlTpts.StartOfRunTime(subject.run_num)=StartOfRunTime;
     
  
   
     
     %% THE BIG LOOP -- experiment lists timing for all trials
     % we only want to go over those trials in this block (run_num)
     
     subject.blockTrial(subject.run_num) = 0; %reset block trial
     
     %waittilltime=0;
     
     for trialnum=startTrial:endTrial
        subject.trialnum= trialnum;
        trialpart=1; % for each event (part) we record timing

        %% get start time based on previous ITI/ISI
        % todo use
        idealtime.start       = 0;
        if(trialnum ~= startTrial)
            % get onset of ITI by inspecting the timing structure
            ITItrialnum = length(subject.timing(1,:,1) ); % last one, 5 or 6
            expectedITIOnset = subject.timing(trialnum-1,ITItrialnum,1);
            % get duration from experiment
            
            % if catch trial,  ITI comes from spin length
            % not ITI column
            if(subject.experiment(trialnum-1,colIDX('Result')) == 0 )
                ITIfield='Spin';
            else
                ITIfield='ITI';
            end
            
            ITIduration = subject.experiment(trialnum-1,colIDX(ITIfield));

            idealtime.start   = expectedITIOnset + ITIduration;
        else
            ITIduration =0;
            idealtime.start   = StartOfRunTime;
        end
        
        if(opts.DEBUG)
          fprintf('waiting %f to next trial start \n\tat\t%f\n\tnow\t%f\n',ITIduration,idealtime.start,GetSecs() );
        end


        %% 1. Start the trial (display the slot machine)
        Screen('DrawTexture', w,  slotimg.CHOOSE);
        % dont clear the buffer... so we can show warnings
        [~,trialStartTime] = Screen('Flip', w, idealtime.start-slack,1);
        % this will eventaully go to afni's 3dDeconvolve
        subject.stimtime(trialnum).start=trialStartTime - StartOfRunTime;
        
        subject.timing(trialnum,trialpart,:)= [ idealtime.start; trialStartTime ];
        trialpart=trialpart+1;
        %waittilltime=trialStartTime;
        
        subject.trlTpts.start(trialnum)=trialStartTime;
        
        
        %% 2. choose a fruit -- get RT
        % get prevchoice so we can make sure we choose differently
        if(trialnum>startTrial), prevchoice=subject.order(trialnum-1,orderidxname('Response') );
        else                     prevchoice=0; end
        
        % get choice, must be different than previous
        numattempts=0;
        response=prevchoice;
        while(response==prevchoice)
         % todo?? capture original response time
         % this only queries for response, w is passed to draw warning (not
         % impletmeneteD)
         [timeAtResponse, response] = chooseFruit(trialStartTime,numattempts,w,acceptableKeyPresses);
         response=response(1); % incase we push 2 buttons
         rspnstime = timeAtResponse - trialStartTime;
         numattempts=numattempts+1;

         %WaitSec(.0001) % so we dont go endlessly thorugh the loop
        end
        fprintf('response time %f\n',rspnstime);
        
        subject.stimtime(trialnum).response=timeAtResponse - StartOfRunTime;
        

      
        %% --. compute timing for the rest of the trial
        % response time just happpend, so now we can set the timing for the
        % rest of the trial
        % want NO delay between response time and spinner
        % add RT to starttime
        % then calculate the display time of all other events durning this trial
        % see priveate/getTimingOrder.m
        offsets = [ timeAtResponse subject.experiment(trialnum,[ colIDX('Spin') colIDX('Result')]) ];
        trlTimes= cumsum( offsets );
        
        idealtime.spinOnset   = trlTimes(1);
        idealtime.resultOnset = trlTimes(2);
        idealtime.itiOnset    = trlTimes(3);
        % struct2array(idealtimes) == [ idealtimes.start trlTimes ]
        
        %% 3. SHOW SPIN (AKA ISI)
        Screen('FillRect', w, 264, [] ) % clear any warnings
        Screen('DrawTexture', w,  slotimg.BLUR);
        [~,spinOnset ] = Screen('Flip', w, idealtime.spinOnset -slack);
        
        %update timing
        subject.stimtime(trialnum).spin=spinOnset - StartOfRunTime;
        subject.timing(trialnum,trialpart,:)= [ idealtime.spinOnset; spinOnset ];
        trialpart=trialpart+1;
        
        %% End (if catch) or Results + ITI 
        % if this is not a catch trial, 
        % -- we will have stim lengths Result + Receipt > 0
        if( subject.experiment(trialnum,colIDX('Result')) >0)

           
           %% 4. SHOW RESULTS (maybe play a sound)
           % get what image should be shown for this trialnum
           imgtype = scoreTrial(  subject.experiment( trialnum, colIDX('WIN') )  );
           Screen('DrawTexture', w,  slotimg.(imgtype)  ); 
           % draw win amount, no gain, or xxxxx for contorl block
           if(strcmp(subject.blocktype,'MOTOR'))
               message='xxxxxxxxxxxxxxxxxxxxx';
               msgcolor=[0 0 0];
           elseif(subject.experiment( trialnum, colIDX('WIN') ) == 1 )
               message=[num2str(subject.experiment(trialnum,colIDX('Score'))) ' points total' ];
               msgcolor=[41    99    34];
           else
               message='no new points';
               msgcolor=[0 0 0];
           end
           % text position should be relative to center of presentaiton part of screen 
           %  upper left corner of slot feedback is 164.0,180.5 from center (add pixels to center in this box)
           % center is 648/2 921/2
            DrawFormattedText(w, message,...
                    opts.screen(1)/2-120, ...
                    opts.screen(2)/2-75 ,...
                    msgcolor);
          
           
           [~,resultsOnset]=Screen('Flip', w,idealtime.resultOnset -slack);
           subject.stimtime(trialnum).(imgtype)=resultsOnset - StartOfRunTime;

           %% 5. ITI  -- show empty slot after WIN/NOWIN
           itiOnset = fixation(w,idealtime.itiOnset-slack);
           subject.stimtime(trialnum).ITI=itiOnset - StartOfRunTime;
           
        else
           fprintf('catch trial!\n')
           resultsOnset=GetSecs();
           itiOnset=resultsOnset;
        end

        % record timings for result and iti (0's if didnt happen)
        subject.timing(trialnum,trialpart,:)= [ idealtime.resultOnset; resultsOnset ];
        trialpart=trialpart+1;
        subject.timing(trialnum,trialpart,:)= [ idealtime.itiOnset; itiOnset ];
        

        %% TRIALs ENDED -- record everything
        %TODO!! What should be recorded
        % wrap up: show/save info
        % trialnum\tstartime\tresponse\ trialscore total
        
        %           blocknum    trialnum  startime response responsetime trialscore total
        trialinfo = [ subject.experiment(trialnum,1) trialnum trialStartTime response rspnstime subject.experiment(trialnum,[colIDX('WIN'),colIDX('Score')]) ];
        subject.order(trialnum,:) = trialinfo;

        % update trial in block
        subject.blockTrial(subject.run_num) = subject.blockTrial(subject.run_num) + 1;

        % print header
        if trialnum == startTrial
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

        timemat = reshape(subject.timing(trialnum,:,:),[trialpart,2]);
        if(trialnum==startTrial)
            prevousend=subject.timing(trialnum,1,1);
        else
            prevousend=subject.timing((trialnum-1),trialpart,1) + subject.experiment(trialnum-1,colIDX('ITI'))/10^3;
        end
        
        todisp= timemat - prevousend;
        todisp = [ todisp todisp(:,2)-todisp(:,1) ];
        eventid = {'start','pull','isi','result','recpt','iti'};
        fprintf('%02d  onset\tideal  \tactual  \tdiff\n',trialnum)
        for dispidx=1:trialpart
          fprintf('   %s\t%.4f\t%.4f\t%.4f\n',eventid{dispidx},todisp(dispidx,:) )
        end
        
        
        
        
        %% debug, show time of this trial
        subject.trlTpts.end(trialnum)= GetSecs();
        if(opts.DEBUG)        
          startend=[subject.trlTpts.start(trialnum), subject.trlTpts.end(trialnum)];
          fprintf('%d -- %f to %f; dur %f\n',trialnum, startend - subject.trlTpts.StartOfRunTime(subject.run_num),diff(fliplr(startend)));
        end

     end 

    subject.trlTpts.EndOfRunTime(subject.run_num)=GetSecs();
    
    %% show a rest screen for 1 minute
    soothdir=fullfile('imgs','Scenes','Soothing');
    allfiles=dir(soothdir);
    files={allfiles.name};
    imgnum = RandSample(3:length(files),[1 1]);

    imgfile=strcat('imgs/Scenes/Soothing/',files{imgnum});
    [imdata, colormap, alpha]=imread(imgfile);
    %imdata(:, :, 4) = alpha(:, :); 
    imgfiletex = Screen('MakeTexture', w, imdata);
    Screen('DrawTexture', w,  imgfiletex);
    Screen('FillRect', w, 264, [0 0 800 40] )
    DrawFormattedText(w, ['You have ', num2str(subject.experiment(trialnum,colIDX('Score'))) 'pts   Now Relax' ] ,...
           0,0,black);

    Screen('Flip', w);
    
    %% wait a minute -- but listen for ESCAPSE to quit early
    while(GetSecs()-subject.trlTpts.EndOfRunTime(subject.run_num) < 60 );
        [ keyIsDown, timeAtRspns, keyCode ] = KbCheck;
         if(keyCode(KbName('ESCAPE'))); 
            msgAndCloseEverything('Early Quit!');
            error('quit early\n');
         end
         WaitSecs(.2);
    end
    
    %msgAndCloseEverything('Thanks for playing!');
    closeEverything();
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
    function [timeAtRspns, whichKeyCode ]=chooseFruit(starttime,numattempts,w,keys)
        % display screen
        if(numattempts>0)
            Screen('FillRect', w, 264, [0 0 opts.screen(1) 40 ] ) % clear any warnings
            DrawFormattedText(w, 'You choose that fruit last time!',...
                    'center',30 ,...
                    [254 0 0]);
             Screen('Flip',w,0,1)
            % draw warning
            %fprintf('this is the %d attempt\n',numattempts);
        end
        seenwarning=0;
        %%draw 
        while(1)
            % check for escape's
            [ keyIsDown, timeAtRspns, keyCode ] = KbCheck;
            
            % pushed a button and was not accidental (>6ms)
            if keyIsDown && timeAtRspns-starttime> .06
                if(keyCode(KbName('ESCAPE'))); 
                    msgAndCloseEverything('Early Quit!');
                    error('quit early\n');
                    %msgAndCloseEverything(['Quit on trial ' num2str(trialnum)]);
                    %error('quit early (on %d)\n',trialnum)
                elseif any(keyCode(keys))
                    whichKeyCode=find(keyCode(keys));
                    break
                end
            end
            
            % TODO:
            % flash warning if response takes too long
             if(timeAtRspns-starttime>1.5 && ~seenwarning)
                 seenwarning=1;
                % text position should be relative to center of presentaiton part of screen 
                %  upper left corner of slot feedback is 164.0,180.5 from center (add pixels to center in this box)
                % lower left corner of slot machine is 50,850
                % center is 648/2 921/2
                % Screen('DrawText',w,scoretext, opts.screen(1)/2-120, opts.screen(2)/2-130);
                DrawFormattedText(w, 'Respond Faster! You''re missing trials!',...
                    'center',opts.screen(2) - 30 ,...
                    [254 0 0]);
                Screen('Flip',w,0,1)
             end
            
        end
        
        %timeAtRspns =  (seconds - starttime)*10^-3;
    end

    %% display fication cross
    % return when fixation corss was displayed
    % made into a function incase it gets fancier
    function onset = fixation(w,waittilltime)
        %DrawFormattedText(w, '+','center','center',black);
        Screen('DrawTexture', w,  slotimg.EMPTY ); 
        [~,onset ] = Screen('Flip', w, waittilltime);
    end
  
    function msgAndCloseEverything(message)
       Priority(0); % set priority to normal 
       Screen('FillRect', w, 264, [] ) % clear framebuffer
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
       
       if(subject.trialnum<endTrial)
        error('quit early (on %d/%d)\n',subject.trialnum,endTrial)
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

