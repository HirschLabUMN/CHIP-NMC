### NIR Scan Correction
### Michael Burns
### 3/27/23

# Libraries
library(tidyverse)
library(readxl)

# Read in old scan data
correction_data_old = read_csv("~/Desktop/Grad_School/Research/Hybrid_NMC/Data/Scans/Hybrid_Rescans.csv") %>%
  select(1:142) %>%
  mutate(Sample_ID = toupper(Sample_ID))

# Read in new scan data
scan_data = read_csv('/Users/michael/Downloads/Hybrids_spectra_round2.csv') %>%
  rename(Sample_ID = `Sample ID`) %>%
  select(1:142) %>%
  mutate(Sample_ID = toupper(Sample_ID)) %>%
  filter(Sample_ID != 'TEST',
         Sample_ID != 'BLANK') %>%
  mutate(Sample_ID = str_replace_all(Sample_ID, '\\)', '0'),
         Sample_ID = str_replace_all(Sample_ID, '\\!', '1'),
         Sample_ID = str_replace_all(Sample_ID, '\\@', '2'),
         Sample_ID = str_replace_all(Sample_ID, '\\#', '3'),
         Sample_ID = str_replace_all(Sample_ID, '\\$', '4'),
         Sample_ID = str_replace_all(Sample_ID, '\\%', '5'),
         Sample_ID = str_replace_all(Sample_ID, '\\^', '6'),
         Sample_ID = str_replace_all(Sample_ID, '\\&', '7'),
         Sample_ID = str_replace_all(Sample_ID, '\\*', '8'),
         Sample_ID = str_replace_all(Sample_ID, '\\(', '9')) %>%
  mutate(row = row_number()) %>%
  arrange(desc(row)) %>%
  mutate(Sample_ID = str_remove_all(Sample_ID, '_RESCAN')) %>%
  distinct(Sample_ID, .keep_all = T) %>%
  select(-row)

scan_data_23 = read_csv('/Users/michael/Downloads/ych23_scan_data.csv') %>%
  rename(Sample_ID = `Sample ID`) %>%
  select(1:142)%>%
  mutate(Sample_ID = toupper(Sample_ID)) %>%
  filter(Sample_ID != 'TEST',
         Sample_ID != 'BLANK',
         Sample_ID != 'YC',
         Sample_ID != 'NE-N') %>%
  mutate(Sample_ID = str_replace_all(Sample_ID, '\\)', '0'),
         Sample_ID = str_replace_all(Sample_ID, '\\!', '1'),
         Sample_ID = str_replace_all(Sample_ID, '\\@', '2'),
         Sample_ID = str_replace_all(Sample_ID, '\\#', '3'),
         Sample_ID = str_replace_all(Sample_ID, '\\$', '4'),
         Sample_ID = str_replace_all(Sample_ID, '\\%', '5'),
         Sample_ID = str_replace_all(Sample_ID, '\\^', '6'),
         Sample_ID = str_replace_all(Sample_ID, '\\&', '7'),
         Sample_ID = str_replace_all(Sample_ID, '\\*', '8'),
         Sample_ID = str_replace_all(Sample_ID, '\\(', '9')) %>%
  mutate(row = row_number()) %>%
  arrange(desc(row)) %>%
  mutate(Sample_ID = str_remove_all(Sample_ID, '_RESCAN'),
         Sample_ID = str_remove_all(Sample_ID, '-RESCAN'),
         Sample_ID = str_remove_all(Sample_ID, 'RESCAN'),
         Sample_ID = str_remove_all(Sample_ID, '_NOLABEL')) %>%
  distinct(Sample_ID, .keep_all = T) %>%
  select(-row)

# Filter scans for test samples (to match with old scans for correction)
correction_data_new = scan_data %>%
  filter(str_detect(Sample_ID, 'TEST')) %>%
  mutate(Sample_ID = str_remove(Sample_ID, '_TEST'))
correction_data_23 = scan_data_23 %>%
  filter(!str_detect(Sample_ID, '^YC'))

