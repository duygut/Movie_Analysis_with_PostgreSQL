In this part data selected for understanding the meaning of data and to be able to find an answer for each goal. 
This analysis helps to discover valuable information for more than 25000 movies. When selecting or creating new variables, some questions ask:
*	Over time what genre is the most popular?
*	What is the average runtime of each genre?
*	Is there any correlation between profit and revenue?
*	Do movies with a high budget have high revenue too?
*	Is there any revenue and profit change in the last five years?

The first step was analyzing the whole movie that has a non-zero budget and non-zero revenue. According to the scatterplot, some movies have higher revenue and budget than others that could be an outlier. 

[link to EDA of All Movies!](https://public.tableau.com/profile/dturgut#!/vizhome/EDAofAllMovieswhichhaveNon-zeroBudgetandRevenue/All_Data_EDA)
![EDA image](All_Data_EDA)

The data preparation steps explain below:
For metadata dataset
1) According to the metadata dataset, some movies have more than one genre. Therefore, two different tables were created as a single genre and multiple genres. 
  a)The single genre table have 2401 rows and the multiple genre table has 3755 rows.
2) Some new features were created. 
  a)The first new one is `Gross Profit` that constituted by (`Revenue` - `Budget`) 
  b)The second new feature is `Is Profitable or Not`. The value (1 or 0) assigned by the result of (Total_revenue * 0.50) is greater than gross profit or not. This formula was found via some online research. Some of them mention the thumb rule to calculate movie profits. In our data, there is no marketing cost, media rights, or other costs. So, this formula just gives a general insight about if the movie is profitable or not (gross).
  c)The final new feature is `decades`. Release year divided by 5 groups between the 70s and 10s until 2020.
3) All data analysis was done on the dataset which has:
  a) Non-zero revenue and non-zero budget, 
  b) A status as `released` 
  c) A genre into the group of `Family, Comedy, Crime, Action, and Thriller`.
For rating dataset, since the requirement is to be a long-term customer, some filters applied to find this customer group.
1) `Different days` feature created. This feature helped to select customers who voted movies more than 1 days.
2) Another feature is the number of movies that voted. This feature helped to select customers who voted movies regularly. Based on the cumulative sum 50% of users voted less than 48 movies and the rest of them voted more than 48 movies. So, the threshold selected 48. Thus, users who voted more than 48 movies selected for the final data. 
3) In this part, all genres include single genres and multiple genres union in one column. 
*	Another constraint is, this dataset contains meaningful data until 2017. After 2017, some genres don't have any information. So, the analysis was done by the year 2017.
*	In the data preparing and cleaning part, duplicate 29 movie ids have been found. These movies didn’t include in the analysis
