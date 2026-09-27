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
  
