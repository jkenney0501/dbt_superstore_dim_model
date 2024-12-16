
# Superstore Dimensional Model with dbt & Snowflake

Objective: Create a new data workflow from a dara dump in AWS that refreshes M-F and create a Tableau summary dashboard to capture high level metrics associated to this data.

Note: this is not meant to be a tutorial but moreso a walk through of high level items that are completed as an example of a process used for a standard dbt job. It may be a little messy right now but it'll get cleaned up!
It's more of a check list of basic items I use a lot.

## Overview

This project mimics some modern day DataMart development and is an example of a star schema is created from the Tableau Superstore data. 
The dataset is cleaned beforehand since this was not the point of the exercise but rather to model and transform data as we would in a DataMart as a demonstration for a standard job that a client may choose to employ. 

The process itself emulates a production type ELT where a batch is loaded to Snowflake external stage and from there dbt takes over and transforms the data in three layers to create a star schema using Kimball architecture while utilizing some dbt best practices such as CI/CD pipelines, testing, using macros, documentation and modularity. 

First, dbt will transform the data by casting it the correct values in a staging area while using the raw source data. 
Once staged, generic and a few singular tests are run to adhere to dbt best practices. From here, model references to the stage data are used in creating intermediate models for the dimensions and fact table. This is where surrogate keys are added and any complex joins or logic is created. 

Finally, the final fact and dimensions are created with a new set of generic tests, unit tests, custom tests and some data governance best practices  are applied as data contracts are enforced on the final models to ensure constraints and data types don’t change without be captured and documented.

The entire process is captured in documentation below for staging and for final fact/dim.
The jobs set up are for a production environment using a standard deployment job for daily batching and a slim CI job that runs on any pull request to automatically integrate into production.


Base Requirements:

- Import source data from external stage in AWS S3 bucket.
- Layer architecture: stage, internediate with business logic, consumption layer.
- Implement testing for sources from generic to custom to unit testing. 
- Add third party package for meta testing to ensure proper schema tests at stage layer.
- Clean an de duplicate data as needed.
- Add type 2 slowly changng dimension to capture customer, product and employee changes for a history table and current table.
- Add incrmental model to capture new orders that are loaded.
- Create a dimensional model as tables for consumption layer.
- Add surrogate keys to each dimesion and fact.
- Create documentation for all.
- Create a standard CI (continous integration) job fro any future changes.
- Create standard daily schedule for CD (continuous deployment) M-F.
- Create a full refresh job that occurs once weekly on sundays to capture any incrments that may have slipped through dev.
- Add data contracts to enforce constraints and satsifay stakeholder requirements at consumption layer.
- Creat high level Tableau Dashboard to cover basic KPI's.


An example of the basic process flow is as follows:

<img src="assets/superstore-conceptual.png" width="1000">

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

*Additonal Steps would also include capacity planning but given the inputs are psuedo, its hard to "psuedoize" the capacity plan but realistically, we would just use a mutiple on our average file size by cadence.*

*******Dicuss layers and then eas into below model as finished product.******

The outcome we expect is a data model found in the below entity relatonship diagram:


The star schema model that is being engineered is as follows:
<img src="assets/Superstore ERD (2).png" width="1000">


## External Stage Set Up with Snowflake DDL

AWS S3 buckets are used to store files which mimics the “Load” portion of ELT after extraction from a source system (lets presum Talend dumos this data to S3). 
From here, DDL in Snowflake will create the basic stage tables (all as string a this layer) just to ingest the data into Snowflake. 

<a href='snowflake_set_up_aws_stage_ddl/snowflake_set_up_external_stage_ddl.sql'>see the snowflake ddl here</a>

## Define Sources

Fisrt thing we do is define our sources in a source.yml file. Thi sallow us to use the {{ source() }} function to create depemdemcies in dbt. This step is crucial to setting up a good foundation for your project.

