-- Synthetic data, generated in-database (fast, no Python loops). {rows} is filled in by bench.py.
INSERT INTO dim_customer
SELECT i, 'customer_' || i, (ARRAY['NA','EMEA','APAC','LATAM'])[1 + i % 4]
FROM generate_series(1, 50000) i;

INSERT INTO dim_product
SELECT i, 'product_' || i, (ARRAY['electronics','home','toys','grocery','apparel','sports'])[1 + i % 6]
FROM generate_series(1, 2000) i;

INSERT INTO fact_sales (customer_id, product_id, sold_at, qty, amount)
SELECT 1 + (random() * 49999)::int,
       1 + (random() * 1999)::int,
       timestamptz '2023-01-01' + random() * interval '3 years',
       q,
       round((q * (5 + random() * 195))::numeric, 2)
FROM (SELECT 1 + (random() * 4)::int AS q FROM generate_series(1, {rows})) s;

ANALYZE;
