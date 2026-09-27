
-- Bronze
-- Create Schema
CREATE SCHEMA IF NOT EXISTS bronze;

CREATE TABLE bronze.orders (
    order_id varchar,
    customer_id varchar,
    order_status varchar,
    order_purchase_timestamp varchar,
    order_approved_at varchar,
    order_delivered_carrier_date varchar,
    order_delivered_customer_date varchar,
    order_estimated_delivery_date varchar,
    _loaded_at timestamp DEFAULT now(),
    _source_file varchar DEFAULT 'olist_orders_dataset.csv'
);

CREATE TABLE bronze.customers (
    customer_id varchar,
    customer_unique_id varchar,
    customer_zip_code_prefix varchar,
    customer_city varchar,
    customer_state varchar,
    _loaded_at timestamp DEFAULT now(),
    _source_file varchar DEFAULT 'olist_customers_dataset.csv'
);

CREATE TABLE bronze.order_items (
    order_id varchar,
    order_item_id varchar,
    product_id varchar,
    seller_id varchar,
    shipping_limit_date varchar,
    price varchar,
    freight_value varchar,
    _loaded_at timestamp DEFAULT now(),
    _source_file varchar DEFAULT 'olist_order_items_dataset.csv'
);

CREATE TABLE bronze.order_payments (
    order_id varchar,
    payment_sequential varchar,
    payment_type varchar,
    payment_installments varchar,
    payment_value varchar,
    _loaded_at timestamp DEFAULT now(),
    _source_file varchar DEFAULT 'olist_order_payments_dataset.csv'
);

CREATE TABLE bronze.order_reviews (
    review_id varchar,
    order_id varchar,
    review_score varchar,
    review_comment_title varchar,
    review_comment_message varchar,
    review_creation_date varchar,
    review_answer_timestamp varchar,
    _loaded_at timestamp DEFAULT now(),
    _source_file varchar DEFAULT 'olist_order_reviews_dataset.csv'
);

CREATE TABLE bronze.products (
    product_id varchar,
    product_category_name varchar,
    product_name_lenght varchar,
    product_description_lenght varchar,
    product_photos_qty varchar,
    product_weight_g varchar,
    product_length_cm varchar,
    product_height_cm varchar,
    product_width_cm varchar,
    _loaded_at timestamp DEFAULT now(),
    _source_file varchar DEFAULT 'olist_products_dataset.csv'
);

CREATE TABLE bronze.sellers (
    seller_id varchar,
    seller_zip_code_prefix varchar,
    seller_city varchar,
    seller_state varchar,
    _loaded_at timestamp DEFAULT now(),
    _source_file varchar DEFAULT 'olist_sellers_dataset.csv'
);

CREATE TABLE bronze.geolocation (
    geolocation_zip_code_prefix varchar,
    geolocation_lat varchar,
    geolocation_lng varchar,
    geolocation_city varchar,
    geolocation_state varchar,
    _loaded_at timestamp DEFAULT now(),
    _source_file varchar DEFAULT 'olist_geolocation_dataset.csv'
);

CREATE TABLE bronze.product_category_name_translation (
    product_category_name varchar,
    product_category_name_english varchar,
    _loaded_at timestamp DEFAULT now(),
    _source_file varchar DEFAULT 'product_category_name_translation.csv'
);

-- Use powershell for adding tables into the sql
-- Row count check
SELECT 'customers' AS table_name, COUNT(*) FROM bronze.customers
UNION ALL SELECT 'geolocation', COUNT(*) FROM bronze.geolocation
UNION ALL SELECT 'orders', COUNT(*) FROM bronze.orders
UNION ALL SELECT 'order_items', COUNT(*) FROM bronze.order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM bronze.order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM bronze.order_reviews
UNION ALL SELECT 'products', COUNT(*) FROM bronze.products
UNION ALL SELECT 'sellers', COUNT(*) FROM bronze.sellers
UNION ALL SELECT 'product_category_name_translation', COUNT(*) FROM bronze.product_category_name_translation;

-- 15 rows visual check on entriess
-- Orders
SELECT *
FROM bronze.orders bo
LIMIT 15;

-- Payment
SELECT *
FROM bronze.order_payments bop
LIMIT 15;

-- Customers
SELECT *
FROM bronze.customers bc
LIMIT 15;

-- Geolocation
SELECT *
FROM bronze.geolocation bg
LIMIT 15;

-- Order items
SELECT *
FROM bronze.order_items boi
LIMIT 15;

-- Reviews
SELECT *
FROM bronze.order_reviews bor
LIMIT 15;

-- Sellers
SELECT *
FROM bronze.sellers bs
LIMIT 15;

-- Product
SELECT *
FROM bronze.products bp
LIMIT 15;

-- Product Category Name translation
SELECT *
FROM bronze.product_category_name_translation bpcnt
LIMIT 15;


-- Silver
CREATE SCHEMA IF NOT EXISTS silver;

-- Cleaning the dim tables

