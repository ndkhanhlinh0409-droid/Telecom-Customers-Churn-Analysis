### Group variables
numeric_vars <- names(dataset)[sapply(dataset, is.numeric)]
categorical_vars <- names(dataset)[sapply(dataset, is.character)]

### convert ordinal variables
ordinal_vars <- c(
  "Contract","charge_tier","PaymentMethod","tenure_group"
)
dataset[ordinal_vars] <- lapply(dataset[ordinal_vars], factor)

for (v in ordinal_vars) {
  dataset[[v]] <- as.numeric(ordered(dataset[[v]]))
}

### convert binary variables
binary_vars <- c(
  "Partner", "Dependents", "PhoneService",
  "PaperlessBilling", "SeniorCitizen"
)
dataset[binary_vars] <- lapply(dataset[binary_vars], factor)

for (v in binary_vars) {
  dataset[[v]] <- as.numeric(dataset[[v]]) - 1
}

### convert unordered variables
internet_cols <- c("TechSupport", "OnlineSecurity", "OnlineBackup",
                   "DeviceProtection", "StreamingTV", "StreamingMovies")
dataset[internet_cols] <- lapply(dataset[internet_cols], factor)

library(tidyverse)
for(v in internet_cols){
  dataset[[v]] <- trimws(as.character(dataset[[v]]))
  dataset[[v]] <- factor(dataset[[v]],
                         levels = c("No internet service","No","Yes"),
                         ordered = TRUE)
  dataset[[v]] <- as.numeric(dataset[[v]]) - 1
}

dataset$InternetService <- as.numeric(factor(trimws(dataset$InternetService),
                                             levels = c("No","DSL","Fiber optic"),
                                             ordered = TRUE)) - 1
dataset$MultipleLines <- as.numeric(factor(trimws(dataset$MultipleLines),
                                           levels = c("No phone service","No","Yes"),
                                           ordered = TRUE)) - 1

### Logistic regresssion
model <- glm(
  churn_flag ~ Partner + Dependents + PhoneService + PaperlessBilling + SeniorCitizen +
    Contract + charge_tier + PaymentMethod + tenure_group +
    TechSupport + OnlineSecurity + OnlineBackup + DeviceProtection +
    StreamingTV + StreamingMovies + MultipleLines + InternetService,
  data = dataset,
  family = binomial
)
summary(model)


### Confusion matrix
dataset$predicted_prob <- predict(model, type = "response")
dataset$predicted_class <- ifelse(dataset$predicted_prob > 0.5, 1, 0)

install.packages("caret")
library(caret)
conf_matrix <- confusionMatrix(as.factor(dataset$predicted_class),
                               as.factor(dataset$churn_flag))
conf_matrix

### Top 30 high risk customers
highrisk_customers <- dataset %>%
  filter(churn_flag == 0) %>%
  arrange(desc(predicted_prob)) %>%
  mutate(annual_revenue_at_risk = MonthlyCharges * 12) %>%
  slice(1:30) %>%
  select(customerID, gender,
         Contract, tenure_group, charge_tier, InternetService,
         PaymentMethod, TechSupport, PaperlessBilling, SeniorCitizen,
         predicted_prob, MonthlyCharges, annual_revenue_at_risk)
print(highrisk_customers)
write.csv(highrisk_customers, "top30_highrisk_customers.csv", row.names = FALSE)
write_xlsx(highrisk_customers, "C:/Users/Asus/Downloads/top30highrisk.xlsx")
