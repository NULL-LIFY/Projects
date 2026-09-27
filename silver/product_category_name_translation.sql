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
