-- Creating a CTE from which we can then calculate the number of friends each user has
WITH all_users AS (
  (SELECT
  user1 AS user_id,
  COUNT(user2) AS n_friends
  FROM facebook_friends
  GROUP BY 1)
  UNION
  (SELECT
  user2 AS user_id,
  COUNT(user1) AS n_friends
  FROM facebook_friends
  GROUP BY 1)
 )
SELECT
user_id,
SUM(n_friends) / (SELECT COUNT(DISTINCT(user_id)) FROM all_users) * 100 AS popularity_perc
FROM all_users
GROUP BY 1
ORDER BY 1;
