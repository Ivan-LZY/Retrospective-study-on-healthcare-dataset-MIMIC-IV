library(tidyverse)
library(epitools)
library(data.table)
library(Amelia)

#read unbalanced dataset 
df <- read.csv("finalwithvte.csv") 
any(is.na(df))
#print missingness map
print(missmap(df))

#read balanced dataset
list.files(getwd())
finalwvte <- fread("finalwithvte_balanced_13Apr_n10.csv")


#Subgroup analysis: No renal impairment 

 #Subgroup: no renal impairment
hep.vte <- 316
hep.novte <- 2724
lmwh.vte <- 145
lmwh.novte <- 162

vte.nori <- as.table(rbind(c(hep.vte, hep.novte),
                           c(lmwh.vte, lmwh.novte)))

dimnames(vte.nori) <- list(c("Heparin", "Enoxaparin"),
                           c("VTE", "No VTE"))

vte.nori #2x2 contingency table
oddsratio(vte.nori) #calculates odds ratio

#Subgroup: renal impairment
##Heparin, renal impairment
hep.ri <- finalwvte %>%
  filter(encoded_input == 1) #for Heparin group

hep.ri_vte <- hep.ri %>%
  filter(creat_clr == 0) #creat clearance <30, vte (+) group

hep.ri_vte <- sum(hep.ri_vte$have_vte)
hep.ri_novte <- nrow(hep.ri_vte)- sum(hep.ri_vte$have_vte)

##Enoxaparin, renal impairment
lmwh.ri <- finalwvte %>%
  filter(encoded_input == 0)

lmwh.ri_vte <- lmwh.ri  %>%
  filter(creat_clr == 0)

lmwh.ri_vte <- sum(lmwh.ri_vte$have_vte)
lmwh.ri_novte <- nrow(lmwh.ri_vte)- sum(lmwh.ri_vte$have_vte)


