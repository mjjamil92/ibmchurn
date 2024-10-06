create database teleco_churn;
use teleco_churn;

-- Query 1: Considering the top 5 groups with the highest average monthly charges among churned -- customers, how can personalized offers be tailored based on age, gender, and contract type to potentially improve customer retention rates?
select*from `ibm churn`;
SELECT 
  CASE 
    WHEN Age < 30 THEN 'Young Adults' 
    WHEN Age >= 30 AND Age < 50 THEN 'Middle-Aged Adults' 
    ELSE 'Seniors' 
  END AS AgeGroup, 
  Contract, 
  Gender,
  ROUND(AVG(`Tenure in Months`), 2) AS AvgTenure,
  ROUND(AVG(`Monthly Charge`), 2) AS AvgMonthlyCharge
FROM `ibm churn`
WHERE `Churn Label` LIKE '%Yes%' 
GROUP BY AgeGroup, Contract, Gender 
ORDER BY AvgMonthlyCharge DESC
LIMIT 5;


-- Query 2: What are the feedback or complaints from those churned customers?
SELECT `Churn Category`, count(`Customer ID`) as churn_count
from  `ibm churn`
where `Churn Label` like "%Yes%"
group by `Churn Category`
order by churn_count desc;

-- check the churn reason for the "Other" category 

SELECT `Churn Category`, `Churn Reason`, COUNT(`Churn Reason`) AS churn_count
FROM `ibm churn`
WHERE `Churn Category` LIKE '%Other%' 
GROUP BY `Churn Category`, `Churn Reason`
ORDER BY churn_count DESC;

-- check the category for those customers who complaints about the poor expertise of online support
SELECT `Churn Category`, COUNT(*) AS churn_count
FROM `ibm churn`
WHERE `Churn Reason` LIKE '%Poor expertise of online support%'
GROUP BY `Churn Category`
ORDER BY churn_count DESC;

-- Updating "Other" category into more meaningful categories:
SET SQL_SAFE_UPDATES = 0;


UPDATE `ibm churn`
SET `Churn Category` = 
  CASE 
    WHEN `Churn Reason` IN ('Moved', 'Deceased') THEN 'Personal Issue'
    WHEN `Churn Reason` = 'Don''t know' THEN 'Unknown'
    WHEN `Churn Reason` = 'Poor expertise of online support' THEN 'Dissatisfaction'
    ELSE `Churn Category`
    END
WHERE `Churn Reason` IS NOT NULL;  -- This is just an example condition
--  Replace blank or NULL "Churn Reason" with 'NA' for loyal customers:
UPDATE `ibm churn`
SET `Churn Reason` = 'NA'
WHERE `Churn Reason` IS NULL OR `Churn Reason` = '';
-- Replace blank or NULL "Churn Category" with 'NA' for loyal customers:
UPDATE `ibm churn`
SET `Churn Category` = 'NA'
WHERE `Churn Category` IS NULL OR `Churn Category` = '';
-- Proportion of churn by category:
SELECT `Churn Category`, COUNT(`Customer ID`) AS churn_count,
  ROUND(COUNT(`Customer ID`)/7043*100, 2) AS proportion_in_percent
FROM `ibm churn`
GROUP BY `Churn Category`
ORDER BY churn_count DESC;

-- Query 3: How does the payment method influence churn behavior?

WITH ChurnData AS (
    SELECT `Payment Method`, COUNT(`Customer ID`) AS Churned
    FROM `ibm churn`
    WHERE `Churn Label` LIKE '%Yes%'
    GROUP BY `Payment Method`
),

LoyalData AS (
    SELECT `Payment Method`, COUNT(`Customer ID`) AS Loyal
    FROM `ibm churn`
    WHERE `Churn Label` LIKE '%No%'
    GROUP BY `Payment Method`
)

SELECT    a.`Payment Method`, 
    COALESCE(a.Churned, 0) AS Churned, 
    COALESCE(b.Loyal, 0) AS Loyal,
    COALESCE(a.Churned, 0) + COALESCE(b.Loyal, 0) AS total,
    SUM(COALESCE(a.Churned, 0) + COALESCE(b.Loyal, 0)) OVER (ORDER BY a.`Payment Method`) AS running_total
FROM ChurnData a
LEFT JOIN LoyalData b ON a.`Payment Method` = b.`Payment Method`
UNION ALL SELECT 
    b.`Payment Method`, 
    COALESCE(a.Churned, 0) AS Churned, 
    COALESCE(b.Loyal, 0) AS Loyal,
    COALESCE(a.Churned, 0) + COALESCE(b.Loyal, 0) AS total,
    SUM(COALESCE(a.Churned, 0) + COALESCE(b.Loyal, 0)) OVER (ORDER BY b.`Payment Method`) AS running_total
FROM LoyalData b
LEFT JOIN ChurnData a ON a.`Payment Method` = b.`Payment Method`
WHERE a.`Payment Method` IS NULL;  -- To avoid duplicates
