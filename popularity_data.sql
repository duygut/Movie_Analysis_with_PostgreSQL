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
genres_parsed_excep_double_id AS (SELECT * FROM genres_parsed 
WHERE movie_id not IN (99080, 109962, 77221,159849,23305,14788,4912,15028,97995,
13209,5511,265189,10991, 110428, 12600, 105045, 119916, 25541, 84198,
18440, 11115, 69234, 168538, 141971, 152795, 42495, 22649,
132641, 298721)), 

-- Select only 5 genres
five_genres_table AS (SELECT * FROM genres_parsed_excep_double_id WHERE genre_name IN('Family', 'Comedy','Crime', 'Action','Thriller')),

-- M2M relationship table between movies and genres (to query which movies has which genres, or other way around)
movies_genres_relationship AS (
SELECT movie_id, genre_id, genre_name FROM five_genres_table
ORDER BY movie_id, genre_id
),

-- Multiple genre 
multiple_genre_table AS (SELECT movie_id, count(genre_id) AS genre_num
FROM movies_genres_relationship
GROUP BY movie_id
HAVING count(genre_id) > 1),
--
multiple_genre_join_table AS (SELECT m.movie_id as movie_id,
m.genre_name as genre_name
FROM movies_genres_relationship m
JOIN multiple_genre_table mg ON mg.movie_id = m.movie_id),

-- Find rows which have more than 2 genres
double_genre_tables AS (SELECT movie_id, count(movie_id) as count_num
FROM multiple_genre_join_table
GROUP BY movie_id
HAVING count(movie_id) > 2),

-- Extract only 2 genres rows
double_genres_diff_table AS (SELECT *
FROM multiple_genre_join_table r1
WHERE NOT EXISTS (SELECT * FROM double_genre_tables r2 WHERE r1.movie_id = r2.movie_id)), 

-- Create new column which has genre_list for double genres
genre_list_table AS (SELECT movie_id, 
STRING_AGG(genre_name, '&') as genre_list
FROM double_genres_diff_table 
GROUP BY movie_id),
--last multiple genre list
multiple_genre_last_table as (select DISTINCT ON (d1.movie_id) d1.movie_id, d2.genre_list as genre_name
from double_genres_diff_table d1
JOIN genre_list_table d2 ON d1.movie_id = d2.movie_id),

single_genre_table AS (
SELECT movie_id, count(genre_id) AS genre_num
FROM movies_genres_relationship
GROUP BY movie_id
HAVING count(genre_id) = 1),

single_genre_last_table AS (SELECT m.movie_id, m.genre_name FROM movies_genres_relationship m 
JOIN single_genre_table s ON s.movie_id = m.movie_id),

all_genres_table as (SELECT * FROM multiple_genre_last_table 
UNION 
SELECT * FROM single_genre_last_table),

-- production_company_id
product_company_table AS (SELECT id as movie_id,
regexp_replace(array_to_string(regexp_matches(production_companies, '''id'': [0-9]+', 'g'), ';'), '''id'': ', '', 'g')::int
as production_company_id FROM tyler_burkett379.movies_metadata)

SELECT at.*, popularity,mt.release_date, mt. status FROM all_genres_table as at
JOIN tyler_burkett379.movies_metadata mt ON at.movie_id = mt.id
ORDER BY popularity ASC
