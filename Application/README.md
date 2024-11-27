# CHIP-NMC Download
The CHIP-NMC application is saved as app.R. 
The models are saved as .RData files to ensure continuity across instances. 
Example datasets with real spectra are included to allow users to practice with the application and see how it is supposed to work.

## To run locally:
1. Clone this repository to your local computer
2. Open app.R in RStudio
3. Click 'Run App' in the upper right corner of your script display
4. Wait for the application to open
5. Select the file you want to upload and wait for the spectra to be displayed
6. Select the model of your choice and wait for the normalized spectra and distribution of nixtamalized moisture content to appear.
7. Download the predictions.

## Additional Options:
- Check the checkbox above the download button to include predictions above the training maximum and below the training minimum. This is not recommended as model extrapolations are less accurate than interpolations.
- Set the upper and lower boundary of predictions to include in the downloaded file. Samples below the minimum threshold or above the maximum threshold set by the user will not be included in the downloaded file.

### For additional information, see the instructions tab of the application window.
