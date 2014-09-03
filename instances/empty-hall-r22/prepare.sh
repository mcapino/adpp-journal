#!/bin/bash

instancesetname="empty-hall-r22"
denvname="empty-hall-r25"
denvxml="d-envs/$denvname.xml"
instancefolder="instances/$instancesetname"
maxtime=15000
timeout=240000

# run the java conflict generator	

mkdir -p $instancefolder
rm $instancefolder/*
cp prepare.sh $instancefolder/

instance=0

for radius in "22"
do  
    #denvxml="d-envs/$envname-r$radius.xml"
    #gracecoef="1.2"
    #radiusgrace=`echo -e "import math\nprint(int(math.ceil($radius*$gracecoef)))" | python`
    #let "dispersion=radiusgrace*3" # to be precise this should be 2*sqrt(2)*radius = 2.82*radius, we rounded up a little...
    #let "connradius=$dispersion+1"
    
    # triangulation generator
    #java -XX:+UseSerialGC -cp solver.jar -Dlog4j.configuration="file:$PWD/log4j.custom" tt.jointeuclid2ni.probleminstance.generator.TriangulationGenerator -problemfile $envxml -dispersion $dispersion -connectionradius $connradius -bodyradius $radius -outfile $denvxml -showvis
    
    for nagents in "1" "2" "3" "4" "5" "10" "12" "15" "18" "20" "25" "30" "35" "40" "45" "50" # "1" "2" "4" "6" "8" "10" "12" "14" "16" "18" "20" "22" "24" "26" "28" "30"
    do        
        for seed in {1..25}
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
		        if [ "$alg" == ORCA ]; then
    				activitylog=""
			    else
			        activitylog="-activitylog $instancefile.$alg.log"
			    fi
			
			    summaryprefix="$envname;$instance;$nagents;$radius;$seed;$maxtime;$alg;"
		        echo -method $alg -problemfile $instancefile -maxtime $maxtime -timestep $timestep -timeout $timeout -summary -summaryprefix "$summaryprefix" $activitylog >> $instancefolder/data.in           
	        done

	        echo Finished instance no $instance. Agents: $nagents. Gridstep: $gridstep Radius: $radius. Seed: $seed.
	        let instance=instance+1  
        done 
     done
done

echo "env;instance;nagents;radius;seed;maxtime;alg;cost;time;msgs;expansions;clusters;replans" > $instancefolder/head
mkdir $instancefolder/figs
