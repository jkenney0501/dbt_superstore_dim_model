--create database superstore;

/********************************************************************************************************
Create tables, file formats and external stages n snowflake for S3 bucket to be used for the project.

Summary:

Project will create a star schema from raw tables with transformations via dbt. 
- Surrogate keys will be used 
- slowly changing dimensions will also be used
- loads will be conducted to simulate incremental process and changes in employee status/new employees
********************************************************************************************************/

-- Steps to create a stirage object and query the files as tables so they can be accessed by dbt
--CREATE DATABASE SUPERSTORE;

-- 1. pick the database
USE DATABASE superstore;

-- verify region for bucket is the same
-- SELECT CURRENT_REGION();


-- 2. create schema for stage objects, this is where all staged will exist
CREATE OR REPLACE SCHEMA EXTERNAL_STGS;


-- 3. create storage object to provide credentials which are created when yuo create a role in AWS 
-- and edit the trusted relationships
CREATE STORAGE INTEGRATION s3_int
 type = external_stage
 storage_provider = 'S3'
 enabled = true
 storage_aws_role_arn = '<your arn from access role in aws >' -- remove this
 storage_allowed_locations = ('s3://superstore-data-dbt/load/' )
 ;

 
--  get sts external id and paste in trusted rel under roles for this bucket
-- also add the STORAGE_AWS_IAM_USER_ARN to the "trust relationshios AWS key."
DESC INTEGRATION s3_int;


-- 4. now you can create the stage and access it via LIST below, this uses the bucket path from AWS
CREATE STAGE SUPERSTORE.EXTERNAL_STGS.s3_dbt_stage
 storage_integration = s3_int
 url = 's3://superstore-data-dbt/load/'
 ;

-- see files after creating the stage
LIST @SUPERSTORE.EXTERNAL_STGS.S3_DBT_STAGE;


-- ***************** done al the above, chneg files to new files in folder to create more relaostic loads. also add updated at cols ****


-- create a schema fro the raw data dump
CREATE OR REPLACE SCHEMA SUPERSTORE.RAW;


-- 5. Use DDL to create table for employees, these will get transformed later
CREATE OR REPLACE TABLE SUPERSTORE.RAW.EMPLOYEES(
emp_id	   STRING,
Name	   STRING,
Surname	   STRING,
Level	   STRING,
State	   STRING,
Age	       STRING,
hire_date  STRING,	
job_title  STRING,	
status	   STRING,
updated_at DATETIME
)


-- 5.1 copy hte data from stage into the table created
COPY INTO SUPERSTORE.RAW.EMPLOYEES
FROM @SUPERSTORE.EXTERNAL_STGS.S3_DBT_STAGE
FILE_FORMAT = (
                TYPE = CSV
                SKIP_HEADER=1
                FIELD_DELIMITER = ',')
                FILES = ('employees.csv')
                
-- check the load
SELECT *
FROM SUPERSTORE.RAW.EMPLOYEES
LIMIT 20;



--  Create one large table to inegst the source data year by year 
CREATE OR REPLACE TABLE SUPERSTORE.RAW.ORDERS(
row_id	        STRING,
Order_ID	    STRING,
Order_Date	    STRING,
Ship_Date	    STRING,
Ship_Mode	    STRING,
Customer_ID	    STRING,
Customer_Name	STRING,
Sales_Agent_ID	STRING,
Country_Region	STRING,
City	        STRING,
State	        STRING,
Postal_Code     STRING,
Region	        STRING,
Product_ID	    STRING,
Category	    STRING,
Sub_Category	STRING,
Product_Name	STRING,
Sales	        STRING,
Quantity	    STRING,
Cost_percent	STRING,
updated_at      DATETIME
);


-- copy the data from stage into the table created, year by year
-- a task can be sett up but this is only for a few years to capture scd's and incrmental changes so manual is fine
COPY INTO SUPERSTORE.RAW.ORDERS
FROM @SUPERSTORE.EXTERNAL_STGS.S3_DBT_STAGE
FILE_FORMAT = (
                TYPE = CSV
                SKIP_HEADER=1
                FIELD_DELIMITER=','
                )
                FILES = ('orders_2018.csv') -- load/2017/18, add 2019 and beyond as needed to test incremental model
                 -- 'orders_2019_a.csv'
                -- 'orders_2019_b.csv'
                -- orders_2020.csv
                
                
-- check the load
SELECT *
FROM SUPERSTORE.RAW.ORDERS 
LIMIT 20;


-- break the products and customers dimesion from the orders file with the columns above. The tables are created using dbt.


