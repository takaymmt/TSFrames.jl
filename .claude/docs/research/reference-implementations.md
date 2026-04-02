# Reference Implementations: Time Series Resampling

Date: 2026-04-02

## Polars (Python/Rust)

### Algorithm
- `group_by_dynamic()` uses **sorted linear scan O(n)** — requires ascending sort order
- After v1.35 fix (skipping empty window ranges): 498ms on 10M rows
- Per-column aggregation via expressive `.agg()` with arbitrary expressions

### API Design
```python
df.sort("time").group_by_dynamic("time", every="1w").agg(
    pl.col("Open").first(),
    pl.col("High").max(),
    pl.col("Low").min(),
    pl.col("Close").last(),
    pl.col("Volume").sum(),
)
```
`closed`, `label`, `start_by` parameters for fine-grained window control.

### Performance
- 10x faster than pandas; competitive with DuckDB after v1.35 fix
- 10M rows: Polars 498ms vs DuckDB 1.41s vs Pandas ~5s
- 100M rows: Polars 26s vs DuckDB 33s vs Pandas 129s

---

## DuckDB

### Algorithm
- Radix-partitioned **hash aggregation** (general-purpose, not sort-optimized)
- 2,048-value vectorized batches fitting L1 cache, SIMD-friendly
- Not specialized for sorted time series — but still very fast due to vectorization

### API Design
```sql
SELECT time_bucket(INTERVAL '1 week', timestamp) AS week,
       FIRST(Open ORDER BY timestamp)  AS Open,
       MAX(High)                       AS High,
       MIN(Low)                        AS Low,
       LAST(Close ORDER BY timestamp)  AS Close,
       SUM(Volume)                     AS Volume
FROM ohlcv
GROUP BY 1
ORDER BY 1;
```
`ASOF JOIN` for nearest-match temporal joins (unique feature).

---

## R xts

### Algorithm
- `endpoints()` via C code: integer-divide timestamps, detect boundary changes → **O(n) linear scan**
- **Same concept as TSFrames.jl `endpoints()`** — already the right approach
- `period.apply(x, INDEX, FUN)` separates endpoint computation from aggregation

### Limitation
Single function per call — no per-column specification (same gap as TSFrames.jl `apply()`)

---

## R tsibble

### API Design
```r
tsibble %>%
  index_by(week = ~ yearweek(.)) %>%
  summarise(
    Open   = first(price),
    High   = max(price),
    Low    = min(price),
    Close  = last(price),
    Volume = sum(volume)
  )
```
Clean separation of temporal grouping from aggregation. Composable with dplyr verbs.

---

## Key Insights for TSFrames.jl

### Algorithm Recommendations
1. **`endpoints()` is already optimal** — O(n) linear scan, matches Polars and xts
2. **Avoid copy+temp column pattern** — use `@view` slices of column vectors directly
3. **Pre-alloc groupindices** — `Vector{Int}(undef, n)` + `.=` instead of `fill+append!`

### API Recommendations
```julia
# Idiomatic Julia — mirrors DataFrames.jl combine() syntax users already know
resample(ts, Week(1),
    :Open => first, :High => maximum, :Low => minimum,
    :Close => last, :Volume => sum)

# Default OHLCV (when no pairs specified)
resample(ts, Week(1))
```

### Features to Consider (Priority Order)
1. **Per-column aggregation** `resample()` — core gap vs all competitors ← **implement now**
2. **Eliminate copy+temp column** in `apply()` — performance fix ← **implement now**
3. **VWAP support** — `sum(price*volume)/sum(volume)` — common financial metric
4. **Gap-aware resampling** — emit `missing` for empty periods (e.g., market holidays)
5. **`closed`/`label` interval control** — pandas-style `closed=:left/:right`
6. **ASOF join** — nearest-match temporal join (DuckDB feature, useful for merging sparse series)
