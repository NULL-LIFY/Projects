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
