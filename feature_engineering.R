# feature_engineering.R
# ---------------------
# Author: Chance Hansen
# Date: February 8, 2026
# Purpose: Reusable feature engineering for Home Credit Default Risk
# Handles train/test consistently, cleans anomalies, imputes missing values,
# creates ratios, interaction features, binned variables, aggregates transactional data,
# produces applicant-level features.
# -----------------------------------------------

library(data.table)
library(dplyr)
library(stringr)

# --------------------------
# Helper Functions
# --------------------------

# Normalize numeric columns using min-max, preserving train/test consistency
normalize_col <- function(x, train_stats = NULL, col_name = NULL) {
  if (!is.null(train_stats)) {
    min_val <- train_stats$min[[col_name]]
    max_val <- train_stats$max[[col_name]]
  } else {
    min_val <- min(x, na.rm = TRUE)
    max_val <- max(x, na.rm = TRUE)
  }
  return((x - min_val) / (max_val - min_val))
}

# Create bins (quantiles) using training thresholds
bin_col <- function(x, thresholds) {
  return(as.integer(cut(x, breaks = c(-Inf, thresholds, Inf), include.lowest = TRUE)))
}

# Convert days to numeric
time_relative <- function(x) as.numeric(x)

# Fix DAYS_EMPLOYED anomaly
clean_days_employed <- function(x) {
  x[x == 365243] <- NA
  return(x)
}

# --------------------------
# Process application data
# --------------------------
process_application <- function(app_df, train_stats = NULL, n_bins = 5) {
  
  df <- copy(app_df)
  
  # ------------------------
  # Fix anomalies
  # ------------------------
  df$DAYS_EMPLOYED <- clean_days_employed(df$DAYS_EMPLOYED)
  
  # Convert negative days to years
  df <- df %>%
    mutate(
      AGE_YEARS = -DAYS_BIRTH / 365.25,
      EMPLOYED_YEARS = ifelse(DAYS_EMPLOYED < 0, -DAYS_EMPLOYED / 365.25, NA),
      REGISTRATION_YEARS = -DAYS_REGISTRATION / 365.25,
      ID_PUBLISH_YEARS = -DAYS_ID_PUBLISH / 365.25
    )
  
  # ------------------------
  # Missing indicators
  # ------------------------
  df <- df %>%
    mutate(
      OWN_CAR_AGE_MISSING = as.integer(is.na(OWN_CAR_AGE)),
      AMT_GOODS_PRICE_MISSING = as.integer(is.na(AMT_GOODS_PRICE)),
      EXT_SOURCE_1_MISSING = as.integer(is.na(EXT_SOURCE_1)),
      EXT_SOURCE_2_MISSING = as.integer(is.na(EXT_SOURCE_2)),
      EXT_SOURCE_3_MISSING = as.integer(is.na(EXT_SOURCE_3))
    )
  
  # Impute EXT_SOURCE variables with median from train
  ext_sources <- c("EXT_SOURCE_1","EXT_SOURCE_2","EXT_SOURCE_3")
  for (col in ext_sources) {
    if (is.null(train_stats)) {
      median_val <- median(df[[col]], na.rm = TRUE)
      df[[col]][is.na(df[[col]])] <- median_val
    } else {
      df[[col]][is.na(df[[col]])] <- train_stats$median[[col]]
    }
  }
  
  # ------------------------
  # Binary flags
  # ------------------------
  df <- df %>%
    mutate(
      FLAG_OWN_CAR    = as.integer(FLAG_OWN_CAR == "Y"),
      FLAG_OWN_REALTY = as.integer(FLAG_OWN_REALTY == "Y"),
      FLAG_MOBIL       = as.integer(FLAG_MOBIL),
      FLAG_EMP_PHONE   = as.integer(FLAG_EMP_PHONE),
      FLAG_WORK_PHONE  = as.integer(FLAG_WORK_PHONE),
      FLAG_CONT_MOBILE = as.integer(FLAG_CONT_MOBILE),
      FLAG_PHONE       = as.integer(FLAG_PHONE),
      FLAG_EMAIL       = as.integer(FLAG_EMAIL)
    )
  
  # ------------------------
  # Financial ratios
  # ------------------------
  df <- df %>%
    mutate(
      INCOME_CREDIT_RATIO = AMT_INCOME_TOTAL / AMT_CREDIT,
      ANNUITY_INCOME_RATIO = AMT_ANNUITY / AMT_INCOME_TOTAL,
      CREDIT_GOODS_RATIO   = AMT_CREDIT / AMT_GOODS_PRICE,
      CREDIT_ANNUITY_RATIO = AMT_CREDIT / AMT_ANNUITY,
      INCOME_PER_PERSON    = AMT_INCOME_TOTAL / CNT_FAM_MEMBERS,
      EMPLOYED_INCOME_RATIO = AMT_INCOME_TOTAL / (EMPLOYED_YEARS + 0.01),
      DTI_RATIO = AMT_ANNUITY / AMT_INCOME_TOTAL,         # Debt-to-Income
      LTV_RATIO = AMT_CREDIT / AMT_GOODS_PRICE           # Loan-to-Value
    )
  
  # ------------------------
  # Interaction features
  # ------------------------
  df <- df %>%
    mutate(
      AGE_X_INCOME = AGE_YEARS * AMT_INCOME_TOTAL,
      INCOME_X_ANNUITY = AMT_INCOME_TOTAL * AMT_ANNUITY,
      CREDIT_X_AGE = AMT_CREDIT * AGE_YEARS
    )
  
  # ------------------------
  # Categorical columns
  # ------------------------
  cat_cols <- c("CODE_GENDER", "NAME_INCOME_TYPE", "NAME_EDUCATION_TYPE",
                "NAME_FAMILY_STATUS", "NAME_HOUSING_TYPE", "OCCUPATION_TYPE")
  df[cat_cols] <- lapply(df[cat_cols], factor)
  
  # ------------------------
  # Normalize numeric columns
  # ------------------------
  norm_cols <- c("REGION_POPULATION_RELATIVE", ext_sources)
  if (is.null(train_stats)) {
    min_vals <- sapply(df[norm_cols], min, na.rm = TRUE)
    max_vals <- sapply(df[norm_cols], max, na.rm = TRUE)
  } else {
    min_vals <- train_stats$min[norm_cols]
    max_vals <- train_stats$max[norm_cols]
  }
  
  for (col in norm_cols) {
    df[[col]] <- (df[[col]] - min_vals[[col]]) / (max_vals[[col]] - min_vals[[col]])
  }
  
  # ------------------------
  # Quantile Binning
  # ------------------------
  bin_cols <- c("AGE_YEARS", ext_sources)
  if (is.null(train_stats)) {
    thresholds <- lapply(df[bin_cols], function(x) quantile(x, probs = seq(0,1,length.out=n_bins+1)[-c(1,n_bins+1)], na.rm = TRUE))
  } else {
    thresholds <- train_stats$bin_thresholds
  }
  
  for (col in bin_cols) {
    df[[paste0(col,"_BIN")]] <- bin_col(df[[col]], thresholds[[col]])
  }
  
  # ------------------------
  # Save train stats
  # ------------------------
  if (is.null(train_stats)) {
    train_stats <- list(
      median = sapply(df[ext_sources], median, na.rm = TRUE),
      min = min_vals,
      max = max_vals,
      bin_thresholds = thresholds
    )
  }
  
  return(list(df = df, train_stats = train_stats))
}