Souurces example: (On a real project, I would most likley set up a separate test file for my sources). NOte we add the source freshness needed for incremental models. Thi stests the freshness of the dat. Below it is configured to throw a warning if the data is older than 1 day. 
```yml
version: 2

sources:
  - name: raw
    database: superstore  
    schema: raw  
    
    tables:
      - name: employees
      - name: orders
        freshness: # default freshness
          warn_after: {count: 24, period: hour}
        loaded_at_field: updated_at
```

Our source DAG at this point just shows orders and employees. Next our staging will expand on our layering.


## Stages Materialized as Views

Once the data is ingested in AWS and sourced in a yml file, the stage layer is created in dbt by applying light transformations and some aliasing to the stage models. We also utilize the {{ source(‘SCHEMA ‘ , ‘SOURCE TABLE’ ) }} function here to create our dependencies as the fist step of our DAG. All the business logic will be later applied in the intermediate layer. All models here are materialized as views. We don’t really care too much about the lag a view produces because this is our lightweight reference to the source data and we are in a dev environment. Below is how the materializations are set up in the dbt_project.yml

```yml
models:
  superstore:
    stg:
      +materialized: view
      +required_tests: {"unique.*|not_null": 1} # requires at least one og the following tests to be conducted on each model
    int:
      +materialized: view
    marts:
      dim:
        +materialized: table
      fct:
        +materialized: table
```
Staging code in dbt is rally simple as we are just importing the ata from the raw layer with some minor transformations. I alwayssy try to get my aliases and data types set here. 
  - One thing we dont want to do is modfy too much here, this is your foundation to reference so keep it simple so we camn easily reference the stage items.I usually will add some audit columns from snowfalke here as well.

Example stage import:
```sql
-- import raw orders to stage

with orders_stage as(
    select 
        *
    from 
        {{ source('raw', 'orders') }}
)

select 
    cast(row_id as int) as row_id,
    order_id,
    cast(order_date as date) as order_date,
    cast(ship_date as date) as ship_date,
    ship_mode,
    customer_id, 
    customer_name,
    sales_agent_id as emp_id,
    country_region,
    city,
    state,
    cast(postal_code as int) as postal_code,
    region,
    product_id,
    category,
    sub_category,
    product_name,
    cast( sales as decimal(20,2)) as sales,
    cast( quantity as integer) as quantity,
    cast( cost_percent as decimal(3,2)) as cost_percent,
    updated_at 
from orders_stage
```

The DAG in dbt now looks alittle bit like something is happening:

<img src="assets/stage_layer.png" width="1000">


After creating stages, we run some basic tests to make sure our sources are not null and the unique keys are in fact unique. 
Oten you can incorporate some accepted values tests here as well. This will help you catch changes from the source early on that may affect your downstream BI. We want to catch as much as possible early on before we materialize our final model in dimensions and facts. This avoids what can be nasty backfills and a backlog of meetings that give you nothing but headaches. 

*Each stage model gets its own test set up in a yml file, the employees is just one of several.*

<a href= 'models/stg'>see more testing source code here</a>
```yml
version: 2

models:
  - name: stg_employees
    description: Employees table that show employee information, mainly for tracking purposes in reporting. Type 2 SCD
    columns:
      - name: emp_id
        description: Primary key for employee table
        tests:
          - not_null
          - unique
      - name: first_name
        description: employees first name.
        tests:
          - not_null
      - name: last_name
        description: employees last name.
        tests:
          - not_null
      - name: age
        description: employees age.
        tests:
          - not_null   
      - name: hire_date
        description: date of employee hire, cannot be null.
        tests:
          - not_null
      - name: status
        description: employee status can be either A - active, T- terminated or LA leave of absence. Cannot be null.
        tests:
          - not_null
          - accepted_values:
              values: ['A', 'T', 'L/A', 'SB']
```


## Building the Dimesional Model

Why do we do this? This has become a standard for intuitive and functionaly performant data consumption from our downstream users. Given we do the SCD's and the join logic, the heacy lifting so to sepak is domne and the data is denormailzed so its easier to understand. Not to mention, in dimesional modeling, we are attempting to always capture a business process to measure. Our fact does just this and our dimensions add conetx to our fact. In short, this make things really easy to understand and document for our stakeholders.

