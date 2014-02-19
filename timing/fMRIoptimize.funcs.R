# FROM DAVID PAULSEN 2013-10-26
# Optimize jittering for fMRI event related design
# see doi:10.1016/j.neuroimage.2006.09.019

library(fmri)
#library(neuRosim)

#######################################################
###########			FUNCTIONS
#######################################################

###########			EFFICIENCY FUNCTIONS
D <- function (design_vector) {
   ## peak to peak bold (min/max) given ITI and ISI
	PPheight <- max(design_vector) - min(design_vector)
	PPheight / sqrt(t(design_vector) %*% design_vector)
}
 
# see also FSL man page and list
# -- also white papers
efficiency <- function (contrasts, design_matrix) {
	solve( t(contrasts) %*% solve(t(design_matrix) %*% design_matrix) %*% contrasts )
}



plot_corr <- function(mat, label=c()) {
	corr <- cor(mat)
	nr <- nrow(corr)
	corr2 <- t(corr[nr:1, ])
	grayscale <- gray(seq(0,0.9,length=120))
	if (length(label) == ncol(mat)) { 
		# plot using abs so that colors correspond to absolute correlation
		# text values can be printed as positive or negative values
		par(mar=c(4.1,7,4.1,2.1))
		image(1:nr, 1:nr, abs(corr2), axes = F, ann = F, col = grayscale)
		axis(side=3, labels=label, at=1:nr)
		axis(side=2, labels=label, at=nr:1, las=1)
		text(rep(1:nr, nr), rep(1:nr, each = nr), round(100*corr2), col="yellow")
	} else { 
		# plot using abs so that colors correspond to absolute correlation
		# text values can be printed as positive or negative values
		write("length(label) != ncol(mat): labels will not be used", stdout())
		image(1:nr, 1:nr, abs(corr2), axes = F, ann = F, col = grayscale)
		text(rep(1:nr, nr), rep(1:nr, each = nr), round(100*corr2), col="yellow")
	}
	
	write("Estimated SVD eigenvector", stdout())
	round(svd(mat)$d/max(svd(mat)$d), digits=3)
}

# randomize list of events
#
# output like
#  $trials_list
#   trial_num ttype info_cue rew_cue outcome info_onset isi1 cue_onset isi2 rew_onset iti
#   1         1     4        1       5      14        0.0  1.6       3.6  8.0      13.6 3.2
#   2         2     5        1       4      12       18.8  2.4      23.2  1.6      26.8 5.6

create_design_matrix <- function(ttype_dist,isi_dist,iti_dist) {
   # this should come in from the function? 
	TR <- 1.5
   # fixed timing (not isi or iti)
   duration <- data.frame('spin'=.5,'win'=.5,'receipt'=1)
   # anticipation is an EV but not in ttype_dist, so + 1 
   nTrlTyps <- length(unique(ttype_dist)) + 1
	
	# resample distributions
	current_ttype_dist <- sample(ttype_dist)

   # make sure we dont have thigns repeating too much
   maxwinrepeat  <- 3
   maxloserepeat <-6
   ttrl <- rle(current_ttype_dist)
   while(max(ttrl$lengths[ttrl$values==1])>maxwinrepeat ||
         max(ttrl$lengths[ttrl$values==2])>maxloserepeat   ){
     current_ttype_dist <- sample(current_ttype_dist)
     ttrl <- rle(current_ttype_dist)
   }

	current_isi_dist   <- sample(isi_dist, length(current_ttype_dist), replace=T)
	current_iti_dist   <- sample(iti_dist, length(current_ttype_dist), replace=T)
	
	# intialize iterated variables
	# explanitory var
	EVs <- vector("list", nTrlTyps) 
	EV_durations <- vector("list", nTrlTyps)
	current_event_time = 0
	
	
	
   # dataframe that will hold each trials onset and cue/prep/reward types
	#trials_list <- data.frame(matrix(nrow=length(current_ttype_dist),ncol=11))
	#names(trials_list) <-c("trial_num", "ttype", "info_onset", "win_onset","isi","iti")
   trials_list <- data.frame()
	
   # for each trial
   #  1. set get onset time (incremented at each event)  
   #  2. build list of EV@time for design matrix (second each ev happens, varaible length)
   #  3. build dataframe row (onset and trial type for rew/cue/out)
	for (trial in 1:length(current_ttype_dist)) {
        # TODO: what if this is random?
	    # df$buttonpush <- sample( rep(seq(.3,1,.1),  rev(round(sapply(1:8/3,exp))) ), 1 )
	    # ... run a bunch of simulations
        duration$buttonpush <- 1


		df <-data.frame(trial_num=trial, ttype=current_ttype_dist[trial], 
                      isi=current_isi_dist[trial], iti=current_iti_dist[trial]
                     )


        
		
        #### 0.1: see stimulus
        #current_event_time <- current_event_time
		
		#### 0.2: BUTTON PUSH (EV is anticipation)
        trialtype<-1 # this is not variable -- they always have to push a button (always the same screen)
        # update time first, anticipation is what we're after -- it's after the button push
		current_event_time <- duration$buttonpush + current_event_time
	    df$buttonRelease <- current_event_time 
        # update EV list
	    EVs[[trialtype]] <- c(EVs[[trialtype]], current_event_time) 
	    EV_durations[[trialtype]] <- c(EV_durations[[trialtype]], duration$buttonpush) 

        
        #### 1 SPIN
        current_event_time <- current_event_time + duration$spin
	

		#### 2 ISI	
		current_event_time <- current_event_time + df$isi
		
		

		##### 3: WIN OR LOSE  (actual receipt?)
		# win (2) or lose (3)
        trialtype <- current_ttype_dist[trial] + 1
    
        # update data frame
		df$win_onset <- current_event_time
    
        # add to EVs
		EVs[[trialtype]] <- c(EVs[[trialtype]], current_event_time) 
		EV_durations[[trialtype]] <- c(EV_durations[[trialtype]], duration$win) 
	
		# update time
		current_event_time <- current_event_time + duration$win
	

        ##### 4: receipt
		current_event_time <- current_event_time + duration$receipt
		
		##### 6 ITI
		current_event_time <- current_event_time + df$iti
		
		#trials_list[trial,] <- c(trial, current_ttype_dist[trial], ev_list$pred_cueEV, ev_list$rew_cueEV, ev_list$outcomeEV,
		#	info_onset, current_isi_dist[[1]][trial], cue_onset, current_isi_dist[[2]][trial], rew_onset, current_iti_dist[trial])
		trials_list <- rbind(trials_list,df)
		
		
		
	}
	
	max_time <- max(unlist(EVs))
	n_vols = ceiling(max_time / TR) + 10
	
	design_matrix <- matrix(nrow=n_vols, ncol=nTrlTyps)
	
	for (current_EV in 1:nTrlTyps) {
		design_matrix[, current_EV] <- fmri.stimulus(scans=n_vols, durations = EV_durations[[current_EV]], rt=TR, times=EVs[[current_EV]])
	}


	list("trial_order"=current_ttype_dist,
		"trials_list"=trials_list,
		"onset_times"=EVs,
		"durations"= EV_durations,
		"design_matrix"=design_matrix,
		"TR"=TR)


}
#### end functions ####
