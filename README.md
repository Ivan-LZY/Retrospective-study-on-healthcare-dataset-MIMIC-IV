# SPH5104 Analytics for Better Health
In this group project, we have done a retrospective study on Unfractionated Heparin and Enoxaparin Prophylaxis in relation to the occurrence of Venous Thromboembolism (VTE) among patients in the surgical intensive care unit. For more context, the written report for this project is uploaded to this repository.

The dataset was extracted from MIMIC-IV, a freely accessible electronic health record dataset: https://www.nature.com/articles/s41597-022-01899-x

# Group Members
1. Chanel Koh Xue Mei
2. Huang Xining
3. Ivan Lim Zhengyu
4. Jin Qianyi
5. Luu Hoang Huong
6. Matthew Peh Wei Ern
7. Wang Zihong

# Brief description on the codes

1. Covariate_extraction.sql: A SQL code that extracts the required covariates and outcomes from from the MIMIC-IV database.
2. MIMIC-IV_dataprocessing_n_cleaning.ipynb: A jupyter-notebook to clean up the dataset and encoded the data to prepare it for model trainings and statistical analysis.
3. Baseline_and_propensity_score_matching.ipynb: A jupyter-notebook to calculate baseline characteristics for Table 1 and adjust for confounder effects using Propensity score matching.
4. Chi_Square_Fiosher.do: A STATA file for Chi-square and Fisher Exact tests for odds ratio calculations
5. Conditional_log_regression: A jupyter-notebook for using conditional logistic regression to calculate odds ratio for a propensity score matched cohort.
6. Survival_Analysis_km_cox.R: R code to perform survival analysis for the secondary outcome: In-hospital mortality rate
7. Subgroup_analysis.R: R code for subgroup analysis for the primary outcome: Risk of VTE

# A quick glance on the results and analysis

<p align="center">
  <img src="https://github.com/Ivan-LZY/Restrospective-study-on-healthcare-dataset-MIMIC-IV/blob/main/Figures/data_extraction.png">
  <a><br>Data extraction</a>
</p>
<br>
<p align="center">
  <img src="https://github.com/Ivan-LZY/Restrospective-study-on-healthcare-dataset-MIMIC-IV/blob/main/Figures/data_cleaning.png">
  <a><br>Data cleaning and processing</a>
</p>
<br>
<p align="center">
  <img src="https://github.com/Ivan-LZY/Restrospective-study-on-healthcare-dataset-MIMIC-IV/blob/main/Figures/PSM.gif">
  <a><br>Propensity score matching with varying 1:N ratios. For our imbalanced dataset, the matching between the treatment group and the control group gets better when N is reduced.</a>
</p>
<br>
<p align="center">
  <img src="https://github.com/Ivan-LZY/Restrospective-study-on-healthcare-dataset-MIMIC-IV/blob/main/Figures/EffectSizing.gif">
  <a><br>A better propensity score matching also leads to small (SMD<0.25) effect sizes on the confounder covariates.</a>
</p>
<br>
<p align="center">
  <img src="https://github.com/Ivan-LZY/Restrospective-study-on-healthcare-dataset-MIMIC-IV/blob/main/Figures/KM.png">
  <a><br>Survival Analysis: Kaplan-Meier survival curves for in-hospital mortality rate</a>
</p>