Orders is the main file dump where all schema are derived from except employees (b/c this has additionla HR data that would typically get dumped or be its own extract separately in most cases anyhow).
That veing said, Employees is a separate uplaod similar to a file or an ELT pull from Human Resources in a company.

Therefore, we extract all dimesions later from orders except employees. First, start with what might chnage and in this case, its the type 2 SCD's so we add them to the snapshots folder.


Example of the simple code import using CTE's (we utiaize the ref() function to create additional dependencies in our DAG): SCD's are captured early, directly from source or stage layers, these are typically a first for me to work on.

```sql
-- import employees file from raw dump in S3 to stage layer
with employees_stage as(
    select 
        *
    from 
        {{ source('raw', 'employees') }}
)
-- transform what we need with some small adjustments, add all aliases here.
select 
    cast(emp_id as int) as emp_id,
    name as first_name,
    surname as last_name,
    level,
    state,
    cast(age as int) as age,
    cast(hire_date as date) as hire_date,
    job_title,
    status,
    updated_at
from employees_stage
```

Once the stages are complete, type 2 slowly changing dimemsnions are sent to the snapshots folder in dbt to capture any changes while 
The other models become intermediate models where we begin to apply business logic to create our consumption layer. Th esanpshots will also go through additional logic as they are imported to intermediate as well. We want to capture and add the is_current and end_dates.


## More on Slowly Changing Dimensions

The employees for Supestore are broken into a separate Dimension that is a type 2 slowly changing dimension. The method used is the timestamp method in dbt. The table is materialized in a file level configuration as a snapshot and written to a dedicated SCD schema. The customers and products table follow the same pattern as both have potential to change and the history should be captured.
Typically, these are pulling directly from the source data but in this case, one large table was broken down into dimensions and fact so the cutomers and prodcuts were aprt of that and had to be broken down as stages first.
The employees is a separate file and was staged as such with all going dorectly to snapshots after testing.

```sql
-- note the scd snapshot uses a snapshot madcro and is run with by calling: dbt snapshot

-- creates type 2 slowly changing dimension for customers

{% snapshot scd_t2_employees %}


{{
    config(
        target_database='superstore',
        target_schema='dev_snapshots',
        unique_key='emp_id',
        strategy='timestamp',
        updated_at='updated_at',
        invalidate_hard_deletes=True
    )
}}

-- create employees dim, this is an scd type 2
with emps_dedupe_dim as(
    select 
        *,
        row_number() over(partition by emp_id, first_name, last_name, level, state, age, hire_date, job_title, status order by emp_id) as total_rows
    from {{ ref('stg_employees') }}
)
select 
    emp_id,
    first_name,
    last_name,
    level,
    state,
    age,
    hire_date,
    job_title,
    status,
    updated_at
from emps_dedupe_dim
where total_rows = 1

{% endsnapshot %}

```

To mimic a source change (and to visualize it), the employee table is updated to reflect a promotion in by way of job title. This is doen in Snowflake with the following code: (Note this is the finsihed row level data.)

```sql
-- change an employees job title to 'SPB' due to a promotion 
update SUPERSTORE.RAW.EMPLOYEES
set job_title = 'SPB', updated_at = current_timestamp()
where emp_id = 2


-- check the change
select *
from SUPERSTORE.RAW.EMPLOYEES
where emp_id = 2


-- check changes in both table, this hist table will show the flags and history
select *
from SUPERSTORE.DEV.DIM_EMPLOYEES_HISTORY
where emp_id = 2
order by updated_at desc;
```


 <img src="assets/SCD_employees.png" width="1000">

The final DAG will look like this as we add a currrent and histroy table (some emps leave, some are new etc so it changes a bit):
 
<img src="assets/scd-t2-emps_dag.png" width="1000">

To further demonstrate, we change a customers name as well by mimicking a source system update with some simple CRUD:

