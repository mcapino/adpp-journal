#!/bin/bash

instancesetname="warehouse-r25"
denvname="warehouse-r25"
denvxml="d-envs/$denvname.xml"
instancefolder="instances/$instancesetname"
maxtime=15000
timeout=600000

# run the java conflict generator	

mkdir -p $instancefolder
rm $instancefolder/*
cp $0 $instancefolder/

instance=0
radius=25
 
for nagents in "1" "10" "20" "30" "40" "50" "60"
do        
    for seed in $(seq 1 $1)
    do
        # create a problem instance file
        instancename="$instance"
        instancefile=$instancefolder/$instancename.xml
	    timestep=30 # CHANGE THIS!

        ## ConflictGenerator
        java -XX:+UseSerialGC -cp solver.jar -Dlog4j.configuration="file:$PWD/log4j.custom" tt.jointeuclid2ni.probleminstance.generator.GenerateInstance -env $denvxml -nagents $nagents -radius $radius -seed $seed -outfile $instancefile -sgnooverlap

        # add instance to data.in
        for alg in "PP" "RPP" "ADPP" "ADRPP" "SDPP" "SDRPP" "ORCA" "BASEST"
        do
    		activitylog=""
		
		    summaryprefix="$envname;$instance;$nagents;$radius;$seed;$maxtime;$alg;"
	        echo -method $alg -problemfile $instancefile -maxtime $maxtime -timestep $timestep -timeout $timeout -summary -summaryprefix "$summaryprefix" $activitylog >> $instancefolder/data.in           
        done

        echo Finished instance no $instance. Agents: $nagents. Radius: $radius. Seed: $seed.
        let instance=instance+1  
    done 
 done


echo "env;instance;nagents;radius;seed;maxtime;alg;cost;status;simtime;time;msgs;expansions;clusters;replans" > $instancefolder/head
mkdir $instancefolder/figs
