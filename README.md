# CHIP-NMC: an application for <ins>C</ins>orn <ins>H</ins>ybrid and <ins>I</ins>nbred <ins>P</ins>rediction of <ins>N</ins>ixtamalization <ins>M</ins>oisture <ins>C</ins>ontent
by Michael J. Burns^1, Sydney Berry, Molly Loftus, Amanda M. Gilbert, and Candice N. Hirsch  
Department of Agronomy and Plant Genetics, University of Minnesota

## Purpose:
Food-grade corn is an economically important crop in the United States and worldwide. However, 
in the United States, it makes up less than 2% of the corn grown by acre. This has reduced
resources for improving food-grade corn, affecting the manufacturing process and downstream consumer
satisfaction with final products. One trait that impacts many other quality traits is the amount of 
water absorbed during the nixtamalization process. Methods have been proposed for measuring this multi-impact
trait, but either require large amounts of sample or were designed for inbreds. This work has developed a 
low-quantity prediction model specific to hybrids. The hybrid specific model, and the inbred model created previously,
were combined into an application called CHIP-NMC to make both models applicable to multiple stages of the masa
production pipeline. The hybrid-trained model was used to assess the effects of grain composition on a hybrid's 
nixtamalization moisture content.

## Publication:
For more information, please see the manuscript at: **ADD DOI HERE**

## Pipeline Description:
This project has developed a machine learning model to predict nixtamalization moisture content from NIR
spectra of ground, raw maize kernels. This requires samples to undergo a grinding (destructive) and NIR scanning
process and a benchtop cooking process (destructive) to collect the predictive features (NIR spectra) and predicted 
nixtamalization moisture content. 300 samples had 50g of sample allocated for grinding and scanning 
(requires at least 30g) and 200g of sample allocated for cook tests (2 reps of 100g). Samples were ground and scanned
first to provide spectra for selecting diverse samples for training.

After samples were selected, initial cook tests were performed to train a preliminary model, which was used to select
more samples to broaden the spectral diversity of the training set. The preliminary model (and subsequent models) 
were trained using supercomputing resources to determine the best combination of data preprocessing, model, hyperparameters,
etc. This process was repeated 100 times to get an estimate for performance variation and allowed us to pick the best model
combination available for the given dataset. After the best model for the final training set was chosen, the model was
used to predict the larger dataset of samples available. 

Using these samples, the relationship between composition and nixtamalization moisture content was assessed. To do this, we
assessed which NIR wavebands were most important to the prediction model and correlated nixtamalization moisture content to 
NIR compositional proximates. The importance of the NIR waveband was measured through repeated permutation testing, which allowed us 
to determine which chemical functional groups were associated with predictive performance.

## Directories:
- Code:
  - scripts used in the analysis for the publication
- Application:
  - A free-to-use, locally running RShiny application that can be implemented in various stages of corn breeding
