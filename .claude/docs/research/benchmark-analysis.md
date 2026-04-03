# TSFrames.jl Benchmark System Analysis

**Date**: 2026-04-03
**Scope**: Complete analysis of `benchmark/` directory structure, runners, suites, reports, and result data.

---

## 1. Directory Structure

```
benchmark/
  Project.toml              # Julia env for current (dev) version benchmarks
  Manifest.toml             # Resolved deps for dev benchmarks (Julia 1.12.5)
  benchmarks.jl             # PkgBenchmark entry point; defines SUITE constant
  run.jl                    # CLI orchestrator (run/compare/report modes)
  utils.jl                  # Shared utilities: format_time, collect_leaves, meta JSON, sorting

  baseline/
    Project.toml            # Julia env pinned to xKDR/TSFrames.jl v0.2.2
    Manifest.toml           # Resolved deps for v0.2.2 baseline

  suites/
    bench_construction.jl   # TSFrame() constructor variants
    bench_apply.jl          # apply() with period/function combos
    bench_resample_vs_to_period.jl  # resample() vs to_period() comparison
    bench_endpoints.jl      # endpoints() with various periods
    bench_lag_lead_diff.jl  # lag/lead/diff/pctchange
    bench_rollapply.jl      # rollapply() rolling window
    bench_join.jl           # join() inner/outer/left
    bench_vcat.jl           # vcat() with compatibility probes

  analysis/
    compare.jl              # N-way benchmark comparison (text output)
    report.jl               # Markdown report generator (table output)

  results/
    .gitkeep
    v0.2.2.json             # Baseline: xKDR v0.2.2 (~9.8 MB)
    v0.3.1.json             # Release v0.3.1 (~13 MB)
    v0.3.2.json             # Release v0.3.2 (~13 MB)
    v0.3.2.meta.json        # Sidecar metadata for v0.3.2
    baseline_apply.json     # Legacy: apply-only baseline (~1.8 MB)
    after_p1_apply.json     # Legacy: apply-only after P1 optimization (~2.1 MB)
    report_v0.3.1_vs_v0.2.2.md     # v0.3.1 vs v0.2.2 comparison report
    report_v0.3.2_vs_v0.2.2.md     # v0.3.2 vs v0.2.2 comparison report (latest)
    report_constructor_fix.md       # v0.2.2 / v0.3.1 / tmp-alpha 3-way report
```

---

## 2. Benchmark Runner Scripts

### 2.1 `run.jl` -- Main CLI Orchestrator

**Modes of operation:**
1. **Run mode** (default): Execute benchmark suite, print summary, optionally save JSON
2. **Compare mode** (`--compare`): Load 2+ JSON files, judge improvements/regressions
3. **Report mode** (`--report`): Generate Markdown table report from JSON files

**Key CLI flags:**
- `--save <path>` -- Save BenchmarkTools JSON
- `--desc <text>` -- Description for `.meta.json` sidecar
- `--group <g1,g2>` -- Filter to specific benchmark groups
- `--compare <f1> <f2> ...` -- N-way comparison
- `--report <f1> <f2> ...` -- Markdown report generation
- `--tune` -- Tune benchmark parameters before running
- `--verbose` -- Detailed progress output

**Save behavior:**
- Uses `BenchmarkTools.save()` for JSON serialization
- Automatically generates `.meta.json` sidecar with version/status/description/timestamp
- Filename parsing: `v0.3.2.json` -> release, `tmp-alpha.json` -> temporary

### 2.2 `benchmarks.jl` -- Suite Registration

Entry point that `include()`s all suite files and registers them into a global `SUITE` BenchmarkGroup.

**Registered groups (always):** construction, apply, endpoints, lag_lead_diff, rollapply, join
**Conditionally registered:** vcat (probe-guarded for DataFrames compat), resample_vs_to_period (guarded on `isdefined(TSFrames, :resample)`)

### 2.3 `utils.jl` -- Shared Utilities

