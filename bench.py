"""Build the warehouse, time the slow report, add the index, time the tuned report. Writes results.md."""
import os, statistics, sys, time
from pathlib import Path
import psycopg

DSN = os.environ.get("DATABASE_URL", "postgresql://postgres:postgres@localhost/dw")
ROWS = int(sys.argv[1]) if len(sys.argv) > 1 else 5_000_000
RUNS = 5
sql = lambda f: Path(__file__).with_name(f).read_text()


def timed(cur, q):
    cur.execute(q)  # warm-up, so both versions are measured with a hot cache
    times = []
    for _ in range(RUNS):
        t = time.perf_counter(); cur.execute(q); rows = cur.fetchall()
        times.append((time.perf_counter() - t) * 1000)
    cur.execute("EXPLAIN (ANALYZE, BUFFERS) " + q)
    plan = "\n".join(r[0] for r in cur.fetchall())
    return statistics.median(times), rows, plan


with psycopg.connect(DSN, autocommit=True, options="-c timezone=UTC") as conn, conn.cursor() as cur:
    print(f"building schema + seeding {ROWS:,} fact rows...")
    cur.execute(sql("schema.sql"))
    cur.execute(sql("seed.sql").format(rows=ROWS))  # ROWS is an int, safe to inline

    slow_ms, slow_rows, slow_plan = timed(cur, sql("slow_query.sql"))
    print(f"before: {slow_ms:.1f} ms")

    t = time.perf_counter()
    for stmt in filter(str.strip, sql("indexes.sql").split(";")):  # one at a time: VACUUM refuses multi-statement
        cur.execute(stmt)
    build_s = time.perf_counter() - t
    fast_ms, fast_rows, fast_plan = timed(cur, sql("tuned_query.sql"))
    print(f"after:  {fast_ms:.1f} ms  ({slow_ms / fast_ms:.1f}x faster, index built in {build_s:.1f}s)")

    assert slow_rows == fast_rows, "tuned query returned different results"
    assert fast_ms < slow_ms, "tuned query was not faster"
    assert "Index Only Scan" in fast_plan, "index not used"

Path(__file__).with_name("results.md").write_text(f"""# Results ({ROWS:,} fact rows, median of {RUNS} warm runs)

| | median ms |
|---|---|
| before (no index, non-sargable filter) | {slow_ms:.1f} |
| after (covering index, range filter) | {fast_ms:.1f} |
| **speedup** | **{slow_ms / fast_ms:.1f}x** |

Results identical: {slow_rows == fast_rows} ({len(fast_rows)} rows)

## Before plan
```
{slow_plan}
```

## After plan
```
{fast_plan}
```
""")
print("wrote results.md")
