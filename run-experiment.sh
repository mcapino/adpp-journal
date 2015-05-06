#!/bin/bash

CPUS=4
N=5
#ENVS="empty-hall-r22 empty-hall-r22-docks ubremen-r27 ubremen-r27-docks warehouse-r25 warehouse-r25-docks"
ENVS="empty-hall-r22-docks"

for ENV in $ENVS
do
    # cleanup
    rm -fr instances/$ENV
    mkdir -p instances/$ENV
    
    # generate N random instances for each number of robots
    instanceset-generators/$ENV.sh $N
    
    # run the algorithms
    ./parallel_experiments.sh -j solver.jar -c instances/$ENV/data.in -o instances/$ENV/data.out -v -s $CPUS/:
    
    # add head row to the generated csv file
    cat "instances/$ENV/head" > "instances/$ENV/data.out.head"
    cat "instances/$ENV/data.out" >> "instances/$ENV/data.out.head"
    
    # run R script to generate the plots
    Rscript make-plots.r $ENV
    
    echo "-------------------------------------------------------"
    echo "PDF with plot has been generated to file plots/$ENV.pdf"
    echo "-------------------------------------------------------"    
done




 

