DECLARE @Counter INT = 1; 
DECLARE @TotalRows INT = 73515; 

WHILE @Counter <= @TotalRows
BEGIN
    INSERT INTO Dim_User (user_id, age, gender, subscription_type)
    VALUES (
        @Counter, -- Incremental user_id
        FLOOR(RAND(CHECKSUM(NEWID())) * (60 - 18 + 1)) + 18, 
        CASE WHEN RAND(CHECKSUM(NEWID())) > 0.5 THEN 'Male' ELSE 'Female' END, 
        CASE 
            WHEN RAND(CHECKSUM(NEWID())) < 0.33 THEN 'Premium' 
            WHEN RAND(CHECKSUM(NEWID())) < 0.66 THEN 'Standard' 
            ELSE 'Free' 
        END 
    );

    SET @Counter = @Counter + 1; 
END;


--insertion in director dimension
INSERT INTO Dim_Director (director_id, director_name)
VALUES
(1, 'John Smith'),
(2, 'Sarah Johnson'),
(3, 'Michael Brown'),
(4, 'Emily Davis'),
(5, 'James Wilson'),
(6, 'Olivia Taylor'),
(7, 'William Martinez'),
(8, 'Sophia Garcia'),
(9, 'Liam Anderson'),
(10, 'Charlotte Thompson'),
(11, 'Noah White'),
(12, 'Isabella Harris'),
(13, 'Mason Clark'),
(14, 'Mia Robinson'),
(15, 'Elijah Walker');
WITH Genre AS (
    
    SELECT 
        genre, 
        ROW_NUMBER() OVER (ORDER BY genre) AS genre_id
    FROM dbo.StagingAnime 
    GROUP BY genre 
)
INSERT INTO Dim_Genre (genre_id, genre_name)
SELECT 
    genre_id, 
    genre
FROM Genre;

-- insert date dimension 
WITH DateRange AS (
    SELECT 
        CAST('2010-01-01' AS DATE) AS date_value  
    UNION ALL
    SELECT 
        DATEADD(DAY, 1, date_value)  
    FROM DateRange
    WHERE date_value < '2024-12-31'  
)

INSERT INTO Dim_Date (date_id, date, year, month, day, quarter)
SELECT 
    CAST(CONVERT(VARCHAR(8), date_value, 112) AS INT) AS date_id,  
    date_value AS date, 
    YEAR(date_value) AS year, 
    MONTH(date_value) AS month, 
    DAY(date_value) AS day, 
    CASE 
        WHEN MONTH(date_value) BETWEEN 1 AND 3 THEN 1
        WHEN MONTH(date_value) BETWEEN 4 AND 6 THEN 2
        WHEN MONTH(date_value) BETWEEN 7 AND 9 THEN 3
        WHEN MONTH(date_value) BETWEEN 10 AND 12 THEN 4
    END AS quarter
FROM DateRange
OPTION (MAXRECURSION 0);  
DECLARE @DateId INT;


SELECT @DateId = date_id 
FROM dbo.Dim_Date 
WHERE date = CAST(GETDATE() AS DATE);
-- movie dimension 
INSERT INTO dbo.Dim_Movie (movie_id, title, release_year)
SELECT 
    DISTINCT 
    anime_id AS movie_id,
    name AS title,
    (CASE 
         WHEN RAND(CHECKSUM(NEWID())) < 0.14 THEN 2011
         WHEN RAND(CHECKSUM(NEWID())) < 0.28 THEN 2015
         WHEN RAND(CHECKSUM(NEWID())) < 0.42 THEN 2017
         WHEN RAND(CHECKSUM(NEWID())) < 0.57 THEN 2019
         WHEN RAND(CHECKSUM(NEWID())) < 0.71 THEN 2020
         WHEN RAND(CHECKSUM(NEWID())) < 0.85 THEN 2021
         ELSE 2022
     END) AS release_year
FROM dbo.StagingAnime;
-- fact table 
WITH FactData AS (
    SELECT 
        CAST(SR.user_id AS INT) AS user_id, 
        CAST(SA.anime_id AS INT) AS movie_id, 
        (SELECT date_id FROM Dim_Date WHERE date = CAST(GETDATE() AS DATE)) AS date_id, 
        FLOOR(RAND(CHECKSUM(NEWID())) * 15) + 1 AS director_id, 
        CAST(SR.rating AS INT) AS rating, 
        FLOOR(RAND(CHECKSUM(NEWID())) * 180) + 60 AS duration, 
        FLOOR(RAND(CHECKSUM(NEWID())) * 3265) + 1 AS genre_id, 
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS fact_id 
    FROM dbo.StagingAnime SA
    JOIN dbo.StagingRating SR ON SA.anime_id = SR.anime_id
)

INSERT INTO Fact_Movie (fact_id, user_id, movie_id, date_id, director_id, rating, view_count, duration, genre_id)
SELECT 
    FD.fact_id,  
    FD.user_id,  
    FD.movie_id, 
    FD.date_id,  
    FD.director_id, 
    FD.rating, 
    VC.view_count, 
    FD.duration,  
    FD.genre_id  
FROM FactData FD
JOIN ViewCount VC ON FD.movie_id = VC.movie_id

JOIN dbo.Dim_User DU ON FD.user_id = DU.user_id;