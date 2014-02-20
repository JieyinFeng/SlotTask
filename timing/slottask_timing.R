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
trialLength <- 1   +  .5 + .5     + 1       + mean(isi_dist)+mean(iti_dist)

nTrials     <- floor(blockLength/trialLength)
nWinTrls    <- ceiling(winFrac*nTrials)

ttype_dist <- rep(1:2, c(nWinTrls, nTrials-nWinTrls) )

# set defaults
current_stim_parameters <- list(
	"eff_sum"=0,
	"design"=NULL)

stim_parameters <- current_stim_parameters


nIterations<-500;

effs<-list()
# contrasts                 c(anticipation,win,lose)
cntrsts <- list(
  win_vs_lose             = c(0,1,-1),
  anticipation_vs_outcome = c(2,-1,-1),
  anticipation            = c(1,0,0),
  win                     = c(0,1,0),
  lose                    = c(0,0,1)
)

for (iterations in 1:nIterations) {
	print(iterations)

   design_matrix <-   create_design_matrix(ttype_dist,isi_dist,iti_dist)
	
	
	# solve each contrast with the design matrix
   # efficiency is a function defined in fMRIoptimize.funcs.R
	efficencies <- lapply(cntrsts,efficiency,design_matrix$design_matrix)

   # record all
   effs[[iterations]] <-efficencies ;

   effsum<-Reduce('+', efficencies )
	
	
	current_stim_parameters <- list(
		 efficencies=efficencies,
		     eff_sum=effsum,
		      design=design_matrix)
	
  	
   # update if eff_winlose is bigger than contender
	if (effsum > stim_parameters$eff_sum) {
		#for (i in min(length(stim_parameters),4):1) {
		#	stim_parameters[[i+1]] <- stim_parameters[[i]]
		#}
		stim_parameters <- current_stim_parameters
	}

}

plot(1:nIterations,effs);x11(); hist(effs)

plot_corr(stim_parameters$design$design_matrix)

stim_parameters$nIterations <- nIterations;
save(stim_parameters, file="optimal_design.Rdata")






