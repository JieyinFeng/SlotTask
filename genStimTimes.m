function genStimTimes(matfile)
%GENSTIMTIMES create stimtimes
%   generate basic stimtimes from mat file output of the slottask
%   1) break up timeing vector into blocks
%   2) save each stim file in a subject_run directory
a=load(matfile);
trialblklist=a.subject.experiment(:,a.subject.expercol2idx('Block'));

% how long we see the start is roughly the RT
%  -- for added percission we could use the spin stimtime
%  -- also maybe consider dropping events where there is a 
%      firstbadresponse
RT=[a.subject.stimtime.response] - [a.subject.stimtime.start];

% catch trials: where result has 0 duration (also no ITI)
catchTrials=find(a.subject.experiment(:,a.subject.expercol2idx('Result'))==0);

%make sure catch trials arent the last in a block
%intersect(catchTrials,cumsum(a.subject.blockTrial))


% where to save
folder=fullfile('stimtimes', ...
       [ num2str(a.subject.subj_id) '_' num2str(a.subject.run_date) ] );
if(~exist(folder,'dir')), mkdir(folder), end

% combine all results into one fields
%  so we can have one regressor for win, nowin, xxx, and hash
%     and we can find catch trials (no results/reciept)
allresults ={a.subject.stimtime.WIN;  ...
             a.subject.stimtime.NOWIN;   ...
             a.subject.stimtime.XXX;     ...
             a.subject.stimtime.HASH };
allresults(cellfun(@isempty,allresults))={0};
allresults=sum(cell2mat(allresults),1);
for i=1:length(allresults)
    if(allresults(i)==0)
      a.subject.stimtime(i).allresults=[];
    else
      a.subject.stimtime(i).allresults=allresults(i);
    end
end



% how long is the spin
% spin changes when there is any resposne (win, nowin, hash, xxx)
% OR when the next start time is (if catch trial)
spinend={a.subject.stimtime.allresults};
emptyidx  = find(cellfun(@isempty,spinend));
% fill missing spinends with next trial starts
% -- will be wrong if block end is catch trial
% -- will error if last trial is catch
% TODO: FIX
spinend(emptyidx) = {a.subject.stimtime(emptyidx+1).start};
spindur = [spinend{:}]-[a.subject.stimtime.spin];

% foreach block
for blknum=unique(trialblklist)'
    
     blkidxs=trialblklist==blknum;
     % foreach stimtime 
     for stim=fieldnames(a.subject.stimtime)'
         stimtimes=[a.subject.stimtime(blkidxs).(stim{1})];
         
         if(isempty(stimtimes))
             continue;
             % ie. XXX or HASH on Reward block
             %     WIN or NOWIN on Control block
         end
         
         % change the name so we can do WIN* or NOWIN* in 3dDeconvolve
         if(strcmp(stim{1},'XXX'))
             stim{1}='NOWINcontrol';
         elseif(strcmp(stim{1},'HASH'))
             stim{1}='WINcontrol';
         end
         
         filename=[ num2str(blknum,'%02d') '_' stim{1} '.1D'];
         fid=fopen(fullfile(folder,filename),'w');
         
         
         fprintf(fid,'%.03f ',stimtimes);
         
         fclose(fid);
         
     end
     
     fid=fopen(fullfile(folder,[ num2str(blknum,'%02d') '_duration_start.1D']),'w');
     fprintf(fid,'%.03f:%.03f ', [ a.subject.stimtime(blkidxs).start; RT(blkidxs) ]);
     fclose(fid);
     
     
     %a.subject.trlTpts.start(blkidxs_n(emptyidx)+1)- a.subject.trlTpts.StartOfRunTime(blknum)
     
     fid=fopen(fullfile(folder,[ num2str(blknum,'%02d') '_duration_spin.1D']),'w');
     fprintf(fid,'%.03f:%.03f ', ...
         [[a.subject.stimtime(blkidxs).spin]; spindur(blkidxs)  ]);
     fclose(fid);
     
end

end

