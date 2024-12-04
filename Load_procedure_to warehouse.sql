ALTER TABLE dbo.StagingRating ADD last_updated DATETIME DEFAULT GETDATE();
ALTER TABLE dbo.StagingAnime ADD last_updated DATETIME DEFAULT GETDATE();
ALTER TABLE dbo.Fact_Movie ADD last_updated DATETIME DEFAULT GETDATE();


ALTER PROCEDURE LoadAndNotifyData
AS
BEGIN
    DECLARE @email_subject NVARCHAR(255);
    DECLARE @email_body NVARCHAR(MAX);
    DECLARE @last_run_time DATETIME;

   
    SET @last_run_time = (SELECT MAX(last_updated) FROM dbo.Fact_Movie);

    BEGIN TRY
    
        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'StagingRating' AND COLUMN_NAME = 'last_updated')
        BEGIN
            ALTER TABLE dbo.StagingRating ADD last_updated DATETIME DEFAULT GETDATE();
            PRINT 'Added last_updated column to StagingRating';
        END

        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'StagingAnime' AND COLUMN_NAME = 'last_updated')
        BEGIN
            ALTER TABLE dbo.StagingAnime ADD last_updated DATETIME DEFAULT GETDATE();
            PRINT 'Added last_updated column to StagingAnime';
        END

        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Fact_Movie' AND COLUMN_NAME = 'last_updated')
        BEGIN
            ALTER TABLE dbo.Fact_Movie ADD last_updated DATETIME DEFAULT GETDATE();
            PRINT 'Added last_updated column to Fact_Movie';
        END

       
        CREATE TABLE #TempStagingRating (
            user_id VARCHAR(255),
            anime_id VARCHAR(255),
            rating INT
        );

        BULK INSERT #TempStagingRating
        FROM 'E:\new_rating_records.csv'
        WITH (
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0A',
            FIRSTROW = 2 
        );

        MERGE INTO StagingRating AS Target
        USING #TempStagingRating AS Source
        ON Target.user_id = Source.user_id AND Target.anime_id = Source.anime_id
        WHEN MATCHED THEN
            UPDATE SET Target.rating = Source.rating, Target.last_updated = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT (user_id, anime_id, rating, last_updated)
            VALUES (Source.user_id, Source.anime_id, Source.rating, GETDATE());

        DROP TABLE #TempStagingRating;

       
        CREATE TABLE #TempStagingAnime (
            anime_id VARCHAR(255),
            name VARCHAR(255),
            genre VARCHAR(255),
            type VARCHAR(255),
            episodes VARCHAR(255),
            rating VARCHAR(255),
            members VARCHAR(255)
        );

        BULK INSERT #TempStagingAnime
        FROM 'E:\anime_cleaned.csv'
        WITH (
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0A',
            FIRSTROW = 2 
        );

        MERGE INTO StagingAnime AS Target
        USING #TempStagingAnime AS Source
        ON Target.anime_id = Source.anime_id
        WHEN MATCHED THEN
            UPDATE SET 
                Target.name = Source.name,
                Target.genre = Source.genre,
                Target.type = Source.type,
                Target.episodes = Source.episodes,
                Target.rating = Source.rating,
                Target.members = Source.members,
                Target.last_updated = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT (anime_id, name, genre, type, episodes, rating, members, last_updated)
            VALUES (Source.anime_id, Source.name, Source.genre, Source.type, Source.episodes, Source.rating, Source.members, GETDATE());

        DROP TABLE #TempStagingAnime;

        
        INSERT INTO dbo.Dim_Movie (movie_id, title, release_year)
        SELECT DISTINCT
        CAST(anime_id AS INT) AS movie_id,
        name AS title,
        CASE 
             WHEN RAND(CHECKSUM(NEWID())) < 0.14 THEN 2011
             WHEN RAND(CHECKSUM(NEWID())) < 0.28 THEN 2015
             WHEN RAND(CHECKSUM(NEWID())) < 0.42 THEN 2017
             WHEN RAND(CHECKSUM(NEWID())) < 0.57 THEN 2019
             WHEN RAND(CHECKSUM(NEWID())) < 0.71 THEN 2020
             WHEN RAND(CHECKSUM(NEWID())) < 0.85 THEN 2021
             ELSE 2022
        END AS release_year
       FROM dbo.StagingAnime SA
       WHERE NOT EXISTS (SELECT 1 FROM dbo.Dim_Movie DM WHERE DM.movie_id = CAST(SA.anime_id AS INT));

       INSERT INTO dbo.Dim_User (user_id, age, gender, subscription_type)
       SELECT DISTINCT
                CAST(CLEANED.user_id AS INT) AS user_id,
                FLOOR(RAND(CHECKSUM(NEWID())) * (60 - 18 + 1)) + 18 AS age, -- Random age between 18 and 60
                CASE 
                     WHEN RAND(CHECKSUM(NEWID())) > 0.5 THEN 'Male'
                     ELSE 'Female'
                     END AS gender,
              CASE 
                     WHEN RAND(CHECKSUM(NEWID())) < 0.33 THEN 'Premium'
                     WHEN RAND(CHECKSUM(NEWID())) < 0.66 THEN 'Standard'
                     ELSE 'Free'
                     END AS subscription_type
            FROM (SELECT DISTINCT REPLACE(REPLACE(SR.user_id, CHAR(13), ''), CHAR(10), '') AS user_id FROM dbo.StagingRating SR) CLEANED
            WHERE NOT EXISTS (SELECT 1 FROM dbo.Dim_User DU WHERE DU.user_id = CAST(CLEANED.user_id AS INT));

        INSERT INTO dbo.Dim_Genre (genre_id, genre_name)
        SELECT DISTINCT RN.genre_id, RN.genre_name
        FROM (SELECT 
        ROW_NUMBER() OVER (ORDER BY genre) + (
            SELECT ISNULL(MAX(genre_id), 0) 
            FROM dbo.Dim_Genre
        ) AS genre_id,
        genre AS genre_name
        FROM dbo.StagingAnime
        GROUP BY genre) RN
        WHERE NOT EXISTS (SELECT 1 FROM dbo.Dim_Genre DG WHERE DG.genre_name = RN.genre_name);

        
        WITH FactData AS (
            SELECT 
                CAST(SR.user_id AS INT) AS user_id, 
                CAST(SA.anime_id AS INT) AS movie_id, 
                (SELECT date_id FROM dbo.Dim_Date WHERE date = CAST(GETDATE() AS DATE)) AS date_id, 
                FLOOR(RAND(CHECKSUM(NEWID())) * 15) + 1 AS director_id, 
                CAST(SR.rating AS INT) AS rating, 
                FLOOR(RAND(CHECKSUM(NEWID())) * 180) + 60 AS duration, 
                FLOOR(RAND(CHECKSUM(NEWID())) * 3265) + 1 AS genre_id, 
                ROW_NUMBER() OVER (ORDER BY SR.user_id, SA.anime_id) + 
                (SELECT ISNULL(MAX(fact_id), 0) FROM dbo.Fact_Movie) AS fact_id -- Offset fact_id
            FROM dbo.StagingAnime SA
            JOIN dbo.StagingRating SR ON SA.anime_id = SR.anime_id
        )
        INSERT INTO dbo.Fact_Movie (fact_id, user_id, movie_id, date_id, director_id, rating, view_count, duration, genre_id, last_updated)
        SELECT 
            FD.fact_id, 
            FD.user_id, 
            FD.movie_id, 
            FD.date_id, 
            FD.director_id, 
            FD.rating, 
            VC.view_count, 
            FD.duration, 
            FD.genre_id,
            GETDATE() AS last_updated -- Timestamp for insertion
        FROM FactData FD
        JOIN (
            SELECT anime_id AS movie_id, COUNT(DISTINCT user_id) AS view_count 
            FROM dbo.StagingRating 
            GROUP BY anime_id
        ) VC ON FD.movie_id = VC.movie_id
       
        WHERE NOT EXISTS (
            SELECT 1 
            FROM dbo.Fact_Movie FM
            WHERE FM.user_id = FD.user_id 
              AND FM.movie_id = FD.movie_id 
              AND FM.date_id = FD.date_id
        );

        -- Success notification
        SET @email_subject = 'Daily Data Load Successful';
        SET @email_body = 'Data was successfully loaded into the data warehouse.';
        PRINT 'Data load completed successfully.';
    END TRY
    BEGIN CATCH
       
        SET @email_subject = 'Daily Data Load Failed';
        SET @email_body = 'Error during data load: ' + ERROR_MESSAGE();
        PRINT ERROR_MESSAGE();
    END CATCH

   
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'Salma',
        @recipients = 'salmaabdelhalim2024@gmail.com',
        @subject = @email_subject,
        @body = @email_body;
END;

exec LoadAndNotifyData;