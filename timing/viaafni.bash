#!/usr/bin/env bash

# 20 mins: 1200 seconds
# stims: button+spin=anticipation, win or nowin

TR=1.5
runTime=1200 # 20min*60sec/min
nTR=800; #20*60/1.5

nTrials=108   # total number of trials: 1200/1+4+1.5+4
winRatio=.25  # win 1/4 of the time

# how many iterations between how many catch trials
nIts=50
maxCatch=20
nIts=50

# clear previous run
rm stims/*

sums=sums.txt
echo "iteration nWin nCatch sum contrast" >  $sums
allinfo=info.txt
echo "it nWin nCatch RMSerror.start RMSerror.antic RMSerror.win RMSerror.nowin GLT.w-n GLT.a-w GLT.a-n GLT.a-w-n" |tee $allinfo

for winRatio in .25 .33 .5; do
 for nCatch in $(seq 5 5 $maxCatch); do
  for i in $(seq 1 $nIts); do

    nWin=$(perl -MPOSIX -e "print ceil($winRatio*$nTrials)")

    # do catch trials take away from total nowins?
    #let nNo=$nTrials-$nCatch-$nWin
    # here they do not, so we lose ISI time with catch trials
    let nNo=$nTrials-$nWin

    # name for this iteration: catch_iteration: cc_iiii 
    ii=w$(printf %02d $nWin)_c$(printf %02d $nCatch)_$(printf %04d $i)

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
          -stim_labels spinW spinN spinCatch   win nowin \
          -num_reps    $nWin $nNo $nCatch    $nWin  $nNo \
          -stim_dur        1    1       1      1.5   1.5 \
          -ordered_stimuli spinW win                   \
          -ordered_stimuli spinN nowin                 \
          -pre_stim_rest 0 -post_stim_rest 12           \
          -min_rest 1                                   \
          -show_timing_stats -prefix stims/${ii}_stimes \
          > stims/${ii}.makerandtimelog 2>&1 
          #-make_3dd_contrasts -save_3dd_cmd testwith3dd.tsch                 \
          #-min_rest 2 -max_rest 8 
          #  -seed 31415
    
    
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
          -stim_times 3 stims/${ii}_stimes_*_win.1D 'BLOCK(1.5,1)'    \
          -stim_label 3 win                                \
          -stim_times 4 stims/${ii}_stimes_*nowin.1D 'BLOCK(1.5,1)' \
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
    python2 $(which 1d_tool.py) -cormat_cutoff 0.1 -show_cormat_warnings -infile stims/${ii}_X.xmat.1D  \
        >> stims/${ii}.info

    # output the trial number, the number of catch trials
    #        sum root mean square of the measurement error variance for each condition (lower is better)
    #        general linear test (http://afni.nimh.nih.gov/pub/dist/doc/manual/3dDeconvolve.pdf pg43)
    echo $ii $nWin $nCatch $(perl -lne \
        '$sum+=$1 if m/.*h\[.*norm. std. dev. = *(\d+.\d+)/; END{print sprintf("%.05f", $sum)}' stims/${ii}.3ddlog
        ) $(perl -lne  \
        '$sum+=$1 if m/.*LC\[.*norm. std. dev. = *(\d+.\d+)/; END{print sprintf("%.05f", $sum)}' stims/${ii}.3ddlog
        ) >> $sums


    # output without collapsing/summing
    echo $i $nWin $nCatch $(perl -ne \
        'push @a,$2 if m/.*(h|LC)\[.*norm. std. dev. = *(\d+.\d+)/; END{print join(" ",map(sprintf("%.05f",$_), @a))}' stims/${ii}.3ddlog
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
