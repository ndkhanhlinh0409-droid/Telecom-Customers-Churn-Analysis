---- DATA PREPROCESSING
-- check data type 
select
    column_name,
    data_type
from information_schema.columns
where table_name = 'telecustomer';


-- row count 
select count(*) as total_rows from telecustomer;

-- duplicate check 
select customerID, count(*) as cnt 
from telecustomer
group by customerID
having count(*) > 1;

-- check missing values
select 
sum(case when customerID is null then 1 else 0 end) as null_ID,
sum(case when gender is null then 1 else 0 end) as null_gender,
sum(case when SeniorCitizen is null then 1 else 0 end) as null_senior,
sum(case when tenure is null then 1 else 0 end) as null_tenure,
sum(case when MonthlyCharges is null then 1 else 0 end) as null_monthly,
sum(case when TotalCharges is null then 1 else 0 end) as null_total,
sum(case when Churn is null then 1 else 0 end) as null_churn
from telecustomer;

select customerID, TotalCharges, Churn, tenure 
from telecustomer 
where tenure = 0;

-- create new clean table and fix
select 
customerID,
gender,
case when SeniorCitizen = 1 then 'Yes' else 'No' end as SeniorCitizen, -- convert 0/1 to yes/no
Partner,
Dependents,
tenure,
PhoneService,
MultipleLines,
InternetService,
OnlineSecurity,
OnlineBackup,
    DeviceProtection,
    TechSupport,
    StreamingTV,
    StreamingMovies,
    Contract,
    PaperlessBilling,
    PaymentMethod,
    MonthlyCharges,

    case when TotalCharges is null then MonthlyCharges else TotalCharges end as TotalCharges, -- imputation of null value in totalcharges with monthlycharges
    case when Churn = 'Yes' then 1 else 0 end as churn_flag, 
    case -- create new column: tenure group
    when tenure <=12 then '0-1 year'
    when tenure <=24 then '1-2 years'
    when tenure <= 48 then '2-4 years'
    else '4+ years'
    end as tenure_group, 

    case -- create charge tier
    when MonthlyCharges < 35 then 'Low'
    when MonthlyCharges < 70 then 'Mid'
    else 'High'
    end as charge_tier
into telecustomer_clean 
from telecustomer
where customerID is not null;

-- checking clean table 
select count(*) as total_rows from telecustomer_clean;
select count(*) as blanks from telecustomer_clean where TotalCharges is null;
select * from telecustomer_clean;

---- DESCRIPTIVE & EDA
---Overall business picture
--churn rate
select
churn_flag,
count(*) as total,
round(100* count(*)/sum(count(*)) over(), 2) as pct
from telecustomer_clean
group by churn_flag;

-- Avg tenure month and charges of each group (churned vs retained)
select 
churn_flag,
round(avg(tenure),1) as avg_tenure,
round(avg(TotalCharges),2) as avg_totalcharges, 
round(avg(MonthlyCharges),2) as avg_monthly
from telecustomer_clean
group by churn_flag;


--- Single factor
-- Customer profile
-- churned by contract type
select 
Contract, 
count(*) as total, 
sum(churn_flag) as churned,
round(100.0 * avg(cast(churn_flag as float)), 1) as contract_churn_pct
from telecustomer_clean
group by Contract;

-- churned by tenure group
select 
tenure_group,
count(*) as total,
sum(churn_flag) as churned, 
round(100.0 * avg(cast(churn_flag as float)), 1) as tenure_churn_pct
from telecustomer_clean
group by tenure_group
order by tenure_group asc;

-- churned by charge tier
select 
charge_tier,
count(*) as total,
sum(churn_flag) as churned, 
round(100.0 * avg(cast(churn_flag as float)), 1) as charge_churn_pct
from telecustomer_clean
group by charge_tier
order by charge_tier asc;

--churned by senior citizen 
select 
SeniorCitizen,
count(*) as total,
sum(churn_flag) as churned, 
round(100.0 * avg(cast(churn_flag as float)), 1) as citizen_churn_pct
from telecustomer_clean
group by SeniorCitizen
order by citizen_churn_pct desc;

-- churned by payment method
select 
PaymentMethod,
count(*) as total,
sum(churn_flag) as churned, 
round(100.0 * avg(cast(churn_flag as float)), 1) as payment_churn_pct
from telecustomer_clean
group by PaymentMethod;

--churned by paperless billing 
select 
PaperlessBilling,
count(*) as total,
sum(churn_flag) as churned, 
round(100.0 * avg(cast(churn_flag as float)), 1) as billing_churn_pct
from telecustomer_clean
group by PaperlessBilling
order by billing_churn_pct desc;

