library(plyr)

### Load the data

env <- "urbanC-bounded-g4"
dir <- paste("instances/",env, sep="")
results <- read.csv(file=paste(dir, "/data.out.head", sep=""), head=TRUE, sep=";")
resultssorted <- results[order(results$instance, results$alg, results$runtime),]

### Select a subset of data

selresults <- results
selruns <- aggregate.results.to.runs(selresults)
cat( paste("Selected instances:", nrow(selruns)/3) )

### Plot graphs ###

successrate.nagents(selruns)
cost.vs.runtime(results=selresults, reftime=750, maxtime=4000, algs=c("PP", "IIHP", "ODCN"), step=100)
successrate.vs.runtime(runs=selruns, maxtime=5000, algs=c("PP","IIHP", "ODCN"), step=50)
successrate.vs.expansions(runs=selruns, maxexpansions=300000, algs=c("PP","IIHP", "ODCN"), step=1000)

quality.comparison(selruns)

suboptimality.boxplot(selruns)
improvement.boxplot(selruns)

first.and.bestsol(selruns)
runtime.to.firstsol(selruns)
expansions.to.firstsol(selruns)
expansions.to.bestsol(selruns)

## aggregate results to runs ##
aggregate.results.to.runs <- function(results) {
  runs <- ddply(results, .(instance, alg), summarise, 
                   nagents = max(nagents),              
                   radius = max(radius),
                   gridstep = max(gridstep),
                   succeeded = max(is.finite(cost)),
                   solutions = length(unique(cost)),
                   firstsoltime = ifelse(max(is.finite(cost)), min(runtime), NA),
                   firstsolexp = ifelse(max(is.finite(cost)), min(expansions), NA),
                   firstsolcost = max(cost),
                   finished = max(runtime),
                   
                   bestsolcost = min(cost),
                   bestsoltime = ifelse(max(is.finite(cost)), max(runtime), NA),
                   bestsolexp = ifelse(max(is.finite(cost)), max(expansions), NA)              
  )
  
  return(runs)
}

successrate.vs.runtime <- function(runs, maxtime, algs, step=500) {
  ninstances <- length(unique(runs[,"instance"]))
  
  succ.rate <- data.frame()
  
  i <- 1
  for (t in seq(0, maxtime, by=step)) {    
    succ.rate[i, "time"] <- t    
    
    for (alg in algs) {
      succ.rate[i, alg] <- length(runs[runs$alg==alg & is.finite(runs$firstsoltime) & runs$firstsoltime <= t, "instance"]) / ninstances    
    }
    
    i <- i + 1
  }
    
  plot(succ.rate[,"time"], 
       succ.rate[,"PP"]*100, 
       type="o", ylim=c(0, 100), 
       ylab="success rate",
       xlab="runtime [ms]")
  
  points(succ.rate[,"time"], 
         succ.rate[,"IIHP"]*100, 
         type="o", pch=22, col="red", lty=2)
  
  if (is.element("ODCN", names(succ.rate))) {
    points(succ.rate[,"time"], 
           succ.rate[,"ODCN"]*100,
           type="o",  pch=23, col="forestgreen", lty=3)
  }
  
  legend(1, 10000, c("PP", "IIHP(first)", "IIHP(best)", "ODCN"), col=c("black", "red", "red", "forestgreen"), pch=c(1,22,23))
  
  title(main=paste(" success rate/runtime allowed n:", ninstances))
  
}


successrate.vs.expansions <- function(runs, maxexpansions, algs, step=500) {
  ninstances <- length(unique(runs[,"instance"]))
  
  succ.rate <- data.frame()
  
  i <- 1
  for (exp in seq(0, maxexpansions, by=step)) {    
    succ.rate[i, "exp"] <- exp
    
    for (alg in algs) {
      succ.rate[i, alg] <- length(runs[runs$alg==alg & is.finite(runs$firstsolexp) & runs$firstsolexp <= exp, "instance"]) / ninstances    
    }
    
    i <- i + 1
  }
  
  plot(succ.rate[,"exp"], 
       succ.rate[,"PP"]*100, 
       type="o", ylim=c(0, 100), 
       ylab="success rate",
       xlab="expansions [ms]")
  
  points(succ.rate[,"exp"], 
         succ.rate[,"IIHP"]*100, 
         type="o", pch=22, col="red", lty=2)
  
  if (is.element("ODCN", names(succ.rate))) {
    points(succ.rate[,"exp"], 
           succ.rate[,"ODCN"]*100,
           type="o",  pch=23, col="forestgreen", lty=3)
  }
  
  legend(1, 10000, c("PP", "IIHP(first)", "IIHP(best)", "ODCN"), col=c("black", "red", "red", "forestgreen"), pch=c(1,22,23))
  
  title(main=paste(" success rate/expansions allowed n:", ninstances))
  
}

