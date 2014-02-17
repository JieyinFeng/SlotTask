% Monitary Incentive Delay


function [subject, time] = MID(varargin)
  format long; %for debuging
  opts.DEBUG=1;
  opts.screen=[800 600];

  %% launch presentation   
  try
  
     %% setup screen
     % Removes the blue screen flash and minimize extraneous warnings.
     % http://psychtoolbox.org/FaqWarningPrefs
     %if (~opts.DEBUG)
       %Screen('Preference', 'SuppressAllWarnings', 1);
  	   Screen('Preference', 'Verbosity', 2); % remove cli startup message 
       Screen('Preference', 'VisualDebugLevel', 3); % remove  visual logo
     %end
     
     backgroundcolor=[ 204 204 204];
     % Find out how many screens and use smallset screen number
     % Open a new window.
     [ w, windowRect ] = Screen('OpenWindow', max(Screen('Screens')),backgroundcolor, [0 0 opts.screen] );
          
     %permit transparency
     Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
     
     % Set text display options. We skip on Linux.
     Screen('TextFont', w, 'Arial');
     Screen('TextSize', w, 22);
   
  
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
     % grab file (assumed to exist), read image, add alpha information
     % save in slotimg struct
     % e.g. slotimg.CHOOSE='slotimgs/CHOOSE.png'
     imgdir='imgs/Scenes/';
     for d={'indoor','outdoor'};
         files=dir([imgdir,d{1}]);
         scenes.(d{1})=cell(1,length(files));
         
         for fidx=3:length(files)
            f=files(fidx).name;
            disp(f)
            %if(strcmp(f(end),'.')); continue;end %only 2: . and ..
            scenefile=strcat(imgdir,d{1},'/',f);
           
            
            [imdata, colormap, alpha]=imread(scenefile);
            % if alpha
            if(any(size(alpha)))
               imdata(:, :, 4) = alpha(:, :); 
            end
            
             
            scenes.(d{1}){fidx-2} = Screen('MakeTexture', w, imdata);
         end
          
     end
     

    

     %% how to increase/decrease response time window to fix accuracy at 80%
     rxtdelta=.1;
     
     
     %% define subject
     subject.id=101;
     subject.date=datestr(date,'yyyymmdd');
     subject.hitrate=0;
     subject.totalcorrect=0;
     subject.totaltrials=0;
     subject.totalrus=0;
     subject.allowedrxt=.5;
     subject.lastcorrect=0;
     subject.start=1;
     
     

     %% define paradigm
     % 4 blocks alternating nue punish
     %blocks = xor(mod(subject.id, 2), [ 1 0 1 0 ]);
     blocks = [ 0 1 0 1 ];

     if(mod(subject.id,2)==0)
        rewardScene ='indoor';
        neutralScene='outdoor';
     else
        neutralScene ='indoor';
        rewardScene  ='outdoor';
     end
     
   
     %% experiment design
     % TODO: read from file
     % parse from 4d matrix given subject info
     % read matrix of all timings
     % TODO: 4d matrix, , mod subjnum to get position
     %  -- blocktype derived from block number and subject ID
     %  -- trial number fixed by row position
     %  1. cuetype -- 0 is neutral, 1 is reward
     %  2. ISI_cueNum
     %  3. ISI_numRew
     %  4. shownumber (1-4,6-9)
     %  5. ITI
     %  6. imagenum
     maxNumRXT=.8; %seconds
     idealHitRate=.8; % 80 percent
     cueTime=3.5; numTime=.1;receiptTime=1.5;

     cueIDX=1; ISI_cueNumIDX=2; ISI_numRewIDX=3; shownumIDX=4; ITIIDX=5; imagenumIDX=6;
     cueRew=1; cueNue=0;
     
     % n X m: n is number of trials per block
     %        m is  number of 
     design=ones(8,6);

     % set neut/reward trials
     % neutral is 0, happens 1/4 of the time
     design(:,cueIDX)        = randi(4,length(design),1)>3;

     % ISI between 1 and 1.8
     design(:,ISI_numRewIDX) = randi(8,length(design),1)/10 + 1;
     % ISI between 1-6
     design(:,ISI_numRewIDX) = exprnd(2,length(design),1)+1;
     design(:,find(design(:,ISI_numRewIDX)>6)) = 6;


     % random ones and zeros
     design(:,shownumIDX)=randi(10,length(design),1);
     design(:,find(design(:,shownumIDX)==5))=4;

     % expected times column
     totalTrialIDX=size(design,2)+1;
     design(:,totalTrialIDX)=cumsum(sum(design(:,[ISI_cueNumIDX ISI_numRewIDX ITIIDX]),2)+cueTime+numTime+receiptTime);

     
     %  allocate time array of structs (sort of)
     times(size(design,1)).trialstart.actual=0;
     
     
      %% Instructions     
     Instructions = { ...
        [ 'Right pointer finger for\n  '...
          rewardScene ' scenes\nor smaller than 5\n' ...
        ], ...
        [ 'Right middle finger for\n  '...
          neutralScene ' scenes\nor bigger than 5\n' ...
        ], ...
        [ 'Are you ready?\n\n' ...
          'Well, too bad\n'  ] ...
      }; 

     InstructionsBetween = ['pointer is ' rewardScene  ' and smaller than 5\n'...
                            'middle is '  neutralScene ' and bigger than 5\n' ];
   
     % is the first time loading?
     % we know this by where we are set to start (!=1 if loaded from mat)
     if subject.start==1  
         % show long instructions for first time player
         for instnum = 1:length(Instructions)
             DrawFormattedText(w, Instructions{instnum},'center','center',black);
             Screen('Flip', w);
             waitForResponse;
         end

    
     % subjects know the drill. Give them breif instructions
     % order is already init. and loaded from mat, so don't work about it
     else
         DrawFormattedText(w, ['Welcome Back!\n\n' InstructionsBetween],'center','center',black);
         Screen('Flip', w);
         waitForResponse;
     end
     
     
     %% THE BIG LOOP -- block design width
     %
     
     %% wait for scanner start
     DrawFormattedText(w, ['Get Ready (waiting for scanner "^")\n'],'center','center',black);
     Screen('Flip', w);
     StartOfParadigm= waitForResponse('6^');
     subject.scannersynctime = StartOfParadigm;

     for blocknum=1:length(blocks);
         
         blocktype=blocks(blocknum);
         %% allocate block
         subject.block(blocknum).rtxs=ones(size(design,1),1)*-1;
         subject.block(blocknum).corrects=ones(size(design,1),1)*-1;
         subject.block(blocknum).cues=ones(size(design,1),1)*-1;
         subject.block(blocknum).starttimes=ones(size(design,1),1)*-1;
         subject.block(blocknum).cuerxts=ones(size(design,1),1)*-1;
         subject.block(blocknum).cuecorrects=ones(size(design,1),1)*-1;

         
         StartOfRunTime = GetSecs();
         subject.block(blocknum).starttime = StartOfRunTime;
         subject.block(blocknum).blocktype = blocktype;
         
         time(1).trialstart.expect = StartOfRunTime; 
         
         length(design)
         for trialnum = subject.start:length(design)
               %% TIMING
               % reset time of trial
               trialRunningTime=GetSecs();
               % and record actual start time
               trialStartTime=trialRunningTime;

               % lock trials to expected timing
               % expect time set by previous trial ending
               time(trialnum).trialstart.actual = trialStartTime; % set start of trial
               time(trialnum).trialstart.duration = 0; % set start of trial

               %% HIT RATE
               % want to match at 80% hit rate
               % adjust hit rate
               if(subject.lastcorrect==1 && subject.totalcorrect/subject.totaltrials > idealHitRate)
                       subject.allowedrxt=subject.allowedrxt-rxtdelta;
                %       fprintf('rxt decremented to %f\n', subject.allowedrxt)
               elseif(subject.lastcorrect~=1 && subject.totalcorrect/subject.totaltrials < idealHitRate && subject.allowedrxt< maxNumRXT )
                       subject.allowedrxt=subject.allowedrxt+rxtdelta;
                %       fprintf('rxt decremented to %f\n', subject.allowedrxt)
               else
                %fprintf('not touching allowedrxt(%f)\ncorrecttotal: %d, total: %d, lastcorrect: %d',...
                %        subject.allowedrxt,subject.totalcorrect,subject.totaltrials,subject.lastcorrect)
               end

               % reward or neutral, number to show
               cuetype=design(trialnum,cueIDX);
               number=design(trialnum,shownumIDX);
               if(number<5)
                   correctCode=KbName('1!');
               else
                   correctCode=KbName('2@');
               end

               %fprintf('we are looking to %d for for idx %d, have neut %d and rew %d\n',...
               %  imagenumIDX, design(trialnum,imagenumIDX), length(scenes.(neutralScene)),...
               %  length(scenes.(rewardScene)) )

               if(cuetype==1) % reward is 1
                   cueCorrectCode=KbName('1!');
                   texture=scenes.(rewardScene){design(trialnum,imagenumIDX)};

               else
                   cueCorrectCode=KbName('2@');
                   texture=scenes.(neutralScene){design(trialnum,imagenumIDX)};
               end
               
               %% stimulus
               % show one of the images from scene
               % duration is fixed at 3.5 -- but we want to compensate for any lost time
               time(trialnum).cue.duration=cueTime - (time(trialnum).trialstart.actual - time(trialnum).trialstart.expect ) ;   
               time(trialnum).cue.expect  = increaseTime(time(trialnum).cue.duration);
               [ cuerxt, cuecorrect, time(trialnum).cue.actual ] = showCue(cueCorrectCode,time(trialnum).cue.expect,texture);

               % jittered wait
               time(trialnum).ISIcueNum.duration=design(trialnum,ISI_cueNumIDX);
               time(trialnum).ISIcueNum.expect  = increaseTime(time(trialnum).ISIcueNum.duration);
               time(trialnum).ISIcueNum.actual  = fixation(time(trialnum).ISIcueNum.expect);

               % flash a number
               time(trialnum).num.duration=numTime;
               time(trialnum).num.expect  = increaseTime(time(trialnum).num.duration);
               time(trialnum).num.actual  = showNumber(number,time(trialnum).num.duration);

               % get input
               duration=subject.allowedrxt;
               [correct, rxt ]=getinput(duration,correctCode);
               rxttime=time(trialnum).num.actual+rxt;

               %delay between input and reward
               time(trialnum).ISInumRew.duration=design(trialnum,ISI_numRewIDX)-rxt;
               time(trialnum).ISInumRew.expect  = increaseTime(time(trialnum).ISInumRew.duration);
               time(trialnum).ISInumRew.actual  = fixation(time(trialnum).ISInumRew.expect);


               %show reward
               time(trialnum).receipt.duration=receiptTime;
               time(trialnum).receipt.expect  = increaseTime(time(trialnum).receipt.duration);
               time(trialnum).receipt.actual  = showReward(blocktype,cuetype,correct,time(trialnum).receipt.expect);


               %% wrap up
               % update block info
               subject.block(blocknum).starttimes(trialnum) = trialStartTime;
               subject.block(blocknum).cues(trialnum)       = cuetype;
               subject.block(blocknum).cuerxts(trialnum)    = cuerxt;
               subject.block(blocknum).cuecorrects(trialnum)= cuecorrect;
               subject.block(blocknum).scores(trialnum)     = correct;
               subject.block(blocknum).rxts(trialnum)       = rxt;

               % update subject
               subject.totaltrials = subject.totaltrials+1;
               subject.lastcorrect = correct;

               %subject.totalcorrect=length(find(subject.block(blocknum).scores==1));
               if(correct==1); subject.totalcorrect=subject.totalcorrect+1; end
               
               fprintf('===%i cue RXT %d %.1f               ====\n',trialnum,cuecorrect,cuerxt);
               fprintf('  =   RXT %d %.1f (rsp time: %.3f)=   \n',         correct,rxt,subject.allowedrxt);
               fprintf('# timepoint\tdiff\tactl expctd\tintnd dur\n')
               for tpnts={'trialstart','cue','ISIcueNum','num','ISInumRew','receipt'}
                  tpnts=tpnts{1};
                  fprintf('%i %9s\t%.2f\t%.0f %.0f\t%f\n',trialnum,tpnts, ...
                    time(trialnum).(tpnts).actual-time(trialnum).(tpnts).expect, ...
                    (time(trialnum).(tpnts).actual-trialStartTime)*1000, ...
                    (time(trialnum).(tpnts).expect-trialStartTime)*1000, ...
                    time(trialnum).(tpnts).duration);
               end
               
               % TRIAL HAS FINISHED
               % ITI before next trial
               % increase trialTime
               %increaseTime(   design(trialnum,ITIIDX) );
               time(trialnum).trialend.duration = design(trialnum,totalTrialIDX);
               time(trialnum).trialend.expect   = design(trialnum,totalTrialIDX) + StartOfRunTime;
               % also expect the next trial to start when this one ended
               if(trialnum<length(design) )
                    time(trialnum+1).trialstart.expect = time(trialnum).trialend.expect;
               end

               %fixation(trialRunningTime);
               time(trialnum).trialend.actual=fixation( time(trialnum).trialend.expect );
         end 
         %% END BLOCK
         % TODO: save subject
         if(blocknum<length(blocks) )
             DrawFormattedText(w, ['You have completed a block!\n'...
                                   'Ready to continue?'],'center','center',black);
             Screen('Flip', w);
             waitForResponse('SPACE');
         end


     end
 catch
     %try, Screen('CloseAll'); end
     psychrethrow(psychlasterror);
     
  end
  
  % close the screen
  sca

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % increment time by duration
    % or return current time
    function expecttime = increaseTime(timeinc)
          trialRunningTime=trialRunningTime+timeinc;
          expecttime=trialRunningTime;
    end
   
    %% indoor or outdor scene
    function [rxt, correct, endtime ] = showCue(correctCode, endtime,texture)
        correct=-1;
        Screen('DrawTexture', w, texture); 
        Screen('Flip', w); 
        
        %check input
        while(GetSecs()<endtime)
          [ keyIsDown, rxt, keyCode ] = KbCheck;
          
          if(keyCode(escKey));
              msgAndCloseEverything(['Quit on trial ' num2str(trialnum)]);
              error('quit early (on %d)\n',trialnum)
          end
          
          if(any(keyCode(acceptableKeyPresses))); 
              if(keyCode(correctCode))
                  correct=1;
              else
                  correct=0;
              end
              break
           end
        end

        % show cross for remander
        endtime=fixation(endtime);
    end
    % %showCue(cuetype,time(trialnum).cue.expect);
    % function endtime = showCue(cuetype, endtime)
    %    if(cuetype)
    %        Screen('DrawTexture', w,  scenes.Outdoor{1}  );
    %        %DrawFormattedText(w, int2str(rewardNumber),'center','center',black);
    %    else
    %        Screen('DrawTexture', w,  scenes.Indoor{1}  ); 
    %        %DrawFormattedText(w, int2str(rewardNumber),'center','center',black);
    %    end
    %    Screen('Flip', w); 
    %    endtime=WaitSecs('UntilTime', endtime);
    % end

    %% Fixations
    % fixation(time(trialnum).ISInumRew.expect);
    function endtime=fixation(endtime)
       DrawFormattedText(w, '+','center','center',black);
       Screen('Flip', w); 
       endtime=WaitSecs('UntilTime',endtime);
    end
    

    %% Number Display
    % showNumber(number,duration);
    function endtime=showNumber(number,duration)
       DrawFormattedText(w, int2str(number),'center','center',black);
       Screen('Flip', w); 
       endtime=WaitSecs(duration);
    end
   
    %% get and judge input
    function [correct, endtime] = getinput(duration,correctCode)
        correct=-1;
        % draw response block
        %bottombox=[0 opts.screen(2) opts.screen(1)-10 opts.screen(1)]
        bottombox=[0 opts.screen(2)-10 opts.screen(1) opts.screen(2)];
        Screen('FillRect', w, [ 40 40 200 ], bottombox);
        %waitStartTime=Screen('Flip',w,0,1); % dont clear
        waitStartTime=Screen('Flip',w); % dont clear
        %waitStartTime=GetSecs();
        while(GetSecs()-waitStartTime<duration)
          [ keyIsDown, endtime, keyCode ] = KbCheck;
          
          if(keyCode(escKey));
              msgAndCloseEverything(['Quit on trial ' num2str(trialnum)]);
              error('quit early (on %d)\n',trialnum)
           end
          
          if(any(keyCode(acceptableKeyPresses))); 
              if(keyCode(correctCode))
                  correct=1;
              else
                  correct=0;
              end
          
              break;
          end 

          WaitSecs(.001);
          
        end
        endtime=GetSecs()-waitStartTime;
    end

   %% show reward
   % showReward(blocktype,cuetype,correct,time(trialnum).receipt.expect);
   function endtime = showReward(blocktype,cuetype,correct,endtime)
        % regardless of block, increase counts
        %if(correct==1)
        %    subject.totalcorrect=subject.totalcorrect+1;
        %    subject.lastcorrect=0;
        %    subject.totalcount=0;
        %end
       
        if(blocktype==1 && cuetype==1) %reward block, reward trial
            % give a score
            if(correct==1)
               DrawFormattedText(w, '^','center','center',[ 0 255 0]);
               %DrawFormattedText(w, '▲','center','center',[ 255 0 0]);
            else
               DrawFormattedText(w, 'V','center','center',[ 255 0 0]);
               %DrawFormattedText(w, '▼','center','center',[ 0 255 0]);
            end
            
        else
            DrawFormattedText(w, '?','center','center',black);
        end
         Screen('Flip', w);
         endtime = WaitSecs('UntilTime',endtime);
    
    
   end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           support functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
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
              msgAndCloseEverything(['Quit on trial ' num2str(trialnum)]);
              error('quit early (on %d)\n',trialnum)
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
%                     fprintf('not auto resuming b/c run=%d and trial=%d\n\n',...
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
        for dirname={'subjects','logs'}
         if ~ exist(dirname{1},'dir'); mkdir(dirname{1}); end
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

