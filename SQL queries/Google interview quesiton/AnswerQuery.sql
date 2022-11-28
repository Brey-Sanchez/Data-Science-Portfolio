-- Creating a CTE with an array for the words and an array for the the number of occurrences
-- of each word in each file
WITH occurrences AS(
    SELECT 
    UNNEST(ARRAY['bull', 'bear']) AS word,
    UNNEST(ARRAY[
                 (LENGTH(contents) - LENGTH(REPLACE(contents, ' bull ', ''))) / LENGTH(' bull '),
                 (LENGTH(contents) - LENGTH(REPLACE(contents, ' bear ', ''))) / LENGTH(' bear ')
                 ]
                 ) AS nentry
    FROM google_file_store
)
-- Obtaining the requested table
SELECT
word,
SUM(nentry) AS nentry
FROM occurrences
GROUP BY 1
ORDER BY 2 DESC;
