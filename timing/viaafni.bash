#!/usr/bin/env bash

# 20 mins: 1200 seconds
# 108 runs
# 27 win
# 81 no win
# ?? catch
# stims: button+spin=anticipation, win or nowin

# how many times to each
nIts=100
nIts=1

sums=sums.txt
echo "iteration nCatch sum contrast" >  $sums

#nCatch=10
#i=1
for nCatch in 0; do #$(seq 0 5 30); do
  for i in $(seq 1 $nIts); do
    ii=$(printf %02d $nCatch)_$(printf %04d $i)
    python2 $(which make_random_timing.py) -num_runs 1 -run_time 1200             \
          -tr 1.5 \
          -num_stim 5  \
          -stim_labels spinW spinL spinCatch  win nowin \
          -num_reps       27    81 $nCatch     27   81 \
          -stim_dur        1     1 1          1.5  1.5 \
          -ordered_stimuli spinW win                 \
          -ordered_stimuli spinL nowin                 \
          -pre_stim_rest 0 -post_stim_rest 12                   \
          -show_timing_stats -prefix stims/${ii}_stimes \
          #-make_3dd_contrasts -save_3dd_cmd testwith3dd.tsch                 \
          #-min_rest 2 -max_rest 8 
          #  -seed 31415
    
    
    # combine all the spins, as these are not different stims
    # (specifiying them as different allowed us to enfoce an order)
    perl -lne 'print sprintf("%.02f",$&) while(/\d+\.?\d*/g)' stims/${ii}_stimes_*spin*1D | \
       sort -n | tr '\n' ' ' \
       > stims/${ii}_stimes_spin.1D 
    # written easier as
    # timing_.py -timing stims/${ii}_stims_01*spin*1D \
    #            -extend stims/${ii}_stims_02*spin*1D \
    #            -extend stims/${ii}_stims_03*spin*1D \
    #            -sort -write_timing stims/${ii}_stims_spin.1D
    
    # get timing
    3dDeconvolve                                         \
          -nodata 800 1.500                              \
          -polort 9                                      \
          -num_stimts 3                                  \
          -stim_times 1 stims/${ii}_stimes_spin.1D GAM   \
          -stim_label 1 spin                             \
          -stim_times 2 stims/${ii}_stimes_*_win.1D GAM  \
          -stim_label 2 win                              \
          -stim_times 3 stims/${ii}_stimes_*nowin.1D GAM \
          -stim_label 3 nowin                             \
          -gltsym "SYM: win  -nowin" \
          -gltsym "SYM: spin -win" \
          -gltsym "SYM: spin -nowin" \
          -x1D stims/${ii}_X.xmat.1D  2>&1 | tee stims/${ii}.3ddlog 
          #-stim_times 2 stims/${ii}_stimes_*_win.1D 'BLOCK(1.5,1)'     \
          # -stim_times 3 stims/${ii}_stimes_*nowin 'BLOCK(1.5,1)'    \
    
        python2 $(which timing_tool.py) -multi_show_isi_stats \
                                        -multi_stim_dur 1 1.5 1.5 \
                                        -run_len 1200  \
                                        -multi_timing stims/${ii}_stimes_{spin,*win,*nowin}.1D \
            | tee stims/${ii}.ISItiming

    echo $ii $nCatch $(perl -lne \
        '$sum+=$1 if m/.*h\[.*norm. std. dev. = *(\d+.\d+)/; END{print sprintf("%.05f", $sum)}' stims/${ii}.3ddlog
        ) $(perl -lne  \
        '$sum+=$1 if m/.*LC\[.*norm. std. dev. = *(\d+.\d+)/; END{print sprintf("%.05f", $sum)}' stims/${ii}.3ddlog
        ) | tee -a $sums

    
    # sum regressor should be zero at some point (according to make_random_stimes.py)
    # 1dplot -xlabel Time X.xmat.1D'[10]' -ylabel sum
  done
done
