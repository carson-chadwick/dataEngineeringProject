-- Purpose: This analysis summarizes sales performance by campaign, customer segment, and advertising strategy.
-- Role: It fits into the project by providing high-level marketing insights for stakeholders, pulling data from the campaign-enriched sales model.

with campaign_sales_summary as (
    -- Aggregate sales metrics at the campaign and strategy level
    select
        campaign_id,
        customer_segment,
        ad_strategy,
        product_category,
        count(distinct sales_order_id) as total_orders,
        avg(total_due) as avg_order_value,
        sum(total_due) as total_revenue
    from {{ ref('int_sales_orders_with_campaign') }}
    group by
        campaign_id,
        customer_segment,
        ad_strategy,
        product_category
)

-- Final selection of campaign metrics, sorted by revenue to highlight top performers
select
    campaign_id,
    customer_segment,
    ad_strategy,
    product_category,
    total_orders,
    total_revenue,
    avg_order_value
from campaign_sales_summary
order by total_revenue desc;