-- churned by tech support
select 
TechSupport,
count(*) as total,
sum(churn_flag) as churned, 
round(100.0 * avg(cast(churn_flag as float)), 1) as support_churn_pct
from telecustomer_clean
group by TechSupport
order by support_churn_pct desc;

-- churned by internet service
select 
InternetService,
count(*) as total,
sum(churn_flag) as churned, 
round(100.0 * avg(cast(churn_flag as float)), 1) as service_churn_pct
from telecustomer_clean
group by InternetService
order by service_churn_pct desc;



--- Muliple factors:
-- tenure group x charge tier 
select
    tenure_group,
    charge_tier,
    count(*) as total,
    sum(churn_flag) as churned,
    round(100.0 * avg(cast(churn_flag as float)), 1) as churn_pct
from telecustomer_clean
group by tenure_group, charge_tier
order by tenure_group, churn_pct desc;


-- tenure group x contract
select
    tenure_group,
    Contract,
    count(*) as total,
    sum(churn_flag) as churned,
    round(100.0 * avg(cast(churn_flag as float)), 1) as churn_pct
from telecustomer_clean
group by tenure_group, Contract
order by tenure_group, churn_pct desc;

-- internet service x tech support
select
    InternetService,
    TechSupport,
     count(*) as total,
    sum(churn_flag) as churned,
    round(100.0 * avg(cast(churn_flag as float)), 1) as churn_pct
from telecustomer_clean
where InternetService != 'No'
group by InternetService, TechSupport
order by InternetService, churn_pct desc;

-- internet service x charge tier
select
    InternetService,
    charge_tier,
     count(*) as total,
    sum(churn_flag) as churned,
    round(100.0 * avg(cast(churn_flag as float)), 1) as churn_pct
from telecustomer_clean
where InternetService != 'No'
group by InternetService, charge_tier
order by InternetService, churn_pct desc;

-- payment method x contract
select
    PaymentMethod,
    Contract,
    count(*) as total,
    sum(churn_flag) as churned,
    round(100.0 * avg(cast(churn_flag as float)), 1) as churn_pct
from telecustomer_clean
group by PaymentMethod, Contract
order by PaymentMethod, churn_pct desc;


-- senior citizen x contract type 
select
    Contract,
    SeniorCitizen,
     count(*) as total,
    sum(churn_flag) as churned,
    round(100.0 * avg(cast(churn_flag as float)), 1) as churn_pct
from telecustomer_clean
group by Contract, SeniorCitizen
order by Contract, churn_pct desc;

--- Revenue + Summary
-- monthly revenue lost
select 
sum(case when churn_flag = 0 then MonthlyCharges else 0 end) as retained_revenue,
sum(case when churn_flag = 1 then MonthlyCharges else 0 end) as churned_revenue
from telecustomer_clean;


-- risk score
create view risk_scored as
select
customerID,
        tenure_group,
        MonthlyCharges,
        Contract,
        InternetService,
        PaymentMethod,
        TechSupport,
        SeniorCitizen,
        PaperlessBilling,
        (case when tenure_group = '0-1 year' then 2 else 0 end +
        case when MonthlyCharges > 70 then 1 else 0 end+
        case when Contract = 'Month-to-month' then 2 else 0 end+
        case when PaymentMethod = 'Electronic check' then 1 else 0 end+
        case when InternetService = 'Fiber optic' then 1 else 0 end +
        case when TechSupport = 'No' then 1 else 0 end+
        case when SeniorCitizen = 'Yes' then 1 else 0 end +
        case when PaperlessBilling = 'Yes' then 1 else 0 end) as risk_score 
from telecustomer_clean
where churn_flag = 0;


-- top 30 customers 
select top 30 *,
rank() over(order by risk_score desc, MonthlyCharges desc) as risk_rank
from risk_scored
order by risk_rank;

-- annual revenue at risk
select 
round(sum(MonthlyCharges),2) as risk_monthly_total,
round(sum(MonthlyCharges) * 12,2) as risk_annual_total
from (select top 30 MonthlyCharges
from risk_scored
order by risk_score desc, MonthlyCharges desc) as top30;


-- Do streaming customers cluster in fiber optic?
SELECT InternetService,
       ROUND(100.0 * SUM(CASE WHEN StreamingTV = 'Yes' THEN 1 ELSE 0 END) 
             / COUNT(*), 1) AS pct_streaming
FROM telecustomer_clean
GROUP BY InternetService;

-- Do streaming customers cluster in month-to-month?
SELECT Contract,
       ROUND(100.0 * SUM(CASE WHEN StreamingTV = 'Yes' THEN 1 ELSE 0 END) 
             / COUNT(*), 1) AS pct_streaming
FROM telecustomer_clean
GROUP BY Contract;