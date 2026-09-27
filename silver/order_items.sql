-- Order Items
DROP TABLE IF EXISTS silver.order_items;

CREATE TABLE silver.order_items AS 
SELECT
  order_id,
  order_item_id,
  product_id,
  seller_id,
  shipping_limit_date::TIMESTAMP,
  NULLIF(price, '')::NUMERIC AS price,
  NULLIF(freight_value, '')::NUMERIC AS freight_value
FROM bronze.order_items
WHERE order_id IS NOT NULL;

SELECT
  (SELECT COUNT(*) FROM bronze.order_items) AS bronze_count,
  (SELECT COUNT(*) FROM silver.order_items) AS silver_count;
