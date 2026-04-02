# TSFrames.jl Codebase Analysis

_Generated: 2026-04-03_

## Key Findings

1. **21 source files (~3,848 LOC), 21 test files (~3,339 LOC), 1,775 tests across 20 testsets.**
   Well-structured with one file per feature and good docstrings.

2. **~47 exported names** including `TSFrame`, `apply`, `resample`, `endpoints`, `to_period`
   (+ 10 frequency shortcuts), `rollapply`, `diff`, `lag`, `lead`, `pctchange`,
   `join`/`cbind`, `vcat`/`rbind`, `subset`, `isregular`, `plot`, `Matrix`, etc.

3. **`upsample()` is defined but NOT exported and has NO tests.**
   File `src/upsample.jl` (75 lines) exists and is included in the module,
   but is missing from the export list and has no corresponding test file.

4. **Minimal test coverage for lag (26 lines), lead (25 lines), rollapply (33 lines).**
   These are functional but have the thinnest test suites in the project.
   Broadcasting (54 lines) is also basic.

5. **`resample()` is the newest and most optimized function.**
   Uses a zero-copy `@view` slice pattern with type-barrier helpers
   (`_build_index_out`, `_alloc_and_fill_col`) that achieve 73 allocations
   on 1M rows vs 659 for `apply()` — a 3.5x speedup.
   Three signatures: default OHLCV, Symbol pairs, String pairs.

6. **Benchmarks exist only internally** in `.claude/docs/benchmarks/`
   (1M row OHLCV for endpoints/apply/to_period/resample).
   The public `Benchmark.md` has older 500-row results and does not include `resample()`.
   No standard `bench/` or `benchmark/` directory exists.

7. **Future work from `tasks/todo.md`:**
   - P1 = eliminate `copy(coredata)` in `apply()` via @view pattern (3-4x potential)
   - P2 = gap-aware resampling (`fill_gaps=true`)
   - P3 = session-reset VWAP (Foxtail.jl)
   - P4 = `endpoints()` pre-allocation

8. **DateTime and Time indexes are under-tested.**
   Nearly all tests use `Date`. Irregular time series gap handling is
   not tested in resample/apply.

9. **`rename!` is defined (6+ method signatures in utils.jl) but NOT exported.**
   Users must qualify as `TSFrames.rename!()`.

10. **CI runs on Julia 1.12 + latest across ubuntu/windows/macos** with Codecov integration.
    Dependencies: DataFrames 1.8, ShiftedArrays 2, RecipesBase 1.3,
    RollingFunctions 0.8, StatsBase 0.34, Tables 1.

## Source Files Summary

| File | LOC | Purpose |
|------|-----|---------|
| TSFrames.jl | ~150 | Module root, exports, includes |
| TSFrame.jl | ~200 | Core struct definition |
| utils.jl | ~300 | Utility functions, rename! |
| apply.jl | ~250 | apply() function |
| resample.jl | ~300 | resample() - newest, most optimized |
| endpoints.jl | ~200 | endpoints() |
| to_period.jl | ~200 | to_period() |
| upsample.jl | ~75 | upsample() - orphaned |
| lag.jl | ~100 | lag() |
| lead.jl | ~100 | lead() |
| rollapply.jl | ~150 | rollapply() |
| (others) | varies | join, subset, diff, pctchange, etc. |

## Test Coverage Gaps

| Function | Test Lines | Status |
|----------|-----------|--------|
| resample | ~200 | Good |
| apply | ~150 | Good |
| endpoints | ~120 | Good |
| lag | ~26 | **Thin** |
| lead | ~25 | **Thin** |
| rollapply | ~33 | **Thin** |
| upsample | 0 | **Missing** |
| DateTime index | minimal | **Missing** |
| Time index | minimal | **Missing** |
| Irregular TS | minimal | **Missing** |

## Benchmark Status

| Location | Status |
|----------|--------|
| `Benchmark.md` | Public, but old (500-row, no resample) |
| `.claude/docs/benchmarks/bench_baseline.jl` | Internal, 1M row OHLCV |
| `.claude/docs/benchmarks/results_after_wave2.md` | Internal results |
| No `bench/` directory | Missing standard benchmark structure |

## Recommendations

1. **Export and test `upsample()`** — Currently orphaned
2. **Expand lag/lead/rollapply tests** — Minimal coverage is a risk
3. **Add DateTime/Time index tests** — Currently only Date is well-covered
4. **Create `bench/` directory structure** with:
   - Orchestrator script (run all or specific benchmarks)
   - Per-function benchmark scripts
   - Results analysis/comparison script
5. **Restructure public Benchmark.md** or replace with generated output
6. **Consider exporting `rename!`** — Useful utility
7. **Implement P1 from todo.md** — eliminate copy() in apply() (3-4x speedup potential)
