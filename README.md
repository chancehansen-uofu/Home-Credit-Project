# Home Credit Default Risk

This project performs feature engineering, data preparation, and predictive modeling for the **Home Credit Default Risk** dataset. The goal is to predict the probability that a loan applicant will default, enabling better-informed credit decisions for borrowers who lack conventional credit histories.

---

## Author
Chance Hansen

---

## Project Status
- Feature engineering functions implemented and reusable for train/test datasets.
- Cleaned anomalies, created demographic and financial ratio features, aggregated transactional data, and ensured train/test consistency.
- Modeling notebook complete with cross-validation, class imbalance experiments, hyperparameter tuning, and Kaggle submission.

---

## Project Files

| File | Description |
|---|---|
| `feature_engineering.R` | Reusable data cleaning and feature engineering pipeline |
| `Modeling_HansenChance.qmd` | Modeling notebook: candidate models, tuning, and Kaggle submission |
| `submission.csv` | Kaggle submission file with predicted default probabilities |

---

## Modeling Notebook (`IS6850_modeling.qmd`)

### Models Compared

Six model configurations were evaluated using 3-fold cross-validation AUC on a stratified 5,000-row subsample:

| Model | CV AUC |
|---|---|
| Majority-class baseline | 0.500 |
| Logistic regression (application features only) | 0.633 |
| Logistic regression (full engineered features) | 0.675 |
| Logistic regression + SMOTE | 0.658 |
| Random forest (100 trees, mtry = 5) | 0.667 |
| XGBoost base (200 trees, depth 4, lr 0.05) | 0.714 |
| XGBoost + SMOTE | 0.708 |
| **XGBoost tuned (space-filling search, 20 iterations)** | **0.726** |

### Key Findings

**Feature engineering provided the largest single performance gain.** Adding bureau history, previous application outcomes, installment payment behavior, credit card utilization, and POS cash features lifted logistic regression AUC from 0.633 to 0.675 — a 4.2-point improvement before changing algorithms at all.

**XGBoost outperformed all other algorithms.** Its ability to model non-linear interactions, handle missing values natively, and build sequentially corrective ensembles gave it a clear edge over both logistic regression and random forest on this dataset.

**SMOTE did not improve AUC.** Despite the severe class imbalance (~8% default rate), SMOTE hurt AUC for both logistic regression (0.675 → 0.658) and XGBoost (0.714 → 0.708). SMOTE is designed to improve minority-class recall, which does not always align with AUC-based ranking quality. The final model was trained without resampling.

### Final Model

The final model is a tuned XGBoost trained on the full 307,511-row training set using the best hyperparameters found via space-filling randomized search:

- Trees: 194
- Tree depth: 4
- Learning rate: 0.0137
- Loss reduction: 1.83
- Row sampling proportion: 0.895

**Kaggle public leaderboard AUC: 0.73592**

The Kaggle score is consistent with and slightly above the tuned CV AUC (0.726), reflecting the benefit of retraining on the full dataset after selecting hyperparameters on the subsample.

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
train_df        <- fread("application_train.csv")
test_df         <- fread("application_test.csv")
bureau_df       <- fread("bureau.csv")
prev_app_df     <- fread("previous_application.csv")
installments_df <- fread("installments_payments.csv")
cc_df           <- fread("credit_card_balance.csv")
pos_df          <- fread("POS_CASH_balance.csv")
```

4. Prepare the training dataset:
```r
train_result <- prepare_data(
  app_df          = train_df,
  bureau_df       = bureau_df,
  prev_app_df     = prev_app_df,
  installments_df = installments_df,
  cc_df           = cc_df,
  pos_df          = pos_df
)
train_clean <- train_result$df
train_stats <- train_result$train_stats
```

5. Prepare the test dataset using training statistics to ensure consistent transformations:
```r
test_result <- prepare_data(
  app_df          = test_df,
  train_stats     = train_stats,
  bureau_df       = bureau_df,
  prev_app_df     = prev_app_df,
  installments_df = installments_df,
  cc_df           = cc_df,
  pos_df          = pos_df
)
test_clean <- test_result$df
```

---

## Outputs

The pipeline produces:

- `train_clean` — Cleaned and feature-engineered training dataset ready for modeling
- `test_clean` — Cleaned and feature-engineered test dataset with identical columns to training
- `train_stats` — Summary statistics (medians, min/max, bin thresholds) used to ensure consistent train/test transformations
- `submission.csv` — Predicted default probabilities for all 48,744 test applicants

Optional: save datasets to CSV:
```r
fwrite(train_clean, "train_features.csv")
fwrite(test_clean,  "test_features.csv")
```