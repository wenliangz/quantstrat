### Sharpe ratio adjustment due to testing multiplicity ------ Harvey and Liu
### (2014): "Backtesting", Duke University 

# Haircut_SR <- function(sm_fre, num_obs, SR, ind_an, ind_aut, rho, num_test, RHO){
Haircut_SR <- function(){

###############################
####### Parameter inputs ######
  
### 'sm_fre': Sampling frequency; [1,2,3,4,5] = [Daily, Weekly, Monthly, Quarterly, Annual]; 
### 'num_obs': No. of observations in the frequency specified in the previous step; 
### 'SR': Sharpe ratio; either annualized or in the frequency specified in the previous step;
### 'ind_an': Indicator; if annulized, 'ind_an' = 1; otherwise = 0; 
### 'ind_aut': Indicator; if adjusted for autocorrelations, 'ind_aut' = 0; otherwise = 1;
### 'rho': Autocorrelation coefficient at the specified frequency ;
### 'num_test': Number of tests allowed, Harvey, Liu and Zhu (2014) find 315 factors;
### 'RHO': Average correlation among contemporaneous strategy returns.
  
### Calculating the equivalent annualized Sharpe ratio 'sr_annual', after 
### taking autocorrelation into account 

  # 1. sm_fre
  p <- getPortfolio(portfolio.st)
  freq <- periodicity(p$summary)$scale
  sm_fre <- switch (freq,
          "daily" = 1,
          "weekly" = 2,
          "monthly" = 3,
          "quarterly" = 4,
          "yearly" = 5)
  # 2. num_obs
  num_obs <- nrow(p$summary)
  
  # 3. Sharpe ratio of strategy returns
  SR <- max(stats$Ann.Sharpe, na.rm = TRUE) # Beware: Excessive annualized Sharpe ratios could be the result of short profitable backtests
  SR_index <- which(stats$Ann.Sharpe == SR) # potentially use later to determine which test yielded optimal SR
  
  # 4. SR annualized? (1=Yes)
  if(SR == max(stats$Ann.Sharpe, na.rm = TRUE)){ # Beware: Excessive annualized Sharpe ratios could be the result of short profitable backtests
    ind_an <- 1
  } else {
    ind_an <- NULL # is Sharpe ratio takes from stats object returned in apply.paramsets, which is annualized?
  }
  
  # 5. AC correction needed? (0=Yes), and per Brian for any quantstrat return series, autocorrelation adjustment will be required.
  ind_aut <- 0
  
  # 6. AC level
  roc <- ROC(cumsum(p$summary$Net.Trading.PL))
  ACF <- acf(roc, na.action = na.pass, plot = FALSE)
  rho <- ACF$acf[[2]] # assume autocorrelation coefficient for lag = 1 is suitable for now
  
  # 7. # of tests assumed
  num_test <- getStrategy(portfolio.st)$trials
  
  # 8. Average correlation assumed
  RHO <- 0.2 # use the assumption from HLZ (and the Cross-Section of Expected Returns) p.32-33 Section 5.3
  
if(sm_fre == 1){
  fre_out <- 'Daily'
  } else if(sm_fre == 2){ 
    fre_out <- 'Weekly'
    } else if(sm_fre == 3){ 
      fre_out <- 'Monthly'
         } else if(sm_fre == 4){ 
            fre_out <- 'Quarterly'
            } else {
              fre_out <- 'Annual'
              }

if(ind_an == 1){
  sr_out <- 'Yes'
  } else {
    sr_out <- 'No'
  }


if(ind_an == 1 & ind_aut == 0){
  sr_annual <- SR
  } else if(ind_an ==1 & ind_aut == 1){
    if(sm_fre ==1){
      sr_annual <- SR*(1 + (2*rho/(1-rho))*(1- ((1-rho^(360))/(360*(1-rho)))))^(-0.5)
      } else if(sm_fre ==2){
          sr_annual <- SR*(1 + (2*rho/(1-rho))*(1- ((1-rho^(52))/(52*(1-rho)))))^(-0.5)
          } else if(sm_fre ==3){
              sr_annual <- SR*(1 + (2*rho/(1-rho))*(1- ((1-rho^(12))/(12*(1-rho)))))^(-0.5)
              } else if(sm_fre ==4){
                  sr_annual <- SR*(1 + (2*rho/(1-rho))*(1- ((1-rho^(4))/(4*(1-rho)))))^(-0.5)
                  } else if(sm_fre ==5){
                    sr_annual <- SR
                  }
  } else if(ind_an == 0 & ind_aut == 0){
      if(sm_fre ==1){ 
        sr_annual <- SR*sqrt(360)
        } else if(sm_fre ==2){
            sr_annual <- SR*sqrt(52)
            } else if(sm_fre ==3){
                sr_annual <- SR*sqrt(12)
                } else if(sm_fre ==4){
                  sr_annual <- SR*sqrt(4)
                    } else if(sm_fre ==5){
                      sr_annual = SR
                    }
  } else if(ind_an == 0 & ind_aut == 1){
      if(sm_fre ==1){ 
        sr_annual <- sqrt(360)*sr*(1 + (2*rho/(1-rho))*(1- ((1-rho^(360))/(360*(1-rho)))))^(-0.5)
        } else if(sm_fre ==2){
            sr_annual <- sqrt(52)*sr*(1 + (2*rho/(1-rho))*(1- ((1-rho^(52))/(52*(1-rho)))))^(-0.5)
            } else if(sm_fre ==3){
              sr_annual <- sqrt(12)*sr*(1 + (2*rho/(1-rho))*(1- ((1-rho^(12))/(12*(1-rho)))))^(-0.5);
              } else if(sm_fre ==4){
                sr_annual <- sqrt(4)*sr*(1 + (2*rho/(1-rho))*(1- ((1-rho^(4))/(4*(1-rho)))))^(-0.5)
                } else if(sm_fre ==5){
                  sr_annual <- SR
                }
  }

### Number of monthly observations 'N' ###
  
if(sm_fre ==1){ 
  N <- floor(num_obs*12/360)
  } else if(sm_fre ==2){
      N <- floor(num_obs*12/52)
      } else if(sm_fre == 3){
          N <- floor(num_obs*12/12)
          } else if(sm_fre == 4){
              N <- floor(num_obs*12/4)
              } else if(sm_fre == 5){
                  N <- floor(num_obs*12/1)
              }

### Number of tests allowed ###
M <- num_test;


###########################################
########### Intermediate outputs ##########
print('Inputs:')
print(paste('Frequency =', fre_out))
print(paste('Number of Observations = ', num_obs))
print(paste('Initial Sharpe Ratio = ', SR))
print(paste('Sharpe Ratio Annualized = ', sr_out))
print(paste('Autocorrelation = ', rho))
print(paste('A/C Corrected Annualized Sharpe Ratio = ', sr_annual))
print(paste('Assumed Number of Tests = ', M))
print(paste('Assumed Average Correlation = ', RHO))

############################################
########## Sharpe ratio adjustment #########

m_vec <- 1:(M+1);
c_const <- sum(1./m_vec);

########## Input for Holm & BHY ##########
### Parameter input from Harvey, Liu and Zhu (2014) %%%%%%%
para0 <- matrix(c(0, 1295, 3.9660*0.1, 5.4995*0.001,
                  0.2, 1377, 4.4589*0.1, 5.5508*0.001,
                  0.4, 1476, 4.8604*0.1, 5.5413*0.001,
                  0.6, 1773, 5.9902*0.1, 5.5512*0.001,
                  0.8, 3109, 8.3901*0.1, 5.5956*0.001),
                nrow = 5, ncol = 4, byrow = TRUE)
### Interpolated parameter values based on user specified level of correlation RHO %%%%%%%%%%   
if (RHO >= 0 & RHO < 0.2){ 
  para_inter <- ((0.2 - RHO)/0.2)*para0[1,] + ((RHO - 0)/0.2)*para0[2,]
} else if (RHO >= 0.2 & RHO < 0.4) {
  para_inter <- ((0.4 - RHO)/0.2)*para0[2,] + ((RHO - 0.2)/0.2)*para0[3,]
} else if (RHO >= 0.4 & RHO < 0.6){
  para_inter <- ((0.6 - RHO)/0.2)*para0[3,] + ((RHO - 0.4)/0.2)*para0[4,]
} else if (RHO >= 0.6 & RHO < 0.8){
  para_inter <- ((0.8 - RHO)/0.2)*para0[4,] + ((RHO - 0.6)/0.2)*para0[5,]
} else if (RHO >= 0.8 & RHO < 1.0){
  para_inter <- ((0.8 - RHO)/0.2)*para0[4,] + ((RHO - 0.6)/0.2)*para0[5,]
} else {
  ### Default: para_vec = [0.2, 1377, 4.4589*0.1, 5.5508*0.001,M_simu]
  para_inter <- para0[2,] ### Set at the preferred level if RHO is misspecified 
}

WW <- 2000;  ### Number of repetitions (in HL on p.30 the authors suggest using 5k simulations, but in the exhibit they use 2k)

### Generate a panel of t-ratios (WW*Nsim_tests) ###
Nsim_tests <- (floor(M/para_inter[2]) + 1)*floor(para_inter[2]+1); # make sure Nsim_test >= M

require(MASS) # for mvrnorm()

### Generate empirical p-value distributions based on Harvey, Liu and Zhu (2014) ------ Harvey and Liu
### (2014): "Backtesting", Duke University 
sample_random_multests <- function(rho, m_tot, p_0, lambda, M_simu){ 
  
  ###Parameter input from Harvey, Liu and Zhu (2014) ############
  ###Default: para_vec = [0.2, 1377, 4.4589*0.1, 5.5508*0.001,M_simu]###########
  
  p_0 <- p_0 ;  # probability for a random factor to have a zero mean   
  lambda <- lambda; # average of monthly mean returns for true strategies
  m_tot <- m_tot; # total number of trials
  rho <- rho; # average correlation among returns
  
  M_simu <- M_simu;  # number of rows (simulations) 
  
  sigma <- 0.15/sqrt(12); # assumed level of monthly vol
  N <- 240; #number of time-series (240 months ie. 20 years; see Harvey, Liu and Zhu (2014) Section 5.2 p.30)
  
  sig_vec <- c(1, rho*rep(1, m_tot-1))
  SIGMA <- toeplitz(sig_vec)
  MU <- rep(0,m_tot)
  shock_mat <- mvrnorm(MU, SIGMA*(sigma^2/N), n = M_simu)
  
  prob_vec <- replicate(M_simu, runif(m_tot,0,1))
  
  mean_vec <- t(replicate(M_simu, rexp(m_tot, rate=1/lambda)))
  m_indi <- prob_vec > p_0
  mu_nul <- as.numeric(m_indi)*mean_vec #Null-hypothesis
  tstat_mat <- abs(mu_nul + shock_mat)/(sigma/sqrt(N))
  
  sample_random_multests <- tstat_mat 
}

t_sample <- sample_random_multests(para_inter[1], Nsim_tests, para_inter[3], para_inter[4], WW)
  
# Sharpe Ratio, monthly
sr <- sr_annual / (12 ^(1/2))
T <- sr * N^(1/2)
p_val <- 2 * (1 - pt(T, N - 1))

# Drawing observations from the underlying p-value distribution; simulate a
# large number (WW) of p-value samples
p_holm <- rep(1, WW)
p_bhy <- rep(1, WW)

for(ww in 1:WW){
  
  yy <-  t_sample[ww, 1:M]
  t_value <- t(yy)
  
  p_val_sub <- 2*(1- pnorm(t_value,0,1));
  
  ### Holm
  p_val_all <-  append(t(p_val_sub), p_val)
  p_val_order <- sort(p_val_all)
  p_holm_vec <- NULL
  
  for(i in 1:(M+1)){
    p_new <- NULL
    for(j in 1:i){
      p_new <- append(p_new, (M+1-j+1)*p_val_order[j])
    }
    p_holm_vec <- append(p_holm_vec, min(max(p_new),1))
  }
  
  p_sub_holm <- p_holm_vec[p_val_order == p_val]
  p_holm[ww] <- p_sub_holm[1];
  
  ### BHY
  p_bhy_vec <- NULL
  
  for(i in 1:(M+1)){
    kk <- (M+1) - (i-1)
    if(kk == (M+1)){
      p_new <- p_val_order[M+1]
    } else {
      p_new <- min( (M+1)*(c_const/kk)*p_val_order[kk], p_0)
    }
    p_bhy_vec <- append(p_new, p_bhy_vec)
    p_0 <- p_new
  }
  
  p_sub_bhy <- p_bhy_vec[p_val_order == p_val]
  p_bhy[ww] <- p_sub_bhy[1]
  
}

### Bonferroni ###
p_BON <- min(M*p_val,1)
### Holm ###
p_HOL <- median(p_holm)
### BHY ###
p_BHY <- median(p_bhy)
### Average ###
p_avg <- (p_BON + p_HOL + p_BHY)/3

# Invert to get z-score
z_BON <- qt(1 - p_BON/2, N - 1)
z_HOL <- qt(1 - p_HOL/2, N - 1)
z_BHY <- qt(1 - p_BHY/2, N - 1)
z_avg <- qt(1- p_avg/2, N - 1)

# Annualized Sharpe ratio
sr_BON <- (z_BON/sqrt(N)) * sqrt(12)
sr_HOL <- (z_HOL/sqrt(N)) * sqrt(12)
sr_BHY <- (z_BHY/sqrt(N)) * sqrt(12)
sr_avg <- (z_avg/sqrt(N))*sqrt(12)

# Calculate haircut
hc_BON <- (sr_annual - sr_BON)/sr_annual
hc_HOL <- (sr_annual - sr_HOL)/sr_annual
hc_BHY <- (sr_annual - sr_BHY)/sr_annual
hc_avg <- (sr_annual - sr_avg)/sr_annual

##################################
######### Final Output ###########
cat("Bonferroni Adjustment: \nAdjusted P-value =", p_BON,
    "\nHaircut Sharpe Ratio =", sr_BON,
    "\nPercentage Haircut =", hc_BON,
    "\nHolm Adjustment: \nAdjusted P-value =", p_HOL,
    "\nHaircut Sharpe Ratio =", sr_HOL,
    "\nPercentage Haircut =", hc_HOL,
    "\nBHY Adjustment: \nAdjusted P-value =", p_BHY,
    "\nHaircut Sharpe Ratio =", sr_BHY,
    "\nPercentage Haircut =", hc_BHY,
    "\nAverage Adjustment: \nAdjusted P-value =", p_avg,
    "\nHaircut Sharpe Ratio =", sr_avg,
    "\nPercentage Haircut =", hc_avg)

}

# Run the function - all inputs gathered inside the function, from quantstrat/blotter environment objects
Haircut_SR()

# # Haircut_SR(3,120,1,1,1,0.1,100,0.4)
# if(periodicity(mktdata)$scale == "daily"){
#   freq <- 3
# }
# obs <- nrow(mktdata) # TODO: determine better approach to user's required periodicity
# sharpe <- dailyStats(portfolio.st)$Ann.Sharpe # for now use Ann.Sharpe from dailyStats
# is.sharpe.ann <- 1 # dailyStats discloses annual Sharpe
# AC.corr.reqd <- 0 # (0=YES, 1=NO), TODO: get from strategy
# AC.level <- 0.1 # TODO: get from strategy
# trials <- get.strategy(portfolio.st)$trials
# Ave.corr <- 0.4 # TODO: get correlation from strategy combinations
# 
# Haircut_SR(freq, obs, sharpe, is.sharpe.ann, AC.corr.reqd, AC.level, trials, Ave.corr)