```sql
-- update raw tables to mimic source system updates
-- change a customers name where customer id = LO-17170, change to Loren Olson
update SUPERSTORE.RAW.ORDERS
set customer_name = 'Loren Olsen', updated_at = current_timestamp()
where customer_id = 'LO-17170';


-- check the change
select *
from SUPERSTORE.RAW.ORDERS
where customer_id = 'LO-17170'

-- see the cahnge in the dimension table
select *
from SUPERSTORE.DEV.DIM_CUSTOMERS_HISTORY
where customer_id = 'LO-17170'
order by 4 desc;
```

 <img src="assets/scd_t2_customers.png" width="1000">

 The final DAG will look like this:
<img src="assets/scd_customers_dag.png" width="1000">

It’s notable that this data is taken early from our stage/source. We want to capture these changes early as dbt adds columns to track the date and the intermediate layer will add further transformations such as the “is_current” flag and it will also fill in the null date with a date that is extended far into the future so we can easily utilize the BETWEEN function when searching. Additionally, I add a row number function to deduplicate these records early just in case this happens. Sometimes our source data can do this and adding this step does no harm and can save you headaches later.



## Intermediate models

Once we get the stages completed, we can start to implement business logic that captures and measures the business process as defined in any requirements. This is where we start to refine things ans model the data in a consumeable way that downstream users will access via SQL queries. Note the fact below alos utilizes incrmental logic and surogate kys whihc will be discussed later.
    - By business logic, we are creating a production level star schema fro data consumers such as analysts and other future user taht will access with SQL.
    - Some orgs my choose to use ephemeral models here but keep in ind, this can be hard to debug and really wrecks your testing.

Example: addning incremental logic in an intermediate step while also creating surrogates to macth dimesions. 
  - several things to note here:
    - We use a strategy using the primary key for the incrment
    - the schema change is set tp fail if there are any changes. This lets us catch changes beforer they go into prod w/o anyone knowing.
    -  the model uses {{ this }} to reference itself by taking the max date of reference from the model (not inclusive of the current load date).
```sql
-- create fact: this needs to be set up as incrmental

{{ 
    config(
        target_schema = 'inc_models',
        materialized = 'incremental', 
        unique_key = 'fct_primary_key',
        on_schema_change ='fail'
    ) 
}}

-- adds dupe check
with orders_dedupe_fact as(
    select 
        *,
        row_number() over(partition by order_id, order_date, ship_date, ship_mode, sales, quantity, cost_percent order by order_id) as total_rows
    from {{ ref('stg_orders') }}
),

-- gets only unique rows from dedupe fact
de_duped as(
    select *
    from orders_dedupe_fact
    where total_rows = 1
),

-- adds increment step after deduped so it is readay for testing before prod
increment_fct as (
    select 
        {{ dbt_utils.generate_surrogate_key(['order_id', 'order_date', 'updated_at']) }} AS fct_primary_key,
        {{ dbt_utils.generate_surrogate_key(['customer_id', 'customer_name']) }} as cust_surr_id,
        order_id,
        customer_id,
        YEAR(order_date) * 10000 + MONTH(order_date) * 100 + DAY(order_date) AS order_date_id,
        YEAR(ship_date) * 10000 + MONTH(ship_date) * 100 + DAY(ship_date) AS ship_date_id,
        ship_mode,
        emp_id,
        {{ dbt_utils.generate_surrogate_key(['country_region', 'state', 'city', 'postal_code', 'region']) }} as location_surr_id,
        {{ dbt_utils.generate_surrogate_key(['product_id', 'category', 'sub_category', 'product_name']) }} as prod_surr_id,
        sales,
        quantity,
        cost_percent,
        updated_at
    from de_duped

     {% if is_incremental() %}

            WHERE updated_at >= (SELECT MAX(updated_at) FROM {{ this }} )

     {% endif %}
)

-- final query
select *
from increment_fct 

```

