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