## IIHP cost ~ runtime based on the instances soved by PP at reftime##

cost.vs.runtime <- function(results, reftime, maxtime, algs, step=500) {
  
  costs <- data.frame()
  
  results.reftime <- results[results$runtime <= reftime & is.finite(results$cost) & is.element(results$alg, algs) , ] 
  
  instance.cost <- ddply(results.reftime, .(instance, alg), summarise,                         
                         cost = min(cost)
  )
  
  instances.solved.by.all <- results.reftime[,"instance"]
  
  for (alg in algs) {
    instances.solved.by.all <- intersect(instances.solved.by.all, instance.cost[instance.cost$alg==alg, "instance"])
  }    
  
  cat(
    " There is total", length(unique(results$instance)), "instances.\n",
    "There is ", length(unique(results.reftime$instance)), "instances solved by either ", algs ,".\n",
    "There is ", length(instances.solved.by.all), "instances solved by all ", algs ,"at the same time at referece runtime "
    , reftime, "ms\n")
  
  i <- 1
  for (t in seq(reftime, maxtime, by=step)) {
       
    costs[i, "time"] <- t
    
    results.t <- results[results$runtime <= t & is.element(results$instance, instances.solved.by.all), ]
    
    cat(length(unique(results.t$instance)), " instances considered at time ", t ," \n")
    
    instance.cost <- ddply(results.t, .(instance, alg), summarise, 
                           cost = min(cost)
    )    
    
    for (alg in algs) {
      costs[i, alg] <- mean(instance.cost[instance.cost$alg==alg, "cost"])     
    }
    
    i <- i +1
  }
  
  ymin <- min(costs[,"IIHP"], na.rm=true)
  
  if (is.element("ODCN", names(costs))) {
    ymin <- min(ymin,  min(costs[,"ODCN"], na.rm=true))
  }
    
  plot(costs[,"time"], 
       costs[,"PP"], 
       type="o", ylim=c(ymin, max(costs[,"PP"],na.rm=true)), 
       ylab="cost",
       xlab="runtime [ms]")
  
  points(costs[,"time"], 
         costs[,"IIHP"], 
         type="o", pch=22, col="red", lty=2)
  
  if (is.element("ODCN", names(costs))) {
    points(costs[,"time"], 
          costs[,"ODCN"],
         type="o",  pch=23, col="forestgreen", lty=3)
  }
  
  title(main=paste(" cost/runtime allowed n:", length(instances.solved.by.all)))
}
    

## successrate ~ nagents ##

successrate.nagents <- function(runs) {
  
  successrate <- ddply(runs, .(nagents, alg), summarise,                     
                    successrate = (sum(succeeded) / length(unique(instance)))
                 )

  plot(successrate[successrate$alg=="PP","successrate"])       

  plot(successrate[successrate$alg=="PP","nagents"], 
       successrate[successrate$alg=="PP","successrate"]*100, 
       type="o", ylim=c(0,100), 
       ylab="% solved",
       xlab="number of agents")
  
  points(successrate[successrate$alg=="IIHP","nagents"], 
         successrate[successrate$alg=="IIHP","successrate"]*100, 
         type="o", pch=22, col="red", lty=2)
  
  points(successrate[successrate$alg=="ODCN","nagents"], 
         successrate[successrate$alg=="ODCN","successrate"]*100, 
         type="o",  pch=23, col="forestgreen", lty=3)
  
  
  title(main="% solved/no of agent")
}

## Quality comparison

quality.comparison <- function(runs) {
  instances <- runs[,c("instance")]
  cost.pp <- runs[runs$alg=="PP", c("instance", "bestsolcost")]
  cost.iihp <- runs[runs$alg=="IIHP", c("instance", "bestsolcost")]
  cost.odcn <- runs[runs$alg=="ODCN", c("instance", "bestsolcost")]
  
  
  cost.diff.iihp.pp <- (cost.iihp$bestsolcost - cost.pp$bestsolcost) / cost.pp$bestsolcost
  cost.diff.odcn.pp <- (cost.odcn$bestsolcost - cost.pp$bestsolcost) / cost.pp$bestsolcost
  plot(cost.diff.iihp.pp, col="red")
  points(cost.diff.odcn.pp, col="forestgreen", pch=20)
  title(main="% cost saved IIHP vs PP ")  
  
  plot(cost.pp)
  points(cost.iihp, col="forestgreen")  
}