To further show how the intermedioate payer adds complexity, the date spline package was used to create a date range which is just a simple date. Uisng this, the date was broken down into its lowest form for anytype of time series anaalysis our user wants to conduct, even wekend and holicday flags. Thats complex logic and needs to be unit tested.  The process was developed using test driven developement before actually writing any SQL. See unit testing below. Here is an example of the complex sql used:
```sql

-- creates date table to exctract whatver you need for any date analysis, includes weekend day flag and holiday flag. Created from date spline package.
with 
    dim_dates as(
        select 
        year(date_day) * 10000 + month(date_day) * 100 + day(date_day) as date_id,
        date_day,
        year(date_day) as yr,
        quarter(date_day) as quarter_of_yr,
        month(date_day) as mth,
        weekofyear(date_day) as wk_of_yr,
        dayofweek(date_day) as day_of_wk,
            case 
                when cast(dayofweek(date_day) as string ) = '0' then 'sunday' 
                when cast(dayofweek(date_day) as string ) = '1' then 'monday'
                when cast(dayofweek(date_day) as string ) = '2' then 'tuesday'
                when cast(dayofweek(date_day) as string ) = '3' then 'wednesday'
                when cast(dayofweek(date_day) as string ) = '4' then 'thursday'
                when cast(dayofweek(date_day) as string ) = '5' then 'friday'
            else 'saturday'
        end as day_name,
            case when dayofweek(date_day) in (0,6) then 1 else 0 end as weekend_flag,
            case 
                when month(date_day) in(1) and day(date_day) in(01) then 1 
                when month(date_day) in(1) and day(date_day) in(18) then 1
                when month(date_day) in(5) and day(date_day) in(31) then 1
                when month(date_day) in(6) and day(date_day) in(19) then 1
                when month(date_day) in(7) and day(date_day) in(4) then 1
                when month(date_day) in(9) and week(date_day) in (35) and dayofweek(date_day) in(0,1) then 1 -- labor day is always 1st monday in september, week 35
                when month(date_day) in(11) and day(date_day) in(11) then 1 
                when month(date_day) in(11) and week(date_day) in(48) and dayofweek(date_day) in (4) then 1 -- tg day is always last thursday of novemeberr, week 48
                when month(date_day) in(12) and day(date_day) in(25) then 1
                else 0
        end as holiday_flag,
        current_timestamp() as refreshed_at
        from {{ ref('stg_all_dates') }}
)

select * 
from dim_dates
```


## dbt Tests - Generic to Unit Testing

Testing is one of the fundamental core pieces of dbt and is  software engineerning best pratice. 
    - Keep in mind, we often dont need hundresedd of tests, we juwt need really good tests at the right moments!
    - Fundamaental tests like unique and not null a always a must and typically I use a thord party package called metatesting to ensure I have at least one of these for each model that I stage.
    - I dind its also vital to test values that should be greater than 0 or what woud  be considered an accepted value frjm the business (such as order status).
    - I also like ot add a unit test for any logic that is considered advanced to test my assertions and catch any potential edge cases. In this exmaple, I unit test my date dimenesion becasue it is complex and \
      I want to ensure my users are getting the required functionality for date searches.


Generic Example that uses unique, not_null and accepted values at the stage layer:
```yml
version: 2

models:
  - name: stg_employees
    description: Employees table that show employee information, mainly for tracking purposes in reporting. Type 2 SCD
    columns:
      - name: emp_id
        description: Primary key for employee table
        tests:
          - not_null
          - unique
      - name: first_name
        description: employees first name.
        tests:
          - not_null
      - name: last_name
        description: employees last name.
        tests:
          - not_null
      - name: age
        description: employees age.
        tests:
          - not_null   
      - name: hire_date
        description: date of employee hire, cannot be null.
        tests:
          - not_null
      - name: status
        description: employee status can be either A - active, T- terminated or LA leave of absence. Cannot be null.
        tests:
          - not_null
          - accepted_values:
              values: ['A', 'T', 'L/A', 'SB']

```


At the intermediate layer, its gets slightly more complicared becasue I use a custom test macro. For this I use:

