# Clear workspace ---------------------------------------------------------
rm(list = ls())


# Load libraries ----------------------------------------------------------
library('tidyverse')
library('keras')


# Define functions --------------------------------------------------------
source(file = "R/99_project_functions.R")


# Load data ---------------------------------------------------------------
joined_data_aug <- read_csv(file = "data/02_joined_data_PAM50_aug.csv")


# Prepare data ------------------------------------------------------------

## Partition data with data_type column: training (~70%) and test (~30%)
joined_data_prep <- joined_data_aug  %>% 
  # Remove control samples (too few samples in this group)
  filter(Class %in% c("Basal", "HER2", "LumA", "LumB")) %>% 
  # Give a random number between 1 and 10 (to use for dividing data in train and test)
  mutate(data_type = sample(10, size = nrow(.), replace = TRUE))  %>% 
  # Make a numbered class
  mutate(Class_num = case_when(Class == "Basal" ~ 0,
                               Class == "HER2" ~ 1,
                               Class == "LumA" ~ 2,
                               Class == "LumB" ~ 3)) %>%
  # Select only relevant columns
  select(patient_ID, starts_with("NP"), data_type, Class_num) 


## Define training and test feature matrices
X_train <- joined_data_prep %>%
  filter(data_type > 3) %>%
  select(patient_ID, starts_with("NP")) %>%
  as_matrix()
         
X_test <- joined_data_prep %>%
  filter(data_type <= 3) %>%
  select(patient_ID, starts_with("NP")) %>%
  as_matrix()
  

## Define known target classes for training and test data
y_train <- joined_data_prep %>%
  filter(data_type > 3 ) %>%
  pull(Class_num) %>% 
  to_categorical

y_test <- joined_data_prep %>%
  filter(data_type <= 3 ) %>%
  pull(Class_num) %>% 
  to_categorical


# Define ANN model --------------------------------------------------------

## Set hyperparameters
input_shape <- 40
n_hidden_1 <- 30
h1_activate <- 'relu'
drop_out_1 <- 0.4
n_hidden_2 <- 40
h2_activate <- 'relu'
drop_out_2 <- 0.3
n_hidden_3 <- 30
h3_activate <- 'relu'
drop_out_3 <- 0.2
n_output   <- 4
o_ativate  <- 'softmax'
n_epochs <- 100
batch_size <- 50
loss_func <- 'categorical_crossentropy'
learn_rate <- 0.001

## Set architecture
model <- keras_model_sequential() %>% 
  layer_dense(units = n_hidden_1, activation = h1_activate, input_shape = input_shape) %>% 
  layer_dropout(rate = drop_out_1) %>% 
  layer_dense(units = n_hidden_2, activation = h2_activate) %>%
  layer_dropout(rate = drop_out_2) %>%
  layer_dense(units = n_hidden_3, activation = h3_activate) %>%
  layer_dropout(rate = drop_out_3) %>%
  layer_dense(units = n_output, activation = o_ativate)

## Compile model
model %>%
  compile(loss = loss_func,
          optimizer = optimizer_rmsprop(lr = learn_rate),
          metrics = c('accuracy'))


# Train model -------------------------------------------------------------

history <- model %>%
  fit(x = X_train,
      y = y_train,
      epochs = n_epochs,
      batch_size = batch_size,
      validation_split = 0)


# Evaluate model ----------------------------------------------------------

## OBS: All classes need to be predicted for the factoring to work
perf_test <- model %>%
  evaluate(X_test, y_test)

acc_test <- perf_test %>%
  pluck('acc') %>%
  round(3) * 100

perf_train <- model %>% 
  evaluate(X_train, y_train)

acc_train <- perf_train %>%
  pluck('acc') %>%
  round(3) * 100

results <- bind_rows(
  tibble(y_true = y_test %>%
           apply(1, function(x){ return( which(x==1) - 1) }) %>%
           factor,
         y_pred = model %>%
           predict_classes(X_test) %>%
           factor,
         Correct = ifelse(y_true == y_pred ,"Yes", "No") %>%
           factor,
         data_type = 'test'),
  tibble(y_true = y_train %>%
           apply(1, function(x){ return( which(x==1) - 1) }) %>%
           factor,
         y_pred = model %>%
           predict_classes(X_train) %>%
           factor,
         Correct = ifelse(y_true == y_pred ,"Yes", "No") %>%
           factor,
         data_type = 'train')) %>%
  # Factor the columns to get training data before test in plot
  mutate(data_type = factor(data_type, 
                          levels = c('train', 'test'))) 

pred_counts <- results %>% 
  count(y_pred, y_true, data_type) %>%
  # Factor the columns to get training data before test in plot
  mutate(data_type = factor(data_type,
                            levels = c('train', 'test')))



# Visualise model performance ---------------------------------------------

results %>%
  ggplot() +
  geom_jitter(mapping = aes(x = y_pred, 
                            y = y_true, 
                            color = Correct),
              size = 6, 
              alpha = 0.3) +
  geom_text(data = pred_counts, 
            mapping = aes(x = y_pred, 
                          y = y_true, 
                          label = n),
            size = 18) +
  labs(x = "Class predicted by ANN",
       y = "Class from clinical data",
       title = "Confusion matrix of Neural Network for cancer class prediction", 
       subtitle = paste0("Training Accuracy = ", acc_train, "%, n = ", nrow(X_train), ". ",
                         "Test Accuracy = ", acc_test, "%, n = ", nrow(X_test), ".")) +
  theme_bw(base_family = "Times", 
           base_size = 14) +
  facet_wrap(~data_type, 
             nrow = 1)

ggsave(filename = "results/06_ANN_performance.png", 
       device = "png")