**Functions:**
- `load_result(path)` -- Load BenchmarkTools JSON, return first BenchmarkGroup
- `format_time(ns)` -- Human-readable time (auto-selects ns/us/ms/s)
- `format_bytes(bytes)` -- Human-readable size (auto-selects bytes/KiB/MiB/GiB)
- `collect_leaves(bg, prefix)` -- Recursively collect all leaf benchmarks
- `navigate_leaf(bg, path)` -- Navigate by slash-separated path
- `save_meta(path; ...)` -- Write `.meta.json` sidecar
- `load_meta(path)` -- Load/infer meta from sidecar or filename
- `parse_result_key(path)` -- Sort key: (major, minor, patch, is_temporary, nato_rank)
- `sort_result_files(files)` -- Sort result files by version order

**NATO Phonetic Alphabet:** Used for sorting temporary files (tmp-alpha < tmp-bravo < ...).

### 2.4 `analysis/report.jl` -- Markdown Report Generator

Generates multi-column Markdown tables comparing N result files.

**Features:**
- Auto-sorts files by version using `sort_result_files()`
- Loads `.meta.json` for labels and WIP markers
- First column is baseline; subsequent columns show speedup/slowdown relative to baseline
- Speedup display: `**12.1 ms (3.7x faster)**` for improvements, `_1.93 ms (2.1x slower)_` for regressions
- Threshold: 5% change (1.05x) to qualify as improvement/regression; otherwise `~1.0x`
- Can filter to a specific group with `--group`

### 2.5 `analysis/compare.jl` -- Text Comparison

Similar to report.jl but outputs plain text format with per-leaf detail and a summary count.
Uses configurable regression threshold (default 5%).

---

## 3. Benchmark Suites

### 3.1 Dataset Sizes

| Suite | Small | Medium | Large |
|-------|-------|--------|-------|
| construction | 100 | 10,000 | 1,000,000 |
| apply | 100 | 10,000 | 1,000,000 |
| resample_vs_to_period | 100 | 10,000 | 1,000,000 |
| endpoints | 100 | 10,000 | 1,000,000 |
| lag_lead_diff | 100 | 10,000 | 1,000,000 |
| rollapply | 100 | 10,000 | **100,000** (reduced due to O(n*w) cost) |
| join | 100 | 10,000 | 1,000,000 |
| vcat | 100 | 10,000 | 1,000,000 |

All suites use `MersenneTwister(42)` for reproducible random data.
Data: cumulative random walk prices starting at 100.0, some suites add volume column.

### 3.2 Suite Details

**construction** (5 variants x 3 sizes = 15 benchmarks):
- `from_dataframe_with_index` -- TSFrame(df) where df has Index column
- `from_dataframe_first_col` -- TSFrame(df, :dates)
- `from_matrix_and_dates` -- TSFrame(matrix, dates)
- `from_vector_and_dates` -- TSFrame(vector, dates)
- `from_dataframe_sorted_nocopy` -- TSFrame(df; issorted=true, copycols=false) -- fast path

**apply** (7 variants x 3 sizes = 21 benchmarks):
- monthly_last, monthly_first, monthly_sum, monthly_mean
- weekly_last, weekly_mean
- yearly_first

**resample_vs_to_period** (up to 16 variants x 3 sizes = 48 benchmarks):
- `to_period/` subgroup (4): weekly, monthly, quarterly, yearly -- always present
- `resample_last/` subgroup (4): weekly_last, monthly_last, quarterly_last, yearly_last -- conditional
- `resample_mean/` subgroup (2): weekly_mean, monthly_mean -- conditional
- `resample_ohlcv/` subgroup (3): monthly_default, weekly_default, monthly_explicit -- conditional
- **Conditional on `isdefined(TSFrames, :resample)`** -- v0.2.2 lacks resample, so only to_period benchmarks exist for baseline

**endpoints** (6 variants x 3 sizes = 18 benchmarks):
- weekly, monthly, quarterly, yearly (Period-based)
- symbol_months, symbol_weeks (Symbol-based API)

**lag_lead_diff** (8 variants x 3 sizes = 24 benchmarks):
- lag_1, lag_5, lead_1, lead_5, diff_1, diff_5, pctchange_1, pctchange_5

