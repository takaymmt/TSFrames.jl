# Benchmark System Research for TSFrames.jl

**Date**: 2026-04-03
**Purpose**: Design a structured, comparable benchmark system for TSFrames.jl

---

## 1. BenchmarkTools.jl Suite Structure Best Practices

### 1.1 BenchmarkGroup Hierarchy

BenchmarkTools.jl uses `BenchmarkGroup` as the fundamental organizational unit. Groups can be nested arbitrarily deep and tagged for flexible filtering.

```julia
# Recommended structure for TSFrames.jl
const SUITE = BenchmarkGroup()

# Top-level groups by functional category
SUITE["construction"] = BenchmarkGroup(["core"])
SUITE["indexing"]     = BenchmarkGroup(["core", "getindex"])
SUITE["apply"]        = BenchmarkGroup(["aggregation"])
SUITE["resample"]     = BenchmarkGroup(["aggregation", "timeseries"])
SUITE["to_period"]    = BenchmarkGroup(["aggregation", "timeseries"])
SUITE["join"]         = BenchmarkGroup(["merge"])
SUITE["transform"]    = BenchmarkGroup(["lag", "lead", "diff", "pctchange"])
SUITE["rollapply"]    = BenchmarkGroup(["rolling", "aggregation"])
SUITE["vcat"]         = BenchmarkGroup(["merge"])
```

### 1.2 Tags for Filtering

Tags enable running subsets of benchmarks by topic:

```julia
# Filter by tag
run(SUITE[@tagged "aggregation"])          # All aggregation-related benchmarks
run(SUITE[@tagged "core"])                  # Only core functionality
run(SUITE[@tagged "timeseries" && !("rolling")])  # Time-series but not rolling
```

Tag rules:
- A group has a tag if explicitly attached via `BenchmarkGroup(["tag"])`
- Tags are inherited up the hierarchy (parent tags apply to children)
- Use lowercase, singular nouns (per BaseBenchmarks.jl convention)

### 1.3 Parameterized Benchmarks (Different N Sizes)

Use tuple keys for multi-parameter benchmarks:

```julia
# Benchmark across data sizes
for N in [100, 1_000, 10_000, 100_000]
    SUITE["construction"]["TSFrame", N] = @benchmarkable TSFrame($df) setup=(df = generate_df($N))
    SUITE["resample"]["Month", N]       = @benchmarkable resample($ts, Month) setup=(ts = generate_ts($N))
end

# Access via tuple key
SUITE["construction"]["TSFrame", 10_000]
```

### 1.4 Data Consistency

**Always seed RNG** for reproducible benchmark data:

```julia
using Random
testdata = generate_df(MersenneTwister(42), 10_000)
```

### 1.5 Parameter Caching (Critical for Consistency)

Cache tuned parameters to avoid re-tuning each session:

```julia
paramspath = joinpath(dirname(@__FILE__), "params.json")

if isfile(paramspath)
    loadparams!(SUITE, BenchmarkTools.load(paramspath)[1], :evals, :samples)
else
    tune!(SUITE)
    BenchmarkTools.save(paramspath, params(SUITE))
end
```

**Why**: Tuning often takes longer than actual benchmarking and causes inconsistency between runs.

---

## 2. Saving, Loading, and Comparing Results

### 2.1 JSON Serialization

```julia
# Save results
results = run(SUITE)
BenchmarkTools.save("benchmark/results/current.json", results)

# Load results
old_results = BenchmarkTools.load("benchmark/results/baseline.json")[1]
```

**Note**: The `[1]` index is needed because `load()` returns an array of serialized objects.

### 2.2 Comparing with `judge()`

```julia
# Compare two result sets
judgement = judge(minimum(new_results), minimum(old_results))

# With custom tolerance (default is 5% for time)
judgement = judge(minimum(new_results), minimum(old_results);
                  time_tolerance = 0.05,    # 5%
                  memory_tolerance = 0.01)   # 1%

# Extract regressions/improvements
regressed = regressions(judgement)
improved  = improvements(judgement)

# Leaf iteration for detailed report
for (id, trial_judgement) in leaves(judgement)
    println(id, " => ", trial_judgement)
end
```

### 2.3 Recommended Use of `minimum()`

