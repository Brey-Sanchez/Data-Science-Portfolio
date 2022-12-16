WITH temp_ AS(
  SELECT
  EXTRACT(DAY from d.date) AS day_,
  COUNT(r.rental_id) AS n_rentals
  FROM dates d
  LEFT JOIN rental r
  ON DATE(r.rental_ts) = d.date
  WHERE EXTRACT(MONTH from d.date) = 5
  AND EXTRACT(YEAR from d.date) = 2020
  GROUP BY 1
  )
SELECT
	SUM(CASE WHEN n_rentals > 100 THEN 1 END) AS good_days,
	SUM(CASE WHEN n_rentals <= 100 THEN 1 END) AS bad_days
FROM temp_
