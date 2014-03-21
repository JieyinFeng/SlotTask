#!/usr/bin/env bash

# 20 mins: 1200 seconds
# stims: button+spin=anticipation, win or nowin



runTime=300                  # length of run:  5min*60sec/min (was too long, 20min*60sec/min)
TR=1.5                       # t_r, MRI setting
nTR=$(echo $runTime/$TR| bc) # number of TRs  # 200 TRs 

avgRT=1      # slotstart display time
resultTime=1  # receipt display time (was result+reciept)

# parameters to test
nIts=200      # how many random timings to genereate to test a condition
maxCatch=20   # start at 0, go up by 5, to this number
winRatio=.33  # ratio of wins to nowins (not actually set here, for loop iterated)
meanISI=4     # time we want for ISI AND ITI (not actually set here, for loop iteratated)

# clear previous run
[ -d stims ] && mv stims stims.$(date +"%F_%H:%M")
mkdir stims
# start new record of each iteration
#        sum root mean square of the measurement error variance for each condition (minimize)
#        general linear test (Ward 1998 http://afni.nimh.nih.gov/pub/dist/doc/manual/3dDeconvolve.pdf pg43,82-88)
#           normalized variance-covariance matrix (X'X)^-1, lower=more power: Pr(Z>k - \theta/(s*d) ) -- d is our meassure
#        correlation between each regressor (minimize)
allinfo=info.txt
echo "it nTrial nWin nCatch RMSerror.start RMSerror.antic RMSerror.win RMSerror.nowin GLT.w-n GLT.a-w GLT.a-n GLT.a-w-n r.win r.nowin" |tee $allinfo

