#!/bin/bash

instancesetname="ubremen-r27"
denvname="ubremen-r27"
denvxml="d-envs/$denvname.xml"
instancefolder="instances/$instancesetname"
maxtime=15000
timeout=240000

# run the java conflict generator	

mkdir -p $instancefolder
rm $instancefolder/*
cp $0 $instancefolder/

instance=0

for radius in "27"
do  
    for nagents in "1" "2" "4" "6" "8" "10" "12" "14" "16" "18" "20" "22" "24" "26" "28" "30" 
    do        
        for seed in $(seq 1 $1)
        do
	        # create a problem instance file
	        instancename="$instance"
	        instancefile=$instancefolder/$instancename.xml
		    timestep=$radius

	        ## ConflictGenerator
	        java -XX:+UseSerialGC -cp solver.jar -Dlog4j.configuration="file:$PWD/log4j.custom" tt.jointeuclid2ni.probleminstance.generator.GenerateInstance -env $denvxml -nagents $nagents -radius $radius -seed $seed -outfile $instancefile -sgnooverlap

	        # add instance to data.in
	        for alg in "PP" "RPP" "ADPP" "ADRPP" "SDPP" "SDRPP" "ORCA" "BASEST"
	        do
    			activitylog=""
			
			    summaryprefix="$envname;$instance;$nagents;$radius;$seed;$maxtime;$alg;"
		        echo -method $alg -problemfile $instancefile -maxtime $maxtime -timestep $timestep -timeout $timeout -summary -summaryprefix "$summaryprefix" $activitylog >> $instancefolder/data.in           
	        done

	        echo Finished instance no $instance. Agents: $nagents. Gridstep: $gridstep Radius: $radius. Seed: $seed.
	        let instance=instance+1  
        done 
     done
done

echo "env;instance;nagents;radius;seed;maxtime;alg;cost;status;simtime;time;msgs;expansions;clusters;replans" > $instancefolder/head
mkdir $instancefolder/figs
