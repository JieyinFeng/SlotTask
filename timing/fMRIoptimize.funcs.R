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

###########		RANDOMIZE 
###########		THIS IS SPECIFIC FOR THIS PARADIGM IN COMPARING TTYPES 1 VS 2 (CEILING TTYPE/8)
## given a trial type distribution (vector 1-16 of EVs?), resample it
## resampled dist will not have more than 2 types (1-8 or 8-16) in a row 
randomize_ttypes <- function(ttype_dist, types_in_a_row=3) {

   # could be written
   #   current_random_dist <- sample(ttype_dist, length(ttype_dist))
   #   while ( max(rle(ceiling(randomize_ttypes(ttype_dist[[1]])/8))$length) >= types_in_a_row ) )
   #      current_random_dist <- sample(ttype_dist, length(ttype_dist))
   #   return(current_random_dist)

	add_to_length = types_in_a_row - 1
	repeated_trials = T


	while (repeated_trials == T) {
		current_random_dist <- sample(ttype_dist, length(ttype_dist))


		current_pred_cue_dist <- ceiling(current_random_dist/8) # ttypes 1-8 pred, 9-16 unpred
		repetitions_found <- F

		# CHECK FOR REPEATS, SKIP TO NEXT ITERATION IF REPEATS ARE FOUND
		for (i in 1:(length(current_pred_cue_dist) - add_to_length)) {
			if ( mean(current_pred_cue_dist[i:(i+add_to_length)] == current_pred_cue_dist[i]) == 1) {
				repetitions_found <- T
				break
			} # end if mean trials = 1
		} # end for num trials

		# CHANGE REPETITION FLAG IF REPEATS WERE NOT FOUND
		if (repetitions_found == F) {
			repeated_trials <- F			
		}

	} # end while repeated_trials

	current_random_dist	

}



### take ttype 1-16 and deduce pred_cue, rew_cue, and outcome
#> do.call(rbind,lapply(1:16,return <- EVs))
#   pred <- cueEV rew <- cueEV outcomeEV
#   1           1         3        11
#   2           1         5        11
#   3           1         3        14
#   4           1         5        14
#   5           1         4        12
#   6           1         6        12
#   7           1         4        13
#   8           1         6        13
#   9           2         7        15
#   10          2         9        15
#   11          2         7        16
#   12          2         9        16
#   13          2         8        15
#   14          2        10        15
#   15          2         8        16
#   16          2        10        16


return_EVs <- function(ttype) {
   # also written as
   #
   # translate ttype into pred rew and outcome types
   #
   # #                 1    2
   # predlist <- list(1:8,9:16)
   #
   # #                    3       4        5      6      7          8        9      10
   # rewlist  <- list( c(1,3),c(5,7), c(2,4), c(6,8), c(9,11),c(13,15), c(10,12),c(14,16) )
   #
   # #                    11     12       13     14      15            16
   # outlist  <- list( c(1,2),c(5,6), c(7,8), c(3,4), c(9,10,13,14), c(11,12,15,16) )
   # # where ttype matches in the lists deterims what pred,rew,and outcome type are
   # pred_cue <- which(sapply(predlist,function(x){ ttype %in% x})
   # rew_cue  <- which(sapply(rewlist, function(x){ ttype %in% x}) + 2
   # outcome  <- which(sapply(outlist, function(x){ ttype %in% x}) + 10
   #

	if (ttype %in% 1:8) {
		pred_cue <- 1
		# rew cue
		if (ttype %in% c(1,3)) {
			rew_cue <- 3
		} else if (ttype %in% c(5,7)) {
			rew_cue <- 4
		} else if (ttype %in% c(2,4)) {
			rew_cue <- 5
		} else if (ttype %in% c(6,8)) {
			rew_cue <- 6
		}
		# outcome
		if (ttype %in% c(1,2)) {
			outcome <- 11
		} else if (ttype %in% c(5,6)) {
			outcome <- 12
		} else if (ttype %in% c(7,8)) {
			outcome <- 13
		} else if (ttype %in% c(3,4)) {
			outcome <- 14
		}		
		
	} else {
		pred_cue <- 2
		# rew cue
		if (ttype %in% c(9,11)) {
			rew_cue <- 7
		} else if (ttype %in% c(13,15)) {
			rew_cue <- 8
		} else if (ttype %in% c(10,12)) {
			rew_cue <- 9
		} else if (ttype %in% c(14,16)) {
			rew_cue <- 10
		}
		# outcome
		if (ttype %in% c(9,10,13,14)) {
			outcome <- 15
		} else if (ttype %in% c(11,12,15,16)) {
			outcome <- 16
		}
	} # end pred (1-8) or unpred (9-16)
	
	data.frame(pred_cueEV=pred_cue, rew_cueEV=rew_cue, outcomeEV=outcome)
	
} # end function

