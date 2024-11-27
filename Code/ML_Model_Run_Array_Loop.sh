#!/bin/bash
# Example Usage: sh ML_Model_Run_Array_Loop.sh ML_Training_Array.csv

lines=$(wc -l $1 | cut -d " " -f 1) # Count number of lines in the file
lines=$((lines-1)) # Reduce number of lines since we won't index the header

for(( c=1; c<=2000; c++ )); do
	sbatch --export=JOB=$c ML_Model_Run_Array.sh
done