
import delimited C:\Users\e0802491\Desktop\finalwithvte.csv
drop last_careunit count admit_provider_id insurance language marital_status edregtime edouttime hospital_expire_flag anchor_year anchor_year_group input age_score weight_admit weight_min weight_max

// . Age
// 2. Congestive Heart Failure
// 3. Cancer
// 4. Liver disease
// 5. ICU types
// 6. Gender
// 7. Sepsis 
// 8. Mechanical ventilation
// 9. SOFA
// 10. Weight 
generate firstcareunit=.
replace firstcareunit=0 if first_careunit=="Medical/Surgical Intensive Care Unit (MICU/SICU)"
replace firstcareunit=1 if first_careunit=="Surgical Intensive Care Unit (SICU)"
//Multivariable logistic regression
xi: logistic have_vte i.encoded_input real_age i.congestive_heart_failure i.have_cancer i.severe_liver_disease i.firstcareunit i.gender i.have_sepsis i.have_at_least_1_ventil first_day_sofa weight
estat gof
lroc
clear

import delimited C:\Users\e0802491\Desktop\finalwithvte_balanced_13Apr_n10.csv
//just cleaning up some unnecessary variables
drop last_careunit count admit_provider_id insurance language marital_status edregtime edouttime hospital_expire_flag anchor_year anchor_year_group input age_score weight_admit weight_min weight_max


generate firstcareunit=.
replace firstcareunit=0 if first_careunit=="Medical/Surgical Intensive Care Unit (MICU/SICU)"
replace firstcareunit=1 if first_careunit=="Surgical Intensive Care Unit (SICU)"

// find out among the two groups of those who took heparin vs enoxaparin, how many have VTE, heparin-induced thrombocytopenia and major bleeding events
// generate risk and odds ratio via chi-sq and fisher exact method
cs have_vte encoded_input
cc have_vte encoded_input
cs hit encoded_input, exact
cc hit encoded_input, exact
cc major_bleeding encoded_input, exact
cs major_bleeding encoded_input, exact

// find out among the two groups of those who took heparin vs enoxaparin, how many have VTE occurences.
// Use fisher in case there are low cell counts
tabulate have_vte encoded_input, chi2 exact
tabulate major_bleeding encoded_input, chi2 exact
tabulate hit encoded_input, chi2 exact

// find out among the two groups of creatinine clearance category, how many have VTE occurences.
by creat_clr , sort : tabulate encoded_input have_vte

//to account for matching, conditional logistic regression should have been done.
// however since propensity score matching was done on python, conditional log reg can be done on  python too.