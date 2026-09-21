-- Purpose: This staging model creates a unified sales order stream by combining legacy and real-time data.
-- Role: It fits into the project by providing a single source of truth for all sales orders, regardless of their origin.
-- Base models represent 'formatting for integration' — getting source data into the shape that staging models expect
-- This is the 'reverse lateral flatten' mentioned in the instructions: you're aggregating order_details rows back into an array per order

with legacy_base as (
    -- Retrieve cleaned legacy sales orders
    select * from {{ ref('base_ecom__sales_orders') }}
),

real_time_base as (
    -- Retrieve cleaned real-time sales orders
    select * from {{ ref('base_real_time__sales_orders') }}
),

ship_methods as (
    -- Reference data for shipping methods
    select * from {{ ref('ship_method') }}
),

combined as (
    -- Section A: Legacy Data - standard fields
    select
        b.sales_order_id::VARCHAR as sales_order_id,
        b.customer_id,
        b.account_number,
        b.bill_to_address_id,
        b.comment,
        b.credit_card_approval_code,
        b.credit_card_id,
        b.currency_rate_id,
        -- Parse delivery estimate into a standard day count
        CASE 
            WHEN b.delivery_estimate ILIKE '%week%' 
                THEN REGEXP_SUBSTR(b.delivery_estimate, '[0-9]+')::INT * 7
            WHEN b.delivery_estimate ILIKE '%day%' 
                THEN REGEXP_SUBSTR(b.delivery_estimate, '[0-9]+')::INT
            ELSE NULL  
        END as delivery_estimate_days,
        b.due_date,
        b.freight,
        b.modified_date::DATE as modified_date,
        b.online_order_flag,
        b.order_date,
        b.order_details,
        b.purchase_order_number,
        b.revision_number,
        b.sales_order_number,
        b.sales_person_id,
        b.ship_date,
        b.ship_method_id, 
        b.ship_to_address_id,
        b.status,
        b.sub_total,
        b.tax_amt,
        b.territory_id,
        b.total_due
    from legacy_base b

    union all

    -- Section B: Real-Time Data - mapped and padded to match Legacy schema
    select
        r.sales_order_id::VARCHAR as sales_order_id,
        r.customer_id::NUMBER(38,0),
        NULL::VARCHAR as account_number,
        NULL::NUMBER(38,0) as bill_to_address_id,
        'Real-time Order'::VARCHAR as comment,
        NULL::VARCHAR as credit_card_approval_code,
        NULL::NUMBER(38,0) as credit_card_id,
        NULL::NUMBER(38,0) as currency_rate_id,
        NULL::NUMBER(38,0) as delivery_estimate_days,
        NULL::TIMESTAMP_NTZ as due_date,
        NULL::FLOAT as freight,
        r.last_modified::DATE as modified_date,
        1::NUMBER(38,0) as online_order_flag, 
        r.order_date::TIMESTAMP_NTZ as order_date,
        r.order_details::VARIANT as order_details,
        NULL::VARCHAR as purchase_order_number,
        NULL::NUMBER(38,0) as revision_number,
        NULL::VARCHAR as sales_order_number,
        NULL::NUMBER(38,0) as sales_person_id,
        NULL::TIMESTAMP_NTZ as ship_date,
        NULL::NUMBER(38,0) as ship_method_id,
        NULL::NUMBER(38,0) as ship_to_address_id,
        1::NUMBER(38,0) as status, 
        NULL::FLOAT as sub_total,
        NULL::FLOAT as tax_amt,
        NULL::NUMBER(38,0) as territory_id,
        NULL::FLOAT as total_due
    from real_time_base r
),

final as (
    -- Enrich combined orders with human-readable shipping method names
    select
        c.* exclude(ship_method_id), 
        s.name as shipping_method
    from combined c
    left join ship_methods s on c.ship_method_id = s.ship_method_id
)

-- Output the unified sales order dataset
select * from final