**rollapply** (2-3 variants x 3 sizes = 7-8 benchmarks):
- mean_w5, sum_w20 (all sizes)
- std_w10 (small/medium only -- skipped for large due to benchmark time)

**join** (3 variants x 3 sizes = 9 benchmarks):
- inner, outer, left (with 50% overlapping date ranges)

**vcat** (up to 3 variants x 3 sizes = 9 benchmarks):
- same_cols_union, diff_cols_union, diff_cols_intersect
- **Probe-guarded**: runtime detection of which vcat variants work (v0.2.2 has insertcols! API incompatibility with DataFrames >= 1.4)

---

## 4. Result Files and Data Structure

### 4.1 JSON Format (BenchmarkTools native)

```json
[
  {"BenchmarkTools": "1.7.0", "Julia": "1.12.5"},
  [
    ["BenchmarkGroup", {
      "data": {
        "apply": ["BenchmarkGroup", {
          "data": {
            "large": ["BenchmarkGroup", {
              "data": {
                "monthly_first": ["Trial", {
                  "allocs": 33373,
                  "gctimes": [0.0, 0.0, ...],
                  "memory": 3145872,
                  "params": {...},
                  "times": [7531234.0, ...]
                }]
              }
            }]
          }
        }]
      }
    }]
  ]
]
```

Structure: nested BenchmarkGroup with Trial objects at leaves. Each Trial contains:
- `times`: array of raw nanosecond measurements
- `gctimes`: corresponding GC times
- `allocs`: allocation count
- `memory`: memory in bytes
- `params`: BenchmarkTools parameters

### 4.2 Meta JSON Sidecar (`.meta.json`)

```json
{
  "version": "0.3.2",
  "suffix": "",
  "status": "release",
  "label": "v0.3.2",
  "description": "constructor fix: Base.issorted fast path",
  "timestamp": "2026-04-03T12:08:22"
}
```

Only v0.3.2 has an explicit `.meta.json`. Others are inferred from filename.

### 4.3 File Inventory

| File | Size | Content | Has Meta |
|------|------|---------|----------|
| v0.2.2.json | 9.8 MB | All groups except resample_* and diff_cols_intersect | No (inferred) |
| v0.3.1.json | 13 MB | All groups including resample_* and diff_cols_intersect | No (inferred) |
| v0.3.2.json | 13 MB | All groups including resample_* | Yes (.meta.json) |
| baseline_apply.json | 1.8 MB | apply group only (legacy) | No |
| after_p1_apply.json | 2.1 MB | apply group only (legacy) | No |

**Size difference**: v0.3.1/v0.3.2 are ~3 MB larger than v0.2.2 because they contain resample_vs_to_period benchmarks (resample_last, resample_mean, resample_ohlcv subgroups) and diff_cols_intersect vcat benchmark.

### 4.4 Baseline Environment (v0.2.2)

`benchmark/baseline/Project.toml` pins TSFrames to xKDR/TSFrames.jl at tag v0.2.2.
It has explicit compat bounds for DataFrames, RollingFunctions, ShiftedArrays.
The baseline environment is a separate Julia project that can be activated independently.

---

## 5. Report Structure

### 5.1 Latest Report: `report_v0.3.2_vs_v0.2.2.md`

3-column comparison: v0.2.2 (baseline) | v0.3.1 | v0.3.2
Covers 7 groups: apply, construction, endpoints, join, lag_lead_diff, resample_vs_to_period, rollapply, vcat.

### 5.2 Report Column Format

- **Baseline (first column)**: Plain time value (e.g., `7.53 ms`)
- **Subsequent columns**: Time + relative speedup
  - Improvement: `**937.88 us (8.0x faster)**` (bold)
  - Regression: `_1.93 ms (2.1x slower)_` (italic)
  - Invariant: `2.21 ms (~1.0x)` (plain)
  - Missing: `N/A` (benchmark not present in that version)

---

## 6. Issues Found

### 6.1 CRITICAL: 0 ns Bug in endpoints/small/symbol_weeks