# Find new scan data samples in old scan data
correction_data_old_filtered = correction_data_old %>%
  filter(Sample_ID %in% correction_data_new$Sample_ID) %>%
  distinct(Sample_ID, .keep_all = T)

# Determine how different the spectra are
correction_data_old_filtered %>%
  pivot_longer(cols = -Sample_ID, names_to = 'Waveband', values_to = 'Absorbance') %>%
  left_join(correction_data_new %>%
              pivot_longer(cols = -Sample_ID, names_to = 'Waveband', values_to = 'Absorbance'),
            by = c('Sample_ID', 'Waveband')) %>%
  mutate(diff_abs = Absorbance.x - Absorbance.y) %>%
  ggplot(aes(x = Absorbance.x, y = Absorbance.y))+
  geom_point()+
  geom_smooth(method = 'lm', se = F)+
  geom_abline()+
  theme_classic()

correction_data_old_filtered %>%
  pivot_longer(cols = -Sample_ID, names_to = 'Waveband', values_to = 'Absorbance') %>%
  left_join(correction_data_23 %>%
              pivot_longer(cols = -Sample_ID, names_to = 'Waveband', values_to = 'Absorbance'),
            by = c('Sample_ID', 'Waveband')) %>%
  mutate(diff_abs = Absorbance.x - Absorbance.y) %>%
  ggplot(aes(x = Absorbance.x, y = Absorbance.y))+
  geom_point()+
  geom_smooth(method = 'lm', se = F)+
  geom_abline()+
  theme_classic()

# Determine the correction factor for each waveband
correction_factors = correction_data_old_filtered %>%
  pivot_longer(cols = -Sample_ID, names_to = 'Waveband', values_to = 'Absorbance') %>%
  left_join(correction_data_new %>%
              pivot_longer(cols = -Sample_ID, names_to = 'Waveband', values_to = 'Absorbance'),
            by = c('Sample_ID', 'Waveband')) %>%
  group_by(Waveband) %>%
  summarise(correction_factor = mean(Absorbance.x - Absorbance.y))

correction_factors_23 = correction_data_old_filtered %>%
  pivot_longer(cols = -Sample_ID, names_to = 'Waveband', values_to = 'Absorbance') %>%
  left_join(correction_data_23 %>%
              pivot_longer(cols = -Sample_ID, names_to = 'Waveband', values_to = 'Absorbance'),
            by = c('Sample_ID', 'Waveband')) %>%
  group_by(Waveband) %>%
  summarise(correction_factor = mean(Absorbance.x - Absorbance.y))

# Create a file for corrected scans
corrected_scans = scan_data %>%
  filter(!str_detect(Sample_ID, 'TEST'))
corrected_scans_23 = scan_data_23 %>%
  filter(str_detect(Sample_ID, '^YC'))

# Correct the scans
for(wav in correction_factors$Waveband){
  corr_fact = correction_factors[correction_factors$Waveband == wav, 2][[1]]
  corrected_scans[,wav] = corrected_scans[,wav] + corr_fact
  
  corr_fact23 = correction_factors_23[correction_factors_23$Waveband == wav, 2][[1]]
  corrected_scans_23[,wav] = corrected_scans_23[,wav] + corr_fact23
}

# Show the corrected scans spectral span
correction_data_old %>%
  mutate(group = 'Old') %>%
  filter(`950` < 0.07) %>%
  bind_rows(scan_data %>%
              filter(!str_detect(Sample_ID, 'Test')) %>%
              mutate(group = 'New - Raw')) %>%
  bind_rows(corrected_scans %>%
              mutate(group = 'New - Corrected')) %>%
  bind_rows(corrected_scans_23 %>%
              mutate(group = '2023 - Corrected')) %>%
  mutate(row_num = row_number()) %>%
  pivot_longer(cols = -c(Sample_ID, group, row_num), names_to = 'Waveband', values_to = 'Absorbance') %>%
  mutate(Waveband = as.numeric(Waveband)) %>%
  group_by(group, Waveband) %>%
  summarise(mean_abs = mean(Absorbance),
            min_abs = min(Absorbance),
            max_abs = max(Absorbance)) %>%
  ggplot(aes(x = Waveband, y = mean_abs, color = group, fill = group))+
  geom_ribbon(aes(ymin = min_abs, ymax = max_abs), alpha = 0.5)+
  geom_line()+
  theme_classic()