# --------------------------
# Bureau Aggregation
# --------------------------
aggregate_bureau <- function(bureau_df) {
  bureau_df <- bureau_df %>%
    mutate(
      DAYS_CREDIT = time_relative(DAYS_CREDIT),
      DAYS_CREDIT_ENDDATE = time_relative(DAYS_CREDIT_ENDDATE),
      DAYS_ENDDATE_FACT = time_relative(DAYS_ENDDATE_FACT),
      DAYS_CREDIT_UPDATE = time_relative(DAYS_CREDIT_UPDATE)
    )
  
  bureau_agg <- bureau_df %>%
    group_by(SK_ID_CURR) %>%
    summarise(
      BUREAU_CREDIT_COUNT = n(),
      BUREAU_CREDIT_ACTIVE = sum(CREDIT_ACTIVE == "Active"),
      BUREAU_CREDIT_CLOSED = sum(CREDIT_ACTIVE == "Closed"),
      BUREAU_CREDIT_SUM = sum(AMT_CREDIT_SUM, na.rm = TRUE),
      BUREAU_CREDIT_DEBT = sum(AMT_CREDIT_SUM_DEBT, na.rm = TRUE),
      BUREAU_CREDIT_OVERDUE = sum(AMT_CREDIT_SUM_OVERDUE, na.rm = TRUE),
      BUREAU_DEBT_RATIO = sum(AMT_CREDIT_SUM_DEBT, na.rm = TRUE) / 
                          sum(AMT_CREDIT_SUM, na.rm = TRUE)
    )
  
  return(bureau_agg)
}

