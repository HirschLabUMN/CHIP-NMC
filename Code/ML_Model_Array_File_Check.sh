#!/bin/bash

# Count number of .err files with > 0 lines
echo "Checking Error Files"
EFILES="*.err"
# EFILES="/home/hirschc1/burns756/Machine_Learning/Hybrid_Validation/*.err" # More exact
for file in $EFILES; do
	if (( $(wc -l <$file) > 0 ));
	then
	echo $file
	fi
done

# Count number of .out files that don't have 2 lines
echo "Checking Output Files"
OFILES="*.out"
# OFILES="/home/hirschc1/burns756/Machine_Learning/Hybrid_Validation/*.out" # More exact
for file in $OFILES; do
	if (( $(wc -l <$file) != 2 ));
	then
	echo $file
	fi
done

# Count number of .csv files that don't have 101 lines
echo "Checking Performances Files"
CSVFILES="Performances/*.csv"
# CSVFILES="/home/hirschc1/burns756/Machine_Learning/Hybrid_Validation/Performances/*.csv" # More exact
for file in $CSVFILES; do
	if (( $(wc -l <$file) != 101 ));
	then
	echo $file
	fi
done


