-- First, we create a CTE over which we can calculate the monthly rolling average.
-- In this step we extract the month and year from the created_at column and
-- calculate the total monthly revenue.

WITH montly_amt AS (SELECT 
TO_CHAR(created_at, 'YYYY-MM') AS year_month,
SUM(purchase_amt) AS total_amt
FROM amazon_purchases
WHERE purchase_amt > 0
GROUP BY 1
ORDER BY 1)

-- Now we can use a window function to get the desired result

SELECT
year_month,
AVG(total_amt) OVER(ORDER BY year_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
FROM montly_amt

-- This is the final result that we obtain:
-- year_month	avg
-- 2020-01	26292
-- 2020-02	23493.5
-- 2020-03	25535.667
-- 2020-04	24082.667
-- 2020-05	25417.667
-- 2020-06	24773.333
-- 2020-07	25898.667
-- 2020-08	25497.333
-- 2020-09	24544
-- 2020-10	21211
