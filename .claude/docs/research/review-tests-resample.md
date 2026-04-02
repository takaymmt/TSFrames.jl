# Test Coverage Review: resample() in TSFrames.jl

**Date**: 2026-04-03
**Reviewer**: Opus subagent (test-reviewer)
**Status**: All 42 existing tests PASS

---

## 1. Existing Test Coverage Summary

| Testset | # Assertions | Coverage Area |
|---------|-------------|---------------|
| resample default OHLCV | 14 | Weekly + Monthly default aggregation, all 5 OHLCV columns |
| resample index_at | 2 | `first` and `last` index selection |
| resample Symbol pairs | 5 | Custom `:Symbol => fn` aggregation (multi-col, single-col, mean) |
| resample String pairs | 3 | `"String" => fn` convenience overload |
| resample renamecols | 2 | `renamecols=false` (default) and `renamecols=true` |
| resample errors | 3 | Missing column (Symbol + String), no OHLCV columns |
| resample partial OHLCV | 3 | Default mode with only Open + Close present |
| resample consistency with apply | 3 | Single-column resample matches apply() output |
| resample output is TSFrame | 2 | Return type and index element type check |

**Total**: 42 assertions across 9 testsets.

---

## 2. Quality Assessment

### Strengths

- **Well-documented test data**: The 28-day dataset is clearly explained with group boundaries (lines 8-14).
- **Descriptive testset names**: Each testset maps to a specific feature/behavior.
- **Independent tests**: No shared mutable state; `ts_ohlcv` and `ts_single` are module-level constants.
- **Value verification**: Tests check actual computed values, not just shapes.
- **Cross-validation**: Consistency test against `apply()` ensures backward compatibility.
- **Both key types tested**: Symbol and String pair interfaces both covered.

### Weaknesses

- **No boundary/edge case tests**: Empty TSFrame, single-row, single-group not tested.
- **Only `Date` index type**: No `DateTime` tests.
- **No custom `index_at` function test**: Only `first` and `last` are tested.
- **No duplicate index test**: Behavior with repeated timestamps not verified.
- **`_alloc_and_fill_col` single-group path not explicitly tested**: When `ep[1]==nrow`, the `for g in 2:n` loop body is never entered.

---

## 3. Coverage Gaps and Missing Tests

### GAP-1: Empty TSFrame (BUG FOUND)
- **Priority**: HIGH
- **File/Function**: `src/endpoints.jl:310` (called by `src/resample.jl:119`)
- **Issue**: `endpoints()` calls `first(timestamps)` on an empty vector, throwing `BoundsError(Date[], (1,))`. The `n == 0` guard in `_resample_core` (line 125) is **dead code** -- it can never be reached.
- **Root cause**: `endpoints(timestamps::AbstractVector{T}, on::V)` at line 310 does `floor(first(timestamps), ...)` without checking `isempty(timestamps)`.
- **Impact**: Any call to `resample(empty_tsframe, period)` crashes.
- **Test needed**:
  ```julia
  @testset "resample empty TSFrame" begin
      ts_empty = TSFrame(DataFrame(Open=Float64[], Close=Float64[]), Date[])
      result = resample(ts_empty, Week(1))
      @test DataFrames.nrow(result.coredata) == 0
      @test names(result) == ["Open", "Close"]
  end
  ```
- **Fix required**: Either guard in `endpoints()` (return `Int[]` for empty input) or guard in `resample()` before calling `endpoints()`.

### GAP-2: Single-Row TSFrame
- **Priority**: MEDIUM
- **File/Function**: `src/resample.jl` -- `_alloc_and_fill_col` single-group path
- **Issue**: When there is exactly 1 row, `endpoints` returns `[1]`, so `n=1` and `ep[1]==nrow`. The `_alloc_and_fill_col` loop `for g in 2:n` is never entered. This path works (verified manually) but has no test.
- **Test needed**:
  ```julia
  @testset "resample single row" begin
      ts_1 = TSFrame(DataFrame(Open=[1.0], High=[2.0], Low=[0.5], Close=[1.5], Volume=[100]), [Date(2020,1,1)])
      r = resample(ts_1, Week(1))
      @test DataFrames.nrow(r.coredata) == 1
      @test r[:, :Open][1] == 1.0
      @test r[:, :High][1] == 2.0
      @test r[:, :Close][1] == 1.5
      @test r[:, :Volume][1] == 100
  end
  ```

