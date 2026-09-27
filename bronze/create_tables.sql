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

