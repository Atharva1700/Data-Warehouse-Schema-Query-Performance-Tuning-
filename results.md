# Results (5,000,000 fact rows, median of 5 warm runs)

| | median ms |
|---|---|
| before (no index, non-sargable filter) | 1532.3 |
| after (covering index, range filter) | 79.4 |
| **speedup** | **19.3x** |

Results identical: True (6 rows)

## Before plan
```
Sort  (cost=75295.29..75295.30 rows=6 width=47) (actual time=1558.798..1558.855 rows=6 loops=1)
  Sort Key: (sum(f.amount)) DESC
  Sort Method: quicksort  Memory: 25kB
  Buffers: shared hit=16836 read=25962
  ->  Finalize GroupAggregate  (cost=75267.56..75295.21 rows=6 width=47) (actual time=1553.192..1558.845 rows=6 loops=1)
        Group Key: p.category
        Buffers: shared hit=16836 read=25962
        ->  Gather Merge  (cost=75267.56..75295.02 rows=12 width=47) (actual time=1552.841..1558.816 rows=18 loops=1)
              Workers Planned: 2
              Workers Launched: 2
              Buffers: shared hit=16836 read=25962
              ->  Partial GroupAggregate  (cost=74267.53..74293.61 rows=6 width=47) (actual time=1520.607..1525.422 rows=6 loops=3)
                    Group Key: p.category
                    Buffers: shared hit=16836 read=25962
                    ->  Sort  (cost=74267.53..74274.03 rows=2600 width=13) (actual time=1520.264..1520.885 rows=11564 loops=3)
                          Sort Key: p.category
                          Sort Method: quicksort  Memory: 860kB
                          Buffers: shared hit=16836 read=25962
                          Worker 0:  Sort Method: quicksort  Memory: 851kB
                          Worker 1:  Sort Method: quicksort  Memory: 844kB
                          ->  Hash Join  (cost=1168.97..74120.06 rows=2600 width=13) (actual time=13.923..1516.984 rows=11564 loops=3)
                                Hash Cond: (f.product_id = p.product_id)
                                Buffers: shared hit=16762 read=25962
                                ->  Hash Join  (cost=1109.97..74054.22 rows=2600 width=10) (actual time=13.430..1498.787 rows=11564 loops=3)
                                      Hash Cond: (f.customer_id = c.customer_id)
                                      Buffers: shared hit=16692 read=25962
                                      ->  Parallel Seq Scan on fact_sales f  (cost=0.00..72916.90 rows=10417 width=14) (actual time=0.045..1458.767 rows=46139 loops=3)
                                            Filter: (to_char(sold_at, 'YYYY-MM'::text) = '2025-06'::text)
                                            Rows Removed by Filter: 1620528
                                            Buffers: shared hit=15705 read=25962
                                      ->  Hash  (cost=954.00..954.00 rows=12478 width=4) (actual time=13.298..13.298 rows=12500 loops=3)
                                            Buckets: 16384  Batches: 1  Memory Usage: 568kB
                                            Buffers: shared hit=987
                                            ->  Seq Scan on dim_customer c  (cost=0.00..954.00 rows=12478 width=4) (actual time=0.008..9.232 rows=12500 loops=3)
                                                  Filter: (region = 'EMEA'::text)
                                                  Rows Removed by Filter: 37500
                                                  Buffers: shared hit=987
                                ->  Hash  (cost=34.00..34.00 rows=2000 width=11) (actual time=0.471..0.471 rows=2000 loops=3)
                                      Buckets: 2048  Batches: 1  Memory Usage: 104kB
                                      Buffers: shared hit=42
                                      ->  Seq Scan on dim_product p  (cost=0.00..34.00 rows=2000 width=11) (actual time=0.013..0.196 rows=2000 loops=3)
                                            Buffers: shared hit=42
Planning:
  Buffers: shared hit=12
Planning Time: 0.267 ms
Execution Time: 1558.902 ms
```

## After plan
```
Sort  (cost=7133.98..7133.99 rows=6 width=47) (actual time=99.273..101.532 rows=6 loops=1)
  Sort Key: (sum(f.amount)) DESC
  Sort Method: quicksort  Memory: 25kB
  Buffers: shared hit=48579
  ->  Finalize GroupAggregate  (cost=7132.30..7133.90 rows=6 width=47) (actual time=99.246..101.515 rows=6 loops=1)
        Group Key: p.category
        Buffers: shared hit=48579
        ->  Gather Merge  (cost=7132.30..7133.70 rows=12 width=47) (actual time=99.233..101.495 rows=18 loops=1)
              Workers Planned: 2
              Workers Launched: 2
              Buffers: shared hit=48579
              ->  Sort  (cost=6132.28..6132.30 rows=6 width=47) (actual time=68.569..68.574 rows=6 loops=3)
                    Sort Key: p.category
                    Sort Method: quicksort  Memory: 25kB
                    Buffers: shared hit=48579
                    Worker 0:  Sort Method: quicksort  Memory: 25kB
                    Worker 1:  Sort Method: quicksort  Memory: 25kB
                    ->  Partial HashAggregate  (cost=6132.13..6132.20 rows=6 width=47) (actual time=68.539..68.544 rows=6 loops=3)
                          Group Key: p.category
                          Batches: 1  Memory Usage: 24kB
                          Buffers: shared hit=48563
                          Worker 0:  Batches: 1  Memory Usage: 24kB
                          Worker 1:  Batches: 1  Memory Usage: 24kB
                          ->  Hash Join  (cost=1169.41..6024.92 rows=14295 width=13) (actual time=13.722..58.135 rows=11564 loops=3)
                                Hash Cond: (f.product_id = p.product_id)
                                Buffers: shared hit=48563
                                ->  Hash Join  (cost=1110.41..5928.31 rows=14295 width=10) (actual time=13.215..48.632 rows=11564 loops=3)
                                      Hash Cond: (f.customer_id = c.customer_id)
                                      Buffers: shared hit=48493
                                      ->  Parallel Index Only Scan using ix_sales_sold_at on fact_sales f  (cost=0.43..4667.97 rows=57280 width=14) (actual time=0.017..15.681 rows=46139 loops=3)
                                            Index Cond: ((sold_at >= '2025-06-01 00:00:00+00'::timestamp with time zone) AND (sold_at < '2025-07-01 00:00:00+00'::timestamp with time zone))
                                            Heap Fetches: 0
                                            Buffers: shared hit=47506
                                      ->  Hash  (cost=954.00..954.00 rows=12478 width=4) (actual time=13.137..13.137 rows=12500 loops=3)
                                            Buckets: 16384  Batches: 1  Memory Usage: 568kB
                                            Buffers: shared hit=987
                                            ->  Seq Scan on dim_customer c  (cost=0.00..954.00 rows=12478 width=4) (actual time=0.009..11.729 rows=12500 loops=3)
                                                  Filter: (region = 'EMEA'::text)
                                                  Rows Removed by Filter: 37500
                                                  Buffers: shared hit=987
                                ->  Hash  (cost=34.00..34.00 rows=2000 width=11) (actual time=0.485..0.485 rows=2000 loops=3)
                                      Buckets: 2048  Batches: 1  Memory Usage: 104kB
                                      Buffers: shared hit=42
                                      ->  Seq Scan on dim_product p  (cost=0.00..34.00 rows=2000 width=11) (actual time=0.013..0.203 rows=2000 loops=3)
                                            Buffers: shared hit=42
Planning:
  Buffers: shared hit=12
Planning Time: 0.329 ms
Execution Time: 101.596 ms
```
