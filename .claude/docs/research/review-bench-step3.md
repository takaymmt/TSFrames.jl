# Benchmark Review: Step 3

## Summary

The benchmark infrastructure is well-designed with comprehensive coverage of all major TSFrames functions. All 8 benchmark suites (143 total benchmarks) load successfully, individual benchmarks execute correctly, and the standalone analysis tools (compare.jl, report.jl) produce meaningful output. However, two bugs exist in the orchestrator (run.jl) that prevent `--compare` and `--report` modes from working via the CLI.

## Benchmark Execution

**Status: PASS (individual suites and orchestrator --group mode)**

- All 8 suites load via `benchmarks.jl` without errors:
  - `apply`: 21 benchmarks
  - `construction`: 15 benchmarks
  - `endpoints`: 18 benchmarks
  - `join`: 9 benchmarks
  - `lag_lead_diff`: 24 benchmarks
  - `resample_vs_to_period`: 39 benchmarks
  - `rollapply`: 8 benchmarks
  - `vcat`: 9 benchmarks
- Running `julia --project=benchmark benchmark/run.jl --group endpoints --verbose` completes successfully with proper summary output
- Individual benchmark execution via `@benchmarkable` works correctly (tested `BENCH_APPLY["small"]["monthly_last"]`)
- Data sizes (small/100, medium/10k, large/1M) are well-chosen; rollapply correctly uses 100k for large to avoid excessive runtime
- Note: Julia 1.12 emits a world-age deprecation warning about `Main.SUITE` access from `run.jl` (non-fatal, but should be addressed)

## Compare/Report Tool Verification

### Standalone tools: PASS
- `julia --project=benchmark benchmark/analysis/compare.jl baseline.json after_p1.json` -- works correctly
- `julia --project=benchmark benchmark/analysis/report.jl baseline.json after_p1.json --labels "baseline,after_p1"` -- works correctly
- Both produce well-formatted, readable output with correct speedup calculations
- Existing JSON result files load and parse correctly

### Via run.jl orchestrator: FAIL (2 bugs)

**Bug 1: `--compare` mode -- `judge(Trial, Trial)` MethodError** (run.jl:256)
- `run_compare()` calls `judge(results[idx], baseline)` on loaded BenchmarkGroups
- BenchmarkTools.judge recursively maps down to leaf nodes and calls `judge(Trial, Trial)`
- BenchmarkTools 1.7.0 has no `judge(Trial, Trial)` method -- it expects `TrialEstimate`
- Fix: Replace `judge(results[idx], baseline)` with `judge(minimum(results[idx]), minimum(baseline))`
  - `minimum()` on a BenchmarkGroup recursively maps to TrialEstimate at leaves

**Bug 2: `--report` mode -- World Age Error** (run.jl:302-303)
- `run_report()` does `include(...)` then immediately calls `generate_report(files)`
- Julia 1.12's stricter world age semantics prevent calling a function defined via `include()` in the same world context
- Error: `MethodError: no method matching generate_report(::Vector{String})` with "method too new" message
- Fix: Replace `generate_report(files)` with `Base.invokelatest(generate_report, files)`

## Structure Assessment

### Strengths
- **Comprehensive coverage**: All major TSFrames functions are benchmarked (construction, apply, resample, to_period, endpoints, lag/lead/diff, pctchange, rollapply, join, vcat)
- **Multi-scale testing**: Each suite tests small (100), medium (10k), and large (1M) data sizes
- **Deterministic data**: All suites use `MersenneTwister(42)` for reproducible benchmark data
- **Efficient construction**: TSFrames are created with `issorted=true, copycols=false` to avoid measuring construction overhead
- **Well-structured comparison**: compare.jl uses its own leaf-walking approach (avoiding the `judge` bug) with clear N-way comparison output
- **Report quality**: report.jl generates clean Markdown tables with bold speedup indicators and italic slowdown markers
- **Extensible design**: Adding new suites is straightforward -- create a file in `suites/`, define a const BenchmarkGroup, include in `benchmarks.jl`
- **Separate benchmark Project.toml**: Clean dependency isolation from the main project
- **Good CLI design**: The orchestrator supports --save, --group, --compare, --report, --tune, --verbose flags
- **PkgBenchmark compatible**: benchmarks.jl defines `SUITE` as the required constant

### Minor Issues
- `format_time` in run.jl uses `us` instead of the unicode `μs` (consistent across files, so this is a style choice -- acceptable)
- The `--compare` path in run.jl's arg parser uses `continue` to skip `i += 1`, which is correct but slightly fragile
- rollapply `std_w10` is excluded for large size but not documented in the summary output
- The `Speedup vs baseline` column in report.jl only shows the last result vs baseline -- for 3+ results, intermediate speedups are shown inline but the dedicated column only covers the last

### Extensibility for xKDR/TSFrames.jl comparison
- The N-way comparison design in compare.jl is well-suited for this: save a result from original xKDR, save one from this fork, and compare
- The label system allows meaningful names (`--label "xKDR,fork-v0.3.0"`)
- Would require running benchmarks against both packages separately and saving JSON results

## Issues Found

| # | Severity | File | Line | Description |
|---|----------|------|------|-------------|
| 1 | **High** | run.jl | 256 | `judge(Trial, Trial)` MethodError in --compare mode |
| 2 | **High** | run.jl | 302-303 | World age error in --report mode (Julia 1.12 incompatibility) |
| 3 | Low | run.jl | 113 | World age deprecation warning for `SUITE` binding access |
| 4 | Low | report.jl | 252 | Speedup column only shows last result vs baseline in N-way comparison |

## Verdict

**Approve with minor fixes required.**

The benchmark infrastructure design is solid and comprehensive. The standalone tools (compare.jl, report.jl) work correctly, and benchmarks execute properly. The two bugs in run.jl's `--compare` and `--report` CLI modes are straightforward to fix:

1. Line 256: `judge(results[idx], baseline)` -> `judge(minimum(results[idx]), minimum(baseline))`
2. Line 303: `generate_report(files)` -> `Base.invokelatest(generate_report, files)`

These are the only blockers. The overall architecture is clean, well-organized, and ready for production use after these fixes.