Use `minimum()` (not `median()` or `mean()`) for comparisons because it represents the "best possible" execution and is least affected by system noise.

---

## 3. PkgBenchmark.jl Integration

### 3.1 Standard Directory Layout

PkgBenchmark expects:
```
TSFrames.jl/
├── benchmark/
│   ├── benchmarks.jl      # Main entry point (required by PkgBenchmark)
│   ├── params.json         # Cached tuning parameters
│   └── results/            # Saved result files
│       ├── baseline.json
│       └── current.json
```

### 3.2 Comparing Commits

```julia
using PkgBenchmark

# Compare current state vs a specific commit/tag
judgement = judge("TSFrames", "HEAD", "v0.2.0")

# Compare with custom config
target  = BenchmarkConfig(id = "main", juliacmd = `julia -O3`)
baseline = BenchmarkConfig(id = "v0.2.0", juliacmd = `julia -O3`)
judgement = judge("TSFrames", target, baseline)

# Export comparison to markdown
export_markdown(stdout, judgement)
export_markdown("benchmark/results/comparison.md", judgement)
```

### 3.3 Accessing Results

```julia
target_res  = target_result(judgement)
baseline_res = baseline_result(judgement)
group       = benchmarkgroup(judgement)
```

---

## 4. Comparing Fork vs Original Package

### 4.1 Strategy: VersionBenchmarks.jl

`VersionBenchmarks.jl` is purpose-built for comparing different package versions/forks:

```julia
using VersionBenchmarks

df = benchmark(
    [
        Config("original", (name = "TSFrames", version = "0.2.1")),  # from General registry
        Config("fork",     (path = "/Users/taka/proj/TSFrames.jl")), # local fork
    ],
    "benchmark/comparison_benchmark.jl",
    repetitions = 10,
)
```

**Key features**:
- Spawns fresh Julia processes for each version (no cross-contamination)
- Alternates between configs to avoid confusing system noise with real differences
- Uses `@vbtime` (single run) and `@vbbenchmark` (BenchmarkTools-wrapped) macros

### 4.2 Strategy: Manual Separate Environments

For more control, use Julia's Pkg environments:

```julia
# Script: benchmark/compare_original.jl
# Run in two separate environments:

# Environment A: Original TSFrames (registered)
# Project.toml: TSFrames = "9f90e835-..." (from registry)

# Environment B: Fork TSFrames (local)
# Project.toml: TSFrames = {path = ".."}

# Share the same benchmark code, save results to different JSON files
# Then load both and judge() them
```

### 4.3 Strategy: PkgBenchmark with Git Remotes

If the fork and original share the same git history:
```julia
# Add original as remote
# git remote add upstream https://github.com/xKDR/TSFrames.jl.git
# git fetch upstream

# Compare fork main vs upstream main
judgement = judge("TSFrames", "main", "upstream/main")
```

**Recommended approach**: Use **VersionBenchmarks.jl** for fork-vs-original comparison (cleanest isolation), and **PkgBenchmark.jl** for within-fork regression tracking.

---

## 5. Real-World Organization Patterns

### 5.1 BaseBenchmarks.jl Pattern (Julia Base)

- Benchmarks organized as **dynamically-loadable groups** (lazy loading)
- Functions being benchmarked prefixed with `perf_` for discoverability
- Tags are lowercase, singular, reused across groups
- `SUITE` is the top-level constant
- Access pattern: `SUITE["category"]["subcategory"]["function", param]`

### 5.2 Recommended TSFrames.jl Benchmark Categories

Based on the existing `Benchmark.md` and source files:

| Category | Functions | Tags |
|----------|-----------|------|
| `construction` | `TSFrame()` | `core` |
| `indexing` | `getindex`, `subset` | `core`, `getindex` |
| `apply` | `apply()` | `aggregation` |
| `resample` | `resample()` | `aggregation`, `timeseries` |
| `to_period` | `to_period()`, `to_monthly()`, etc. | `aggregation`, `timeseries` |
| `transform` | `lag()`, `lead()`, `diff()`, `pctchange()` | `transform` |
| `rollapply` | `rollapply()` | `rolling`, `aggregation` |
| `join` | `leftjoin`, `rightjoin`, `innerjoin`, `outerjoin` | `merge`, `join` |
| `vcat` | `vcat()`, `rbind()` | `merge` |

