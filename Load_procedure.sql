Alter PROCEDURE LoadAndNotifyData
AS
BEGIN
    DECLARE @email_subject NVARCHAR(255);
    DECLARE @email_body NVARCHAR(MAX);

    BEGIN TRY
        -- Drop existing staging tables
        DROP TABLE IF EXISTS StagingRating;
        DROP TABLE IF EXISTS StagingAnime;

        -- Create StagingRating table
        CREATE TABLE StagingRating (
            user_id VARCHAR(255),
            anime_id VARCHAR(255),
            rating int
        );

        -- Create StagingAnime table
        CREATE TABLE StagingAnime (
            anime_id VARCHAR(255),
            name VARCHAR(255),
            genre VARCHAR(255),
            type VARCHAR(255),
            episodes VARCHAR(255),
            rating VARCHAR(255),
            members VARCHAR(255)
        );

        -- Bulk insert data into StagingRating table
        BULK INSERT StagingRating
        FROM 'D:\rating_cleaned.csv'
        WITH (
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0A',
            FIRSTROW = 2 -- Skip header row
        );

        -- Bulk insert data into StagingAnime table
        BULK INSERT StagingAnime
        FROM 'D:\\anime_cleaned.csv'
        WITH (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0A',
            TABLOCK
        );

        -- Set email subject and body for success
        SET @email_subject = 'Data Load Success';
        SET @email_body = 'Data was loaded successfully into the staging tables.';

        PRINT 'Data loaded successfully.';
    END TRY
    BEGIN CATCH
        -- Handle errors
        SET @email_subject = 'Data Load Failure';
        SET @email_body = 'Error occurred while loading data. Error: ' + ERROR_MESSAGE();

        PRINT 'Error loading data. Check error log for details.';
        PRINT ERROR_MESSAGE();
    END CATCH

    -- Send email notification
    BEGIN TRY
        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'FaridaH', -- Replace with your Database Mail profile name
            @recipients = 'faridahamid2004@gmail.com', -- Replace with the system administrator's email
            @subject = @email_subject,
            @body = @email_body;

        PRINT 'Email sent successfully.';
    END TRY
    BEGIN CATCH
        PRINT 'Error sending email.';
        PRINT ERROR_MESSAGE();
    END CATCH
END;

-- To execute the combined procedure
EXEC LoadAndNotifyData;
