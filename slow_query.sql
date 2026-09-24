-- Monthly revenue by category for one region.
-- Slow: to_char() on sold_at is non-sargable, so no index can be used -> full scan of fact_sales.
SELECT p.category, count(*) AS orders, sum(f.amount) AS revenue
FROM fact_sales f
JOIN dim_customer c USING (customer_id)
JOIN dim_product  p USING (product_id)
WHERE to_char(f.sold_at, 'YYYY-MM') = '2025-06'
  AND c.region = 'EMEA'
GROUP BY p.category
ORDER BY revenue DESC;
