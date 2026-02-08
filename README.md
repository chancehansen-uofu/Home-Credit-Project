# Home Credit Default Risk

This project performs feature engineering and data preparation for the **Home Credit Default Risk** dataset. The goal is to create a clean, enriched dataset suitable for predictive modeling of credit default risk.

---

## Author

Chance Hansen

---

## Project Status

- Feature engineering functions implemented and reusable for train/test datasets.  
- Cleaned anomalies, created demographic and financial ratio features, aggregated transactional data, and ensured train/test consistency.  

---

## Purpose of `feature_engineering.R`

The `feature_engineering.R` script performs **reusable data cleaning and feature engineering** for the Home Credit dataset. It generates features from multiple sources:

- **Application data**: Demographics (age, employment duration), missing indicators, binary flags, financial ratios (credit-to-income, loan-to-value, DTI), interaction terms, and binned variables  
- **Bureau data**: Loan counts, active vs. closed loans, debt amounts, overdue amounts, debt ratios  
- **Previous applications**: Application count, approval rate, refusal history, credit amounts  
- **Installments payments**: Late payment percentages, overpayments, payment trends  
- **Credit card balances**: Credit utilization, total balance, total drawings  
- **POS/Cash balances**: DPD (days past due) history, installment trends  

All functions are designed to ensure **identical transformations on training and test datasets**, preventing data leakage and ensuring reproducibility.

---

## Data Requirements / Inputs

Place the following CSV files in the project root:

- `application_train.csv`
- `application_test.csv`
- `bureau.csv`
- `previous_application.csv`
- `installments_payments.csv`
- `credit_card_balance.csv`
- `POS_CASH_balance.csv`

---

## Usage Instructions

1. Load the required libraries:

```r
library(data.table)
library(dplyr)
```

2. Source the feature engineering script:

```r
source("feature_engineering.R")
```

3. Load the datasets:

```r
train_df <- fread("application_train.csv")
test_df  <- fread("application_test.csv")
bureau_df <- fread("bureau.csv")
prev_app_df <- fread("previous_application.csv")
installments_df <- fread("installments_payments.csv")
cc_df <- fread("credit_card_balance.csv")
pos_df <- fread("POS_CASH_balance.csv")
```

4. Prepare the training dataset:

```r
train_result <- prepare_data(
  app_df = train_df,
  bureau_df = bureau_df,
  prev_app_df = prev_app_df,
  installments_df = installments_df,
  cc_df = cc_df,
  pos_df = pos_df
)

train_clean <- train_result$df
train_stats <- train_result$train_stats
```

5. Prepare the test dataset using training statistics to ensure consistent transformations:

```r
test_result <- prepare_data(
  app_df = test_df,
  train_stats = train_stats,
  bureau_df = bureau_df,
  prev_app_df = prev_app_df,
  installments_df = installments_df,
  cc_df = cc_df,
  pos_df = pos_df
)
test_clean <- test_result$df
```

---

## Outputs

The script produces:

- `train_clean` → Cleaned and feature-engineered training dataset ready for modeling
- `test_clean` → Cleaned and feature-engineered test dataset with identical columns to training
- `train_stats` → Summary statistics (medians, min/max, bin thresholds) used to ensure consistent train/test transformations

Optional: You can save these datasets to CSV:

```r
fwrite(train_clean, "train_features.csv")
fwrite(test_clean, "test_features.csv")
