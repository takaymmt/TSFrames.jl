# Research: OHLCV Resample Design for TSFrames.jl

Date: 2026-04-02

## Key Findings

### Finding 1: Calendar-based resampling is the universal industry standard
- **pandas** `resample('W')` is calendar-based, anchored to Sunday by default
- **xts** `apply.weekly()` is calendar-based, using `endpoints()` internally
- Fixed 7-day windows are NOT used by any major library for weekly resampling
- All financial data providers (Polygon, Databento, Kaiko) use calendar-aligned periods

### Finding 2: pandas anchor-day customization is the gold standard for weekly flexibility
- pandas supports `'W-MON'`, `'W-FRI'` etc. to specify which day ends the week
- It separates 3 concerns: anchor day, closed side (which edge is inclusive), label side (which edge labels the bin)
- Financial users typically use `'W-FRI'` (trading week end)
- TSFrames.jl's current `endpoints(ts, Week(1))` uses `floor(timestamp, Week)` which aligns to **Monday** (ISO 8601) — no anchor customization exists yet

### Finding 3: Dict/Pair-based per-column aggregation is the best API pattern
- pandas uses `df.resample('W').agg({'Open': 'first', 'High': 'max', 'Low': 'min', 'Close': 'last', 'Volume': 'sum'})`
- DataFrames.jl uses the `=>` pair syntax: `:Open => first => :Open`
- **Recommended for TSFrames.jl**: Varargs Pair syntax (idiomatic Julia)
  ```julia
  resample(ts, Week(1),
      :Open => first, :High => maximum, :Low => minimum,
      :Close => last, :Volume => sum)
  ```

### Finding 4: DataFrames.jl `combine` already handles multi-column aggregation efficiently
- `combine(gd, :A => f1, :B => f2, :C => f3)` processes each group once and applies all functions — it does NOT do separate passes per pair
- TSFrames.jl's existing `apply()` already uses `combine()` internally, so extending it to accept per-column pairs is architecturally straightforward
- The existing `apply()` signature `apply(ts, period, fun)` applies ONE function to ALL columns — a new method signature is needed for per-column specs

### Finding 5: Single-pass OHLCV is achievable via pre-allocated vectors + @view
- For maximum performance, bypass DataFrames groupby entirely
- Use `endpoints()` to get group boundaries, then iterate once with `@view` slices
- Pre-allocate output vectors (avoid growing arrays)
- `first`/`last` are O(1), `maximum`/`minimum`/`sum` are O(n) per group but only one pass through data
- This is an optimization path for the OHLCV convenience function, not the general API

### Finding 6: Julia ecosystem has a gap — no package has a good resample API
- **TimeSeries.jl**: No built-in resample (open issue #257 since 2017)
- **TimeSeriesResampler.jl**: Exists but unmaintained, limited API
- **TSFrames.jl**: Has `endpoints()` and `apply()` foundations, but lacks per-column aggregation
- This is an opportunity for TSFrames.jl to provide the best resample API in the Julia ecosystem

### Finding 7: Recommended implementation priority
1. **Per-column `apply()`** with Pair syntax — extends existing infrastructure, core building block
2. **`resample_ohlcv()` convenience** — high user value, detects OHLCV columns automatically
3. **Anchor day customization** for `Week` period — important for financial users (Friday-ending weeks)
4. **Optimized single-pass path** for OHLCV — performance optimization, can be deferred
