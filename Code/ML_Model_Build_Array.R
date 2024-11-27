# Path to save the array
Path = '~/Desktop/Grad_School/Research/Hybrid_NMC/Data/'
# Paritioning Factor
Partition = c(
              'Random',
              'Genotype',
              'Environment'
              )
# List of models to try
Models = c(
           'pls',
           'svmLinear',
           'rf',
           'lm'
           )
# List of Spectra Preprocessing
Spectra = c(
            'raw',
            'snv',
            'baseline'#,
            #'abs',
            #'max'
            )
# List of Hyperparameter Values
HypParam = c(
             #1:5
             1:100
             )
# Make the above variables into an array
VarArray <- expand.grid(Partition = Partition,
                        Models = Models,
                        Spectra = Spectra,
                        HypParam = HypParam)
# Write the array above to a file
VarArray %>%
  filter(!(Models == 'lm' & HypParam > 2),
         !(Models == 'pls' & (HypParam > 20 | HypParam < 5)),
         !(Models == 'rf' & (HypParam > 70 | HypParam < 20))) %>%
  write_csv(paste0(Path,"ML_Training_Array_Full_Training_Set.csv"))
