# Install packages --------------------------------------------------------

if (!requireNamespace("tidyverse", quietly = TRUE))
  install.packages("tidyverse") 
if (!requireNamespace("broom", quietly = TRUE))
  install.packages("broom") 
if (!requireNamespace("gridExtra", quietly = TRUE))
  install.packages("gridExtra") 
if (!requireNamespace("grid", quietly = TRUE))
  install.packages("grid")
if (!requireNamespace("patchwork", quietly = TRUE))
  install.packages("patchwork") 
if (!requireNamespace("keras", quietly = TRUE))
  install.packages("keras") 
if (!requireNamespace("miniconda", quietly = TRUE))
  install.packages("miniconda") 
if (!requireNamespace("tensorflow", quietly = TRUE))
  install.packages("tensorflow") 


# Run all scripts ---------------------------------------------------------

source(file = "R/01_load_and_clean.R.R")
source(file = "R/02_augment.R")
source(file = "R/03_EDA.R")
source(file = "R/04_heatmap.R")
source(file = "R/05_PCA_clustering.R")
source(file = "R/06_ANN_model.R")