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
run.sec <- 1200

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
  st.df$duration<-1.5
  st.df$duration[st.df$type=='slotstart']<-1
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
getMAT <- function(st.df) {
 # ISI's are the actually important bit 
}

visTiming <- function(st.df) {
 # also see repeats
 tail(sort(rle(st.df$type[st.df$type!='slotstart'])$lengths))

 ggplot(st.df,aes(x=onset,y=type,color=type))+geom_segment(aes(xend=offset,yend=type))+theme_bw()+ scale_x_continuous(limits=c(0,200))
 x11()
 # see exp dist of isi (and iti)
 hist(st.df$nextwait)
}

vis3DDout <- function() {
 # read in table input that we generated from 3ddeconvolve (and perl)
 a<-read.table(sep=" ",'info.txt',header=T)
 # put each iteration type (num wins and num catches) into long format
 a.m <- melt(a,id.vars=c('it','nWin','nCatch'))
 # add combined catch-win id
 a.m$cw <- paste0(a.m$nCatch,'c',a.m$nWin,'w')

 pp <- ggplot(a.m,aes(x=variable,y=value,color=cw))+geom_boxplot()+theme_bw()


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
