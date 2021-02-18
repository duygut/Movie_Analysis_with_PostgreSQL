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
WHERE NOT EXISTS (SELECT FROM double_genre_tables r2 WHERE r1.movie_id = r2.movie_id)), 

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

-- last single table
single_genre_last_table AS (SELECT m.movie_id, m.genre_name FROM movies_genres_relationship m 
JOIN single_genre_table s ON s.movie_id = m.movie_id),

--- union all genres

all_genres_table as (SELECT * FROM multiple_genre_last_table 
UNION
SELECT * FROM single_genre_last_table),

--------

user_diff_days AS
  (SELECT user_id,
          max_rate_days,
          min_rate_days,
          (max_rate_days - min_rate_days) AS diff_days FROM
    (SELECT user_id, max(rating_date::date) AS max_rate_days, min(rating_date::date) AS min_rate_days
      FROM tyler_burkett379.movielens_ratings
      GROUP BY user_id) AS min_max_table 
      ORDER BY diff_days DESC),
      
 
-- movies rated >n 48 and diff days > 10
long_term_user_list AS (SELECT r1.user_id, max_rate_days, min_rate_days,
r1.diff_days, count(r2.movie_id) as count_movies FROM user_diff_days r1
JOIN tyler_burkett379.movielens_ratings R2 ON r1.user_id = r2.user_id
where diff_days > 10
GROUP BY r1.user_id,r2.user_id,max_rate_days, min_rate_days, r1.diff_days
HAVING count(r2.movie_id) > 48
order by diff_days),

user_rating_list AS (SELECT rt1.user_id, rt1.movie_id, rt1.rating, p.genre_name FROM tyler_burkett379.movielens_ratings as rt1
JOIN long_term_user_list as rt2 ON rt1.user_id = rt2.user_id
JOIN all_genres_table p ON p.movie_id = rt1.movie_id),

-- MOST rated genre per user
most_rated_genre_per_user AS (SELECT user_id, genre_name, count_num FROM (
SELECT *, DENSE_RANK() OVER(PARTITION BY user_id ORDER BY count_num DESC) as row_num FROM (
SELECT user_id, genre_name, count(genre_name)  as count_num FROM user_rating_list
GROUP BY user_id, genre_name) as row_table) AS last_row_table
WHERE row_num = 1),

---- most liked genre per user (max(avg(rating)))
most_liked_genre_per_user AS (SELECT * FROM (
SELECT *, DENSE_RANK() OVER(PARTITION BY user_id ORDER BY avg_rating DESC) as row_num FROM (
SELECT user_id, genre_name, AVG(rating) as avg_rating FROM user_rating_list
GROUP BY user_id, genre_name) as row_table) AS last_row_table
WHERE row_num = 1),

most_liked_and_rated_table as (SELECT m.user_id, m.genre_name as most_rated_genre,l.genre_name as most_liked_genre, l.avg_rating as avg_rating
FROM most_rated_genre_per_user as m
JOIN most_liked_genre_per_user as l ON m.user_id = l.user_id)

SELECT * FROM most_liked_and_rated_table
