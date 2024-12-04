create database dwh
use dwh

create TABLE Dim_User (
    user_id INT PRIMARY KEY,          
    age INT,                          
    gender VARCHAR(10),               
    subscription_type VARCHAR(20)     
);

-- Create Dimension Table: Dim_Date
CREATE TABLE Dim_Date (
    date_id INT PRIMARY KEY,          
    date DATE,                        
    year INT,                         
    month INT,                        
    day INT,                          
    quarter INT                       
);

-- Create Dimension Table: Dim_Genre
create TABLE Dim_Genre (
    genre_id INT PRIMARY KEY,         
    genre_name VARCHAR(255)           
);

ALTER TABLE Dim_Genre
ALTER COLUMN genre_name VARCHAR(255); 


-- Create Dimension Table: Dim_Director
CREATE TABLE Dim_Director (
    director_id INT PRIMARY KEY,      
    director_name VARCHAR(100)        
);

-- Create Dimension Table: Dim_Movie
CREATE TABLE Dim_Movie (
    movie_id INT PRIMARY KEY,         
    title VARCHAR(255),               
    release_year INT                  
);

-- Create Fact Table: Fact_Movie
CREATE TABLE Fact_Movie (
    fact_id INT PRIMARY KEY,          
    user_id INT,                      
    movie_id INT,                     
    date_id INT,                      
    genre_id INT,                     
    director_id INT,                  
    rating INT,                       
    view_count INT,                   
    duration INT,                     
    FOREIGN KEY (user_id) REFERENCES Dim_User(user_id),         
    FOREIGN KEY (movie_id) REFERENCES Dim_Movie(movie_id),       
    FOREIGN KEY (date_id) REFERENCES Dim_Date(date_id),         
    FOREIGN KEY (genre_id) REFERENCES Dim_Genre(genre_id),       
    FOREIGN KEY (director_id) REFERENCES Dim_Director(director_id) 
);
-- Table to store Anime data
CREATE TABLE Dim_Anime (
    anime_id INT PRIMARY KEY,         
    name NVARCHAR(255),               
    genre NVARCHAR(255),              
    type NVARCHAR(50),                
    episodes INT,                     
    rating DECIMAL(3,2),              
    members INT                       
);

-- Table to store Rating data
CREATE TABLE Dim_Rating (
    rating_id INT PRIMARY KEY,        
    user_id INT,                     
    anime_id INT,                     
    rating INT,                       
    FOREIGN KEY (anime_id) REFERENCES Dim_Anime(anime_id)
);
CREATE TABLE ViewCount (
    movie_id INT PRIMARY KEY,  
    view_count INT             
);
INSERT INTO ViewCount (movie_id, view_count)
SELECT 
    anime_id AS movie_id, 
    COUNT(DISTINCT user_id) AS view_count
FROM dbo.StagingRating 
GROUP BY anime_id;