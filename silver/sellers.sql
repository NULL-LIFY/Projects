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
