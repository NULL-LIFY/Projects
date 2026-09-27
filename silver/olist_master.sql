DROP TABLE IF EXISTS silver.olist_master;

CREATE TABLE silver.olist_master AS
WITH items_agg AS (
  SELECT
    order_id,
    COUNT(order_item_id) AS total_items,
    SUM(price) AS total_price,
    SUM(freight_value) AS total_freight
  FROM silver.order_items
  GROUP BY order_id
),
payments_agg AS (
  SELECT
    order_id,
    SUM(payment_value) AS total_payment_value,
    COUNT(*) AS payment_count
  FROM silver.order_payments
  GROUP BY order_id
),
reviews_agg AS (
  SELECT DISTINCT ON (order_id)
    order_id,
    review_id,
    review_score,
    review_answer_timestamp
  FROM silver.order_reviews
  ORDER BY order_id, review_answer_timestamp DESC
)
SELECT
  o.order_id,
  o.customer_id,
  o.order_status,
  o.order_purchase_timestamp,
  o.order_approved_at,
  o.order_delivered_carrier_date,
  o.order_delivered_customer_date,
  o.order_estimated_delivery_date,
  o.delivery_status_flag,
  o.has_order_items,
  c.customer_unique_id,
  c.customer_zip_code_prefix,
  c.customer_city,
  c.customer_state,
  i.total_items,
  i.total_price,
  i.total_freight,
  p.total_payment_value,
  p.payment_count,
  r.review_id,
  r.review_score,
  r.review_answer_timestamp
FROM silver.orders o
LEFT JOIN silver.customers c ON o.customer_id = c.customer_id
LEFT JOIN items_agg i ON o.order_id = i.order_id
LEFT JOIN payments_agg p ON o.order_id = p.order_id
LEFT JOIN reviews_agg r ON o.order_id = r.order_id;

-- Checking
SELECT 
  (SELECT COUNT(*) FROM silver.orders) AS orders_count,
  (SELECT COUNT(*) FROM silver.olist_master) AS master_count;


SELECT COUNT(*) FROM silver.olist_master WHERE review_score IS NULL; -- 768 null review score
