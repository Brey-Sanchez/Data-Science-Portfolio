SELECT
  -- We need to use distinct so we don't count repeated customers, as it possible that some
  -- of them have more than one two-day streak within the specified period (24th to 31st of May)
	COUNT(DISTINCT(customer_id))
FROM (
  SELECT
  customer_id,
  EXTRACT(DAY from rental_ts) AS day_,
  -- This is the key part, where we get the number of days that have passed since the last day that
  -- the same customer rented a movie
  EXTRACT(DAY from rental_ts)- LAG(EXTRACT(DAY from rental_ts), 1) 
     -- We need to partition by customer so we only calculate the time differences
     -- for the same customer
     OVER (PARTITION BY customer_id ORDER BY EXTRACT(DAY from rental_ts)) AS day_diff
  FROM rental
  -- Filtering conditions as requested
  WHERE EXTRACT(DAY from rental_ts) BETWEEN 24 AND 31
  AND EXTRACT(MONTH from rental_ts) = 5
  ORDER BY 1, 2
  ) AS temp
-- We are only interested in consecutive days rentals, which is when day_diff equals 1
WHERE day_diff = 1
