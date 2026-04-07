# Home Credit Default Risk — Predicting Loan Default for Underserved Borrowers

**Author:** Chance Hansen &nbsp;|&nbsp; **Program:** MS Business Analytics, University of Utah &nbsp;|&nbsp; **Kaggle AUC: 0.73592**

---

## Table of Contents

1. [Business Problem & Project Objective](#-business-problem--project-objective)
2. [Project Status](#-project-status)
3. [Solution](#-solution)
4. [Group Project](#-group-project)
5. [My Individual Contribution](#-my-individual-contribution)
6. [Business Value](#-business-value)
7. [Key Results](#-key-results)
8. [Challenges Encountered](#-challenges-encountered)
9. [What I Learned](#-what-i-learned)
10. [Technical Project Overview](#-technical-project-overview)
11. [Repository Files](#-repository-files)
12. [Modeling Notebook Highlights](#-modeling-notebook)
13. [How to Reproduce](#-how-to-reproduce)
14. [FAQ](#-FAQ)

---

## Business Problem & Project Objective

**Home Credit** serves borrowers who are largely excluded from traditional lending, such as those without credit scores, formal employment records, or conventional banking history. This population is often denied credit not because they are high-risk, but simply because there is insufficient data to evaluate them using standard methods.

The challenge: **predict the probability that a loan applicant will default**, using a rich set of alternative data sources including payment history, bureau records, previous applications, and transactional behavior. Accurate predictions allow Home Credit to extend credit responsibly to more people while protecting the business from unacceptable losses.

This project was completed as part of a [Kaggle competition](https://www.kaggle.com/competitions/home-credit-default-risk) involving over 300,000 loan applications and 7 relational data tables.

---

## Project Status
- Feature engineering functions implemented and reusable for train/test datasets.
- Cleaned anomalies, created demographic and financial ratio features, aggregated transactional data, and ensured train/test consistency.
- Modeling notebook complete with cross-validation, class imbalance experiments, hyperparameter tuning, and Kaggle submission.
- Model Card created
- Project completed.

---

## Solution

I built an end-to-end machine learning pipeline in R that:

1. **Cleaned and prepared** raw data across 7 relational tables, fixing sentinel values, normalizing encodings, and handling missing data without leakage
2. **Engineered 50+ predictive features** from demographic, financial, behavioral, and bureau data
3. **Evaluated six model configurations** using stratified cross-validation, comparing a majority-class baseline through tuned XGBoost
4. **Selected a tuned XGBoost model** as the champion, trained on the full 307,511-row training set
5. **Submitted predictions** for 48,744 test applicants to Kaggle, achieving a public leaderboard AUC of **0.73592**

The final model outputs a default probability for each applicant. In a real deployment, this score would drive underwriting decisions, such as approving, declining, or flagging applications for manual review based on a business-optimized probability threshold.

### Group Project

After completing our own iterations of the project, I connected with colleages to collaborate and present the best overall findings of the Home Credit Default Risk assignment.

### My Individual Contribution

My work focused on setup and components of the pipeline such as **feature engineering**. Additionally I reported on the outcome of the **predictive modeling**, and what the **key indicators** were that predicted default.

---

## Business Value

A well-calibrated default prediction model delivers value across multiple dimensions:

**Reduced Loan Losses**
The model identifies high-risk applicants before a loan is made. Even modest improvement in default detection translates to millions of dollars in avoided losses across a portfolio of 300,000+ loans.

**More Inclusive Lending**
By using alternative data (payment history, bureau records, transactional behavior) rather than traditional credit scores alone, the model helps extend credit to creditworthy borrowers who would otherwise be rejected. This expands the customer base while managing risk responsibly which was the Home Credit's mission.

**Faster, More Consistent Decisions**
An automated scoring model makes decisions in milliseconds, at any volume, with no variation due to human judgment or fatigue. This reduces the cost per application and enables scalable lending operations.

**Regulatory Defensibility**
The model card documents performance, limitations, and fairness considerations, which provides an audit trail for regulatory review and enabling adverse action reasons to be communicated to declined applicants in compliance with ECOA and FCRA requirements.

---

## Key Results

| Model | Cross-Validation AUC |
|---|---|
| Majority-class baseline | 0.500 |
| Logistic Regression — application features only | 0.633 |
| Logistic Regression — full engineered features | 0.675 |
| Logistic Regression + SMOTE | 0.658 |
| Random Forest (100 trees, mtry = 5) | 0.667 |
| XGBoost — base configuration | 0.714 |
| XGBoost + SMOTE | 0.708 |
| **XGBoost — tuned (20-iteration search)** | **0.726** |

**Final model hyperparameters** (selected via space-filling search):

- Trees: 194 &nbsp;|&nbsp; Max depth: 4 &nbsp;|&nbsp; Learning rate: 0.0137
- Loss reduction: 1.83 &nbsp;|&nbsp; Row sampling: 0.895

---

## Challenges Encountered

**1. Data Scale and Complexity**
The dataset spans 7 relational tables with hundreds of raw variables and over 300,000 records. Joining and aggregating this data (especially the bureau, installment, and credit card tables) required careful thinking and planning about aggregation logic and memory efficiency in R.

**2. Preventing Data Leakage**
A subtle but critical challenge: any preprocessing statistic (median, min/max, bin threshold) computed on the combined train+test set leaks future information into the training process, inflating apparent model performance. Designing the pipeline to compute all parameters from training data only (and apply them consistently to test data) required disciplined engineering and careful code architecture.

**3. Class Imbalance**
Only about 8% of applicants in the training set defaulted. This imbalance causes naive models to simply predict "no default" for everyone, achieving 92% accuracy while being completely useless for the business. We tested SMOTE oversampling but found it actually reduced AUC, ultimately relying on XGBoost's built-in `scale_pos_weight` parameter instead.

**4. Computational Constraints**
Training on the full 307,511-row dataset with cross-validation was time-consuming, especially for hyperparameter search. We addressed this by running model selection on a stratified 5,000-row subsample and only retraining the final model on the full dataset after selecting the best configuration.

**5. Feature Selection and Noise**
With 50+ engineered features, there was risk of overfitting to noise. Balancing feature richness against model generalizability required disciplined use of cross-validation and early stopping.

---

## What I Learned

**Feature engineering matters more than algorithm choice.** Adding engineered features lifted logistic regression AUC from 0.633 to 0.675 (a +4.2 point gain) without changing the algorithm at all. No amount of hyperparameter tuning on weak inputs can substitute for better features.

**Gradient boosting is exceptionally well-suited to tabular, imbalanced data.** XGBoost's sequential error-correction, native missing value handling, and built-in regularization gave it a decisive edge over both logistic regression and random forest. Understanding *why* a method works not just *that* it works is essential for explaining modeling decisions to stakeholders.

**Empirical validation beats intuition.** I expected SMOTE to help given the severe class imbalance. It didn't, it actually hurt AUC for both logistic regression and XGBoost. The lesson: always validate your assumptions, because common intuitions don't always hold on a given dataset.

**Reproducible pipelines are non-negotiable.** Designing a pipeline where all parameters flow cleanly from training data to test data with no manual steps or ad hoc fixes was more work upfront but made iteration far faster and the final results trustworthy and auditable.

**Data science is communication.** A model that produces great predictions but cannot be explained to a business stakeholder or regulator has limited real-world value. Writing the model card forced me to think about how the model would actually be used, by whom, and what could go wrong.

---

## Technical Project Overview

There were two major elements to this project that lead to the success, **feature engineering** and **predictive modeling**. I finalized the project with a **model card** to document the outcome.

### Feature Engineering (`feature_engineering.R`)

I built a fully modular, reusable R script that transforms raw Home Credit data into a model-ready feature set. Key contributions include:

- **Financial ratios:** Debt-to-income (DTI), credit-to-income, loan-to-value (LTV), and payment-to-annuity ratios. All variables that directly capture a borrower's financial burden.
- **Demographic features:** Age in years (converted from days), employment duration, derived age groups and income brackets.
- **Bureau aggregations:** Loan counts, active vs. closed loans, overdue debt amounts, and credit utilization from external bureau records.
- **Behavioral features:** Late payment rates, overpayment trends, and installment payment consistency derived from transaction history.
- **Missing value indicators:** Strategic binary flags for missingness patterns, which themselves carry predictive signal (e.g., applicants without external credit scores).
- **Train/test consistency:** All imputation parameters (medians, bin thresholds) are computed from training data only and applied identically to the test set, **preventing data leakage**.

### Predictive Modeling (`Modeling_HansenChance.qmd`)

I designed and ran a systematic model comparison and tuning workflow:

- Constructed a stratified 5,000-row subsample for fast, reproducible cross-validation
- Evaluated six model configurations: majority-class baseline, logistic regression (two feature sets), SMOTE variants, random forest, and XGBoost
- Performed a 20-iteration space-filling hyperparameter search to tune XGBoost
- Retrained the final model on the full 307,511-row dataset and submitted predictions to Kaggle

### Model Card (`ModelCard_HansenChance.qmd`)

I documented the final model's intended use cases, performance characteristics, limitations, and fairness considerations in a structured model card.

---

## Repository Files

| File | Description |
|---|---|
| [`feature_engineering.R`](feature_engineering.R) | Reusable data cleaning & feature engineering pipeline |
| [`Modeling_HansenChance.qmd`](Modeling_HansenChance.qmd) | Full modeling notebook: cross-validation, tuning, Kaggle submission |
| [`ModelCard_HansenChance.qmd`](ModelCard_HansenChance.qmd) | Model card: intended use, performance, limitations, fairness |

---

## Modeling Notebook (`Modeling_HansenChance.qmd`)

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

**Feature engineering provided the largest single performance gain.** Adding bureau history, previous application outcomes, installment payment behavior, credit card utilization, and POS cash features lifted logistic regression AUC from 0.633 to 0.675; a 4.2-point improvement before changing algorithms at all.

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

## How to Reproduce

### Requirements

```r
install.packages(c("data.table", "dplyr", "tidymodels", "xgboost", "themis"))
```

### Data Setup

Download the following CSVs from the [Kaggle competition page](https://www.kaggle.com/competitions/home-credit-default-risk/data) and place them in the project root:

- `application_train.csv`
- `application_test.csv`
- `bureau.csv`
- `previous_application.csv`
- `installments_payments.csv`
- `credit_card_balance.csv`
- `POS_CASH_balance.csv`

### Run the Pipeline

```r
# Step 1: Source the feature engineering script
source("feature_engineering.R")

# Step 2: Load the datasets:
train_df        <- fread("application_train.csv")
test_df         <- fread("application_test.csv")
bureau_df       <- fread("bureau.csv")
prev_app_df     <- fread("previous_application.csv")
installments_df <- fread("installments_payments.csv")
cc_df           <- fread("credit_card_balance.csv")
pos_df          <- fread("POS_CASH_balance.csv")

# Step 3: Prepare training data
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

# Step 4: Prepare test data using training statistics (no leakage)
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

# Step 5: Open Modeling_HansenChance.qmd in RStudio or Positron and render to run the full pipeline
```

### Outputs

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

---

## FAQ

**Q: What was your approach to feature engineering?**
- A: I joined 7 relational tables and engineered 50+ features from scratch creating financial ratios like DTI and LTV, behavioral aggregations from payment history, missing value indicators, and interaction terms. The critical discipline was computing all statistics from training data only and applying them identically to the test set. That constraint forces you to think carefully about every transformation, and it's the difference between a model that generalizes and one that just looks good in development.

**Q: Why did you choose XGBoost over the other algorithms?**
- A: Logistic regression plateaued around 0.675 AUC even with rich features because it cannot capture non-linear interactions without explicit polynomial terms. Random forest (0.667) underperformed XGBoost (0.714) because the boosting framework iteratively corrects residual errors, which is particularly powerful on noisy, imbalanced data. XGBoost also handles missing values natively and trains in seconds at 300K rows. Those practical advantages matter in actual production.

**Q: How did you handle class imbalance?**
- A: I tested SMOTE but found it reduced AUC from 0.675 to 0.658 for logistic regression and from 0.714 to 0.708 for XGBoost. SMOTE optimizes minority-class recall, not AUC ranking quality, and those objectives don't always align. I ultimately used XGBoost's `scale_pos_weight` parameter to implicitly up-weight the minority class during training, which proved more effective.

**Q: What would you do with more time?**
- A: I'd explore LightGBM or CatBoost, run a broader hyperparameter search, and invest more systematically in feature selection to reduce noise. I'd also deepen the fairness analysis in the model card — credit models can encode demographic bias in subtle ways, and that has both ethical and regulatory implications worth understanding before deployment.

---

*This project was completed as part of IS 6850 — Business Analytics Capstone 1, David Eccles School of Business, University of Utah.*
