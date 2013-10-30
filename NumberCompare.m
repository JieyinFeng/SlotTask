% Slot Task:
%  1. show "SELECT FRUIT" slot machine that has 4 choices
%  2. take choice input from button box
%     2.1 show warning if same choice is made twice, go back to 1 (500ms)
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


function NumberCompare(varargin)
  %% SlotTask
  
  % defines opts structure     
  % sets screen resolution
  % and some debug options
  getopts(varargin); 
  
  %% what are we doing
  blocktype='WINBLOCK';
  
  %% Set length of experiment
  runTimeSec=24*60; % in secs

  %% start recording data
  % sets txtfid, subject.*, start, etc 
  start=1; % before we know anything, we think we'll start at the beginning
  score=0;
  txtfid=getSubjInfo();



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
     
     backgroundcolor=[ 204 204 204];
     % Find out how many screens and use smallset screen number
     % Open a new window.
     [ w, windowRect ] = Screen('OpenWindow', max(Screen('Screens')),backgroundcolor, [0 0 opts.screen] );
          
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
     escKey  = KbName('ESCAPE');
     
     % RA can push space, subject can push button box
     acceptableKeyPresses = [ KbName('space') KbName('1!') KbName('2@') KbName('3#') KbName('4$') ];

     
    
     %% preload textures
     % grab file (assumed to exist), read iamge, add alpha information
     % save in slotimg struct
     % e.g. slotimg.CHOOSE='slotimgs/CHOOSE.png'
     for slotimgnames={'CHOOSE','BLUR','WIN','NOWIN','XXX','HASH'}
        stimfilename=strcat('imgs/',slotimgnames{1},'.png');
        [imdata, colormap, alpha]=imread(stimfilename);
        imdata(:, :, 4) = alpha(:, :); 
        slotimg.(slotimgnames{1}) = Screen('MakeTexture', w, imdata);
     end


     %% setup sound
     % http://docs.psychtoolbox.org/PsychPortAudio
     % http://wiki.stdout.org/matlabcookbook/Presenting%20auditory%20stimuli/Playing%20sounds/
     
     %InitializePsychSound;
     %[wavedata, sndFreq] = audioread('snd/incorrect.wav');
     %wavedata=wavedata';
     %nrchannels = size(wavedata,1);
     % 2nd to last arg should be sndFreq, but portaudio returns error w/it
     %todo fix sounds
     %pahandle= PsychPortAudio('Open', [], [], [], [], nrchannels);
     %PsychPortAudio('FillBuffer',pahandle,wavedata);
     
     
     

     %% Instructions     
     Instructions = { ...
        [ 'You will be bored\n' ...
          'Nothing is as bad as this task\n'...
        ], ...
        [ 'Are you ready?\n' ...
          'Well too bad\n'  ] ...
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

        % inialize the order of events only if we arn't resuming
        %order=cell(length(experiment{facenumC}),1);
        order=cell(100,1); % variable length!
     
     % subjects know the drill. Give them breif instructions
     % order is already init. and loaded from mat, so don't work about it
     else
         DrawFormattedText(w, ['Welcome Back!\n\n' InstructionsBetween],'center','center',black);
         Screen('Flip', w);
         waitForResponse;
     end
     
     %% wait for scanner start
     DrawFormattedText(w, ['Get Ready (waiting for scanner "^")\n'],'center','center',black);
     Screen('Flip', w);
     waitForResponse('6^')
     StartOfRunTime = GetSecs();
     
     i=start; % fixation calls drawRect which uses i to get the block number   
  
   
     
     %% THE BIG LOOP -- block design do for about 24 minutes
     %for i=start:length(experiment{facenumC})
     while(GetSecs()-StartOfRunTime < runTimeSec)
        trialnum=i;
        %% debug, start time keeping
        % start of time debuging global var
        trailStartTime=GetSecs();
        % seconds into the experiement from start of for loop
        timing.start=trailStartTime-StartOfRunTime;
        
        %% choose a fruit, "spin", WIN/NOWIN, score

        % get prevchoice so we can make sure we choose differently
        if(trialnum>1), prevchoice=order{trialnum-1}{4};
        else            prevchoice=0; end
        
        % get choice, must be different than previous
        response=prevchoice;
        numattempts=0;
        while(response==prevchoice)  
         [rspnstime, response] = chooseFruit(numattempts);
         numattempts=numattempts+1;
        end
        
        
        [imgtype, trialscore] =scoreTrial(trialnum,score,blocktype);
        score=score+trialscore;
        %% SHOW SPIN
        Screen('DrawTexture', w,  slotimg.BLUR  ); 
        Screen('Flip', w);
        WaitSecs(.5);
        
        %% SHOW RESULTS (maybe play a sound)
        Screen('DrawTexture', w,  slotimg.(imgtype)  ); 
        Screen('Flip', w);
        WaitSecs(1);
        
        %% SHOW score
        DrawFormattedText(w, ['your total score is ' num2str(score) '\n' ],'center','center',black);
        Screen('Flip', w);
        WaitSecs(1);
        
        %% TRIAL ENDED
        %TODO!! What should be recorded
        % wrap up: show/save info
        % trialnum\tstartime\tresponse\ trialscore total
        trialinfo = { blocktype trialnum trailStartTime rspnstime response trialscore score };
        order(i) = {trialinfo};
        
        
        % print header
        if i == 1
            fprintf(txtfid,'blocktype\ttrialnum\tstartime\tresponse\tresponsetime\ttrialscore\ttotal\n');
        end
        
        fprintf(txtfid,'%s\t',order{i}{1} );
        fprintf(txtfid,'%i\t',order{i}{2} );
        fprintf(txtfid,'%.03f\t',order{i}{3:4} );
        fprintf(txtfid,'%d\t',order{i}{5:6} );
        fprintf(txtfid,'%d',order{i}{7} );
        fprintf(txtfid, '\n');
        
        % save to mat so crash can be reloaded
        save(filename,'order','trialnum','subject','score');
       
        
        
        
        %% debug, show time of this trial
        if(opts.DEBUG)        
          timing.end= GetSecs() - trailStartTime;
          fprintf('%d: (%f,%f) %f\n',i, timing.start, timing.end,timing.end-timing.start);
        end

      i=i+1;
     end 

    % everyone should earn the bonus
    % but they should have at least 2000 pts
    earnedmsg='\n\nYou earned a $25 bonus !'; 
    if(score<2000); earnedmsg=''; end;


    msgAndCloseEverything(['Your final score is ', num2str(score) ,' points', earnedmsg, '\n\nThanks for playing!']);
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
    function [rsptimeMS, keyCode ]=chooseFruit(numattempts)
        startTimeSec   = GetSecs();
        % display screen
        Screen('DrawTexture', w,  slotimg.CHOOSE  );
        if(numattempts>0)
            % draw warning
        end
        %%draw 
        Screen('Flip', w);
        while(1)
            % check for escape's
            [ keyIsDown, seconds, keyCode ] = KbCheck;

            if keyIsDown
                if(keyCode(escKey)); 
                    msgAndCloseEverything(['Quit on trial ' num2str(i)]);
                    error('quit early (on %d)\n',i)
                elseif any(keyCode(acceptableKeyPresses))
                    break
                end
            end     
            
            % TODO:
            % flash warning if response takes too long
            
        end
        rsptimeMS = round( (GetSecs() - startTimeSec) * 10^3);
    end

    function msgAndCloseEverything(message)
       DrawFormattedText(w, [message '\n\n push any key but esc to quit'],...
           'center','center',black);
       fprintf('%s\n',message)
       Screen('Flip', w);
       waitForResponse;
       diary off;	%stop diary
       fclose('all');	%close data file
       Screen('Close')
       Screen('CloseAll');
       PsychPortAudio('Close');
       sca
    end
  


   %% wait for a response
function seconds = waitForResponse(varargin)
      %% sometimes we only want a specfic set of keys
      if(~isempty(varargin))
       usekeys=KbName(varargin{1});
      else
       usekeys=acceptableKeyPresses;
      end
      
      while(1)
          [ keyIsDown, seconds, keyCode ] = KbCheck;
          
          if(keyIsDown && keyCode(escKey));
              msgAndCloseEverything(['Quit on trial ' num2str(i)]);
              error('quit early (on %d)\n',i)
           end
          
          % go on any key
          % if(keyIsDown && any(keyCode)); break; end %any() is redudant

          % specify keys
          if(keyIsDown && any(keyCode(usekeys))); break; end 

          WaitSecs(.001);
      end
      Screen('Flip', w); % change the screen so we don't hold down space
      WaitSecs(.2);
    end


   %% score: 1/4 of the time correct
   function [imgtype, score]=scoreTrial(trial,numcorrect,blocktype)
      %% score should be random, win 1/4 of the time
      score=0;
%       if(numcorrect*4 < trial )
%         % maybe check to see if they should win based on the number of
%         % trials and how many correct they've already won
%         randscore=1;
%       else
%         randscore=0;
%       end
      randscore=0;
      if(random('unif',0,1) >= .75 )
          randscore=1;
      end
      %% we might return 4 different images
      % depends on blocktype and win/lose status
      if(strcmp(blocktype,'WINBLOCK'))
          if(randscore>0)
            imgtype='WIN' ;
            score=randscore;
            %todo: play win sound
          else
            imgtype='NOWIN';
          end
        else
          if(trialscore>0)
            imgtype='HASH' ;
            %todo: play tick noise
          else
            imgtype='XXX';
          end
            
       end
   end
    

   %% get who the subject is
   function txtfid=getSubjInfo 
        % skip the questions if we provide var ourself
        subject.subj_id = input('Enter the subject ID number: ','s');
        

        filename = ['subjects/' subject.subj_id '_tc'];

        % is the subject new? should we resume from existing?
        % set t accordingly, maybe load subject structure 
        txtfile=[filename '.txt'];
        backup=[txtfile '.' num2str(GetSecs()) '.bak'];
        
        % we did something with this subject before?
        if exist(txtfile,'file') 
            
            % check that we have a mat file
            % if not, backup txt file and restart
            if ~ exist([filename '.mat'],'file')
                fprintf('%s.txt exists, but .mat does not!\n',filename)
                reload= 'n'; % move txt file to backup and start from scratch
            
            % we have the mat file
            % * is this resuming the previous run -- we were at the halfwaypt
            % * if it's not obviously resuming, do we want to continue where
            %   we left off?
            else
                localVar = load(filename);
                % sanity check
                if localVar.subject.subj_id ~= subject.subj_id
                    error('mat file data conflicts with name!: %d != %d',...
                        localVar.subject.subj_id, subject.subj_id);
                end
                
                % we have a mat, but did we stop when we should have?
%                 if  localVar.subject.run_num == 1 && ...
%                    localVar.trialnum == halfwaypt;
%                     
%                     fprintf('incrementing run_num and assuming reload\n');
%                     resume = 'y';
%                     localVar.subject.run_num=2;
%                     localVar.trialnum=halfwaypt+1; 
%                     % need to increment trial here 
%                     % b/c we exit before incrementing i earlier
%                     % and we'll get stuck in a one trial loop otherwise
%                 
%                 % no where we expect, maybe psychtoolbox crashed
%                 % prompt if we want to restart
%                 else
%                     fprintf('not auto resuming b/c run=%d and trail=%d\n\n',...
%                         localVar.subject.run_num,localVar.trialnum)
                     resume = lower(input('Want to load previous session (y or n)? ','s'));
%                 end
       
                %
                % if we auto incremented run_num
                % or decided to resume
                %   clear subject, and load from mat file
                if strcmp(resume,'y')
                    
                    clear subject
                    start=localVar.trialnum;
                    subject=localVar.subject;

                    order=localVar.order;
                    score=localVar.score;
                
                % otherwise, move the existing txt file to a backup
                % and we'll fill in the subject info below
                else
                    fprintf('moving %s to %s, start from top\n', txtfile,backup)
                    movefile(txtfile,backup);
                end
                
            end
            
         end
        
        %% fill out the subject struct if any part of it is still empty
        for attribCell={'gender','age','run_num'}
            % make a normal string
            attrib = cell2mat(attribCell);

            % check if it's already filled out
            if  ~ismember( attrib,fields(subject) )  
              promptText=sprintf('Enter subject''s %s: ',attrib);
              subject.(attrib) = input(promptText,'s');
            else
               if ~ischar(subject.(attrib)); tmp=num2str(subject.(attrib)); else tmp=subject.(attrib); end 
              fprintf('using old %s (%s)\n', attrib, tmp);
            end
        end

        %% age should be a number
        if ischar(subject.age);     subject.age    =str2double(subject.age);    end
        if ischar(subject.run_num); subject.run_num=str2double(subject.run_num);end

        if start==1 && subject.run_num==2; 
            fprintf('WARNING: new subject, but run number 2 means start from the top\n')
            fprintf('there is no good way to do the first part again\n')
            start=halfwaypt+1;
        end

        %% set sex to a standard
        if ismember(lower(subject.gender),{'male';'dude';'guy';'m';'1'} )
            subject.gender = 'male';
        else
            subject.gender = 'female';
        end
        % print out determined sex, give user a chance to correct
        fprintf('Subject is %s\n', subject.gender);

        %% Initialize data storage and records
        % make directoires
        for dir={'subjects','logs'}
         if ~ exist(dir{1},'dir'); mkdir(dir{1}); end
        end
        
        % log all output of matlab
        diaryfile = ['logs/' subject.subj_id '_' num2str(GetSecs()) '_tcdiary'];
        diary(diaryfile);
        
        % log presentation,score, timing (see variable "order")
        txtfid=fopen(txtfile,'a'); % we'll append to this..maybe
        
        if txtfid == -1; error('couldn''t open text file for subject'); end


      %% START/RESUME SUBJECT INFO
      % print the top of output file
      if start == 1
        fprintf(txtfid,'#Subj:\t%s\n',  subject.subj_id);
        fprintf(txtfid,'#Run:\t%i\n',   subject.run_num); 
        fprintf(txtfid,'#Age:\t%i\n',   subject.age);
        fprintf(txtfid,'#Gender:\t%s\n',subject.gender);
      end

      % always print date .. even though it'll mess up reading data if put in the middle
      fprintf(txtfid,'#%s\n',date);
   end



%% SET OPTIONS
 function getopts(o)
      
      %% BY DEFAULT
      opts.DEBUG=0;
      opts.sound=1;
      opts.screen=[1280 1024];
      
      %% PARSE REST
      i=1;
      while(i<=length(o))
          switch o{i}
              case {'DEBUG'}
                  opts.DEBUG=1;
                  opts.screen=[800 600];
              case {'screen'}
                  i=i+1;
                  if isa(o{i},'char')
                      
                    % SlotTask('screen','mac laptop')
                    switch o{i}
                        case {'mac laptop'}
                            opts.screen=[1680 1050]; %mac laptop
                        case {'VGA'}
                            opts.screen=[640 480]; %basic VGA
                        case {'eyelab'}
                            opts.screen=[1440 900]; %new eyelab room
                        otherwise
                            fprintf('dont know what %s is\n',o{i});
                    end
                    
                  %SlotTask('screen',[800 600])
                  else
                    opts.screen=o{i};    
                  end    
                  
              otherwise
                  fprintf('unknown option #%d\n',i)
          end
          
       i=i+1;    
      
      end
      
      disp(opts)
    end
end

