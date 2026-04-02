# TSFrames.jl Performance Improvement — Design Document

Date: 2026-04-03
Status: Proposed
Scope: Benchmark system, test coverage, performance features, README

---

## Table of Contents

1. [Benchmark System Design](#1-benchmark-system-design)
2. [Test Improvement Plan](#2-test-improvement-plan)
3. [Performance Implementation Priority](#3-performance-implementation-priority)
4. [README Restructure](#4-readme-restructure)

---

## 1. Benchmark System Design

### 1.1 Directory Structure

```
bench/
  README.md                     # How to run, interpret results
  run_all.jl                    # Orchestrator: runs all benchmarks, saves results
  run_single.jl                 # Run a single benchmark group by name
  Project.toml                  # Benchmark-specific dependencies (BenchmarkTools, etc.)
  
  suites/
    construction.jl             # TSFrame() constructor benchmarks
    getindex.jl                 # Indexing and subsetting benchmarks
    apply.jl                    # apply() benchmarks (key optimization target)
    resample.jl                 # resample() benchmarks (new function)
    endpoints.jl                # endpoints() benchmarks
    to_period.jl                # to_weekly/monthly/etc. benchmarks
    lag_lead_diff.jl            # lag(), lead(), diff(), pctchange()
    rollapply.jl                # rollapply() benchmarks
    join.jl                     # join/cbind benchmarks
    vcat.jl                     # vcat/rbind benchmarks
    
  results/
    baseline_YYYYMMDD.json      # BenchmarkTools JSON output (before optimization)
    current_YYYYMMDD.json       # Latest run
    
  analysis/
    compare.jl                  # Load two result files, run BenchmarkTools.judge()
    report.jl                   # Generate markdown comparison table
```

### 1.2 Data Sizes

Each suite benchmarks at three scales to capture algorithmic complexity:

| Label  | N         | Purpose                                    |
|--------|-----------|--------------------------------------------|
| small  | 100       | Overhead-dominated; catches startup costs  |
| medium | 10,000    | Realistic daily-data workload              |
| large  | 1,000,000 | Reveals O(n) vs O(n log n) differences     |

OHLCV data is generated with a fixed `MersenneTwister(42)` seed for reproducibility.

### 1.3 Orchestrator Design (`run_all.jl`)

```julia
# Pseudocode for orchestrator
using BenchmarkTools, JSON

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 5
BenchmarkTools.DEFAULT_PARAMETERS.samples = 50

# Each suite file defines a function: suite_name() -> BenchmarkGroup
include("suites/construction.jl")
include("suites/apply.jl")
# ... etc.

# Build top-level BenchmarkGroup
top = BenchmarkGroup()
top["construction"] = bench_construction()
top["apply"]        = bench_apply()
top["resample"]     = bench_resample()
top["endpoints"]    = bench_endpoints()
top["to_period"]    = bench_to_period()
top["lag_lead_diff"]= bench_lag_lead_diff()
top["rollapply"]    = bench_rollapply()
top["join"]         = bench_join()
top["vcat"]         = bench_vcat()
top["getindex"]     = bench_getindex()

# Run all
results = run(top)

# Save
timestamp = Dates.format(now(), "yyyymmdd_HHMMSS")
BenchmarkTools.save("results/run_$(timestamp).json", results)
```

### 1.4 Suite File Convention

Each suite file exports a single function that returns a `BenchmarkGroup`:

```julia
# suites/apply.jl
function bench_apply()
    suite = BenchmarkGroup()
    
    for (label, n) in [("small", 100), ("medium", 10_000), ("large", 1_000_000)]
        ts = generate_ohlcv(n)
        suite["$(label)_week_first"]  = @benchmarkable apply($ts, Week(1),  first)
        suite["$(label)_month_first"] = @benchmarkable apply($ts, Month(1), first)
        suite["$(label)_week_sum"]    = @benchmarkable apply($ts, Week(1),  sum)
    end
    
    suite
end
```

### 1.5 Single-Suite Runner (`run_single.jl`)

```julia
# Usage: julia --project=bench bench/run_single.jl apply
suite_name = ARGS[1]
include("suites/$(suite_name).jl")
fn = getfield(Main, Symbol("bench_$(suite_name)"))
results = run(fn())
display(results)
# Optionally save to results/
```

### 1.6 Comparison (`analysis/compare.jl`)

Uses `BenchmarkTools.judge()` to compare two result files:

```julia
# Usage: julia --project=bench bench/analysis/compare.jl baseline_20260403.json current_20260403.json
using BenchmarkTools, JSON

baseline = BenchmarkTools.load(ARGS[1])[1]
current  = BenchmarkTools.load(ARGS[2])[1]

judgment = judge(minimum(current), minimum(baseline))

# Print regressions and improvements
for (key, trial) in leaves(judgment)
    status = if isimprovement(trial)
        "IMPROVED"
    elseif isregression(trial)
        "REGRESSION"
    else
        "INVARIANT"
    end
    println("$(rpad(join(key, "/"), 50)) $(status)  $(ratio(trial))")
end
```

### 1.7 Shared Data Generator

```julia
# bench/suites/_data.jl (shared helper, included by all suites)
using TSFrames, DataFrames, Dates, Random, Statistics

function generate_ohlcv(n::Int; seed=42)
    rng = MersenneTwister(seed)
    dates = collect(Date(2000,1,1):Day(1):Date(2000,1,1) + Day(n-1))
    df = DataFrame(
        Open   = 100.0 .+ cumsum(randn(rng, n)),
        High   = 100.0 .+ cumsum(randn(rng, n)) .+ 1.0,
        Low    = 100.0 .+ cumsum(randn(rng, n)) .- 1.0,
        Close  = 100.0 .+ cumsum(randn(rng, n)),
        Volume = rand(rng, 1000:10000, n),
    )
    TSFrame(df, dates)
end

function generate_datetime_ohlcv(n::Int; seed=42)
    rng = MersenneTwister(seed)
    dts = collect(DateTime(2020,1,1):Second(1):DateTime(2020,1,1) + Second(n-1))
    df = DataFrame(
        Open   = 100.0 .+ cumsum(randn(rng, n)),
        High   = 100.0 .+ cumsum(randn(rng, n)) .+ 1.0,
        Low    = 100.0 .+ cumsum(randn(rng, n)) .- 1.0,
        Close  = 100.0 .+ cumsum(randn(rng, n)),
        Volume = rand(rng, 1000:10000, n),
    )
    TSFrame(df, dts)
end

function generate_single_col(n::Int; seed=42)
    rng = MersenneTwister(seed)
    dates = collect(Date(2000,1,1):Day(1):Date(2000,1,1) + Day(n-1))
    TSFrame(DataFrame(x1 = randn(rng, n)), dates)
end
```

### 1.8 Future: Upstream Comparison

For comparing with original TSFrames.jl (xKDR/TSFrames.jl):
- Save a "upstream baseline" by checking out the original code, running the same suite
- Store as `results/upstream_baseline.json`
- Use `compare.jl` to generate a comparison table
- This enables a clear narrative: "resample() is X faster than apply() for the same task"

---

## 2. Test Improvement Plan

### 2.1 Current Coverage Assessment

| Function     | Lines | Tests | Coverage Quality | Issues |
|-------------|-------|-------|-----------------|--------|
| lag          | 26    | ~8    | Basic           | No multi-column, no DateTime index, no edge cases |
| lead         | 25    | ~8    | Basic           | Same gaps as lag |
| rollapply    | 33    | ~12   | Basic           | No edge cases, no DateTime, no custom functions |
| upsample     | --    | 0     | None            | Not exported, no tests at all |
| resample     | 201   | 48    | Good            | Already well-tested |
| apply        | 172   | 334   | Excellent       | -- |
| endpoints    | 382   | many  | Excellent       | -- |

### 2.2 Test Additions: lag/lead

**File:** `test/lag.jl` and `test/lead.jl`

Missing test cases:
1. **Multi-column TSFrame** — lag/lead should work on all columns simultaneously
2. **DateTime index** — verify lag/lead preserves DateTime index correctly
3. **Single-row TSFrame** — edge case: lag(1) on 1-row => all missing
4. **Default argument** — `lag(ts)` uses default lag_value=1
5. **Float64 data** — current tests only use integer data
6. **Column names preserved** — verify output column names match input
7. **Type stability** — ensure eltype after lag is `Union{Missing, T}`
8. **Symmetry** — `lag(ts, n)` == `lead(ts, -n)` for any n

```julia
# Proposed additions for lag.jl
@testset "lag multi-column" begin
    ts_multi = TSFrame([1:10 11:20], index_timetype[1:10], colnames=[:A, :B])
    lagged = lag(ts_multi, 2)
    @test isequal(lagged[1:2, :A], [missing, missing])
    @test isequal(lagged[1:2, :B], [missing, missing])
    @test names(lagged) == ["A", "B"]
end

@testset "lag DateTime index" begin
    dt_index = collect(DateTime(2020,1,1):Hour(1):DateTime(2020,1,1)+Hour(9))
    ts_dt = TSFrame(collect(1.0:10.0), dt_index)
    lagged = lag(ts_dt, 1)
    @test eltype(index(lagged)) <: DateTime
    @test index(lagged) == dt_index
end

@testset "lag single row" begin
    ts1 = TSFrame([42.0], [Date(2020,1,1)])
    lagged = lag(ts1, 1)
    @test isequal(lagged[1, :x1], missing)
end

@testset "lag default argument" begin
    ts = TSFrame(collect(1:5), Date(2020,1,1):Day(1):Date(2020,1,5))
    @test isequal(lag(ts)[1, :x1], missing)
    @test lag(ts)[2, :x1] == 1
end

@testset "lag-lead symmetry" begin
    ts = TSFrame(integer_data_vector, index_timetype)
    for n in [1, 5, 10]
        @test isequal(lag(ts, n).coredata, lead(ts, -n).coredata)
    end
end
```

### 2.3 Test Additions: rollapply

**File:** `test/rollapply.jl`

Missing test cases:
1. **Single-column TSFrame** — simplest case
2. **DateTime index** — verify output index type preserved
3. **Custom aggregation functions** — std, median, custom lambda
4. **windowsize = nrow** — edge case: single output row
5. **windowsize = 1** — identity-like operation
6. **Empty result** — should not error
7. **Column name format** — verify rolling_X_fn naming convention
8. **Single row TSFrame** — windowsize=1 on 1-row input
9. **Large window on small data** — windowsize > nrow (currently capped)

```julia
# Proposed additions
@testset "rollapply DateTime index" begin
    dt_idx = collect(DateTime(2020,1,1):Hour(1):DateTime(2020,1,1)+Hour(9))
    ts_dt = TSFrame(collect(1.0:10.0), dt_idx)
    result = rollapply(ts_dt, mean, 3)
    @test eltype(index(result)) <: DateTime
    @test length(index(result)) == 8  # 10 - 3 + 1
end

@testset "rollapply single column" begin
    ts1 = TSFrame(collect(1.0:10.0), Date(2020,1,1):Day(1):Date(2020,1,10))
    result = rollapply(ts1, sum, 3)
    @test result[1, :rolling_x1_sum] == 6.0  # 1+2+3
    @test result[2, :rolling_x1_sum] == 9.0  # 2+3+4
end

@testset "rollapply custom function" begin
    ts1 = TSFrame(collect(1.0:10.0), Date(2020,1,1):Day(1):Date(2020,1,10))
    result = rollapply(ts1, x -> maximum(x) - minimum(x), 3)
    @test result[1, Symbol("rolling_x1_#1")] == 2.0  # max(1,2,3)-min(1,2,3)
end

@testset "rollapply windowsize equals nrow" begin
    ts1 = TSFrame(collect(1.0:5.0), Date(2020,1,1):Day(1):Date(2020,1,5))
    result = rollapply(ts1, mean, 5)
    @test TSFrames.nrow(result) == 1
    @test result[1, :rolling_x1_mean] == 3.0
end
```

### 2.4 Test Additions: upsample

**File:** `test/upsample.jl` (new file)

`upsample()` is not exported but exists in `src/upsample.jl`. Tests should cover:

```julia
# test/upsample.jl

@testset "upsample basic" begin
    # Monthly -> Daily
    dates = [Date(2020,1,1), Date(2020,2,1), Date(2020,3,1)]
    ts = TSFrame(DataFrame(x1=[10.0, 20.0, 30.0]), dates)
    result = TSFrames.upsample(ts, Day(1))
    
    # Should have rows for every day from Jan 1 to Mar 1
    @test first(index(result)) == Date(2020,1,1)
    @test last(index(result)) == Date(2020,3,1)
    
    # Original values preserved at original dates
    @test result[Date(2020,1,1), :x1] == 10.0
    @test result[Date(2020,2,1), :x1] == 20.0
    @test result[Date(2020,3,1), :x1] == 30.0
    
    # Intermediate dates are missing
    @test ismissing(result[Date(2020,1,2), :x1])
end

@testset "upsample DateTime" begin
    dts = [DateTime(2020,1,1,0), DateTime(2020,1,1,6), DateTime(2020,1,1,12)]
    ts = TSFrame(DataFrame(x1=[1.0, 2.0, 3.0]), dts)
    result = TSFrames.upsample(ts, Hour(1))
    
    @test first(index(result)) == DateTime(2020,1,1,0)
    @test last(index(result)) == DateTime(2020,1,1,12)
    @test TSFrames.nrow(result) == 13  # 0,1,2,...,12
end

@testset "upsample single row" begin
    ts = TSFrame(DataFrame(x1=[1.0]), [Date(2020,1,1)])
    result = TSFrames.upsample(ts, Day(1))
    @test TSFrames.nrow(result) == 1
    @test result[1, :x1] == 1.0
end

@testset "upsample already at target freq" begin
    dates = Date(2020,1,1):Day(1):Date(2020,1,5)
    ts = TSFrame(DataFrame(x1=collect(1.0:5.0)), collect(dates))
    result = TSFrames.upsample(ts, Day(1))
    @test TSFrames.nrow(result) == 5
    @test result[:, :x1] == collect(1.0:5.0)
end

@testset "upsample multi-column" begin
    dates = [Date(2020,1,1), Date(2020,1,3)]
    ts = TSFrame(DataFrame(A=[1.0, 2.0], B=[10.0, 20.0]), dates)
    result = TSFrames.upsample(ts, Day(1))
    @test TSFrames.nrow(result) == 3
    @test result[Date(2020,1,1), :A] == 1.0
    @test ismissing(result[Date(2020,1,2), :A])
    @test ismissing(result[Date(2020,1,2), :B])
end
```

### 2.5 Test Additions: DateTime/Time Index

**File:** `test/datetime_index.jl` (new file)

No tests currently exercise DateTime or Time as index types for core operations:

```julia
# test/datetime_index.jl

@testset "DateTime index operations" begin
    dt_idx = collect(DateTime(2020,1,1):Minute(1):DateTime(2020,1,1,1,0))
    ts = TSFrame(DataFrame(val=randn(61)), dt_idx)
    
    # endpoints with DateTime
    ep = endpoints(ts, Hour(1))
    @test length(ep) >= 1
    @test last(ep) == 61
    
    # apply with DateTime
    result = apply(ts, Hour(1), first)
    @test result isa TSFrame
    @test eltype(index(result)) <: DateTime
    
    # resample with DateTime
    result2 = resample(ts, Minute(15), :val => mean)
    @test result2 isa TSFrame
    
    # to_period with DateTime
    hourly = to_hourly(ts)
    @test hourly isa TSFrame
    
    # lag/lead with DateTime
    lagged = lag(ts, 1)
    @test eltype(index(lagged)) <: DateTime
    
    # subset with DateTime
    sub = TSFrames.subset(ts, DateTime(2020,1,1,0,10), DateTime(2020,1,1,0,20))
    @test TSFrames.nrow(sub) == 11
end

@testset "Time index operations" begin
    t_idx = collect(Time(9,0,0):Second(1):Time(9,1,0))
    ts = TSFrame(DataFrame(val=randn(61)), t_idx)
    
    # endpoints with Time
    ep = endpoints(ts, Second(10))
    @test length(ep) >= 1
    
    # to_seconds with Time
    result = to_seconds(ts, 10)
    @test result isa TSFrame
end
```

### 2.6 Test Additions: Irregular Time Series

```julia
# test/irregular_timeseries.jl (new file)

@testset "irregular time series" begin
    # Dates with gaps (weekends removed)
    dates = filter(d -> dayofweek(d) <= 5, 
                   collect(Date(2020,1,1):Day(1):Date(2020,1,31)))
    ts = TSFrame(DataFrame(val=randn(length(dates))), dates)
    
    # endpoints handles gaps
    ep = endpoints(ts, Week(1))
    @test all(diff(ep) .> 0)  # monotonically increasing
    
    # apply on irregular
    result = apply(ts, Week(1), first)
    @test result isa TSFrame
    
    # resample on irregular
    result2 = resample(ts, Week(1), :val => mean)
    @test result2 isa TSFrame
    
    # to_weekly on irregular
    weekly = to_weekly(ts)
    @test weekly isa TSFrame
end
```

### 2.7 Integration into runtests.jl

Add new testsets to `test/runtests.jl`:

```julia
# After existing testsets:
@testset "upsample()" begin
    include("upsample.jl")
end

@testset "DateTime index" begin
    include("datetime_index.jl")
end

@testset "Irregular time series" begin
    include("irregular_timeseries.jl")
end
```

### 2.8 Test Count Estimate

| Category                    | New Tests (est.) |
|-----------------------------|-----------------|
| lag improvements            | ~15             |
| lead improvements           | ~15             |
| rollapply improvements      | ~12             |
| upsample (new)              | ~15             |
| DateTime/Time index (new)   | ~20             |
| Irregular time series (new) | ~10             |
| **Total new tests**         | **~87**         |
| **Current total**           | **1,775**       |
| **Projected total**         | **~1,862**      |

---

## 3. Performance Implementation Priority

### 3.1 Priority Order

```
P1: apply() copy() elimination    — HIGH ROI, highest user impact
    |
P2: gap-aware resampling         — Feature, medium complexity
    |
P3: session-reset VWAP           — Foxtail.jl scope, separate repo
    |
P4: endpoints() pre-allocation   — Low ROI, minor optimization
```

### 3.2 P1: Eliminate copy() in apply() via @view pattern

**Status:** Next implementation target
**Estimated speedup:** 3-4x for apply()
**Files:** `src/apply.jl`

**Current bottleneck (from profiling):**
```
apply() internals (1M rows, Week):
  endpoints():    0.42 ms  ( 8%)
  groupindices:   0.74 ms  (14%)
  copy(coredata): 0.74 ms  (14%)  <-- ELIMINATE
  groupby():      1.89 ms  (35%)  <-- ELIMINATE
  combine():      2.36 ms  (44%)  <-- ELIMINATE
  TOTAL:          5.36 ms
```

**Approach:** Apply the same type-barrier @view pattern proven in `resample()` to `apply()`:

```julia
function apply_fast(ts::TSFrame, period::T, fun::V, index_at::Function=first;
                    renamecols::Bool=true) where {T<:Dates.Period, V<:Function}
    idx = index(ts)
    isempty(idx) && return _apply_empty(ts, fun, renamecols)
    
    ep = endpoints(ts, period)
    n  = length(ep)
    
    # Type-barrier for index
    index_out = _build_index_out(idx, ep, index_at, n)
    
    # Type-barrier for each column
    df = DataFrame(:Index => index_out)
    coredata = ts.coredata
    for colname in names(ts)
        src = coredata[!, colname]
        dst = _alloc_and_fill_col(src, ep, fun, n)
        col_out = renamecols ? Symbol(colname, :_, nameof(fun)) : Symbol(colname)
        df[!, col_out] = dst
    end
    
    TSFrame(df, :Index; issorted=true, copycols=false)
end
```

**Key insight:** `_build_index_out` and `_alloc_and_fill_col` already exist in `resample.jl`. 
They can be shared (move to a common internal module or keep in `apply.jl` as well).

**Acceptance criteria:**
- All 334 existing apply() tests pass
- apply(ts, Week(1), first) time drops from ~5.36ms to ~1.5ms for 1M rows
- Allocations drop from 659 to <100

**Risks:**
- `apply()` currently supports arbitrary `fun` that may return different types per column
  (e.g., `size` returning tuples). The type-barrier pattern infers output type from the 
  first group; if `fun` returns inconsistent types across groups, this would fail.
- Mitigation: add a try-catch that falls back to the current groupby/combine path.

**Implementation plan:**
1. Extract shared helpers (`_build_index_out`, `_alloc_and_fill_col`) to `src/utils.jl` 
   or keep them duplicated (simpler, avoids coupling)
2. Implement `apply()` rewrite using @view type-barrier pattern
3. Keep old implementation as `_apply_groupby` fallback
4. Run full test suite
5. Benchmark comparison

### 3.3 P2: Gap-aware Resampling

**Status:** Future feature
**Files:** `src/resample.jl`
**Dependency:** Independent of P1

**Goal:** `resample(ts, Week(1); fill_gaps=true)` fills periods with no data as `missing`.

**Design considerations:**
- Need to generate a complete period grid from first to last date
- For each expected period, check if data exists
- Missing periods get `missing` for all value columns
- Index gets the expected period boundary date
- Requires knowing the period type to generate expected dates

**Implementation sketch:**
```julia
function _fill_period_gaps(result::TSFrame, period::T, idx_range) where {T<:Dates.Period}
    expected_dates = collect(floor(first(idx_range), typeof(period)):period:last(idx_range))
    # Left join expected dates with result
    # Fill gaps with missing
end
```

**Estimated effort:** Medium (2-3 hours)

### 3.4 P3: Session-Reset VWAP

**Status:** Separate repository (Foxtail.jl)
**Not tracked here.** Reference only.

### 3.5 P4: endpoints() Pre-allocation

**Status:** Low priority
**Files:** `src/endpoints.jl`
**Estimated speedup:** ~16% of endpoints() time (which is only 8% of apply() total)

**Current issue:**
```julia
ep = Int[]
sizehint!(ep, length(timestamps))  # already has sizehint
# ... push!(ep, i-1) in loop
```

**The `sizehint!` already exists.** The remaining 16% overhead is from branch prediction and 
the `push!` call itself. The actual impact on end-to-end performance is:
- endpoints is 8% of apply() time
- 16% of 8% = 1.3% end-to-end improvement

**Recommendation:** Skip for now. The ROI is too low to justify the complexity of pre-estimating
the number of periods. If needed later:

```julia
# Estimate: upper bound of period count
est_periods = div(length(timestamps), max(1, Dates.value(on))) + 2
ep = Vector{Int}(undef, est_periods)
count = 0
# ... ep[count += 1] = i-1 in loop
resize!(ep, count)
```

---

## 4. README Restructure

### 4.1 Design Principles

- **Fork acknowledgment first** — respect for original authors
- **Changes summary** — what and why, not how
- **Minimal duplication** — link to original docs, don't copy
- **New features front and center** — resample() gets detailed docs
- **Benchmarks** — show performance gains

### 4.2 Proposed Structure

```markdown
# TSFrames.jl

> A high-performance fork of [xKDR/TSFrames.jl](https://github.com/xKDR/TSFrames.jl)
> for time-series data manipulation in Julia.

[![Build Status](...)][...]

## Fork Notice

This is a fork of the excellent [TSFrames.jl](https://github.com/xKDR/TSFrames.jl)
by xKDR Forum. All original functionality is preserved.

### Changes from upstream

- **`resample()` function** — Period-based resampling with per-column aggregation, 
  3.5x faster than `apply()` for OHLCV data, with 9x fewer allocations
- **Performance optimizations** — Type-barrier patterns, eliminated unnecessary 
  copy/sort operations in `to_period()` and `apply()`
- **Bug fixes** — Empty TSFrame handling in `resample()` and `apply()`

For full upstream documentation, see the [original docs](https://xkdr.github.io/TSFrames.jl/dev/).

## Installation

```julia
# From this fork
using Pkg
Pkg.add(url="https://github.com/takaymmt/TSFrames.jl.git")
```

## Quick Start

[Keep essential: TSFrame creation, indexing, subsetting — same as original]

## New: resample()

### Default OHLCV Resampling

```julia
using TSFrames, DataFrames, Dates

# Create daily OHLCV data
dates = Date(2020,1,1):Day(1):Date(2020,12,31)
ts = TSFrame(DataFrame(
    Open=randn(366), High=randn(366).+1, Low=randn(366).-1,
    Close=randn(366), Volume=rand(1:10000, 366)
), collect(dates))

# Resample to weekly — auto-detects OHLCV columns
weekly = resample(ts, Week(1))
# Open→first, High→maximum, Low→minimum, Close→last, Volume→sum
```

### Custom Per-Column Aggregation

```julia
# Specify exactly which columns and functions
monthly = resample(ts, Month(1), :Open => first, :Close => last, :Volume => sum)

# String keys work too
resample(ts, Week(1), "Open" => first, "Volume" => sum)
```

### Parameters

| Parameter    | Default | Description |
|-------------|---------|-------------|
| `index_at`  | `first` | Function to select period label (`first` or `last`) |
| `renamecols`| `false` | If `true`, columns named `Open_first`, etc. |

## Performance

### resample() vs apply() (1M rows, 5 OHLCV columns)

| Function       | Time    | Allocations | vs apply() |
|----------------|---------|-------------|------------|
| apply(first)   | 5.36 ms | 659         | 1x         |
| resample()     | 1.54 ms | 73          | **3.5x faster** |

### Key Optimizations

- **Type-barrier pattern**: Eliminates per-group boxing via `where {V<:AbstractVector}`
- **@view slicing**: Zero-copy group access, no `groupby()`/`combine()` overhead
- **Pre-sorted output**: `issorted=true` skips redundant sort in TSFrame constructor

## API Reference

[Link to full API docs or brief table of all exported functions]

## Benchmarks

Run benchmarks:
```julia
julia --project=bench bench/run_all.jl
```

Compare results:
```julia
julia --project=bench bench/analysis/compare.jl results/baseline.json results/current.json
```

## Acknowledgements

This project builds upon the work of:
- **xKDR Forum** — Original TSFrames.jl authors (Chirag Anand, Siddhant Chaudhary, 
  Naman Kumar, Sumeet Suley)
- **JuliaLab at MIT** — Financial support for the original project
- **Bogumil Kaminski** — DataFrames.jl and continuous feedback
- The R **zoo** and **xts** package authors for foundational concepts

## License

[Same as upstream]
```

---

## Appendix: Implementation Timeline

| Phase | Task | Est. Effort | Dependencies |
|-------|------|-------------|-------------|
| Phase 1 | Create `bench/` directory structure | 2h | None |
| Phase 2 | Write benchmark suites for all functions | 4h | Phase 1 |
| Phase 3 | Run baseline benchmarks, save results | 1h | Phase 2 |
| Phase 4 | Add test improvements (lag/lead/rollapply/upsample/DateTime) | 4h | None |
| Phase 5 | P1: apply() @view optimization | 3h | Phase 3 (for before/after comparison) |
| Phase 6 | Run post-optimization benchmarks, compare | 1h | Phase 5 |
| Phase 7 | Restructure README.md | 1h | Phase 5, Phase 6 |
| Phase 8 | P2: gap-aware resampling (optional) | 3h | Phase 5 |
| **Total** | | **~19h** | |

Phases 1-3 (benchmarks) and Phase 4 (tests) can proceed in parallel.