# --------------------------
# Previous Applications Aggregation
# --------------------------
aggregate_prev_app <- function(prev_df) {
  prev_df <- prev_df %>%
    mutate_at(vars(DAYS_DECISION:DAYS_TERMINATION, DAYS_FIRST_DRAWING:DAYS_LAST_DUE),
              time_relative)
  
  prev_agg <- prev_df %>%
    group_by(SK_ID_CURR) %>%
    summarise(
      PREV_COUNT = n(),
      PREV_APPROVED = sum(STATUS %in% c("Approved","XNA")),
      PREV_REFUSED = sum(!(STATUS %in% c("Approved","XNA"))),
      PREV_AMT_CREDIT_SUM = sum(AMT_CREDIT, na.rm = TRUE),
      PREV_AMT_ANNUITY_SUM = sum(AMT_ANNUITY, na.rm = TRUE),
      PREV_APPROVAL_RATE = PREV_APPROVED / PREV_COUNT
    )
  
  return(prev_agg)
}

# --------------------------
# Installments Aggregation
# --------------------------
aggregate_installments <- function(inst_df) {
  inst_df <- inst_df %>%
    mutate(DAYS_INSTALMENT = time_relative(DAYS_INSTALMENT),
           DAYS_ENTRY_PAYMENT = time_relative(DAYS_ENTRY_PAYMENT))
  
  inst_agg <- inst_df %>%
    group_by(SK_ID_CURR) %>%
    summarise(
      INSTALMENT_COUNT = n(),
      INSTALMENT_OVERPAY = sum(pmax(AMT_PAYMENT - AMT_INSTALMENT,0), na.rm = TRUE),
      INSTALMENT_LATE_RATE = mean(DAYS_ENTRY_PAYMENT - DAYS_INSTALMENT > 0, na.rm = TRUE)
    )
  
  return(inst_agg)
}

# --------------------------
# POS Cash Aggregation
# --------------------------
aggregate_pos <- function(pos_df) {
  pos_df <- pos_df %>%
    mutate(MONTHS_BALANCE = time_relative(MONTHS_BALANCE))
  
  pos_agg <- pos_df %>%
    group_by(SK_ID_CURR) %>%
    summarise(
      POS_COUNT = n(),
      POS_INSTALMENTS_LEFT = sum(CNT_INSTALMENT_FUTURE, na.rm = TRUE),
      POS_DPD_RATE = mean(CNT_INSTALMENT > CNT_INSTALMENT_FUTURE, na.rm = TRUE)
    )
  
  return(pos_agg)
}

# --------------------------
# Credit Card Aggregation
# --------------------------
aggregate_cc <- function(cc_df) {
  cc_df <- cc_df %>%
    mutate(MONTHS_BALANCE = time_relative(MONTHS_BALANCE))
  
  cc_agg <- cc_df %>%
    group_by(SK_ID_CURR) %>%
    summarise(
      CC_BALANCE_TOTAL = sum(AMT_BALANCE, na.rm = TRUE),
      CC_DRAWINGS_TOTAL = sum(AMT_DRAWINGS_CURRENT, na.rm = TRUE),
      CC_UTILIZATION = sum(AMT_BALANCE, na.rm = TRUE)/sum(AMT_CREDIT_LIMIT_ACTUAL, na.rm = 1)
    )
  
  return(cc_agg)
}

# --------------------------
# Prepare Data: Train/Test
# --------------------------
prepare_data <- function(app_df, train_stats = NULL,
                         bureau_df = NULL, prev_app_df = NULL,
                         installments_df = NULL, cc_df = NULL,
                         pos_df = NULL) {
  
  # ------------------------
  # Application features
  # ------------------------
  app_result <- process_application(app_df, train_stats)
  df <- app_result$df
  if (is.null(train_stats)) train_stats <- app_result$train_stats
  
  # ------------------------
  # Aggregate supplementary data
  # ------------------------
  if (!is.null(bureau_df)) df <- df %>%
    left_join(aggregate_bureau(bureau_df), by = "SK_ID_CURR")
  
  if (!is.null(prev_app_df)) df <- df %>%
    left_join(aggregate_prev_app(prev_app_df), by = "SK_ID_CURR")
  
  if (!is.null(installments_df)) df <- df %>%
    left_join(aggregate_installments(installments_df), by = "SK_ID_CURR")
  
  if (!is.null(cc_df)) df <- df %>%
    left_join(aggregate_cc(cc_df), by = "SK_ID_CURR")
  
  if (!is.null(pos_df)) df <- df %>%
    left_join(aggregate_pos(pos_df), by = "SK_ID_CURR")
  
  return(list(df = df, train_stats = train_stats))
}

# -----------------------------------------------
# End of feature_engineering.R
# -----------------------------------------------