for winRatio in .25 .5; do
for meanISI in 2 3 4 5; do
 for nCatch in $(seq 0 5 $maxCatch); do
  possible=1
  for i in $(seq 1 $nIts); do
    [ $possible -eq 0 ] && continue

    # total number of trials (endtime-last iti)/(RT+ISI+Result+ITI) #bc floors division
    nTrials=$(echo "($runTime-(12-$meanISI))/($avgRT+$meanISI+$resultTime+$meanISI)"|bc) 

    # total number of wins
    nWin=$(perl -MPOSIX -e "print ceil($winRatio*$nTrials)")

    # do catch trials take away from total nowins?
    #let nNo=$nTrials-$nCatch-$nWin
    # here they do not, so we lose ISI time with catch trials
    let nNo=$nTrials-$nWin

    # name for this iteration: catch_iteration: cc_iiii 
    #ii=w$(printf %02d $nWin)_c$(printf %02d $nCatch)_$(printf %04d $i)
    ii=t$(printf %02d $nTrials)_w$(printf %02d $nWin)_c$(printf %02d $nCatch)_$(printf %04d $i)

    # make random timing using afni's python2 script
    # presentation is always 
    #    (1) slotpresentation+buttonpress+spin                -> (2) win/nowin + receipt
    #          0s            + 1s        + 0s (goes into ISI)           .5s        1s
    #
    # to enforce order and allow catch trials, spin is broken into 3 times
    #  (1) spinW: spin followed by a win
    #  (2) spinN: spin followed by a nowin
    #  (3) spinC: spin without anything following it
    python2 $(which make_random_timing.py) -num_runs 1 -run_time $runTime  \
          -tr $TR \
          -num_stim 5  \
          -stim_labels spinW  spinN  spinCatch win         nowin \
          -num_reps    $nWin  $nNo   $nCatch   $nWin       $nNo \
          -stim_dur    $avgRT $avgRT $avgRT    $resultTime $resultTime  \
          -ordered_stimuli spinW win                   \
          -ordered_stimuli spinN nowin                 \
          -pre_stim_rest 0 -post_stim_rest 12           \
          -min_rest 2 -max_rest 8                       \
          -show_timing_stats -prefix stims/${ii}_stimes \
          > stims/${ii}.makerandtimelog 2>&1 
          #-make_3dd_contrasts -save_3dd_cmd testwith3dd.tsch                 \
          #-min_rest 2 -max_rest 8 
          #  -seed 31415
    
    if [ $? -ne 0 ]; then echo "impossible combination: ${nWin}w ${nCatch}c  ${nTrials}t " 1>&2; possible=0; continue; fi 
    # combine all the spins, as these are not different stims
    # (specifiying them as different allowed us to enfoce an order)
    perl -lne 'print sprintf("%.02f",$&) while(/\d+\.?\d*/g)' stims/${ii}_stimes_*spin*1D | \
       sort -n | tr '\n' ' ' \
       > stims/${ii}_stimes_slotstart.1D 
    # written easier as
    # timing_.py -timing stims/${ii}_stims_01*spin*1D \
    #            -extend stims/${ii}_stims_02*spin*1D \
    #            -extend stims/${ii}_stims_03*spin*1D \
    #            -sort -write_timing stims/${ii}_stims_spin.1D
    

    # use R to get timing into a dataframe
    # marry duration (ISI) to spin duration to get anticipation block
    Rscript -e "source('timingFromAfni.R'); writeAnticipation(getStimTime('$ii'),'$ii');"

    # run hrf through afni without any data
    # generates:
    #  design matrix (*.xmat)
    #  measurement error variance
    #  general linear tests
    3dDeconvolve                                           \
          -nodata $nTR $TR                                \
          -polort 9                                        \
          -num_stimts 4                                    \
          -stim_times 1 stims/${ii}_stimes_slotstart.1D 'BLOCK(1,1)' \
          -stim_label 1 slotstart                               \
          -stim_times_AM1 2 stims/${ii}_stimes_anticipation.1D 'dmBLOCK(1)' \
          -stim_label     2 anticipation                       \
          -stim_times 3 stims/${ii}_stimes_*_win.1D "BLOCK($resultTime,1)"    \
          -stim_label 3 win                                \
          -stim_times 4 stims/${ii}_stimes_*nowin.1D "BLOCK($resultTime,1)" \
          -stim_label 4 nowin                            \
          -num_glt 4                                     \
          -gltsym "SYM: win  -nowin"              -glt_label 1 wVn  \
          -gltsym "SYM: anticipation -win"        -glt_label 2 aVw  \
          -gltsym "SYM: anticipation -nowin"      -glt_label 3 aVn  \
          -gltsym "SYM: anticipation -nowin -win" -glt_label 4 aVwn \
          -x1D stims/${ii}_X.xmat.1D   >  stims/${ii}.3ddlog 2>&1
          #-stim_times 1 stims/${ii}_stimes_spin.1D 'GAM' \
          #-stim_label 1 spin                               \
          #-stim_times 2 stims/${ii}_stimes_*_win.1D 'BLOCK(1.5,1)'     \
          # -stim_times 3 stims/${ii}_stimes_*nowin 'BLOCK(1.5,1)'    \
    
    ## ISI distribution
    #python2 $(which timing_tool.py) -multi_show_isi_stats \
    #                                -multi_stim_dur 1 1.5 1.5 \
    #                                -run_len 1200  \
    #                                -multi_timing stims/${ii}_stimes_{spin,*_win,*_nowin}.1D \
    #    >  stims/${ii}.info
        
    # correlation between regressors
    python2 $(which 1d_tool.py) -cormat_cutoff 0 -show_cormat_warnings -infile stims/${ii}_X.xmat.1D  \
        >> stims/${ii}.info

    # output the h (RMSvarErr) and LC (gen lin test) values from .3ddlog 
    # and the correlation ($F[1]) from anticipation vs (no)win from .info
    # space delminted
    echo $i $nTrials $nWin $nCatch $(perl -ne \
        'push @a,$2 if m/.*(h|LC)\[.*norm. std. dev. = *(\d+.\d+)/; END{print join(" ",map(sprintf("%.05f",$_), @a))}'\
          stims/${ii}.3ddlog
     ) $(perl -slane  \
        '$a{$1}=$F[1] if m/anticipation.* (.*?win)/;END{print join(" ",@a{qw/win nowin/})}' \
          stims/${ii}.info
     ) |tee -a $allinfo

    
    ##sum regressor should be zero at some point (according to make_random_stimes.py)
    #1dplot -xlabel Time stims/${ii}_X.xmat.1D'[10]' -ylabel sum
    ##view the whole thing
    #1dplot -sep_scl stims/${ii}_X.xmat.1D
    #1dgrayplot -sep stims/${ii}_X.xmat.1D 
    #
  done
 done
done
done