In `report_v0.3.2_vs_v0.2.2.md` line 70:
```
| small/symbol_weeks | 0.0 ns | _125.0 ns (125000.0x slower)_ | _125.0 ns (125000.0x slower)_ |
```

**Root cause**: The v0.2.2 baseline reports `0.0 ns` for `endpoints(ts, :weeks)` with the "small" (n=100) dataset. This is almost certainly a measurement artifact -- the operation is so fast on 100 rows that BenchmarkTools rounds to 0 ns. This produces a mathematically absurd speedup ratio of `125000.0x slower` for v0.3.1/v0.3.2.

**Impact**: Misleading report data. The `format_time` function handles `ns < 1000` fine, but the division `baseline_time / t` when `baseline_time = 0` is avoided by the `baseline_time > 0` guard in report.jl. However the inverse case (0 in baseline) produces `speedup = 0 / 125 = 0` which triggers the slowdown display: `t / baseline_time = 125 / 0 = Inf` -- but actually, looking at the code, `baseline_time / t = 0 / 125 = 0` which is `< 1/1.05 = 0.952`, so it's flagged as "slower". The `slowdown = t / baseline_time` would be `125 / 0 = Inf`, but the display shows `125000.0x` which means baseline_time is actually stored as something tiny like 0.001 ns rather than exactly 0.

**Also appears in**: `small/symbol_months` shows v0.2.2 = 125.0 ns, v0.3.1 = 208.0 ns -- this is likely noise at this scale. And `small/quarterly` shows v0.2.2 = 84.0 ns.

**Recommendation**: Either (a) add a floor threshold in report generation (skip or warn for benchmarks < ~10 ns) or (b) remove small-dataset benchmarks for endpoints/symbol_* which are too fast to measure meaningfully.

### 6.2 Missing resample Data for v0.2.2

In all reports, the resample_vs_to_period group shows `N/A` for all resample_last, resample_mean, and resample_ohlcv benchmarks when comparing with v0.2.2.

**Root cause**: This is **expected behavior**, not a bug. TSFrames v0.2.2 (xKDR) does not export `resample()`. The suite correctly guards this with `const _HAS_RESAMPLE = isdefined(TSFrames, :resample)` and omits those sub-groups when running against v0.2.2. The report correctly shows `N/A`.

**However**: This means v0.2.2 results only contain `to_period/*` benchmarks within the resample_vs_to_period group, while v0.3.x contains all 4 sub-groups. Cross-version resample performance comparison is impossible.

### 6.3 Missing `.meta.json` for Most Result Files

Only `v0.3.2.json` has an explicit `.meta.json` sidecar. The other files (v0.2.2, v0.3.1) rely on filename inference via `_infer_meta_from_filename()`. This works correctly for `v{major}.{minor}.{patch}` patterns but means there's no description or timestamp recorded for older results.

### 6.4 Legacy apply-only Result Files

`baseline_apply.json` and `after_p1_apply.json` are legacy files from earlier profiling. They only contain the `apply` group and follow a different naming convention. They are not used by any current reports but still take up ~4 MB.

### 6.5 No resample_vs_to_period in v0.3.2 Report

In `report_v0.3.2_vs_v0.2.2.md`, the resample_vs_to_period section only shows `to_period/*` entries. All resample_* entries are missing. This is because the report uses v0.2.2 as the reference (first file) and v0.2.2 only has to_period leaves. The report iterates over `ref_idx` leaves only, so any benchmarks that exist in v0.3.x but not in v0.2.2 are silently omitted.

This is different from the v0.3.1 report which was generated with v0.3.1 as the first file (baseline), so resample entries showed up with N/A for v0.2.2. The report generation ordering matters significantly for what appears.

### 6.6 vcat diff_cols_intersect Missing in v0.3.2 Report

In `report_v0.3.2_vs_v0.2.2.md`, the vcat group is missing `diff_cols_intersect`. This is present in v0.3.1 but absent from the v0.3.2 report. Since v0.2.2 is the reference and v0.2.2 doesn't have `diff_cols_intersect` (due to vcat probe failure on v0.2.2), it won't appear.