```yml
version: 2

# this tests the intermediate layer before it moves to the final prod layer, if it fails then no load, similar to WAP.

models:
  - name: int_fct_orders
    description: fact table for orders
    columns:
      - name: sales
        description: sales amount of the orders
        tests:
         - not_null
         - positive_value
      - name: quantity
        description: the number of items in the order
        tests:
         - not_null
         - positive_value       
```
The above tests are derived from a custome test macro and test that the column has a value greater tahn zero. This runs as applied above to a column and is triigered by dbt build or test.

```sql
-- applies to all numeric cols with a count, date math or a dolar amount
{% test positive_value(model, column_name) %}
    with gte_zero as(
        select  *
        from {{ model }}
        where {{ column_name}} <= 0
)

select * from gte_zero

{% endtest %}
```
At the consumption layer (dim/fact), I will look to test two things, relationships (aka referential integrity) and unit test complex logic:

Unit Tests and Test Driven Development:
- The unit test is typically used for test driven development meaning we make the test first and then development the model by incorporatng that same logic.
- The date dimesnion has som ecomplexity to it and is a great candiate with several case statements and flags, all fields are derived from one date field whic mkaes ourinput simple.
- The unit test is meant to capture edge cases that fall outside our assumptions.

Example of the actual untit test for the dim date model (not this is conducted at the intermediate level before the dim is built):
```yml
unit_tests:
  - name: test_date_dimension_logic
    description: >
      Validate logic in the date dimension model given it is a bit complex, holiday flags, 
      weekend flags, are completed as custome tests given week one is actually 52 and requires customization as do flags.
    model: int_dim_date
    given:
      - input: ref('stg_all_dates')
        rows:
          - {date_day: '2024-01-01'}
          - {date_day: '2024-07-04'}
          - {date_day: '2024-12-25'}
          - {date_day: '2024-11-28'}
          - {date_day: '2024-09-01'}
          - {date_day: '2024-09-02'}
          - {date_day: '2024-11-11'}
          - {date_day: '2024-05-31'}
          - {date_day: '2024-06-01'}
          - {date_day: '2024-06-02'}
          - {date_day: '2024-06-19'}
    expect:
      rows:
        - {date_day: '2024-01-01', date_id: 20240101, yr: 2024, quarter_of_yr: 1, mth: 1,  day_of_wk: 1, day_name: 'monday', weekend_flag: 0, holiday_flag: 1}
        - {date_day: '2024-07-04', date_id: 20240704, yr: 2024, quarter_of_yr: 3, mth: 7,  day_of_wk: 4, day_name: 'thursday', weekend_flag: 0, holiday_flag: 1}
        - {date_day: '2024-12-25', date_id: 20241225, yr: 2024, quarter_of_yr: 4, mth: 12, day_of_wk: 3, day_name: 'wednesday', weekend_flag: 0, holiday_flag: 1}
        - {date_day: '2024-11-28', date_id: 20241128, yr: 2024, quarter_of_yr: 4, mth: 11, day_of_wk: 4, day_name: 'thursday', weekend_flag: 0, holiday_flag: 1}
        - {date_day: '2024-09-01', date_id: 20240901, yr: 2024, quarter_of_yr: 3, mth: 9,  day_of_wk: 0, day_name: 'sunday', weekend_flag: 1, holiday_flag: 1}
        - {date_day: '2024-09-02', date_id: 20240902, yr: 2024, quarter_of_yr: 3, mth: 9,  day_of_wk: 1, day_name: 'monday', weekend_flag: 0, holiday_flag: 0}
        - {date_day: '2024-11-11', date_id: 20241111, yr: 2024, quarter_of_yr: 4, mth: 11, day_of_wk: 1, day_name: 'monday', weekend_flag: 0, holiday_flag: 1}
        - {date_day: '2024-05-31', date_id: 20240531, yr: 2024, quarter_of_yr: 2, mth: 5,  day_of_wk: 5, day_name: 'friday', weekend_flag: 0, holiday_flag: 1}
        - {date_day: '2024-06-01', date_id: 20240601, yr: 2024, quarter_of_yr: 2, mth: 6,  day_of_wk: 6, day_name: 'saturday', weekend_flag: 1, holiday_flag: 0}
        - {date_day: '2024-06-02', date_id: 20240602, yr: 2024, quarter_of_yr: 2, mth: 6,  day_of_wk: 0, day_name: 'sunday', weekend_flag: 1, holiday_flag: 0}
        - {date_day: '2024-06-19', date_id: 20240619, yr: 2024, quarter_of_yr: 2, mth: 6,  day_of_wk: 3, day_name: 'wednesday', weekend_flag: 0, holiday_flag: 1}
```

