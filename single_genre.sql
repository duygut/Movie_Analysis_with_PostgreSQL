-- Replace single quotes with double quotes in order to use Postgres JSON functions properly
WITH temp_genres AS (
SELECT regexp_replace(genres, '''', '"', 'g') AS genres_fixed, id AS movie_id FROM tyler_burkett379.movies_metadata
), 
-- Parse json strings into columns
genres_parsed AS (
SELECT arr.item_object->>'name' AS genre_name, arr.item_object->>'id' AS genre_id, movie_id
FROM temp_genres, jsonb_array_elements(genres_fixed::jsonb) with ordinality arr(item_object, position)
),
-- remove double ids
genres_parsed_except_double_id AS (SELECT * FROM genres_parsed 
WHERE movie_id not IN (99080, 109962, 77221,159849,23305,14788,4912,15028,97995,
13209,5511,265189,10991, 110428, 12600, 105045, 119916, 25541, 84198,
18440, 11115, 69234, 168538, 141971, 152795, 42495, 22649,
132641, 298721)), 

-- Select only 5 genres
five_genres_table AS (SELECT * FROM genres_parsed_except_double_id WHERE genre_name IN('Family', 'Comedy','Crime', 'Action','Thriller')),

-- M2M relationship table between movies and genres (to query which movies has which genres, or other way around)
movies_genres_relationship AS (
SELECT movie_id, genre_id, genre_name FROM five_genres_table
),
-- Rank num by movie id and genre

-- Multiple genre 
multiple_genre_table AS (SELECT movie_id, count(genre_id) AS genre_num
FROM movies_genres_relationship
GROUP BY movie_id
HAVING count(genre_id) > 1),

single_genre_table AS (
SELECT movie_id, count(genre_id) AS genre_num
FROM movies_genres_relationship
GROUP BY movie_id
HAVING count(genre_id) = 1
),
-- production_company_id
product_company_table AS (SELECT id as movie_id,
regexp_replace(array_to_string(regexp_matches(production_companies, '''id'': [0-9]+', 'g'), ';'), '''id'': ', '', 'g')::int
as production_company_id FROM tyler_burkett379.movies_metadata),

--- remove zero budget and zero revenue
non_zero_profit_table AS (SELECT m.id as movie_id, 
status as movie_status,
revenue as Total_revenue, 
budget as Total_Budget, 
revenue-budget as gross_profit,
runtime,
date_part('year', release_date::date) as year_movie
FROM tyler_burkett379.movies_metadata m
WHERE budget != 0 and revenue != 0),
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
------------- SINGLE GENRE EXPLORATORY ANALYSIS -----
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
single_genre_join_table AS (SELECT m.movie_id as movie_id,
p.genre_name,
movie_status,
Total_revenue, 
Total_Budget, 
gross_profit,
year_movie,
(
CASE 
WHEN year_movie BETWEEN '1960' AND '1969' THEN '1960s'
WHEN year_movie BETWEEN '1970' AND '1979' THEN '1970s'
WHEN year_movie BETWEEN '1980' AND '1989' THEN '1980s'
WHEN year_movie BETWEEN '1990' AND '1999' THEN '1990s'
WHEN year_movie BETWEEN '2000' AND '2009' THEN '2000s'
WHEN year_movie BETWEEN '2010' AND '2020' THEN '2010s' ELSE 'out_of_range'
END) AS decade_group,
runtime,
(CASE WHEN gross_profit > (Total_revenue * 0.50) THEN 1 ELSE 0 END) as is_profit
FROM non_zero_profit_table m
JOIN movies_genres_relationship p ON p.movie_id = m.movie_id
JOIN single_genre_table sg ON sg.movie_id = p.movie_id)

SELECT * FROM single_genre_join_table
ORDER BY movie_id
