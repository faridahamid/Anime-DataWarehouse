SELECT
    g.genre_name,
    m.title, 
    AVG(f.rating) AS avg_rating
FROM
    Fact_Movie f
JOIN
    Dim_Genre g ON f.genre_id = g.genre_id
JOIN
    Dim_Movie m ON f.movie_id = m.movie_id
GROUP BY
    g.genre_name, m.title
ORDER BY
    avg_rating DESC;
-- Total number of movies per genre
SELECT TOP 10
    g.genre_name,
    COUNT(f.movie_id) AS total_movies
FROM
    Fact_Movie f
JOIN
    Dim_Genre g ON f.genre_id = g.genre_id
GROUP BY
    g.genre_name
ORDER BY
    total_movies DESC;
-- Top 10 movies by rating
SELECT TOP 10
    m.title,
    AVG(f.rating) AS avg_rating
FROM
    Fact_Movie f
JOIN
    Dim_Movie m ON f.movie_id = m.movie_id
GROUP BY
    m.title
ORDER BY
    avg_rating DESC;
-- Get the most popular director by total movie views (view_count)
SELECT
    d.director_name,
    SUM(CAST(f.view_count AS BIGINT)) AS total_views
FROM
    Fact_Movie f
JOIN
    Dim_Director d ON f.director_id = d.director_id
GROUP BY
    d.director_name
ORDER BY
    total_views DESC;
-- Count the number of unique users who rated movies by genre
SELECT
    g.genre_name,
    COUNT(DISTINCT f.user_id) AS unique_users
FROM
    Fact_Movie f
JOIN
    Dim_Genre g ON f.genre_id = g.genre_id
GROUP BY
    g.genre_name
ORDER BY
    unique_users DESC;
-- Find the top 10 most-watched movies (highest view_count)
SELECT TOP 10
    m.title AS movie_title,
    SUM(f.view_count) AS total_views
FROM
    Fact_Movie f
JOIN
    Dim_Movie m ON f.movie_id = m.movie_id
GROUP BY
    m.title
ORDER BY
    total_views DESC;
-- Analyze user engagement by subscription type (total views per subscription type)
SELECT
    u.subscription_type,
    SUM(CAST(f.view_count AS BIGINT)) AS total_views
FROM
    Fact_Movie f
JOIN
    Dim_User u ON f.user_id = u.user_id
GROUP BY
    u.subscription_type
ORDER BY
    total_views DESC;
