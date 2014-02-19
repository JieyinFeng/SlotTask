source('fMRIoptimize.funcs.R')
#######################################################
###########			ISI & ITI DISTRIBUTIONS
#######################################################

# create distributions to sample from
# should have many more short duration than long duration 

iti      <- seq(0.6,2.1,by=0.2)
counts   <- round(exp(iti)) # 2   2   3   3   4   5   6   7
seconds  <- rev(4*iti)      # 8.0 7.2 6.4 5.6 4.8 4.0 3.2 2.4
iti_dist <- rep(seconds,counts)

isi      <- seq(0.4,2.1,by=0.2) 
counts   <- round(2*exp(isi)) # 6  7   9   11  13  16  20  24  30
seconds  <- rev(4*isi)        # 8  7.2 6.4 5.6 4.8 4.0 3.2 2.4 1.6
isi_dist <- rep(seconds,counts)

# > txtdensity(isi_dist,height=10,width=30)
#       +-+**----+------+------++
#   0.2 +** ***                 +
#       |*    ***               |
#  0.15 +       ***             +
#       |         ***           |
#   0.1 +           ****        +
#       |              *****    |
#  0.05 +                  *****+
#       +-+------+------+------*+
#         2      4      6      8




#######################################################
###########			TRIAL TYPE DISTRIBUTIONS
#######################################################
#
# 2 trial types, win or lose 
# considerations
#  * we want to win 1/4 of the time
#  * we need 20min of trials, 
#     trial length is about rsptime(.5?)+.5 + .5 + 1 + mean(isi_dist)+mean(iti_dist)

blockLength <- 20*60
winFrac     <- 1/4
            # button+ spin+ result + reciept + fixations
trialLength <- .5   +  .5 + .5     + 1       + mean(isi_dist)+mean(iti_dist)

nTrials     <- floor(blockLength/trialLength)
nWinTrls    <- ceiling(winFrac*nTrials)

ttype_dist <- rep(1:2, c(nWinTrls, nTrials-nWinTrls) )





# set defaults
current_stim_parameters <- list(
	"eff_winlose"=0,
	"design"=NULL)

stim_parameters <- current_stim_parameters


nIterations<-500;

effs<-array(dim=nIterations)
for (iterations in 1:nIterations) {
	print(iterations)

   design_matrix <-   create_design_matrix(ttype_dist,isi_dist,iti_dist)
	
	
	
	win_vs_lose <- c(1,-1)
	
	eff_winlose <- efficiency(win_vs_lose, design_matrix$design_matrix)

   # record all
   effs[iterations] <- eff_winlose
	
	
	current_stim_parameters <- list(
		"eff_winlose"=eff_rew_size,
		"design"=design_matrix)
	
  	
   # update if eff_winlose is bigger than contender
	if (eff_winlose > stim_parameters$eff_winlose) {
		#for (i in min(length(stim_parameters),4):1) {
		#	stim_parameters[[i+1]] <- stim_parameters[[i]]
		#}
		stim_parameters <- current_stim_parameters
	}

}

plot(1:nIterations,effs); hist(effs)

plot_corr(stim_parameters$design$design_matrix)

stim_parameters$nIterations <- nIterations;
save(stim_parameters, file="optimal_design.Rdata")






