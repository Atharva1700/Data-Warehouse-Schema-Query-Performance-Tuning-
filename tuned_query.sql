-- Same report, same result. Half-open range on the raw column is sargable -> index range scan.
SELECT p.category, count(*) AS orders, sum(f.amount) AS revenue
FROM fact_sales f
JOIN dim_customer c USING (customer_id)
JOIN dim_product  p USING (product_id)
WHERE f.sold_at >= '2025-06-01' AND f.sold_at < '2025-07-01'
  AND c.region = 'EMEA'
GROUP BY p.category
ORDER BY revenue DESC;