/*
SELECT 
  (SELECT COUNT(*) FROM bronze.customers) AS bronze_count,
  (SELECT COUNT(*) FROM silver.customers) AS silver_count;

SELECT 
  COUNT(*) AS total,
  COUNT(DISTINCT customer_id) AS distict_ids
FROM silver.customers;

SELECT DISTINCT customer_state
FROM silver.customers
ORDER BY customer_state;
*/

-- Sellers
DROP TABLE IF EXISTS silver.sellers;

CREATE TABLE silver.sellers AS
SELECT
  seller_id,
  seller_zip_code_prefix,
  TRIM(INITCAP(seller_city)) AS seller_city,
  UPPER(TRIM(seller_state)) AS seller_state
FROM bronze.sellers
WHERE seller_id IS NOT NULL;


SELECT 
  (SELECT COUNT(*) FROM bronze.sellers) AS bronze_count,
  (SELECT COUNT(*) FROM silver.sellers) AS silver_count;


-- Products
DROP TABLE IF EXISTS silver.products;

CREATE TABLE silver.products AS
SELECT
    p.product_id,
    p.product_category_name,
    t.product_category_name_english,
    CASE
      WHEN p.product_category_name IS NULL THEN 'No Category'
      WHEN t.product_category_name_english IS NULL THEN 'No Translation'
      ELSE t.product_category_name_english
    END AS product_category,    
    NULLIF(p.product_name_lenght, '')::int AS product_name_length,
    NULLIF(p.product_description_lenght, '')::int AS product_description_length,
    NULLIF(p.product_photos_qty, '')::int AS product_photos_qty,
    NULLIF(p.product_weight_g, '')::int AS product_weight_g,
    NULLIF(p.product_length_cm, '')::int AS product_length_cm,
    NULLIF(p.product_height_cm, '')::int AS product_height_cm,
    NULLIF(p.product_width_cm, '')::int AS product_width_cm
FROM bronze.products p
LEFT JOIN bronze.product_category_name_translation t
  ON TRIM(p.product_category_name) = TRIM(t.product_category_name)
WHERE p.product_id IS NOT NULL;

/*
SELECT *
FROM silver.products
WHERE product_category_name IS NULL
  OR product_category_name_english IS NULL;
*/


-- geolocation
DROP TABLE IF EXISTS silver.geolocation;

-- Grouped by zip code, make the lat/lnd median,
-- and use the most frequent city and state to uniform the dataset
-- !! This is not ideal for data pipe that will use for delivery, cx address, etc
-- as it will give a false address to the customer
CREATE TABLE silver.geolocation AS
SELECT
  geolocation_zip_code_prefix,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY NULLIF(geolocation_lat, '')::NUMERIC))::NUMERIC, 6) AS geolocation_lat,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY NULLIF(geolocation_lng, '')::NUMERIC))::NUMERIC, 6) AS geolocation_lng,
  MODE() WITHIN GROUP (ORDER BY TRIM(INITCAP(geolocation_city))) AS geolocation_city,
  MODE() WITHIN GROUP (ORDER BY UPPER(TRIM(geolocation_state))) AS geolocation_state
FROM bronze.geolocation
WHERE geolocation_zip_code_prefix IS NOT NULL
GROUP BY geolocation_zip_code_prefix;


/*
SELECT 
(SELECT COUNT(*) FROM bronze.geolocation) AS bronze_count,
(SELECT COUNT(*) FROM silver.geolocation) AS silver_count;
*/


-- product_category_name_translation
DROP TABLE IF EXISTS silver.product_category_name_translation;

CREATE TABLE silver.product_category_name_translation AS
SELECT 
  TRIM(product_category_name) AS product_category_name,
  TRIM(product_category_name_english) AS product_category_name_english
FROM bronze.product_category_name_translation
WHERE product_category_name IS NOT NULL;

/*
SELECT 
(SELECT COUNT(*) FROM bronze.product_category_name_translation) AS bronze_count,
(SELECT COUNT(*) FROM silver.product_category_name_translation) AS silver_count;
*/

/*
SELECT product_category_name, COUNT(*)
FROM silver.product_category_name_translation
GROUP BY product_category_name 
HAVING COUNT(*) > 1;  -- No duplicates
*/


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


-- Customers
SELECT customer_unique_id, COUNT(DISTINCT customer_id) AS order_count
FROM bronze.customers
GROUP BY customer_unique_id 
HAVING COUNT(DISTINCT customer_id) > 1
ORDER BY order_count DESC
LIMIT 10; -- The customer_unique_id is unique per person not per order ID


DROP TABLE IF EXISTS silver.customers;

CREATE TABLE silver.customers AS
  SELECT 
    customer_unique_id,
    customer_id,
    customer_zip_code_prefix,
    TRIM(INITCAP(customer_city)) AS customer_city,
    UPPER(TRIM(customer_state)) AS customer_state
FROM bronze.customers;


SELECT 
  (SELECT COUNT(*) FROM bronze.customers) AS bronze_count,
  (SELECT COUNT(*) FROM silver.customers) AS silver_count;

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


