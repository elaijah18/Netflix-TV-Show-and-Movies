SELECT * FROM netflix_eda.netflix_titles; -- View the dataset

-- Insight Questions:

-- 1. Which actor has the most shows?
WITH RECURSIVE split AS (
    SELECT 
        title,
        TRIM(SUBSTRING_INDEX(`cast`, ',', 1)) AS actor,
        IF(LOCATE(',', `cast`) > 0, SUBSTRING(`cast`, LOCATE(',', `cast`) + 1), NULL) AS remaining
    FROM netflix_eda.netflix_titles
    WHERE `cast` IS NOT NULL AND TRIM(`cast`) <> ''

    UNION ALL

    SELECT 
        title,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)),
        IF(LOCATE(',', remaining) > 0, SUBSTRING(remaining, LOCATE(',', remaining) + 1), NULL)
    FROM split
    WHERE remaining IS NOT NULL
)
SELECT actor, COUNT(title) AS total_shows
FROM split
GROUP BY actor
ORDER BY total_shows DESC
LIMIT 10;

-- 2 Which country has the highest number of TV Show produced based on each genre?
WITH RECURSIVE split_genre AS (
    SELECT 
        country,
        title,
        type,
        TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,
        IF(LOCATE(',', listed_in) > 0, SUBSTRING(listed_in, LOCATE(',', listed_in) + 1), NULL) AS remaining
    FROM netflix_eda.netflix_titles
    WHERE listed_in IS NOT NULL AND country IS NOT NULL AND TRIM(country) <> ''
    UNION ALL
    SELECT 
        country,
        title,
        type,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)),
        IF(LOCATE(',', remaining) > 0, SUBSTRING(remaining, LOCATE(',', remaining) + 1), NULL)
    FROM split_genre
    WHERE remaining IS NOT NULL
),
split_country AS (
    SELECT 
        title,
        type,
        genre,
        TRIM(SUBSTRING_INDEX(country, ',', 1)) AS country,
        IF(LOCATE(',', country) > 0, SUBSTRING(country, LOCATE(',', country) + 1), NULL) AS remaining
    FROM split_genre
    WHERE country IS NOT NULL
    UNION ALL
    SELECT 
        title,
        type,
        genre,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)),
        IF(LOCATE(',', remaining) > 0, SUBSTRING(remaining, LOCATE(',', remaining) + 1), NULL)
    FROM split_country
    WHERE remaining IS NOT NULL
),
country_genre_counts AS (
    SELECT 
        type,
        country, 
        genre, 
        COUNT(title) AS total_shows
    FROM split_country
    WHERE `type` = 'TV Show'
    GROUP BY type, country, genre
),
ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY type, genre ORDER BY total_shows DESC) AS rn
    FROM country_genre_counts
)
SELECT genre, country, total_shows
FROM ranked
WHERE rn = 1
ORDER BY type, genre;

-- 3 Which country has the highest number of Movie produced based on each genre?
WITH RECURSIVE split_genre AS (
    SELECT 
        country,
        title,
        type,
        TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,
        IF(LOCATE(',', listed_in) > 0, SUBSTRING(listed_in, LOCATE(',', listed_in) + 1), NULL) AS remaining
    FROM netflix_eda.netflix_titles
    WHERE listed_in IS NOT NULL AND country IS NOT NULL AND TRIM(country) <> ''
    UNION ALL
    SELECT 
        country,
        title,
        type,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)),
        IF(LOCATE(',', remaining) > 0, SUBSTRING(remaining, LOCATE(',', remaining) + 1), NULL)
    FROM split_genre
    WHERE remaining IS NOT NULL
),
split_country AS (
    SELECT 
        title,
        type,
        genre,
        TRIM(SUBSTRING_INDEX(country, ',', 1)) AS country,
        IF(LOCATE(',', country) > 0, SUBSTRING(country, LOCATE(',', country) + 1), NULL) AS remaining
    FROM split_genre
    WHERE country IS NOT NULL
    UNION ALL
    SELECT 
        title,
        type,
        genre,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)),
        IF(LOCATE(',', remaining) > 0, SUBSTRING(remaining, LOCATE(',', remaining) + 1), NULL)
    FROM split_country
    WHERE remaining IS NOT NULL
),
country_genre_counts AS (
    SELECT 
        type,
        country, 
        genre, 
        COUNT(title) AS total_shows
    FROM split_country
    WHERE `type` = 'Movie'
    GROUP BY type, country, genre
),
ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY type, genre ORDER BY total_shows DESC) AS rn
    FROM country_genre_counts
)
SELECT genre, country, total_shows
FROM ranked
WHERE rn = 1
ORDER BY type, genre;

