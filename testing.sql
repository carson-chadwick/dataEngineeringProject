use database BULLFROG_DB;
use schema raw_ext;

list @orders_stage;

list @order_details_stage;

list @chat_stage;

SELECT COUNT(*) FROM raw_ext.orders_raw;
SELECT COUNT(*) FROM raw_ext.order_details_raw;
SELECT COUNT(*) FROM raw_ext.chat_logs_raw;

TRUNCATE TABLE orders_raw;
TRUNCATE TABLE order_details_raw;
TRUNCATE TABLE chat_logs_raw;

DESCRIBE VIEW BULLFROG_DB.DBT_DEV.BASE_ECOM__SALES_ORDERS;
-- OR if it's a table:
DESCRIBE TABLE BULLFROG_DB.DBT_DEV.BASE_ECOM__SALES_ORDERS;

SHOW TABLES IN BULLFROG_DB.RAW_EXT;

select * from BULLFROG_DB.RAW_EXT.CHAT_LOGS_RAW;

DESCRIBE TABLE BULLFROG_DB.RAW_EXT.CHAT_LOGS_RAW;

LIST @BULLFROG_DB.RAW_EXT.CHAT_STAGE;

-- Then "peek" into the file sitting in the stage:
SELECT $1 FROM @BULLFROG_DB.RAW_EXT.CHAT_STAGE (file_format => 'YOUR_JSON_FORMAT_NAME');

SELECT * FROM raw_ext.chat_logs_raw limit 10;

SELECT 
    COUNT(*) as total_rows,
    -- Use _id instead of chat_id
    COUNT(DISTINCT RAW:_id) as unique_chat_ids,
    COUNT(*) - COUNT(DISTINCT RAW:_id) as duplicate_count
FROM BULLFROG_DB.RAW_EXT.CHAT_LOGS_RAW;

select * from BULLFROG_DB.RAW_EXT.CHAT_LOGS_RAW limit 10;
SELECT * FROM RAW_EXT.web_analytics_raw limit 20;

SELECT COUNT(*) FROM dbt_dev.stg_web_analytics;
SELECT * FROM dbt_dev.int_web_analytics_with_customers LIMIT 10;

-- This calculates the number of records per individual load "cycle"
SELECT 
    _LOADED_AT, 
    COUNT(*) as records_processed
FROM RAW_EXT.WEB_ANALYTICS_RAW
GROUP BY _LOADED_AT
ORDER BY _LOADED_AT DESC;