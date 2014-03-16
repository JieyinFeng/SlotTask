#!/usr/bin/env bash

# we have 20 minutes (800 tp @ 1.5 TR) for each block
#  1. buttonPush+Spin 1sec (assume RT =1s)
#  2. win or lose  +Receipt    1.5s
# 2.5s + avg 4s gitter + 4s ITI = 10.5s per block
# lets say about 108 trials (7 less than max at 1s response rate)
# 1/4 should be win trials (27) 3/4 are lose (81 trials)
#
od=optseqout
# first order counter balance matrix
focb=focb.mat
#-- order of events
#       spin win lose
# spin   0   .25  .75
# win    1    0    0
# lose   1    0    0
echo   "0   .25  .75" > $focb
echo   "0   .25  .75" >> $focb
echo   "1    0    0"  >> $focb


./optseq2  --tr 1.5 --tprescan 0 --ntp 800 \
           --o $od/slottasktiming  --cmtx $od/contrast --mtx  $od/design \
           --sum $od/summary --log $od/log \
           --psdwin .5 8 .5 \
           --ev bpspin 1   108 \
           --ev win    1.5  27 \
           --ev lose   1.5  81 \
           --tnullmin 2 \
           --tnullmax 8 \
           --tsearch .1 \
           --focb $fobc \
           --nkeep 50 \

