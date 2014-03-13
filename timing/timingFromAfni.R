######
#
# R functions for dealing with stim files 
#  these are the files given to 3dDeconvolve (from make_random_stimtimes.py)
# 
#####
# ASSUMES:
#   # reading in
#    stim files are stims/xxxxx_stims_{spin,04_win,05_nowin}.1D
#    (and that the new file should be  ..._anticipation.1d ) 
#   # for fmri.stimulus
#    resposne time is always 1 for slotstart
#    youwin+receipt is 1.5
#
#
# functions to:
# - read stim files
# - see timing
# - get efficency
# - save as matfile
#
# 20140311 WF
######
library(reshape2)
#library(fmri) # for fmri.stimulus -- to gerenrate hrf

tr <- 1.5

# event durations
slotstartduration <- 1 # estimate RT
receiptduration   <- 1 # how long will they see you win + total wins

# only used for fmri.stimulus -- which 3ddeconvolve does better already?
#run.sec <- 1200
run.sec <- 200

# design mat efficency
eff <- function(c,dm) { solve( t(c) %*% solve(t(dm) %*% dm) %*% c ) }
# from DPs implementation
# see Henson 2007. "Efficient Experimental Design for fMRI."

# load files and setup timing
getStimTime <- function(iteration) {
  # get all the times by reading in each 1D file made by make_random_stimes.py
  stimfiles <- c('slotstart','04_win','05_nowin')
  st <- sapply(stimfiles, function(x){
              strsplit(
                # suppress warning about no newline
                suppressWarnings( readLines(
                     paste0("stims/",iteration,"_stimes_",x,".1D")
                     ) ),
                "[[:space:]]+") 
      })

  # melt them into a dataframe, rename, and sort
  st.df <- melt(sapply(st,function(x){as.numeric(as.character(x))}))
  names(st.df)<-c('onset','type')
  st.df$type <- gsub('\\d+_','',st.df$type) # remove number in type name
  st.df <- st.df[sort(st.df$onset,index.return=T)$ix,]

  # duration for everythign but slotstart is 1.5
  #TODO: make this loop over settings
  st.df$duration<-receiptduration
  st.df$duration[st.df$type=='slotstart']<-slotstartduration
  # when does stim go off
  st.df$offset <- st.df$onset+st.df$duration

  # isi/iti
  st.df$nextwait <- signif(c(st.df$onset[2:nrow(st.df)] - st.df$offset[1:nrow(st.df)-1], 0),4)
  return(st.df)
}

# anticipation is the ISI between slotstart button push and win/nowin
writeAnticipation <- function(st.df,iteration) {
  starttype=st.df$type=='slotstart'
  # afni uses ":" to "marry" information
  married <- paste(sep=":",st.df$onset[starttype]+st.df$duration[starttype],st.df$nextwait[starttype])
  # putput to file
  sink( file.path('stims',paste0(iteration,"_stimes_anticipation.1D")) )
  cat(married) #,"\n") # afni doesn't make newline files,why should we
  sink()
}
# we want timing for this set of stim times in a .mat 
genMAT <- function(st.df,name) {
 # ISI's are the actually important bit 
 #order is 'Block','Spin','ISI','Result','Receipt','ITI','WIN','Score'
 # where 
 #  Block   implemented in matlab
 #          the same for e.g. the 36 trials in this block
 #  Spin    how long the spin picture is displayed
 #  Result  how long result is displayed
 #  ITI     how long before the next trial
 #  Score   if this is win, score is 1, otherwise 0
 #
 #  TODO: REMOVE 
 #  ISI     Spin is ISI
 #  Receipt Result will tell score if needed
 startinds <- which(st.df$type=='slotstart')

 timing=matrix(0,length(startinds),4)
 mati=1;
 for(si in startinds ){ 
   starttime <- st.df$onset[si]    # ignored, we assumed avgRT -- person will not respond same
   startlen  <- st.df$duration[si] # ignored, for the same reason
   
   spinlen   <- st.df$nextwait[si] # time between button push and score

   # and if this is not a catch trial
   if(nrow(st.df)>si && st.df$type[si+1] != 'slotstart'){
      resultlen <- st.df$duration[si+1]    # should be constant (1s)
      ITIlen    <- st.df$nextwait[si+1]    
      score     <- ifelse(st.df$type[si+1]=='win',1,0)

   # otherwise, zero everything
   }else{
      resultlen <- 0
      ITIlen    <- 0 
      score     <- 0
   }
   
   timing[mati,]=cbind(spinlen,resultlen,ITIlen,score)
   mati<-mati+1
 }
 
 return(timing)
 require(R.matlab)
 writeMat(con=file.path('mats',paste0(name,".mat")), block=timing)
}

visTiming <- function(st.df) {
 require(gridExtra)
 # also see repeats
 print(tail(sort(rle(st.df$type[st.df$type!='slotstart'])$lengths)))
 print(summary(st.df$nextwait))

 # ggplot to see actual order
 # hist to see exp dist of isi (and iti)  (with last isi (0.0) removed)
 ptim <- ggplot(st.df,aes(x=onset,y=type,color=type))+geom_segment(aes(xend=offset,yend=type))+theme_bw() #+ scale_x_continuous(limits=c(0,200)) )
 phist <- qplot(geom='histogram',x=st.df$nextwait[-nrow(st.df)],binwidth=1)+theme_bw() + scale_x_continuous(limits=c(1,9),breaks=c(2:8))
 grid.arrange(phist,ptim,nrow=2)
}

vis3DDout <- function() {
 # read in table input that we generated from 3ddeconvolve (and perl)
 a<-read.table(sep=" ",'info.txt',header=T)
 # put each iteration type (num wins and num catches) into long format
 a.m <- melt(a,id.vars=c('it','nWin','nCatch'))
 # add combined catch-win id
 a.m$cw <- paste0(a.m$nCatch,'c',a.m$nWin,'w')

 #pp <- ggplot(a.m,aes(x=variable,y=value,color=cw))+geom_boxplot()+theme_bw()
 pp <- ggplot(a.m,aes(x=variable,y=value,color=cw))+geom_jitter(height=0,alpha=.4) + geom_violin()+theme_bw()


 #p<-ggplot(a.m,aes(x=value,linetype=cw,fill=cw ) ) + geom_density(alpha=.7) +theme_bw()+theme(legend.position="none")
 # + scale_fill_brewer(palette="Set1")

 #require(gridExtra)
 #pp <- grid.arrange(p+facet_grid(~variable,scale="free_x"),p+facet_grid(~cw),nrow=2)

 return(pp)
}

getEffs <- function(st.df){

  # design matrix is fmri.stimulus for each EV (slotstart,win,nowin)
  dmat<-sapply(c('slotstart','win','nowin'),
                function(x){fmri.stimulus(
                         scans=run.sec/tr,
                         duration=st.df$duration[st.df$type==x],
                         rt=tr, times=st.df$onset[st.df$type==x]   )})

 return(list(winMnowin=eff(c(0, 1,-1),dmat), 
               allStim=eff(c(1, 1, 1),dmat),
             startMwin=eff(c(1,-1, 0),dmat),
           startMnowin=eff(c(1, 0,-1),dmat)
   ))
}