### 
# randomize list of events
#
# output like
#  $trials_list
#   trial_num ttype info_cue rew_cue outcome info_onset isi1 cue_onset isi2 rew_onset iti
#   1         1     4        1       5      14        0.0  1.6       3.6  8.0      13.6 3.2
#   2         2     5        1       4      12       18.8  2.4      23.2  1.6      26.8 5.6

create_design_matrix <- function(ttype_dist) {
	
	current_ttype_dist <- randomize_ttypes(ttype_dist, 5)
	
	# intialize iterated variables
	# explanitory var
	EVs <- vector("list", 16)
	EV_durations <- vector("list", 16)
	current_event_time = 0
	
	# 2 sets of isis, 1 set of iti
	current_isi_dist <- list()
	current_isi_dist[[1]] <- sample(isi_dist, length(current_ttype_dist), replace=T)
	current_isi_dist[[2]] <- sample(isi_dist, length(current_ttype_dist), replace=T)
	current_iti_dist <- sample(iti_dist, length(current_ttype_dist), replace=T)
	
	
   # dataframe that will hold each trials onset and cue/prep/reward types
	trials_list <- data.frame(matrix(nrow=length(current_ttype_dist),ncol=11))
	names(trials_list) <-c("trial_num", "ttype", "info_cue", "rew_cue", "outcome", 
			"info_onset", "isi1", "cue_onset", "isi2", "rew_onset", "iti")
	
   # for each trial
   #  1. set get onset time (incremented at each event)  
   #  2. build list of EV@time for design matrix (second each ev happens, varaible length)
   #  3. build dataframe row (onset and trial type for rew/cue/out)
	for (trial in 1:length(current_ttype_dist)) {
		
		ev_list <- return_EVs(current_ttype_dist[trial]) # pred_cueEV rew_cueEV outcomeEV

		info_onset <- current_event_time
		# 1 PREDICTION SYMBOL
		EVs[[ev_list$pred_cueEV]] <- c(EVs[[ev_list$pred_cueEV]], current_event_time) # add current time to EV list
		info_cue_duration = 2
		EV_durations[[ev_list$pred_cueEV]] <- c(EV_durations[[ev_list$pred_cueEV]], info_cue_duration) # add current time to EV list
		current_event_time <- current_event_time + info_cue_duration
	
		# 2 FIRST ISI	
		current_event_time <- current_event_time + current_isi_dist[[1]][trial]	
		
		
		cue_onset <- current_event_time
		# 3 REWARD CUE IMAGE	
		EVs[[ev_list$rew_cueEV]] <- c(EVs[[ev_list$rew_cueEV]], current_event_time) # add current time to EV list
		rew_cue_duration = 2
		EV_durations[[ev_list$rew_cueEV]] <- c(EV_durations[[ev_list$rew_cueEV]], rew_cue_duration) # add current time to EV list
		current_event_time <- current_event_time + rew_cue_duration
	
		# 4 SECOND ISI
		current_event_time <- current_event_time + current_isi_dist[[2]][trial]	
		
		rew_onset <- current_event_time
		# 5 REWARD OUTCOME
		EVs[[ev_list$outcomeEV]] <- c(EVs[[ev_list$outcomeEV]], current_event_time) # add current time to EV list
		outcome_duration = 2
	
		EV_durations[[ev_list$outcomeEV]] <- c(EV_durations[[ev_list$outcomeEV]], outcome_duration) # add current time to EV list
		current_event_time <- current_event_time + outcome_duration
	
		# 6 ITI
		current_event_time <- current_event_time + current_iti_dist[trial]	
		
		trials_list[trial,] <- c(trial, current_ttype_dist[trial], ev_list$pred_cueEV, ev_list$rew_cueEV, ev_list$outcomeEV,
			info_onset, current_isi_dist[[1]][trial], cue_onset, current_isi_dist[[2]][trial], rew_onset, current_iti_dist[trial])
		
		
		
		
	}
	
	max_time <- max(unlist(EVs))
	TR = 1.5
	n_vols = ceiling(max_time / TR) + 10
	
	design_matrix <- matrix(nrow=n_vols, ncol=16)
	
	for (current_EV in 1:16) {
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
