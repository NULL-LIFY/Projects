-- Retention customer grain
DROP TABLE IF EXISTS gold.customer_retention;

CREATE TABLE gold.customer_retention AS
SELECT
  customer_unique_id,
  COUNT(DISTINCT order_id) AS total_orders,
  MIN(order_purchase_timestamp) AS first_purchase_date,
  MAX(order_purchase_timestamp) AS last_purchase_date,
  SUM(total_price) AS customer_lifetime_value,
  CASE
    WHEN COUNT(DISTINCT order_id) > 1 THEN TRUE
    ELSE FALSE
  END AS is_repeat_customer
FROM silver.olist_master
WHERE delivery_status_flag != 'abandoned'
  AND total_price IS NOT NULL
GROUP BY customer_unique_id;

-- Checking
SELECT
  (SELECT COUNT(DISTINCT customer_unique_id) FROM silver.olist_master
    WHERE delivery_status_flag != 'abandoned' AND total_price IS NOT NULL) AS expected_count,
  (SELECT COUNT(*) FROM gold.customer_retention) AS actual_count;

SELECT is_repeat_customer, COUNT(*)
FROM gold.customer_retention
GROUP BY is_repeat_customer;  

SELECT MIN(order_purchase_timestamp), MAX(order_purchase_timestamp) 
FROM silver.olist_master;

SELECT is_repeat_customer, 
  COUNT(*) AS customer_count, 
  ROUND(AVG(customer_lifetime_value), 2) AS avg_ltv
FROM gold.customer_retention
GROUP BY is_repeat_customer;
