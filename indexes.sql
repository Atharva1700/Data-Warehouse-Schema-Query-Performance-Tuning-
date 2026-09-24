-- Covering index: range on sold_at, INCLUDE the columns the report reads -> index-only scan, heap untouched.
CREATE INDEX IF NOT EXISTS ix_sales_sold_at ON fact_sales (sold_at) INCLUDE (customer_id, product_id, amount);
VACUUM ANALYZE fact_sales;  -- sets the visibility map so the index-only scan actually skips the heap
