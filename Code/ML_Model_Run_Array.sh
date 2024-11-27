#!/bin/bash
#SBATCH --ntasks=100
#SBATCH --mem=100gb
#SBATCH --time=00:05:00
#SBATCH --mail-type=NONE
#SBATCH --mail-user=burns756@umn.edu
#SBATCH -o /home/hirschc1/burns756/Machine_Learning/Hybrid_Validation/%j.out
#SBATCH -e /home/hirschc1/burns756/Machine_Learning/Hybrid_Validation/%j.err

# Load R and Parallel
module load R/4.1.0

# Change to correct working directory
cd /home/hirschc1/burns756/Hybrid_NMC/

# Run Rscripts in parallel
Rscript --max-ppsize=500000 ML_Model_Run_Array.R ${JOB}