Week is not part of this test as the the unit test was capturing January 1st 2024 as week 1 when its actually week 52 of 2023. That is certainly an edge case!
However, this was a great candidate for a custom test with one specific task in mid.

```sql
with week_test as (

    select
        *
    from 
        {{ ref('int_dim_date') }}
    where wk_of_yr != week(date_day) -- does my week match the ANSI standard week?

)

select * from week_test
```
A quick DAG view of the unit test in action is below: if the test fails, the model does not build!
<img src="assets/fact_oreders_row_level_w_unit_tests.png" width="1000">


To test referential integrity, I am using a basic relationship test from dbt after incorporating surrogate keys becaseu the design of tge star schem requires a relationship from the fact to the dimesions via surrogte key that I created in dbt.

Test relationships on fact (note contracts are added later and in the final version):

```yml
version: 2
# this example is only a relationship tes, final version ahs contracts added
models:
  - name: fact_orders
    description: Fact table for orders.
    columns:
      - name: fct_primary_key
        description: Primary key for fact table.
        data_type: varchar
        tests:
          - not_null 
          - unique
      - name: cust_surr_id
        description: the foreign key to the customers dimension.
        data_type: varchar
        tests:
          - relationships:
              field: cust_surr_id
              to: ref('dim_customers_current')
      - name: order_date_id
        description: The foriegn key to the date dimension whihc allows the id of varius date attributes from bus day to holiday to month to quarter etc.
        data_type: number
        tests:
          - relationships:
              field: date_id
              to: ref('dim_date')
      - name: ship_date_id
        description: Foreign key to date table.
        data_type: number
        tests:
          - relationships:
              field: date_id
              to: ref('dim_date')
      - name: location_surr_id
        description: The location id, foriegn key to location dimension.
        tests:
          - relationships:
              field: location_surr_id
              to: ref('dim_location')
        data_type: varchar
      - name: prod_surr_id
        description: The product identifier, foriegn key to products dimension.
        data_type: varchar
        tests:
          - relationships:
              to: ref('dim_products_current')
              field: prod_surr_id
      - name: customer_id
        description: The customer id, foreign key to customers dimension.
        data_type: varchar
        tests:
          - relationships:
              field: customer_id
              to: ref('dim_customer_current')
      - name: emp_id
        description: The employee id - foriegn key to employees dimension.
        data_type: varchar
        tests:
          - relationships:
              field: emp_id
              to: ref('dim_employees_current')
    
```

Overall, this project has 155 total tests. All of which have passed. Testing is crucial to building a successful project with data!.

<img src="assets/dbt_test_155_success.png" width="1000">

## Data Mesh