suboptimality.boxplot <- function(runs) {
  
  library(vioplot)
  
  # find instances solved by all
  instances.solved.by.all <- 
    intersect(
    intersect(
      runs[runs$alg=="PP" & runs$succeeded==1, "instance"],
      runs[runs$alg=="IIHP" & runs$succeeded==1, "instance"]),
      runs[runs$alg=="ODCN" & runs$succeeded==1, "instance"])
  
  runs <- runs[is.element(runs$instance, instances.solved.by.all),] 

  instance.cost <- data.frame(instance = instances.solved.by.all,
                              ODCN = runs[is.element(runs$instance, instances.solved.by.all) & runs$alg=="ODCN", "bestsolcost"],
                              PP = runs[is.element(runs$instance, instances.solved.by.all) & runs$alg=="PP", "bestsolcost"],
                              IIHP = runs[is.element(runs$instance, instances.solved.by.all) & runs$alg=="IIHP", "bestsolcost"]
  )
  
  suboptimality <- data.frame(instance = instance.cost["instance"],
    PP = ((instance.cost["PP"]-instance.cost["ODCN"])/instance.cost["ODCN"]),
    IIHP = ((instance.cost["IIHP"]-instance.cost["ODCN"])/instance.cost["ODCN"])
  )
  
  vioplot(suboptimality[,"PP"], suboptimality[,"IIHP"], names=c("PP", "IIHP"))
  title( main=paste("Suboptimality. n: ", nrow(suboptimality)) )
  
}


improvement.boxplot <- function(runs) {
  library(vioplot)
  
  # find instances solved by both
  instances.solved.by.both <-     
      intersect(
        runs[runs$alg=="PP" & runs$succeeded==1, "instance"],
        runs[runs$alg=="IIHP" & runs$succeeded==1, "instance"]
      )
  
  runs <- runs[is.element(runs$instance, instances.solved.by.both),] 
  
  ### Continue here with making a table that has instance, costpp, costiihp and costodcn... 
  
  instance.cost <- data.frame(instance = instances.solved.by.both,
                              PP = runs[is.element(runs$instance, instances.solved.by.both) & runs$alg=="PP", "bestsolcost"],
                              IIHP = runs[is.element(runs$instance, instances.solved.by.both) & runs$alg=="IIHP", "bestsolcost"]
                             )                              
  
  
  improvement <- data.frame(instance = instance.cost["instance"],                              
                              IIHP = ((instance.cost["PP"]-instance.cost["IIHP"])/instance.cost["PP"])
  )
  
  
  vioplot(improvement[,"IIHP"])
  title( main=paste("Improvement of IIHP over PP n:", nrow(suboptimality)) )  
}


### first and best solution for the algorithms
first.and.bestsol <- function(runs) {
  plot(runs[runs$alg=="PP",c("firstsolcost")], ylab="cost")
  points(runs[runs$alg=="IIHP",c("firstsolcost")], col="red", type="p", pch=4)
  points(runs[runs$alg=="IIHP",c("bestsolcost")], col="red4", type="p", pch=5)
  points(runs[runs$alg=="ODCN",c("bestsolcost")], col="forestgreen", type="p", pch=20)
  text(1:length(runs[runs$alg=="IIHP","instance"]), runs[runs$alg=="IIHP","bestsolcost"], runs[runs$alg=="IIHP","instance"], cex=0.6, pos=1, col="red")
  legend("topleft", c("PP", "IIHP(first)", "IIHP(best)", "ODCN"), col=c("black", "red", "red", "forestgreen"), pch=c(1,4,5,20))
  title("First and best solution")
}

### runtime to first solution
runtime.to.firstsol <- function(runs) {
  plot(runs[runs$alg=="PP",c("firstsoltime")], ylim=c(0,6000))
  points(runs[runs$alg=="IIHP",c("firstsoltime")], col="red", type="p", pch=4)
  points(runs[runs$alg=="ODCN",c("firstsoltime")], col="forestgreen", type="p", pch=20)
  title("Runtime to first solution [ms]")
}

### expansions to first solution
expansions.to.firstsol <- function(runs) {
  plot(runs[runs$alg=="PP",c("firstsolexp")], ylim=c(0,100000))
  points(runs[runs$alg=="IIHP",c("firstsolexp")], col="red", type="p", pch=4)
  points(runs[runs$alg=="ODCN",c("firstsolexp")], col="forestgreen", type="p", pch=20)
  title("Expansions to first solution")
}

### expansions to best solution
expansions.to.bestsol <- function(runs) {
  plot(runs[runs$alg=="PP",c("bestsolexp")], ylim=c(0,1000000))
  points(runs[runs$alg=="IIHP",c("bestsolexp")], col="red", type="p", pch=4)
  points(runs[runs$alg=="ODCN",c("bestsolexp")], col="forestgreen", type="p", pch=20)
  title("Expansions to best solution")
}

