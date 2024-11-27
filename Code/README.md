# CHIP-NMC Analysis
This directory includes the analysis scripts that were used for the publication. Please note, that file names in the script will not match those in the manuscript tables. A data reading rework is planned soon to ensure everything runs properly.

## File Descriptions
- Hybrid_NMC_Model.Rmd
  - The Rmarkdown file containing the majority of the analysis performed for this project.
  - All figures were created in this file.
  - Besides from formatting changes, tables were also created here.
  - In the future, scripts will run with tables from the manuscript rather than arbitrary names of files that are not included here.
- ML_Model_Build_Array.R
  - The R script used to create the table of ML training parameter combinations that was used for training all of the model combinations.
- ML_Model_Run_Array_Loop.sh
  - A shell script that runs a loop to submit many jobs to parallelize training the many model combinations.
  - At the University of Minnesota, our super computing clusters allow us to submit 2,000 job per person, so users will need to change the iteration values here to be appropriate for their own HPC requirements.
- ML_Model_Run_Array.sh
  - This job submission script is run automatically by the loop script above.
  - This script will take the array row number and pass it along to the R script to ensure it trains the correct model combination.
- ML_Model_Run_Array.R
  - The R script that trains models. It will train one combination in parallel.
  - Runs 100 models in parallel to records the performance of each.
- ML_Model_Array_File_Check.sh
  - Reports which files were not created based on what is in the given directory and in the array created by ML_Model_Build_Array.R
- Model_Performance_Concatenation.sh
  - Concatenates the performances of all trained model combinations as all are saved separately.
- NIR_Scan_Correction.R
  - A script used to correct the spectral profile of samples to ensure that all sample spectra are consistent across time and machines.
