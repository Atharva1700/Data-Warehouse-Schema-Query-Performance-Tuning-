-- Star schema: small dimensions, one append-only fact table that grows forever.
DROP TABLE IF EXISTS fact_sales, dim_customer, dim_product;

CREATE TABLE dim_customer (
  customer_id int  PRIMARY KEY,
  name        text NOT NULL,
  region      text NOT NULL CHECK (region IN ('NA','EMEA','APAC','LATAM'))
);

CREATE TABLE dim_product (
  product_id int  PRIMARY KEY,
  name       text NOT NULL,
  category   text NOT NULL
);

CREATE TABLE fact_sales (
  sale_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- bigint: won't overflow as data grows
  customer_id int           NOT NULL REFERENCES dim_customer,
  product_id  int           NOT NULL REFERENCES dim_product,
  sold_at     timestamptz   NOT NULL,
  qty         int           NOT NULL CHECK (qty > 0),
  amount      numeric(12,2) NOT NULL CHECK (amount >= 0)
);
-- ponytail: single table; switch to PARTITION BY RANGE (sold_at) monthly once it passes ~100M rows.
