### Movie_analysis_with_postgresql

Company A is a US based Netflix competitor. Rather than charging a monthly fee, Company A charges a low annual fee of $19.99 and allows users to rent movies for a discounted rate compared to other services. Company A is focused on growing users in English speaking countries.
Company A has two key initiatives for 2020:
1. Produce new Company A exclusive movies to differentiate the platform.
2. Personalize the Company A experience via Product & Marketing.

You’ve been brought into Company A to support these goals and you’ve been tasked with two separate items:
1. Find insights regarding customer preferences to determine the types of movies to produce.
2. Build out curated user data tables that enable personalization efforts.


#### GOALS
1.	Finding the genre out of 5 genres (Family, Comedy, Crime, Action, and Thriller) has the highest probability of success based on revenue.
2.	Finding the genre out of 5 genres (Family, Comedy, Crime, Action, and Thriller) recommended the team based on customer engagement.
3.	Describing the data for marketing that can help to answer marketing teams' questions. 


####	DATA DICTIONARY
The `movies metadata` dataset contains information of each movie such as movie id, genres, title, duration, budget, genres, revenue.

| Movies_metadata              |               |
|------------------------------|---------------|
|     belongs_to_collection    |     string    |
|      budget                  |     float     |
|      genres                  |     string    |
|      id                      |     float     |
|      original_language       |     string    |
|      original_title          |     string    |
|      overview                |     string    |
|      popularity              |     float     |
|      poster_path             |     string    |
|      production_companies    |     string    |
|      production_countries    |     string    |
|      release_date            |     string    |
|      revenue                 |     float     |
|      runtime                 |     float     |
|      spoken_languages        |     string    |
|      status                  |     string    |
|      tagline                 |     string    |
|      title                   |     string    |

The `movilens_rating` dataset contains information about each user’s vote details.  

| Movilens_rating     |               |
|---------------------|---------------|
|      Index          |     float     |
|      movie_id       |     float     |
|      rating         |     float     |
|      rating_date    |     string    |
|      user_id        |     float     |

In `movies_metadata` dataset genres column convert to JSON format (replace single quotes with double quotes) and parse each genre to the columns with Postgres Functions. 
