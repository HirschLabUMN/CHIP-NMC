### Hybrid Model Bootstrapping
### Michael Burns
### 3/28/23

# The purpose of this script is to boot strap various model/spectra/hyperparameters 100 times on MSI to determine which 
# model/spectra/hyperparameter performs the best. From this data we will also be able to look at how changing hyperparameters affects performance
# of the models (potentially indicating if another value not tested would be better), and how spectra preprocessing and models interact.
# The models tested will be:
#   PLS: Generally accepted as the go-to chemometric model
#   SVML: The best model in the 2021 Burns et al. inbred paper
#   Random Forest: A common model in biology for classification and regression
#   Linear Model: A common and basic model that all models should outperform

# Spectra preprocessing:
#   Raw spectra: no pretreatments
#   SNV: used for descattering spectra
#   Baseline removal: used to reduce and linear trends in the data and separate peaks

# Hyperparameters:
#   Preproc: Center, Scale, Center and Scale, None
#   PLS: ncomp = c(1:141) | ensures all options are considered
#   SVML: C = ((i^3) * 0.001) | ensures a large range of values are tried from 0.001 to 2803
#   RF: mtry = c(1:141) | ensures all options are considered
#   LM: intercept = c(0,1) | ensures all options are considered

# Libraries
suppressMessages(library(tidyverse))
suppressMessages(library(caret))
suppressMessages(library(parallel))
suppressMessages(library(doParallel))
suppressMessages(library(foreach))
suppressMessages(library(pls))
suppressMessages(library(prospectr))
suppressMessages(library(kernlab))
suppressMessages(library(randomForest))

# Collect Command Line Argument (Which Array Line to Use)
cli_arg = commandArgs(trailingOnly = T)
array_line = as.numeric(cli_arg[1])
#array_line = 2534 # Debugging

# set the path
Path = "/home/hirschc1/burns756/Hybrid_NMC/"
#Path = '~/Desktop/Grad_School/Research/Hybrid_NMC/' # Debugging
# read in the array variables
VarArray = suppressMessages(read_csv(paste0(Path,"ML_Training_Array_Full_Training_Set.csv")))

Array_Info = VarArray[array_line,]

# Loading Data
hybrid_data = suppressMessages(read_csv(paste0(Path, 'Hybrid_Training_Data_273.csv')))

# Specifying Number of Cores
num_cores_limit <- 100
if (detectCores() > num_cores_limit) {
  num_cores <- num_cores_limit
} else {
  num_cores <- detectCores()
}
registerDoParallel(cores = num_cores)

paste0("Entering Loop of Array Line ", array_line)

