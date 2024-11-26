{{
    config(
        materialized='ephemeral'
    )
}}


-- creates date table to ectract whatver you need for any date analysis, includes weekend day flag and holiday flag
-- created from ephemeral model that uses date spline package to create a range of dates.
WITH 
    dim_dates AS(
        SELECT 
        DATE_DAY,
        YEAR(DATE_DAY) * 10000 + MONTH(DATE_DAY) * 100 + DAY(DATE_DAY) AS DATE_ID,
        YEAR(DATE_DAY) AS YR,
        QUARTER(DATE_DAY) AS QUARTER_OF_YR,
        MONTH(DATE_DAY) AS MTH,
        WEEK(DATE_DAY) AS WK,
        DAYOFWEEK(DATE_DAY) AS DAY_OF_WK,
            CASE 
                WHEN CAST(DAYOFWEEK(DATE_DAY) AS STRING ) = '0' THEN 'Sunday' 
                WHEN CAST(DAYOFWEEK(DATE_DAY) AS STRING ) = '1' THEN 'Monday'
                WHEN CAST(DAYOFWEEK(DATE_DAY) AS STRING ) = '2' THEN 'Tuesday'
                WHEN CAST(DAYOFWEEK(DATE_DAY) AS STRING ) = '3' THEN 'Wednesday'
                WHEN CAST(DAYOFWEEK(DATE_DAY) AS STRING ) = '4' THEN 'Thursday'
                WHEN CAST(DAYOFWEEK(DATE_DAY) AS STRING ) = '5' THEN 'Friday'
            ELSE 'Saturday'
        END AS DAY_NAME,
        WEEKOFYEAR(DATE_DAY) AS WK_OF_YR,
            CASE WHEN DAYOFWEEK(DATE_DAY) IN (0,6) THEN 1 ELSE 0 END AS WEEKEND_FLAG,
            CASE 
                WHEN MONTH(DATE_DAY) IN(1) AND DAY(DATE_DAY) IN(01) THEN 1 
                WHEN MONTH(DATE_DAY) IN(1) AND DAY(DATE_DAY) IN(18) THEN 1
                WHEN MONTH(DATE_DAY) IN(5) AND DAY(DATE_DAY) IN(31) THEN 1
                WHEN MONTH(DATE_DAY) IN(6) AND DAY(DATE_DAY) IN(19) THEN 1
                WHEN MONTH(DATE_DAY) IN(7) AND DAY(DATE_DAY) IN(4) THEN 1
                WHEN MONTH(DATE_DAY) IN(9) AND WEEK(DATE_DAY) IN (35) AND DAYOFWEEK(DATE_DAY) IN(0,1) THEN 1 -- labor day is always 1st monday in september, week 35
                WHEN MONTH(DATE_DAY) IN(11) AND DAY(DATE_DAY) IN(11) THEN 1 
                WHEN MONTH(DATE_DAY) IN(11) AND WEEK(DATE_DAY) IN(48) AND DAYOFWEEK(DATE_DAY) IN (4) THEN 1 -- tg day is always last thursday of novemeberr, week 48
                WHEN MONTH(DATE_DAY) IN(12) AND DAY(DATE_DAY) IN(25) THEN 1
                ELSE 0
        END AS HOLIDAY_FLAG,
        CURRENT_TIMESTAMP() AS refreshed_at
        FROM {{ ref('stg_all_dates') }}
)

SELECT * 
FROM dim_dates