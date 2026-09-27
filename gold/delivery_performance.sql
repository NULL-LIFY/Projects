-- Delivery performance
DROP TABLE IF EXISTS gold.delivery_performance;

CREATE TABLE gold.delivery_performance AS 
SELECT
  order_id,
  customer_unique_id,
  customer_state,
  order_purchase_timestamp,
  order_delivered_customer_date,
  order_estimated_delivery_date,
  (order_delivered_customer_date::DATE - order_estimated_delivery_date) AS days_late,
  CASE
    WHEN order_delivered_customer_date::DATE > order_estimated_delivery_date THEN TRUE
    ELSE FALSE
  END AS is_late,
  review_score
FROM silver.olist_master
WHERE delivery_status_flag = 'valid';

-- Checking
SELECT
  (SELECT COUNT(*) FROM silver.olist_master WHERE delivery_status_flag = 'valid') AS expected_count,
  (SELECT COUNT(*) FROM gold.delivery_performance) AS actual_count;

SELECT is_late, COUNT(*), ROUND(AVG(review_score), 2) AS avg_review_score
FROM gold.delivery_performance
GROUP BY is_late;
  
