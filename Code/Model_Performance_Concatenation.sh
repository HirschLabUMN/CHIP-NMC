#!/bin/bash
# Example Usage: sh Model_Performance_Concatenation.sh ML_Training_Array.csv

lines=$(ls -l $1 | wc -l) # Count number of lines in the file
lines=$((lines-1)) # Reduce number of lines since we dont want to count the header.  This should be -2 if a ML_Model_Performances.csv file has already been created.

cat ML_Model_Performances_1.csv > ML_Model_Performances.csv

for(( c=2; c<=${lines}; c++ )); do
	tail -n+2 analysis/ml_performances/full_hybrid/ML_Model_Performances_${c}_Full.csv >> ML_Model_Performances_Full.csv
done