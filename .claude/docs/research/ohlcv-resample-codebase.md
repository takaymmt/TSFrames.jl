# Codebase Analysis: TSFrames.jl (OHLCV Resample Feature)

Date: 2026-04-02

## Key Findings

### 1. `apply()` is built on `endpoints()` + DataFrames `groupby`/`combine`
Computes period endpoints, converts them into a per-row group-index vector, adds that as a temp column,
then uses `groupby` on that column followed by `combine` with `Not(["Index", tmp_col]) .=> fun`.
The grouping mechanism (src/apply.jl lines ~137-143) is clean and reusable.

### 2. `apply()` only supports a single uniform function across all columns
The critical line is `Not(["Index", tmp_col]) .=> fun` which broadcasts the same `fun` to every data column.
**No way** to specify different aggregation functions per column (e.g., `first` for Open, `maximum` for High).

### 3. `endpoints()` is robust and efficient (O(n) linear scan)
Handles Date, DateTime, Time types, irregular series (via while-loop gap catching), all Period types,
and both function-based and Period-based grouping. Well-tested with 349 lines of tests.
This is the solid foundation for any new resampling feature.

### 4. `to_period()` is trivially simple — just `tsf[endpoints(tsf, period)]`
Picks only the last row per period with no aggregation.
The convenience wrappers (`to_yearly`, `to_monthly`, etc.) are metaprogrammed via `@eval`.

### 5. DataFrames `combine` natively supports per-column function mapping
Pattern: `combine(gd, :Open => first => :Open, :High => maximum => :High, ...)`
The gap is that `apply()` doesn't expose this capability.

### 6. Performance bottleneck in `apply()`: allocations
- `copy(ts.coredata)` on every call
- `fill` + `append!` for group indices (instead of pre-allocated vector)
- Temp column insertion
Fix: pre-allocate `groupindices` as `Vector{Int}(undef, nrow(ts))`, use `@view`

### 7. Test coverage gaps
587 lines testing various period conversions and functions, but only single-column TSFrames are tested.
No multi-column tests exist (because the API doesn't support multi-function aggregation).
`renamecols=false` keyword is also untested.

## File Map

| File | Lines | Purpose |
|------|-------|---------|
| `src/apply.jl` | ~150 | apply() implementation — KEY FILE |
| `src/endpoints.jl` | ~200 | endpoints() family — KEY FILE |
| `src/to_period.jl` | ~50 | to_period + convenience wrappers |
| `test/apply.jl` | 587 | apply() tests |
| `test/endpoints.jl` | 349 | endpoints() tests |

## Recommendations

- Add new `apply()` method overload accepting `Pair{Union{Symbol,String}, Function}...`
- Reuse the existing endpoint-to-groupindex logic
- Extract group-index building into shared helper `_build_groupindices(ep, nrows)`
- Pre-allocate the groupindices vector (performance improvement)