### 6.7 Potential Measurement Concerns at Small Scale

Several small-dataset benchmarks show times in the sub-microsecond range (83 ns, 125 ns, 458 ns). At these scales, BenchmarkTools quantization artifacts dominate. The 458.0 ns exact value appearing multiple times for `from_dataframe_sorted_nocopy` across all versions suggests timer resolution rather than actual performance.

---

## 7. How Reports Are Generated

### Command Examples

```bash
# Run all benchmarks and save
julia benchmark/run.jl --save benchmark/results/v0.3.2.json --desc "constructor fix"

# Generate comparison report
julia benchmark/run.jl --report benchmark/results/v0.2.2.json benchmark/results/v0.3.1.json benchmark/results/v0.3.2.json

# Or directly via analysis/report.jl
julia benchmark/analysis/report.jl \
  benchmark/results/v0.2.2.json \
  benchmark/results/v0.3.1.json \
  benchmark/results/v0.3.2.json \
  --output benchmark/results/report_v0.3.2_vs_v0.2.2.md
```

### Report Generation Flow

1. `run.jl --report` calls `run_report(files)` which includes `analysis/report.jl`
2. `generate_report(files)` is invoked:
   a. Files are sorted by version via `sort_result_files()`
   b. JSON results loaded via `BenchmarkTools.load()`
   c. Metadata loaded for WIP markers
   d. Iterates over top-level groups from the **first** (baseline) result
   e. For each group, iterates over leaf paths from the first non-nothing result
   f. Builds markdown table with speedup calculations
3. Output written to file or stdout

### Critical Report Behavior

The report uses the **first file** as the reference for discovering benchmark paths. Any benchmarks that exist only in later versions but not in the first file will be **silently omitted**. This is why the file ordering matters:

- `v0.2.2.json` first -> resample_* benchmarks hidden (v0.2.2 lacks them)
- `v0.3.1.json` first -> resample_* visible, v0.2.2 shows N/A

---

## 8. Baseline (v0.2.2) Setup

The `benchmark/baseline/` directory contains a separate Julia project environment:

- `Project.toml`: Pins `TSFrames` to `{url = "https://github.com/xKDR/TSFrames.jl", rev = "v0.2.2"}`
- Explicit compat: `DataFrames = "1.3, 1.4, 1.5, 1.6, 1.7"`, `TSFrames = "0.2"`
- To run baseline benchmarks, activate this environment and run the suite

The v0.2.2 results were generated against this pinned environment. Key differences from current version:
- No `resample()` function
- vcat `diff_cols_intersect` not supported (DataFrames API incompatibility)
- Slower apply/lag_lead_diff/pctchange/rollapply performance

---

## 9. Performance Summary (v0.3.2 vs v0.2.2)

| Area | Improvement |
|------|-------------|
| apply (small) | 48-54x faster |
| apply (medium) | 9-21x faster |
| apply (large) | 7-15x faster |
| lag/lead (all sizes) | 1.8-2.7x faster |
| diff (all sizes) | 1.4-2.5x faster |
| pctchange (all sizes) | 1.9-3.1x faster |
| rollapply (medium/large) | 1.2-2.5x faster |
| construction (matrix/vector) | Fixed regression from v0.3.1 (back to ~1.0x) |
| to_period (all sizes) | 1.1-3.3x faster |
| endpoints | ~1.0x (no change) |
| join | ~1.0x (no change, small improvement at small scale) |
| vcat | ~1.0x (no change) |

---

## 10. Recommendations

1. **Fix 0 ns bug**: Add minimum time threshold in report.jl to skip or flag benchmarks with baseline < 1 ns
2. **Union-based leaf discovery**: Change report.jl to discover leaves from ALL result files (union), not just the first, to avoid silently hiding new benchmarks
3. **Add `.meta.json` for all results**: Generate meta files for v0.2.2 and v0.3.1 retroactively
4. **Clean up legacy files**: Consider removing or archiving `baseline_apply.json` and `after_p1_apply.json`
5. **Consider removing small-scale endpoint benchmarks**: Sub-100ns measurements are unreliable