-- Order Payments

-- Checking the categories
SELECT payment_type, COUNT(*)
FROM bronze.order_payments op 
GROUP BY  op.payment_type 
ORDER BY COUNT(*) DESC;

-- Checking the uniqueness
SELECT order_id, payment_sequential, COUNT(*)
FROM bronze.order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;   -- No dupe

-- Creating the Table
DROP TABLE IF EXISTS silver.order_payments;

CREATE TABLE silver.order_payments AS 
SELECT
  order_id,
  payment_sequential::INT,
  payment_type,
  payment_installments::INT,
  NULLIF(payment_value, '')::NUMERIC AS payment_value
FROM bronze.order_payments
WHERE order_id IS NOT NULL;

-- Check if there are changes to the new table
SELECT 
  (SELECT COUNT(*) FROM bronze.order_payments) AS bronze_counts,
  (SELECT COUNT(*) FROM silver.order_payments) AS silver_counts;
  
-- Order Reviews
SELECT *
FROM bronze.order_reviews t 
WHERE t.review_id IN (
  SELECT review_id
  FROM bronze.order_reviews
  GROUP BY review_id
  HAVING COUNT(*) > 1
)
ORDER BY review_id
LIMIT 30;


SELECT *
FROM silver.orders o 
LEFT JOIN bronze.order_reviews t 
USING(order_id)
LEFT JOIN silver.order_items oi
ON o.order_id = oi.order_id
LEFT JOIN silver.customers c 
ON o.customer_id = c.customer_id
WHERE t.review_id = '0115633a9c298b6a98bcbe4eee75345f'; -- Instead of 1 review per order they are 1 review per purchase
-- That's the reason of duplication in review id

-- Creating the table
DROP TABLE IF EXISTS silver.order_reviews;

CREATE TABLE silver.order_reviews AS
SELECT
  review_id,
  order_id,
  NULLIF(review_score,'')::INT AS review_score,
  review_comment_title,
  review_comment_message,
  review_creation_date::TIMESTAMP,
  review_answer_timestamp::TIMESTAMP
FROM bronze.order_reviews
WHERE review_id IS NOT NULL
  AND order_id IS NOT NULL;

SELECT *
FROM silver.order_reviews
LIMIT 10;

-- Check the row count
SELECT
  (SELECT COUNT(*) FROM bronze.order_reviews) AS bronze_count,
  (SELECT COUNT(*) FROM silver.order_reviews) AS silver_count
  
  
-- master table  
-- For order-level grain
SELECT
  order_id,
  COUNT(order_item_id) AS total_items,
  SUM(price) AS total_price,
  SUM(freight_value) AS total_freight
FROM silver.order_items
GROUP BY order_id


SELECT order_id, COUNT(DISTINCT review_id)
FROM silver.order_reviews
GROUP BY order_id
HAVING COUNT(DISTINCT review_id) > 1;


SELECT *
FROM silver.order_reviews t 
WHERE t.order_id = '0035246a40f520710769010f752e7507';

SELECT COUNT(*) FROM (
  SELECT order_id
  FROM bronze.order_reviews
  GROUP BY order_id
  HAVING COUNT(DISTINCT review_id) > 1
);

-- For reviews 
SELECT DISTINCT ON (order_id)
  order_id,
  review_id,
  review_score,
  review_answer_timestamp
FROM silver.order_reviews
ORDER BY order_id, review_answer_timestamp DESC;

-- For order_payments
SELECT COUNT(*) FROM (
  SELECT order_id
  FROM silver.order_payments op 
  GROUP BY order_id
  HAVING COUNT(*) > 1
  );

-- Aggregating the split payments
SELECT
  order_id,
  SUM(payment_value) AS total_payment_value,
  COUNT(*) AS payment_count
FROM silver.order_payments
GROUP BY order_id;

--Joining Order < customers
DROP TABLE IF EXISTS silver.olist_master;

CREATE TABLE silver.olist_master AS
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
  c.customer_state
FROM silver.orders o 
LEFT JOIN silver.customers c
  ON o.customer_id = c.customer_id;

-- Checking
SELECT
  (SELECT COUNT(*) FROM silver.orders) AS orders_count,
  (SELECT COUNT(*) FROM silver.olist_master) AS master_count;

-- Joining aggregated order payments and items
DROP TABLE IF EXISTS silver.olist_master;

CREATE TABLE silver.olist_master AS
WITH  items_agg AS (
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
  p.payment_count
FROM silver.orders o
LEFT JOIN silver.customers c ON o.customer_id = c.customer_id
LEFT JOIN items_agg i ON o.order_id = i.order_id
LEFT JOIN payments_agg p ON o.order_id = p.order_id;

-- Checking
SELECT 
  (SELECT COUNT(*) FROM silver.orders) AS orders_count,
  (SELECT COUNT(*) FROM silver.olist_master) AS master_count;

SELECT * FROM silver.olist_master WHERE total_payment_value IS NULL;  -- Only one NULL total_payment_value

-- Joining the reviews
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
  
