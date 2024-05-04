USE imdb;


SELECT * FROM role_mapping ;
SELECT * FROM director_mapping;
SELECT * FROM genre;
SELECT * FROM movie; 
SELECT * FROM names;
SELECT * FROM ratings;



#Total rows in each table
SELECT table_name,
       table_rows
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'imdb'
ORDER BY table_rows DESC;



#total movies in each genre
SELECT genre,
	   COUNT(*) as total_movies
FROM genre
GROUP BY genre
ORDER BY total_movies DESC;



#number of movies released by country
WITH numbering AS (SELECT (a.N + b.N * 10 + 1) AS n
FROM (SELECT 0 AS N 
      UNION ALL SELECT 1 
      UNION ALL SELECT 2 
      UNION ALL SELECT 3 
      UNION ALL SELECT 4 
      UNION ALL SELECT 5) AS a
CROSS JOIN (SELECT 0 AS N 
	    UNION ALL SELECT 1) AS b),
country_table AS (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(m.country, ',', n.n), ', ', -1) AS country
				  FROM movie m
				  INNER JOIN numbering n
				  WHERE n.n <= 1 + (LENGTH(m.country) - LENGTH(REPLACE(m.country, ',', ''))))
SELECT country,
	   COUNT(*) AS total_movies
FROM country_table
GROUP BY country
ORDER BY total_movies DESC;



#production houses with the highest number of movies released
SELECT production_company,
	   COUNT(*) AS total_movies
FROM movie
WHERE production_company is NOT NULL
GROUP BY production_company
ORDER BY total_movies DESC
LIMIT 8;


#avg_rating and total reviews per genre
SELECT g.genre,
	   ROUND(AVG(r.avg_rating),2) as average_rating,
       SUM(r.total_votes) AS total_reviews
FROM ratings r
INNER JOIN genre g
ON r.movie_id=g.movie_id
GROUP BY g.genre
ORDER BY total_reviews DESC;



#total movies released each month
SELECT EXTRACT(YEAR_MONTH FROM date_published) AS year_months,
       COUNT(*) AS total_movies_released
FROM movie
GROUP BY EXTRACT(year_month from date_published)
ORDER BY year_months;



#how many directors have also worked as actors
SELECT COUNT(DISTINCT d.name_id) AS total
FROM director_mapping d
INNER JOIN role_mapping r
ON d.name_id = r.name_id;



#highest rated movie of each quarter, including rating
SELECT title,
	   quarter_year,
       avg_rating
FROM(SELECT m.title,
			m.date_published,
			m.year,
			CONCAT('Q', EXTRACT(QUARTER FROM date_published), ' ', m.year) as quarter_year,
            r.avg_rating,
            DENSE_RANK() OVER(PARTITION BY CONCAT(EXTRACT(QUARTER FROM date_published), '-', m.year) ORDER BY avg_rating DESC) AS ranks
FROM movie m
INNER JOIN ratings r
ON m.id = r.movie_id) AS derived_table
WHERE ranks=1
ORDER BY year;



#birth_year ranges of directors and actors 
WITH dir_dob AS (SELECT id,
		CONCAT(FLOOR(EXTRACT(YEAR FROM date_of_birth)/20)*20, '-', FLOOR(EXTRACT(YEAR FROM date_of_birth)/20)*20+19) AS year_range
				 FROM names
				 WHERE date_of_birth is NOT NULL AND id IN(SELECT name_id 
														  FROM director_mapping)
				 ),
act_dob AS(SELECT id,
	CONCAT(FLOOR(EXTRACT(YEAR FROM date_of_birth)/20)*20, '-', FLOOR(EXTRACT(YEAR FROM date_of_birth)/20)*20+19) as year_range
			 FROM names
			 WHERE date_of_birth is NOT NULL AND id IN(SELECT name_id 
													   FROM role_mapping)
             )
SELECT a.year_range,
	   d.dir_count,
       a.act_count
FROM(SELECT year_range,
			COUNT(id) as act_count
	 FROM act_dob
	 GROUP BY year_range) AS a
LEFT JOIN(SELECT year_range,
			COUNT(id) as dir_count
	 FROM dir_dob
	 GROUP BY year_range) AS d
ON a.year_range = d.year_range;



#Highest_&_lowest_rated_movies
SELECT title AS highest_rated_movies
FROM movie
WHERE id IN (SELECT movie_id
			 FROM ratings
			 WHERE avg_rating = (SELECT MAX(avg_rating)
								 FROM ratings));
SELECT title AS lowest_rated_movies
FROM movie
WHERE id IN (SELECT movie_id
			 FROM ratings
			 WHERE avg_rating = (SELECT MIN(avg_rating)
								 FROM ratings));



#avg. duration trends of movies over the year
SELECT ROUND(AVG(duration)) AS avg_duration
FROM movie;
SELECT year,
	   ROUND(AVG(duration)) AS duration_in_minutes
FROM movie;
SELECT year,
	   ROUND(AVG(duration)) AS avg_duration
FROM movie
GROUP BY year;



#leading production houses by total revenue
SELECT production_company,
	   SUM(SUBSTRING(worlwide_gross_income, LOCATE(' ', worlwide_gross_income)+1)) AS total_worldwide_gross_income
FROM movie
WHERE worlwide_gross_income is NOT NULL
GROUP BY production_company
ORDER BY total_worldwide_gross_income DESC;