### GAP-3: DateTime Index
- **Priority**: MEDIUM
- **File/Function**: `src/resample.jl` -- all methods (index type polymorphism)
- **Issue**: All tests use `Date` index. `DateTime` is a common real-world use case (intraday data). The code should work due to generic typing, but it is untested.
- **Test needed**:
  ```julia
  @testset "resample DateTime index" begin
      dts = collect(DateTime(2020,1,1):Hour(1):DateTime(2020,1,2,23))
      ts_dt = TSFrame(DataFrame(Open=Float64.(1:48), Close=Float64.(1:48).+0.5), dts)
      r = resample(ts_dt, Day(1))
      @test DataFrames.nrow(r.coredata) == 2
      @test eltype(r.coredata[:, :Index]) <: DateTime
      @test r[:, :Open][1] == 1.0   # first hour of day 1
      @test r[:, :Close][2] == 48.5 # last hour of day 2
  end
  ```

### GAP-4: Custom `index_at` Function
- **Priority**: LOW
- **File/Function**: `src/resample.jl:137` -- `_build_index_out`
- **Issue**: Only `first` and `last` are tested. A user-supplied function (e.g., pick middle element) is not tested.
- **Test needed**:
  ```julia
  @testset "resample custom index_at" begin
      mid(v) = v[div(length(v)+1, 2)]
      r = resample(ts_ohlcv, Week(1); index_at=mid)
      @test r.coredata[1, :Index] == Date(2020, 1, 3)  # mid of 5-element group
  end
  ```

### GAP-5: Period Longer Than Data Span (Single Group)
- **Priority**: LOW
- **File/Function**: `src/resample.jl` -- `_alloc_and_fill_col` and `_build_index_out`
- **Issue**: When `period` exceeds data span, all rows collapse into one group. This is the same code path as single-group, but it's a distinct user scenario.
- **Test needed**:
  ```julia
  @testset "resample period exceeds data span" begin
      r = resample(ts_ohlcv, Year(1))
      @test DataFrames.nrow(r.coredata) == 1
      @test r[:, :Open][1] == 1.0
      @test r[:, :High][1] == maximum(Float64.(2:29))
      @test r[:, :Close][1] == 28.5
      @test r[:, :Volume][1] == sum(100:127)
  end
  ```

### GAP-6: Duplicate Index Values
- **Priority**: LOW
- **File/Function**: `src/resample.jl` -- interaction with `endpoints()`
- **Issue**: Duplicate timestamps are valid in some financial datasets (e.g., multiple trades at the same second). Behavior is undefined/untested.
- **Test needed**:
  ```julia
  @testset "resample duplicate index" begin
      dup_dates = [Date(2020,1,1), Date(2020,1,1), Date(2020,1,2), Date(2020,1,2)]
      ts_dup = TSFrame(DataFrame(Open=Float64.(1:4), Close=Float64.(1:4).+0.5), dup_dates)
      r = resample(ts_dup, Week(1))
      @test DataFrames.nrow(r.coredata) == 1
      @test r[:, :Open][1] == 1.0   # first of all 4 rows
      @test r[:, :Close][1] == 4.5  # last of all 4 rows
  end
  ```

---

## 4. Bug Report

### BUG: Empty TSFrame causes BoundsError in endpoints()

- **Severity**: Medium (crashes on valid edge case input)
- **Location**: `src/endpoints.jl`, line 310
- **Trigger**: `resample(empty_tsframe, any_period)`
- **Error**: `BoundsError(Date[], (1,))`
- **Root cause**: `first(timestamps)` called without empty-check
- **Dead code**: `_resample_core` lines 125-133 (`if n == 0`) can never execute
- **Suggested fix**: Add early return in `endpoints()`:
  ```julia
  # At start of endpoints(timestamps::AbstractVector{T}, on::V)
  isempty(timestamps) && return Int[]
  ```

---

## 5. Internal Function Coverage

| Function | Tested? | Notes |
|----------|---------|-------|
| `resample(ts, period)` (default OHLCV) | Yes | Weekly + Monthly |
| `resample(ts, period, ::Pair{Symbol}...)` | Yes | Multi-col, single-col, custom fn |
| `resample(ts, period, ::Pair{String}...)` | Yes | Delegates to Symbol version |
| `_resample_core` | Yes (indirectly) | All paths except n=0 |
| `_build_index_out` | Yes (indirectly) | Via index_at tests |
| `_alloc_and_fill_col` | Yes (indirectly) | Multi-group path; single-group not explicitly tested |
| `_OHLCV_DEFAULT_AGG` | Yes (indirectly) | Via default OHLCV tests |

---

## 6. Recommendations (Prioritized)

1. **HIGH**: Fix the `endpoints()` empty-vector bug and add empty TSFrame test.
2. **MEDIUM**: Add single-row TSFrame test (exercises `_alloc_and_fill_col` single-group path).
3. **MEDIUM**: Add DateTime index test (validates index type polymorphism).
4. **LOW**: Add custom `index_at` function test.
5. **LOW**: Add period-exceeds-span test.
6. **LOW**: Add duplicate index test (document expected behavior).
