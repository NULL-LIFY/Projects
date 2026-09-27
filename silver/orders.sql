-- Orders
DROP TABLE IF EXISTS silver.orders;

CREATE TABLE silver.orders AS
SELECT
  order_id,
  customer_id,
  order_status,
  order_purchase_timestamp::TIMESTAMP,
  order_approved_at::TIMESTAMP,
  order_delivered_carrier_date::TIMESTAMP,
  order_delivered_customer_date::TIMESTAMP,
  order_estimated_delivery_date::DATE,
  CASE
    WHEN order_status = 'delivered' AND order_delivered_customer_date IS NULL 
      THEN 'corrupted'
    WHEN order_status IN ('canceled', 'unavailable') 
      THEN 'abandoned'
    WHEN order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL 
      THEN 'valid'
  ELSE 'pending'
END AS delivery_status_flag,
CASE
  WHEN oi.order_id IS NULL THEN FALSE
  ELSE TRUE
END AS has_order_items -- There are 775 no order_id in order_items
FROM bronze.orders o
LEFT JOIN (SELECT DISTINCT order_id FROM bronze.order_items) oi
  USING(order_id);

SELECT has_order_items, COUNT(*)
FROM silver.orders o
GROUP BY has_order_items;

SELECT delivery_status_flag, COUNT(*) 
FROM silver.orders 
GROUP BY delivery_status_flag 
ORDER BY COUNT(*) DESC;

SELECT 
  (SELECT COUNT(*) FROM bronze.orders WHERE order_delivered_customer_date IS NULL) bronze_null,
  (SELECT COUNT(*) FROM silver.orders WHERE order_delivered_customer_date IS NULL) silver_null;
