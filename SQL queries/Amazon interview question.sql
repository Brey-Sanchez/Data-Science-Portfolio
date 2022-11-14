-- First, we create a CTE over which we can calculate the monthly rolling average
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
