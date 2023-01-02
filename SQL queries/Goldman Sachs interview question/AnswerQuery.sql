WITH temp AS(
    SELECT
    ta.train_id,
    arrival_time,
    departure_time
    FROM train_arrivals ta
    INNER JOIN train_departures td
    ON ta.train_id = td.train_id
)
SELECT
t1.train_id,
t1.arrival_time,
t1.departure_time,
(COUNT(t1.train_id) - 1) AS min_num_platforms
FROM temp t1
JOIN temp t2
ON t1.arrival_time BETWEEN t2.arrival_time AND t2.departure_time
GROUP BY 1, 2, 3
ORDER BY 4 DESC
