# Anime-DataWarehouse
# Overview

This project involves the creation of a data warehouse designed to analyze various aspects of anime, including user engagement, ratings, and viewing trends. It employs a star schema to efficiently organize data for querying and reporting.

# Motivation

The goal of this project is to provide a robust analytics platform for understanding user interactions with anime, including:

1)Popular genres

2)Top-rated movies

3)User engagement based on subscription types


# Features

Schema Design
The data warehouse follows a star schema structure with:

Dimension Tables:

1)Dim_Movie: Details about movies (e.g., title, release year).

2)Dim_User: Information about users (e.g., age, gender, subscription type).

3)Dim_Genre: Genre classifications for movies.

4)Dim_Director: Details about movie directors.

5)Dim_Date: Time hierarchy for analysis.

Fact Table:

Fact_Movie: Contains measures like user  view counts.

# Analytical Queries

The project supports queries to answer questions such as:

1)Average rating per movie by genre.

2)Total number of movies per genre.

3)Top 10 movies by rating.

4)Most popular director based on movie views.

5)Unique users who rated movies by genre.

6)Most-watched movies (highest view count).

7)User engagement analysis by subscription type.

# Data Processing
Data Loading
Data from CSV files is loaded into staging tables and then transformed into the data warehouse tables. A stored procedure (LoadAndNotifyData) automates the process and sends email notifications upon success or failure.
