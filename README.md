
# Superstore Dimensional Model with dbt & Snowflake

Objective: Create a star schema for business to utilize various business intelligence and create a Tableau summary dashboard to capture high level metrics.

## Overview

This project mimics some modern day DataMart development and is an example of a star schema is created from the Tableau Superstore data. The dataset is cleaned beforehand since this was not the point of the exercise but rather to model and transform data as we would in a DataMart as a demonstration for a standard job that a client may choose to employ. 

The process itself emulates a production type ELT where a batch is loaded to Snowflake external stage and from there dbt takes over and transforms the data in three layers to create a star schema using Kimball architecture while utilizing some dbt best practices such as CI/CD pipelines, testing, using macros, documentation and modularity. 

First, dbt will transform the data by casting it the correct values in a staging area while using the raw source data. 
Once staged, generic and a few singular tests are run to adhere to dbt best practices. From here, model references to the stage data are used in creating intermediate models for the dimensions and fact table. This is where surrogate keys are added and any complex joins or logic is created. 

Finally, the final fact and dimensions are created with a new set of generic tests, unit tests, custom tests and some data governance best practices  are applied as data contracts are enforced on the final models to ensure constraints and data types don’t change without be captured and documented.

The entire process is captured in documentation below for staging and for final fact/dim.
The jobs set up are for a production environment using a standard deployment job for daily batching and a slim CI job that runs on any pull request to automatically integrate into production.

### Subjects utilized in this project are as follows:

-	Layered Engineering with staging, intermediate, fact and dim models.
-	External staging with AWS.
-	Materializations: view to advanced incremental and type 2 SCD’s
-	Testing: generic, unit and custom are all utilized.
-	CI/CD job/environments set and used for dbt cloud.
-	Macros
-	Data contracts
-	Star Schema
-	Data Visualization with Tableau (exposures may be add here-TBD)
-	And nothing fancy happening with the SQL! Its all very basic.
-	
## External Stage Set Up with Snowflake DDL

AWS S3 buckets are used to store files which mimics the “Load” portion of ELT. 
From here, DDL creates basic stage tables (all as string a this layer) o ingest the data into Snowflake. 

## Stages Materialized (Stage Layer)

Once the data is ingested in AWS,  the stage layer is created in dbt by applying light transformations and some aliasing to the stage models. We also utilize the {{ source(‘SCHEMA ‘ , ‘SOURCE TABLE’ ) }} function here to create our dependencies as the fist step of our DAG. All the business logic will be later applied in the intermediate layer. All models here are materialized as views. We don’t really care too much about the lag a view produces because this is our lightweight reference to the source data and we are in a dev environment. 

**DAG SS**
**Example code to materialize views (easy import of source data.**
**summary screensnip**

After creating stages, we run some basic tests to make sure our sources are not null and the unique keys are in fact unique. 
Oten you can incorporate some accepted values tests here as well. This will help you catch changes from the source early on that may affect your downstream BI. We want to catch as much as possible early on before we materialize our final model in dimensions and facts. This avoids what can be nasty backfills and a backlog of meetings that give you nothing but headaches. 
** add test yml  for stages**

## Slowly Changing Dimensions

The employees for Supestore are broken into a separate Dimension that is a type 2 slowly changing dimension. The method used is the timestamp method in dbt. The table is materialized in a file level configuration as a snapshot and written to a dedicated SCD schema. The customers and products table follow the same pattern as both have potential to change and the history should be captured.

Add sql ss and update for cust and emps
** add screenshot with snf update statement **

It’s notable that this data is taken early from our stage/source. We want to capture these changes early as dbt adds columns to track the date and the intermediate layer will add further transformations such as the “is_current” flag and it will also fill in the null date with a date that is extended far into the future so we can easily utilize the BETWEEN function when searching. Additionally, I add a row number function to deduplicate these records early just in case this happens. Sometimes our source data can do this and adding this step does no harm and can save you headaches later.

## Intermediate models

Once we get the stages completed,
** add screenshots, several dim date etc **

## Dbt Tests

summary screensnip audit helper results snip

## dimensional models

** talk hist tables and current for scd **
•	surrorate keys

## Data Mesh
summary screen snip
•	model contracts
•	groups

## Documentation

## Deployment

summary screen snips

## Tableau Dashboard
link to dash