### 5.3 Recommended Data Sizes

```julia
const BENCHMARK_SIZES = [100, 1_000, 10_000, 100_000]
```

- **100**: Edge case / small data (warm-up, overhead measurement)
- **1,000**: Typical small dataset
- **10,000**: Medium dataset (performance patterns emerge)
- **100,000**: Large dataset (allocation/GC pressure visible)

---

## 6. Proposed File Structure

```
TSFrames.jl/
├── benchmark/
│   ├── benchmarks.jl          # Main entry point (PkgBenchmark-compatible)
│   ├── bench_construction.jl  # TSFrame construction benchmarks
│   ├── bench_indexing.jl      # Indexing and subset benchmarks
│   ├── bench_apply.jl         # apply() benchmarks
│   ├── bench_resample.jl      # resample() benchmarks
│   ├── bench_to_period.jl     # to_period() benchmarks
│   ├── bench_transform.jl     # lag, lead, diff, pctchange
│   ├── bench_rollapply.jl     # rollapply() benchmarks
│   ├── bench_join.jl          # Join operation benchmarks
│   ├── bench_vcat.jl          # vcat/rbind benchmarks
│   ├── helpers.jl             # Data generation helpers
│   ├── params.json            # Cached tuning parameters (gitignored)
│   ├── run.jl                 # CLI runner script (selective execution)
│   └── results/               # Saved results (gitignored)
│       ├── .gitkeep
│       ├── baseline.json
│       └── current.json
```

### 6.1 `benchmarks.jl` (Main Entry Point)

```julia
using BenchmarkTools
using TSFrames
using DataFrames, Dates, Random, Statistics

include("helpers.jl")

const SUITE = BenchmarkGroup()

# Include individual benchmark files
include("bench_construction.jl")
include("bench_indexing.jl")
include("bench_apply.jl")
include("bench_resample.jl")
include("bench_to_period.jl")
include("bench_transform.jl")
include("bench_rollapply.jl")
include("bench_join.jl")
include("bench_vcat.jl")

# Parameter caching
paramspath = joinpath(dirname(@__FILE__), "params.json")
if isfile(paramspath)
    loadparams!(SUITE, BenchmarkTools.load(paramspath)[1], :evals, :samples)
else
    tune!(SUITE)
    BenchmarkTools.save(paramspath, params(SUITE))
end
```

### 6.2 `run.jl` (Selective Execution)

```julia
# Usage:
#   julia benchmark/run.jl                    # Run all
#   julia benchmark/run.jl resample           # Run specific group
#   julia benchmark/run.jl resample apply     # Run multiple groups
#   julia benchmark/run.jl --save baseline    # Run all and save as baseline
#   julia benchmark/run.jl --compare          # Compare current vs baseline

include("benchmarks.jl")

function main()
    args = ARGS
    save_name = nothing
    compare_mode = false
    groups = String[]

    i = 1
    while i <= length(args)
        if args[i] == "--save" && i < length(args)
            save_name = args[i+1]
            i += 2
        elseif args[i] == "--compare"
            compare_mode = true
            i += 1
        else
            push!(groups, args[i])
            i += 1
        end
    end

    # Select benchmarks to run
    suite_to_run = if isempty(groups)
        SUITE
    else
        filtered = BenchmarkGroup()
        for g in groups
            if haskey(SUITE, g)
                filtered[g] = SUITE[g]
            else
                @warn "Unknown benchmark group: $g"
            end
        end
        filtered
    end

    # Run benchmarks
    results = run(suite_to_run, verbose=true, seconds=5)

    # Display results
    for (id, trial) in leaves(results)
        println(join(id, "/"), ": ", minimum(trial))
    end

    # Save if requested
    if save_name !== nothing
        path = joinpath(dirname(@__FILE__), "results", "$save_name.json")
        mkpath(dirname(path))
        BenchmarkTools.save(path, results)
        println("\nResults saved to: $path")
    end

    # Compare if requested
    if compare_mode
        baseline_path = joinpath(dirname(@__FILE__), "results", "baseline.json")
        if isfile(baseline_path)
            baseline = BenchmarkTools.load(baseline_path)[1]
            judgement = judge(minimum(results), minimum(baseline))
            println("\n=== Comparison vs Baseline ===")
            for (id, trial_j) in leaves(judgement)
                println(join(id, "/"), ": ", trial_j)
            end
            regressed = regressions(judgement)
            if !isempty(leaves(regressed))
                println("\n⚠ REGRESSIONS DETECTED:")
                for (id, tj) in leaves(regressed)
                    println("  ", join(id, "/"), ": ", tj)
                end
            end
        else
            @warn "No baseline found at $baseline_path. Run with --save baseline first."
        end
    end
end

main()
```