# Combine the 2022 and 2023 datasets
combined_corrected_scans = corrected_scans %>%
  bind_rows(corrected_scans_23)

# QC the data - check for spectral outliers
combined_corrected_scans %>%
  select(Sample_ID) %>%
  bind_cols(as_tibble(prcomp(combined_corrected_scans[,2:142])$x[,1:2])) %>%
  ggplot(aes(x = PC1, y = PC2))+
  geom_point(alpha = 0.5)+
  theme_classic()

combined_corrected_scans %>%
  select(Sample_ID) %>%
  bind_cols(as_tibble(prcomp(combined_corrected_scans[,2:142])$x[,1:2])) %>%
  pivot_longer(cols = c(PC1, PC2),
               names_to = 'PC',
               values_to = 'Eigenvalue') %>%
  ggplot(aes(x = PC, y = Eigenvalue))+
  geom_boxplot()+
  theme_classic()

outlier_detection = function(data){
  #Create a matrix with lower and upper limits equal to the min and max wavelengths in your dataset
  #Select every 5th (you could also do every 10th, 15th, etc.) wavelength to remove collinearity issues for outlier detection
  #Calculate the mahalanobis distance on all samples using subset of wavelengths
  data$Mdist = mahalanobis(data[,colnames(data) %in% seq(950, 1650, 5)], 
                           colMeans(data[,colnames(data) %in% seq(950, 1650, 5)]), 
                           cov(data[,colnames(data) %in% seq(950, 1650, 5)]),na.rm=TRUE)
  
  #Calculate threshold for sample to be considered an outlier (here I use 3 times the mean)
  return(data %>%
           mutate(outlier = case_when(Mdist <= 3*mean(Mdist) ~ 'no',
                                      Mdist > 3*mean(Mdist) ~ 'yes')))
}

outlier_detection(combined_corrected_scans) %>%
  mutate(Sample = row_number()) %>%
  pivot_longer(cols = -c(Sample_ID, Sample, outlier, Mdist), names_to = 'Waveband', values_to = 'Absorbance') %>%
  mutate(Waveband = as.numeric(Waveband)) %>%
  ggplot(aes(x = Waveband, y = Absorbance, group = Sample, color = outlier))+
  geom_line()+
  theme_classic()

outlier_detection(combined_corrected_scans) %>%
  select(Sample_ID, outlier, Mdist) %>%
  bind_cols(as_tibble(prcomp(combined_corrected_scans[,2:142])$x[,1:2])) %>%
  arrange(PC2) %>%
  ggplot(aes(x = PC1, y = PC2, color = outlier))+
  geom_point(alpha = 0.5)+
  theme_classic()

potential_outliers = outlier_detection(corrected_scans) %>%
  filter(outlier == 'yes') %>%
  select(-c(2:142))

print_option = readline(prompt = 'Would you like to save the file of potential outliers? (y/n) ')

if(print_option == 'y'){
  potential_outliers %>%
    left_join(scan_inventory) %>%
    select(Sample_ID, Box_Number, Proportion_Through_Box) %>%
    write_csv("~/Desktop/Grad_School/Research/Projects/Machine_Learning/Hybrid_Validation/Hybrids_Scan_Potential_Outliers.csv")
}

# Save output from scans - if desired
print_input = readline(prompt = 'Would you like to save the file of corrected scans? (y/n) ')

if(print_input == 'y'){
  outlier_detection(combined_corrected_scans) %>%
    filter(outlier == 'no') %>%
    select(-Mdist, -outlier) %>%
    write_csv("~/Desktop/Grad_School/Research/Hybrid_NMC/Hybrid_Scans_Corrected.csv")
}