-- 4. What show has the most seasons?
SELECT title, 
	CAST(SUBSTRING_INDEX(duration, " ", 1)AS UNSIGNED) AS seasons
	FROM netflix_eda.netflix_titles
	WHERE `type` = 'TV Show'
    ORDER BY seasons DESC
    LIMIT 10;
	
-- 5. Which movie director has the most shows?
WITH RECURSIVE split AS (
    SELECT 
        title,
        `type`,
        TRIM(SUBSTRING_INDEX(director, ',', 1)) AS director,
        IF(LOCATE(',', director) > 0, SUBSTRING(director, LOCATE(',', director) + 1), NULL) AS remaining
    FROM netflix_eda.netflix_titles
    WHERE director IS NOT NULL AND TRIM(director) <> ''
		AND `type` = 'Movie'

    UNION ALL

    SELECT 
        title,
        `type`,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)),
        IF(LOCATE(',', remaining) > 0, SUBSTRING(remaining, LOCATE(',', remaining) + 1), NULL)
    FROM split
    WHERE remaining IS NOT NULL
)
SELECT director, COUNT(title) AS total_shows
FROM split
GROUP BY director
ORDER BY total_shows DESC
LIMIT 10;

-- 5. Which tv show director has the most shows?
WITH RECURSIVE split AS (
    SELECT 
        title,
        `type`,
        TRIM(SUBSTRING_INDEX(director, ',', 1)) AS director,
        IF(LOCATE(',', director) > 0, SUBSTRING(director, LOCATE(',', director) + 1), NULL) AS remaining
    FROM netflix_eda.netflix_titles
    WHERE director IS NOT NULL AND TRIM(director) <> ''
		AND `type` = 'TV Show'

    UNION ALL

    SELECT 
        title,
        `type`,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)),
        IF(LOCATE(',', remaining) > 0, SUBSTRING(remaining, LOCATE(',', remaining) + 1), NULL)
    FROM split
    WHERE remaining IS NOT NULL
)
SELECT director, COUNT(title) AS total_shows
FROM split
GROUP BY director
ORDER BY total_shows DESC
LIMIT 10;

-- 6. Does netflix have more focus on TV shows than movies in recent years?
SELECT 
    YEAR(date_added) AS year_added,
    SUM(CASE WHEN `type` = 'TV Show' THEN 1 ELSE 0 END) AS tv_shows,
    SUM(CASE WHEN `type` = 'Movie' THEN 1 ELSE 0 END) AS movies
FROM netflix_eda.netflix_titles
WHERE date_added IS NOT NULL
  AND TRIM(date_added) != ''
GROUP BY year_added
HAVING year_added IS NOT NULL
ORDER BY year_added;

-- 7. Which country has the most shows produced?
WITH RECURSIVE split_country AS (
	SELECT 
		title,
		TRIM(SUBSTRING_INDEX(country, ',', 1)) AS country,
		IF (LOCATE(',', country) > 0, SUBSTRING(country, LOCATE(',', country) + 1), NULL) AS remaining
	FROM netflix_eda.netflix_titles
    WHERE country IS NOT NULL AND TRIM(country) <> ''
    
    UNION ALL
    
    SELECT 
		title, 
        TRIM(SUBSTRING_INDEX(remaining, ', ', 1)),
        IF (LOCATE(',', remaining) > 0, SUBSTRING(remaining, LOCATE(',', remaining) + 1), NULL)
	FROM split_country
    WHERE remaining IS NOT NULL
)

SELECT country, COUNT(title) AS total_shows
FROM split_country
GROUP BY country
ORDER BY total_shows DESC
LIMIT 10;
 
-- 8. Which country has the highest number of shows in each rating category?
WITH RECURSIVE split_country AS (
    SELECT 
        title,
        rating,
        TRIM(SUBSTRING_INDEX(country, ',', 1)) AS country,
        IF(LOCATE(',', country) > 0, SUBSTRING(country, LOCATE(',', country) + 1), NULL) AS remaining
    FROM netflix_eda.netflix_titles
    WHERE country IS NOT NULL AND rating IS NOT NULL AND rating NOT LIKE '%min%' AND TRIM(rating) <> ''

    UNION ALL

    SELECT
        title,
        rating,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)),
        IF(LOCATE(',', remaining) > 0, SUBSTRING(remaining, LOCATE(',', remaining) + 1), NULL)
    FROM split_country
    WHERE remaining IS NOT NULL
),

country_rating_count AS (
    SELECT
        rating,
        country,
        COUNT(title) AS total_shows
    FROM split_country
    GROUP BY rating, country
),

ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY rating ORDER BY total_shows DESC) AS rn
    FROM country_rating_count
)

SELECT rating, country, total_shows
FROM ranked
WHERE rn = 1
ORDER BY rating;