###################
# START THE LOOPS #
###################
results <- foreach(n = c(1:100), .combine = rbind) %dopar% {
  
  # Set seed for consistent parititioning across models
  set.seed(n)
  
  if(Array_Info$Partition == 'Random'){
    training_index = createDataPartition(hybrid_data$Moisture.Avg, p = 0.8, list = F)
    train_data = hybrid_data[training_index,]
    validation_data = hybrid_data[-training_index,]
  }
  if(Array_Info$Partition == 'Genotype'){
    # Parition data by genotype
    validation_genos = hybrid_data %>%
      select(Genotype) %>%
      unique() %>%
      sample_frac(0.20) %>%
      pull()
    
    validation_data = hybrid_data %>%
      filter(Genotype %in% validation_genos)
  
    train_data = hybrid_data %>%
      filter(!Genotype %in% validation_genos)
  }
  if(Array_Info$Partition == 'Environment'){
    validation_envs = hybrid_data %>%
      mutate(SC = Location) %>%
      select(SC) %>%
      unique() %>%
      sample_frac(0.80) %>%
      pull()
    
    validation_data = hybrid_data %>%
      mutate(SC = Location) %>%
      filter(!SC %in% validation_envs) %>%
      select(-SC)
    
    train_data = hybrid_data %>%
      mutate(SC = Location) %>%
      filter(SC %in% validation_envs) %>%
      select(-SC)
  }
  
  
  # Preprocess spectra (if needed)
  if(Array_Info$Spectra == 'snv' | Array_Info$Spectra == 'baseline'){
    train_data = train_data %>%
      select(1:6) %>%
      bind_cols(as_tibble(detrend(train_data[,7:147],
                                  wav = as.numeric(colnames(train_data[,7:147])),
                                  p = 2)))
    
    validation_data = validation_data %>%
      select(1:6) %>%
      bind_cols(as_tibble(detrend(validation_data[,7:147],
                                  wav = as.numeric(colnames(validation_data[,7:147])),
                                  p = 2))) 
  }
  
  if(Array_Info$Spectra == 'baseline'){
    train_data = train_data %>%
      select(1:6) %>%
      bind_cols(as_tibble(baseline(X = train_data[,7:147],
                                   wav = as.numeric(colnames(train_data[,7:147])))))
    
    validation_data = validation_data %>%
      select(1:6) %>%
      bind_cols(as_tibble(baseline(X = validation_data[,7:147],
                                   wav = as.numeric(colnames(validation_data[,7:147])))))

    train_data = train_data[,-nearZeroVar(train_data)]
  }
  
  if(Array_Info$Spectra == 'abs'){
    train_data <- train_data %>%
      mutate(Sample = row_number()) %>%
      pivot_longer(cols = as.character(seq(950,1650,5)), names_to = "Waveband", values_to = "Absorbance") %>%
      group_by(Sample) %>%
      mutate(Norm_Abs = Absorbance / sum(abs(Absorbance))) %>%
      pivot_wider(id_cols = c(Sample_ID, Genotype, Moisture.Avg, Location, Source, Experiment),
                  values_from = Norm_Abs,
                  names_from = Waveband) %>%
      ungroup()
    
    validation_data = validation_data %>%
      mutate(Sample = row_number()) %>%
      pivot_longer(cols = as.character(seq(950,1650,5)), names_to = "Waveband", values_to = "Absorbance") %>%
      group_by(Sample) %>%
      mutate(Norm_Abs = Absorbance / sum(abs(Absorbance))) %>%
      pivot_wider(id_cols = c(Sample_ID, Genotype, Moisture.Avg, Location, Source, Experiment),
                  values_from = Norm_Abs,
                  names_from = Waveband) %>%
      ungroup()
    
    #train_data = train_data[,-nearZeroVar(train_data)]
  }
  
  if(Array_Info$Spectra == 'max'){
    train_data <- train_data %>%
      mutate(Sample = row_number()) %>%
      pivot_longer(cols = as.character(seq(950,1650,5)), names_to = "Waveband", values_to = "Absorbance") %>%
      group_by(Sample) %>%
      mutate(Norm_Abs = Absorbance / max(Absorbance)) %>%
      pivot_wider(id_cols = c(Sample_ID, Genotype, Moisture.Avg, Location, Source, Experiment),
                  values_from = Norm_Abs,
                  names_from = Waveband) %>%
      ungroup()
    
    validation_data = validation_data %>%
      mutate(Sample = row_number()) %>%
      pivot_longer(cols = as.character(seq(950,1650,5)), names_to = "Waveband", values_to = "Absorbance") %>%
      group_by(Sample) %>%
      mutate(Norm_Abs = Absorbance / max(Absorbance)) %>%
      pivot_wider(id_cols = c(Sample_ID, Genotype, Moisture.Avg, Location, Source, Experiment),
                  values_from = Norm_Abs,
                  names_from = Waveband) %>%
      ungroup()
    
    #train_data = train_data[,-nearZeroVar(train_data)]
  }
  
  # Set hyperparameters for each model
  if(Array_Info$Models == 'pls'){
    hyperparams = expand.grid(ncomp = Array_Info$HypParam)
  }
  if(Array_Info$Models == 'rf'){
    hyperparams = expand.grid(mtry = Array_Info$HypParam)
  }
  if(Array_Info$Models == 'svmLinear'){
    hyperparams = expand.grid(C = seq(0.01,1000,length.out = 100)[Array_Info$HypParam])
  }
  if(Array_Info$Models == 'lm'){
    hyperparams = expand.grid(intercept = Array_Info$HypParam - 1)
  }
  
  # # Set Preprocessing of the model for none and centering and scaling (others are fine as is)
  # PreProc = Array_Info$PreProc
  # if(Array_Info$PreProc == 'center and scale'){
  #   PreProc = c('center', 'scale')
  # }
  # if(Array_Info$PreProc == 'none'){
  #   PreProc = NULL
  # }
  
  # Train the Model
  if(Array_Info$Partition == 'Random'){
    model = train(Moisture.Avg ~ ., 
                  data = train_data %>%
                    select_if(is.numeric), 
                  method = Array_Info$Models, 
                  metric = "RMSE", 
                  #preProcess = PreProc,
                  tuneGrid = hyperparams,
                  trControl = trainControl(method = "cv",
                                           number = 10,
                                           savePredictions = T,
                                           allowParallel = T
                  )
    )
  }
  
  if(Array_Info$Partition == 'Genotype'){
    model = train(Moisture.Avg ~ ., 
                  data = train_data %>%
                    select_if(is.numeric), 
                  method = Array_Info$Models, 
                  metric = "RMSE", 
                  #preProcess = PreProc,
                  tuneGrid = hyperparams,
                  trControl = trainControl(method = "cv",
                                           index = groupKFold(train_data$Genotype, 
                                                              k = 10),
                                           savePredictions = T,
                                           allowParallel = T
                  )
    )
  }
  
  if(Array_Info$Partition == 'Environment'){
    model = train(Moisture.Avg ~ ., 
                  data = train_data %>%
                    select_if(is.numeric), 
                  method = Array_Info$Models, 
                  metric = "RMSE", 
                  #preProcess = PreProc,
                  tuneGrid = hyperparams,
                  trControl = trainControl(method = "cv",
                                           index = groupKFold(train_data$Location, 
                                                              k = 10),
                                           savePredictions = T,
                                           allowParallel = T
                  )
    )
  }
  
  # Assess Performance and Aggregate Results
  return(list(pearsonr_test = cor(predict(model, validation_data),
                             validation_data$Moisture.Avg),
              spearmanr_test = cor(predict(model, validation_data),
                              validation_data$Moisture.Avg,
                              method = 'spearman'),
              rmse_test = RMSE(predict(model, validation_data),
                          validation_data$Moisture.Avg),
              pearsonr_train = model$pred %>%
                                  group_by(Resample) %>%
                                  summarise(PearsonR = cor(as.numeric(pred), obs)) %>%
                                  ungroup() %>%
                                  summarise(PeasonR = mean(PearsonR, na.rm = T)) %>%
                                  pull(),
              spearmanr_train = model$pred %>%
                                  group_by(Resample) %>%
                                  summarise(SpearmanR = cor(as.numeric(pred), obs, method = 'spearman')) %>%
                                  ungroup() %>%
                                  summarise(SpearmanR = mean(SpearmanR, na.rm = T)) %>%
                                  pull(),
              rmse_train = model$pred %>%
                              group_by(Resample) %>%
                              summarise(RMSE = RMSE(as.numeric(pred), obs)) %>%
                              ungroup() %>%
                              summarise(RMSE = mean(RMSE, na.rm = T)) %>%
                              pull(),
              partitioning = Array_Info$Partition,
              spectra = Array_Info$Spectra,
              model = Array_Info$Models,
              hyperparameter = hyperparams[[1]],
              #model_preprocessing = Array_Info$PreProc,
              seed = n,
              training_size = nrow(train_data),
              testing_size = nrow(validation_data)))
}

results %>%
  as_tibble() %>%
  unnest(cols = everything()) %>%
  write_csv(paste0(Path, 'analysis/ml_performances/full_hybrid/ML_Model_Performances_', array_line, '_Full_Train.csv'))

paste0("Finished Loop of Array Line ", array_line)