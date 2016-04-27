#!/bin/bash

# how many CPU cores will be used to run the experiment?
CPUS=4

# how many instances will be generated for each data point (i.e. for each number of robots in each instanceset)
N=2

# list of environments
ENVS="empty-hall-r22 empty-hall-r22-docks ubremen-r27 ubremen-r27-docks warehouse-r25 warehouse-r25-docks"

echo "---------------------------------------------------------------------------------"
echo " Compiling the implementation of algorithms, instance generator, simulator etc. "
echo "---------------------------------------------------------------------------------"

cd admap-solver
mvn package
cp target/admap-1.0-SNAPSHOT-jar-with-dependencies.jar ../solver.jar
cd ..

echo "----------------------------------------------------------"
echo " Compilation finished! Will run the experiment now."
echo "-----------------------------------------------------------"    

# run the experiment for each environment

for ENV in $ENVS
do
    # cleanup
    rm -fr instances/$ENV
    mkdir -p instances/$ENV

    echo "-------------------------------------------------------"
    echo " Generating instances for $ENV instanceset"
    echo "-------------------------------------------------------"
    
    # generate N random instances for each number of robots
    instanceset-generators/$ENV.sh $N
    
    echo "-------------------------------------------------------"
    echo " Running the algorithms in $ENV instanceset"
    echo "-------------------------------------------------------"
    
    # run the algorithms
    ./parallel_experiments.sh -j solver.jar -c instances/$ENV/data.in -o instances/$ENV/data.out -v -s $CPUS/:
    
    echo "-------------------------------------------------------"
    echo " Processing results"
    echo "-------------------------------------------------------"
    
    # add head row to the generated csv file
    cat "instances/$ENV/head" > "instances/$ENV/data.out.head"
    cat "instances/$ENV/data.out" >> "instances/$ENV/data.out.head"
    
    # run R script to generate the plots
    Rscript make-plots.r $ENV
    
    echo "-------------------------------------------------------"
    echo " PDF with plot has been generated to file plots/$ENV.pdf"
    echo "-------------------------------------------------------"    
done

echo "----------------------------------------------------------"
echo " Done! Plots have been generated to plots/ directory."
echo "-----------------------------------------------------------"    




 

