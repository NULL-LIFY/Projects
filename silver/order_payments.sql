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
  
