# Load necessary libraries
library(survival)
library(tidyverse)

# Read in the data
data <- read.csv("finalwithvte_balanced_13Apr.csv")


# Subset the data to include only relevant columns
cols <- c("subject_id", "admittime", "dischtime", "dod", "died", "label", "real_age", "congestive_heart_failure", "have_cancer", "severe_liver_disease", "first_careunit", "gender", "have_sepsis", "have_at_least_1_ventil", "first_day_sofa", "weight", "have_diabetes", "avg_creat")
data <- data %>% select(cols)

# Convert time variables to correct format
data$admittime <- as.POSIXct(data$admittime, format="%Y-%m-%d %H:%M:%S")
data$dischtime <- as.POSIXct(data$dischtime, format="%Y-%m-%d %H:%M:%S")
data$dod <- as.Date(data$dod, format="%Y-%m-%d")

# Create a time-to-event variable
data$time_to_event <- ifelse(data$died == 1, as.numeric(difftime(data$dod, data$admittime, units="days")), as.numeric(difftime(data$dischtime, data$admittime, units="days")))

# Subset the data by treatment group
data_heparin <- subset(data, label == "Heparin Sodium (Prophylaxis)")
data_enoxaparin <- subset(data, label == "Enoxaparin (Lovenox)")

# Fit Kaplan-Meier survival curves for each group
km_fit_heparin <- survfit(Surv(time_to_event, died) ~ 1, data = data_heparin)
km_fit_enoxaparin <- survfit(Surv(time_to_event, died) ~ 1, data = data_enoxaparin)

# Plot the Kaplan-Meier survival curves for each group
plot(km_fit_heparin, col="blue", xlab = "Days since admission", ylab = "Survival probability", main = "Kaplan-Meier survival curves", ylim=c(0,1), xlim=c(0, 100))
lines(km_fit_enoxaparin, col="red")

# Add a legend
legend("bottomright", legend=c("Heparin Sodium (Prophylaxis)", "Enoxaparin"), col=c("blue", "red"), lty=1, cex=0.7)

# Conduct a log-rank test to compare the survival curves
lr_test <- survdiff(Surv(time_to_event, died) ~ label, data = data)

# Print the results of the log-rank test
cat("Log-rank test results:\n")
print(lr_test)


# Fit Cox regression model
cox_fit <- coxph(Surv(time_to_event, died) ~ label + real_age + congestive_heart_failure + have_cancer + severe_liver_disease + first_careunit + gender + have_sepsis + have_at_least_1_ventil + first_day_sofa + weight + have_diabetes + avg_creat, data = data)
hazard_ratio <- exp(coef(cox_fit)[1])
conf_interval <- exp(confint(cox_fit)[1,])

hazard_ratio
conf_interval

cox_fit






























