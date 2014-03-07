#!/usr/bin/env bash

# 20 mins: 1200 seconds
# 108 runs
# 27 win
# 81 no win
# ?? catch
# stims: button+spin=anticipation, win or lose

python2 $(which make_random_timing.py) -num_runs 1 -run_time 1200             \
      -tr 1.5 \
      -num_stim 3  \
      -stim_labels spin win lose \
      -num_reps 108  27  81                               \
      -stim_dur 1   1.5 1.5                               \
      -ordered_stimuli spin win                 \
      -ordered_stimuli spin lose                 \
      -pre_stim_rest 0 -post_stim_rest 2                   \
      -save_3dd_cmd testwith3dd.tsch                 \
      -show_timing_stats -seed 31415 -prefix stimesH

