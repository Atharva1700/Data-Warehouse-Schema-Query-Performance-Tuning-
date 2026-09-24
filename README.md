# Data Warehouse Schema + Query Performance Tuning

Star schema in PostgreSQL, a deliberately slow report query, and a tuned version of the
same report, with a measured before/after benchmark (Python).

**Measured on 5M fact rows: 1532 ms → 79 ms (19.3x faster), identical results.** Full plans in [`results.md`](results.md).

## Files
| File | What |
|---|---|
| `schema.sql` | Star schema: `dim_customer`, `dim_product`, append-only `fact_sales` (bigint identity, FKs, CHECKs) |
| `seed.sql` | Synthetic data generated in-database with `generate_series` |
| `slow_query.sql` | Monthly revenue-by-category report. `to_char(sold_at, ...)` is non-sargable → parallel seq scan of all 5M rows |
| `tuned_query.sql` | Same report with a half-open date range on the raw column |
| `indexes.sql` | Covering index `(sold_at) INCLUDE (customer_id, product_id, amount)` → index-only scan, heap never touched |
| `bench.py` | Builds everything, times both queries (median of 5 warm runs), asserts identical results + index used, writes `results.md` |

## Run
```bash
docker run -d --name dw -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=dw -p 5432:5432 postgres:16
pip install -r requirements.txt
python bench.py            # 5M rows (~1 min); pass a number for a different size, e.g. python bench.py 20000000
```
Set `DATABASE_URL` to use another database.

## Why it's faster
1. **Sargable predicate.** Wrapping a column in a function hides it from the index. A plain range on `sold_at` lets the planner seek straight to June.
2. **Covering index.** `INCLUDE` puts every column the query reads into the index, so Postgres answers from the index alone (`Index Only Scan`, after `VACUUM` sets the visibility map).
3. **Scales with growth.** The slow query's cost grows with the whole table; the tuned one grows only with the month being reported.

Next step when `fact_sales` passes ~100M rows: monthly range partitioning on `sold_at`.