### 6.3 `helpers.jl` (Data Generation)

```julia
"""
Generate a DataFrame with OHLCV-like data for benchmarking.
Uses a seeded RNG for reproducibility.
"""
function generate_ohlcv_df(rng::AbstractRNG, n::Int)
    dates = Date(2020, 1, 1) .+ Day.(0:n-1)
    open_prices  = 100.0 .+ cumsum(randn(rng, n) .* 0.5)
    high_prices  = open_prices .+ abs.(randn(rng, n))
    low_prices   = open_prices .- abs.(randn(rng, n))
    close_prices = open_prices .+ randn(rng, n) .* 0.3
    volumes      = abs.(round.(Int, randn(rng, n) .* 1000 .+ 5000))
    DataFrame(
        Index  = dates,
        Open   = open_prices,
        High   = high_prices,
        Low    = low_prices,
        Close  = close_prices,
        Volume = volumes,
    )
end

generate_ohlcv_df(n::Int) = generate_ohlcv_df(MersenneTwister(42), n)

"""
Generate a TSFrame with OHLCV data.
"""
function generate_ohlcv_ts(n::Int)
    TSFrame(generate_ohlcv_df(n))
end

"""
Generate a simple single-column TSFrame.
"""
function generate_simple_ts(rng::AbstractRNG, n::Int)
    dates = Date(2020, 1, 1) .+ Day.(0:n-1)
    TSFrame(DataFrame(Index = dates, Value = randn(rng, n)))
end

generate_simple_ts(n::Int) = generate_simple_ts(MersenneTwister(42), n)

const BENCHMARK_SIZES = [100, 1_000, 10_000, 100_000]
```

---

## 7. Key Recommendations

### 7.1 Regression Testing Workflow

1. **Establish baseline**: Run full suite, save as `baseline.json`
2. **Before PR merge**: Run suite, compare with `judge()` against baseline
3. **Tolerance**: Use 5% for time, 1% for memory (defaults)
4. **Report**: Export judgement to markdown for PR comments

### 7.2 Fork-vs-Original Comparison

- Use **VersionBenchmarks.jl** for clean isolated comparison
- Alternatively, use git remotes + PkgBenchmark.jl if git history is shared
- The original package is at `https://github.com/xKDR/TSFrames.jl` (registered as "TSFrames" in General registry)
- Compare shared functions only (exclude fork-specific features like `resample()`)

### 7.3 CI Integration (Future)

```yaml
# .github/workflows/benchmark.yml
# Trigger on PR, compare against main branch
# Use PkgBenchmark.judge("TSFrames", "HEAD", "main")
# Post results as PR comment via export_markdown()
```

---

## References

- [BenchmarkTools.jl Manual](https://juliaci.github.io/BenchmarkTools.jl/dev/manual/)
- [BenchmarkTools.jl Reference](https://juliaci.github.io/BenchmarkTools.jl/dev/reference/)
- [BenchmarkTools.jl GitHub](https://github.com/JuliaCI/BenchmarkTools.jl)
- [PkgBenchmark.jl Documentation](https://juliaci.github.io/PkgBenchmark.jl/stable/)
- [PkgBenchmark.jl Comparing Commits](https://juliaci.github.io/PkgBenchmark.jl/stable/comparing_commits/)
- [BaseBenchmarks.jl](https://github.com/JuliaCI/BaseBenchmarks.jl) — Real-world benchmark suite for Julia Base
- [VersionBenchmarks.jl](https://github.com/jkrumbiegel/VersionBenchmarks.jl) — Cross-version comparison tool
- [Original TSFrames.jl (xKDR)](https://github.com/xKDR/TSFrames.jl)
- [BenchmarkTools.jl sample benchmarks.jl](https://github.com/JuliaCI/BenchmarkTools.jl/blob/main/benchmark/benchmarks.jl)