To enforce constraints, data contracts were used at the consumption layer. These are used to ensure the LOB will have some consistency in the data served to their users. If the data type is changed, the etst will throw an error and the model will not materialize which triggers a review for the dev team. This protecst the consumption layer from incosistenices and potential errors or unknown changes that have negative downstream impqacts that no one knows is a problem unitl it becomes a majpr headache. Note: they are combined in the final yml file with the final testing.
```yml
version: 2

# this tests the intermediate layer before it moves to the final prod layer, if it fails then no load, similar to WAP.

models:
  - name: int_fct_orders
    description: fact table for orders
    columns:
      - name: fct_primary_key
        tests:
          - unique  
          - not_null
      - name: cust_surr_id
        description: customer surrogate key that relates to customers table
        tests:
         - not_null
      - name: order_id
        description: unique aplha-numeric for the order
        tests:
         - not_null
         - unique  
      - name: order_date_id
        description: foreign key to date dimension
        tests:
         - not_null
      - name: ship_date_id
        description: foreign key to date dimension - join twice ot get both order/ship
        tests:
         - not_null
      - name: ship_mode
        description: method of shipping used for the order
        tests:
         - not_null
      - name: emp_id
        description: primary key to employees dimension
        tests:
         - not_null
      - name: location_surr_id
        description: foreign key to location dimension 
        tests:
         - not_null
      - name: prod_surr_id
        description: foreign key to product dimension 
        tests:
         - not_null
      - name: sales
        description: sales amount of the orders
        tests:
         - not_null
         - positive_value
      - name: quantity
        description: the number of items in the order
        tests:
         - not_null
         - positive_value
      - name: cost_percent
        description: the percentage of the order that is attributed to the overall cost of production
        tests:
         - not_null
      - name: updated_at
        description: batch load date - will differ as batches arrive daily
        tests:
         - not_null
      
```

## Documentation

Along the way for each step/layer, I document everthing by using the "description" in every yml file for every column or table. We need to be mindful of our audience. Typically, at the stage layers or intermediate layer, developers will be our auduence so we try to add wht we think can best help them. Below is an example of documentation in dbt cloud. You can get way more elaborate with overviews and descriptions but I tend to keep it simple b/c it takes time away from dev and well...., that is generally the strength for most of us.

dbt docs allow us to:
- capture tablelevel descriptions
- capture column level descriptions
- capture column leveltest descriptions
- models referenced
- code
- DAG visuals like below

Example of the finished DAG from dbt docs:

<img src="assets/docs_lineage_complete.png" width="1000">

Example of table level docs in dbt cloud:
<img src="assets/docs_table_level_desc.png" width="1000">


## Deployment

The last very important part of using dbt -  CI/CD part of your pipeline!

Typically, we develop three different jobs. 
  - continuous delivery (Slim CI job triggered on a pull request/merge after testsing passes for new changes)
  - continous deployment (M-F at 12am)
  - weekly full refresh (in case of missing increments)

CI Example (on merge):
<img src="assets/slim_ci_job.png" width="1000">

CD Example -  M-F at 12am:
<img src="assets/deploy_job_mon_fri.png" width="1000">

Weekly Full Refresh (Sundays only)
<img src="assets/deploy_weekly_full_refresh.png" width="1000">

Succcessul Run Example: (the warnings are from an unused path that was not configured, nothing material)
<img src="assets/run_summary_unused_resource_warning.png" width="1000">

## Tableau Dashboard

This is just a placeholder while the actual dahshbaord is being developed form the data used for this project. This is a simple version whereas the actial version is developed using the model data above and will have much more detail and various grain layers to tell a deeper story.

https://public.tableau.com/views/superstore_17058800874340/Dashboard1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link


<div class='tableauPlaceholder' id='viz1734287914112' style='position: relative'><noscript><a href='#'><img alt='Dashboard 1 ' src='https:&#47;&#47;public.tableau.com&#47;static&#47;images&#47;su&#47;superstore_17058800874340&#47;Dashboard1&#47;1_rss.png' style='border: none' /></a></noscript><object class='tableauViz'  style='display:none;'><param name='host_url' value='https%3A%2F%2Fpublic.tableau.com%2F' /> <param name='embed_code_version' value='3' /> <param name='site_root' value='' /><param name='name' value='superstore_17058800874340&#47;Dashboard1' /><param name='tabs' value='no' /><param name='toolbar' value='yes' /><param name='static_image' value='https:&#47;&#47;public.tableau.com&#47;static&#47;images&#47;su&#47;superstore_17058800874340&#47;Dashboard1&#47;1.png' /> <param name='animate_transition' value='yes' /><param name='display_static_image' value='yes' /><param name='display_spinner' value='yes' /><param name='display_overlay' value='yes' /><param name='display_count' value='yes' /><param name='language' value='en-US' /></object></div>                
