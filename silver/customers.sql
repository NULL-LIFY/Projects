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
