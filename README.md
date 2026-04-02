# TSFrames.jl

A performance-focused fork of [xKDR/TSFrames.jl](https://github.com/xKDR/TSFrames.jl) — Julia's timeseries DataFrame package.

> **Thanks** to the xKDR team and all contributors to the original TSFrames.jl.  
> This fork builds on their excellent foundation. For the full API reference and user guide, see the [original documentation](https://xkdr.github.io/TSFrames.jl/dev/).

---

## Quick Start

### Load from Yahoo Finance

```julia
using TSFrames, MarketData

# Fetch AAPL daily OHLCV (returns a TimeArray; TSFrame converts it automatically)
ts = TSFrame(MarketData.yahoo(:AAPL); issorted=true)
# 10550×6 TSFrame with Date Index
#  Index       Open     High     Low      Close    AdjClose  Volume
#  Date        Float64  Float64  Float64  Float64  Float64   Float64
```

### Load from CSV

```julia
using CSV, DataFrames, Dates, TSFrames

ts = CSV.read("data/AAPL.csv", TSFrame)
# or, if you know the data is already sorted:
ts = CSV.read("data/AAPL.csv", TSFrame; issorted=true)
```

### Resample OHLCV data

```julia
using TSFrames, Dates, Statistics

# Resample to weekly OHLCV bars — per-column aggregation (new in this fork)
weekly = resample(ts, Week(1))
#  Open→first, High→maximum, Low→minimum, Close→last, Volume→sum

# Apply the same function uniformly to all columns
monthly_mean = apply(ts, Month(1), mean)

# Existing convenience converters still work
weekly_last = to_weekly(ts)   # all columns: last value of each week
```

---

## About This Fork

This fork started for a fairly practical reason: I wanted TSFrames.jl to work with newer dependency versions.

Initially, I did not intend to make substantial implementation changes. I was also curious how effective coding agents such as Claude Code could be in real package maintenance, so this fork became partly an experiment in AI-assisted development.

As the work progressed, it grew beyond a simple compatibility update. The changes below — including `resample()`, internal performance improvements to `apply()`, and expanded tests and benchmarks — emerged gradually rather than being part of the original plan:

- Added **`resample()`** for OHLCV-aware per-column period aggregation
- Rewrote **`apply()`** internals for significant speedup (API fully unchanged)
- Expanded test suite with edge cases, DateTime indexes, and irregular time series
- Restructured benchmark suite covering all major operations

---

## New Functions

### `resample()` — Per-Column Period Aggregation

`resample()` is designed for financial OHLCV data where each column requires a
different aggregation rule. It complements the existing `to_period` / `apply()` functions.

#### Comparison with `to_period` and `apply`

|              | `to_weekly` / `to_period`   | `apply`                         | `resample`                         |
| ------------ | --------------------------- | ------------------------------- | ---------------------------------- |
| Aggregation  | All columns: `last` (fixed) | All columns: same user function | Per-column, user-specified         |
| Typical use  | Quick frequency conversion  | Uniform statistical aggregation | OHLCV bar construction             |
| Index label  | **Last** date of period     | First date (default)            | First date (default, configurable) |
| Column names | `col_last` (auto-renamed)   | `col_fun` (renamed by default)  | Original names (default)           |

`to_weekly(ts)` is essentially `apply(ts, Week(1), last)` — all columns get `last`.
`resample` allows specifying a different function for each column.

#### Usage

```julia
# Default OHLCV: auto-detects Open/High/Low/Close/Volume columns
weekly = resample(ts, Week(1))
# Open→first, High→maximum, Low→minimum, Close→last, Volume→sum

# Custom per-column rules (Symbol keys)
monthly = resample(ts, Month(1), :Open => first, :Close => last)

# String keys also work
quarterly = resample(ts, Month(3), "Open" => first, "Volume" => sum)

# Use last date of each period as the index label
resample(ts, Week(1); index_at=last)

# Preserve original column names (default); or rename like DataFrames combine
resample(ts, Week(1); renamecols=false)   # default: Open, Close, ...
resample(ts, Week(1); renamecols=true)    # renamed: Open_first, Close_last, ...
```

#### When to use which

- **`to_weekly(ts)` / `to_monthly(ts)`** — Fastest and most concise for simple
  frequency conversion. Applies `last` to every column. Ideal for closing prices.
- **`apply(ts, period, fn)`** — When you need the same function applied uniformly
  to all columns (e.g., `mean`, `sum`, `std`).
- **`resample(ts, period, :col => fn, ...)`** — When different columns need
  different aggregations. Essential for constructing proper OHLCV bars.

---

## Changelog

### New Features

- **`resample()`** — OHLCV-aware per-column period resampling (see [New Functions](#new-functions) above).
  Supports auto-detection of OHLCV columns, explicit `Symbol => Function` or `String => Function` pairs,
  and configurable index labeling (`index_at=first` or `last`).
- **`upsample()`** — was present in the codebase but not exported; now properly exported from the package.

### Internal Optimizations

#### `apply()` — significant speedup, API unchanged

The implementation of `apply()` was completely rewritten. The external API, argument types,
and return values are **fully backward-compatible** — only the internals changed.

**Before:** Used DataFrames `groupby` / `combine`, which constructs intermediate `GroupedDataFrame`
objects and allocates a new `DataFrame` per aggregation step.

**After:** Direct `@view`-slice iteration over pre-computed period endpoints
(`endpoints(ts, period)`), using type-barrier helper functions:

- `_build_index_out(idx, ep, index_at, n)` — builds the result index vector
- `_alloc_and_fill_col(src, ep, fn, n)` — applies the aggregation function to each period slice

These helpers are declared with concrete type parameters (`where {V, IA, F}`) so Julia's JIT
can specialize on the exact function types at each call site, eliminating dynamic dispatch and
reducing per-group allocations. Both `apply()` and `resample()` share the same helpers.

### Test Suite Expansion

New `@testset` blocks and new test files were added to improve coverage of edge cases:

**Existing test files:**

- `test/apply.jl` — added: multi-column correctness, `renamecols=false`, empty TSFrame
- `test/lag.jl` — added: multi-column, DateTime index, single-row, default argument,
  lag/lead symmetry, out-of-bounds (lag > nrow), negative lag equals lead
- `test/lead.jl` — added: mirror set of 6 `@testset` blocks matching the lag tests

**New test files:**

- `test/datetime_index.jl` — 40 tests covering 10 operation areas with `DateTime`
  and `Time` indexes (construction, subset, apply, lag/lead, join, rolling, etc.)
- `test/irregular_timeseries.jl` — 44 tests using weekday-only (business day) data
  and OHLCV aggregation verification against expected values
- `test/upsample.jl` — 29 tests covering single-row, multi-column, same-frequency,
  and output length checks for `upsample()`

### Benchmark Suite Restructure

The benchmark tooling was redesigned for modularity and repeatability:

**Suite files** (`benchmark/suites/`) — 143 benchmarks across 3 data sizes (100 / 10,000 / 1,000,000 rows):

- `bench_apply.jl` — `apply()` with various functions and periods
- `bench_construction.jl` — TSFrame construction from DataFrame and vectors
- `bench_endpoints.jl` — `endpoints()` at multiple frequencies
- `bench_join.jl` — inner / left / outer joins between TSFrames
- `bench_lag_lead_diff.jl` — `lag`, `lead`, `diff` at various offsets
- `bench_resample_vs_to_period.jl` — `resample()` vs `to_period` comparison
- `bench_rollapply.jl` — rolling window operations
- `bench_vcat.jl` — vertical concatenation

**Supporting scripts:**

- `benchmark/utils.jl` — shared utilities: `load_result`, `format_time`, `format_bytes`,
  `collect_leaves`, `navigate_leaf` (consolidated from previously duplicated code)
- `benchmark/run.jl` — orchestrator: `--group`, `--save`, `--compare`, `--report`, `--tune`, `--verbose`
- `benchmark/analysis/compare.jl` — regression/improvement detection between two result files
- `benchmark/analysis/report.jl` — Markdown report generation from one or more result files

**Bug fixes in benchmark tooling:**

- `judge()` now receives `TrialEstimate` (via `minimum()`) instead of raw `Trial` objects
- `Base.invokelatest` used when calling `generate_report` after `include()` to avoid world-age errors

---

_Based on [xKDR/TSFrames.jl](https://github.com/xKDR/TSFrames.jl).  
Full documentation: [xkdr.github.io/TSFrames.jl](https://xkdr.github.io/TSFrames.jl/dev/)_
