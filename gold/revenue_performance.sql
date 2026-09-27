-- Gold layer
CREATE SCHEMA IF NOT EXISTS gold;

-- Revenue table order grain
DROP TABLE IF EXISTS gold.revenue_performance;

CREATE TABLE gold.revenue_performance AS
SELECT
  order_id,
  order_purchase_timestamp,
  DATE_TRUNC('month', order_purchase_timestamp)::DATE AS order_month,
  customer_state,
  customer_city,
  delivery_status_flag,
  total_items,
  total_price,
  total_freight,
  total_payment_value
FROM silver.olist_master
WHERE delivery_status_flag != 'abandoned'
  AND total_price IS NOT NULL;

-- Checking
SELECT
  (SELECT COUNT(*) FROM silver.olist_master
    WHERE delivery_status_flag != 'abandoned' AND total_price IS NOT NULL) AS expected_count,
  (SELECT COUNT(*) FROM gold.revenue_performance) AS actual_count;
