# Quality Review: resample() Implementation

**Date**: 2026-04-03
**Reviewer**: Opus subagent (quality-reviewer)
**Files reviewed**:
- `src/resample.jl` (new, 198 lines)
- `src/apply.jl` (modified, `_build_groupindices` extracted)
- `src/to_period.jl` (modified, `issorted`/`copycols` optimization)
- `test/resample.jl` (new, 183 lines)

**Test status**: All 42 resample tests pass. Full suite (1,769 tests) passes.

---

## Finding 1: Empty TSFrame triggers BoundsError in endpoints(), not ArgumentError

- **Severity**: High
- **File**: `src/resample.jl` lines 119-133, `src/endpoints.jl` lines 306-351
- **Current approach**: `_resample_core` has an `n == 0` guard (line 125) that handles the case when `endpoints()` returns an empty vector. However, `endpoints(timestamps, period)` calls `first(timestamps)` at line 310 of `endpoints.jl`, which throws a `BoundsError` on an empty vector *before* `resample` ever gets to check `n == 0`.
- **Impact**: The empty-TSFrame code path in `_resample_core` (lines 125-133) is dead code. An empty TSFrame will crash with a confusing `BoundsError` from `endpoints.jl` rather than returning an empty TSFrame.
- **Suggested improvement**: Add an early-return guard in `resample()` (or `_resample_core`) *before* calling `endpoints()`:
  ```julia
  if nrow(ts) == 0
      # build empty result directly
  end
  ```
- **Note**: This is not a regression -- `apply()` and `to_period()` have the same upstream issue with `endpoints()`. But it means the empty-TSFrame handling code is untestable in its current form. The test suite has no empty-TSFrame test for `resample()`.

## Finding 2: _alloc_and_fill_col type inference from first group only

- **Severity**: Medium
- **File**: `src/resample.jl` lines 84-100
- **Current approach**: The output element type is inferred from `fn(@view src[1:ep[1]])` (line 90-91). If the first group produces a different type than later groups (e.g., `fn` returns `Int` for first group but `Float64` for others), this will throw an `InexactError` or silently narrow.
- **Impact**: In practice, this is unlikely for OHLCV data (homogeneous Float64/Int columns), but a user could pass a custom `fn` that returns heterogeneous types. For example, a function that returns `missing` for small groups and a number otherwise.
- **Suggested improvement**: Document this contract explicitly: "The aggregation function must return a type-stable result across all groups." Alternatively, use `promote_type` or `Base.return_types` for a defensive fallback, but that would add complexity for an edge case.

## Finding 3: No test for empty TSFrame

- **Severity**: Medium
- **File**: `test/resample.jl`
- **Current approach**: No test covers empty TSFrame input or single-row TSFrame input.
- **Impact**: Related to Finding 1 -- the dead code in `_resample_core` lines 125-133 is untested.
- **Suggested improvement**: Add tests:
  ```julia
  @testset "resample edge cases" begin
      # Single-row TSFrame
      ts1 = TSFrame(DataFrame(Open=[1.0], Volume=[100]), [Date(2020,1,1)])
      r = resample(ts1, Week(1))
      @test nrow(r.coredata) == 1

      # Empty TSFrame (once endpoints() is fixed or early guard added)
      # ts0 = TSFrame(Date, [(Float64, :Open)])
      # r0 = resample(ts0, Week(1))
      # @test nrow(r0.coredata) == 0
  end
  ```

## Finding 4: renamecols default inconsistency between apply() and resample()

- **Severity**: Low
- **File**: `src/resample.jl` line 162 vs `src/apply.jl` line 148
- **Current approach**: `apply()` defaults `renamecols=true` (column names become `x1_first`), while `resample()` defaults `renamecols=false` (column names stay as `Open`, `Close`, etc.).
- **Impact**: This is a deliberate design choice documented in the docstring -- OHLCV resampling should preserve original names. The difference is justified but could surprise users who switch between `apply()` and `resample()`.
- **Suggested improvement**: Add a note in the docstring: "Note: unlike `apply()`, `renamecols` defaults to `false`."

## Finding 5: @inline on type-barrier helpers is appropriate

- **Severity**: Low (positive finding)
- **File**: `src/resample.jl` lines 64, 84
- **Current approach**: `@inline` is applied to `_build_index_out` and `_alloc_and_fill_col`. These are small functions called from a loop in `_resample_core` (once per column).
- **Assessment**: Appropriate. These are called a small number of times (once per column, 1-5 for OHLCV), and inlining them into `_resample_core` helps the compiler see through the type barrier at the call site. The functions are small enough that inlining cost is negligible.

## Finding 6: copycols=false usage is safe

- **Severity**: Low (positive finding)
- **File**: `src/resample.jl` line 152, `src/to_period.jl` line 27
- **Assessment**: In `resample.jl`, the DataFrame is built from freshly allocated vectors (`index_out`, `dst`), so `copycols=false` avoids a redundant copy with no aliasing risk. In `to_period.jl`, `tsf.coredata[ep, :]` performs row-indexing which always creates new column vectors, so `copycols=false` is also safe. Both usages are correct.

## Finding 7: Well-structured type parameterization

- **Severity**: Low (positive finding)
- **File**: `src/resample.jl` lines 112-118
- **Current approach**: `_resample_core` uses `where {T<:Dates.Period, P, IA<:Function}` to force specialization on:
  - `T` (period type) -- standard Julia pattern
  - `P` (col_agg_pairs concrete tuple type) -- enables union-splitting on OHLCV tuple
  - `IA` (index_at function type) -- avoids dynamic dispatch in index loop
- **Assessment**: This is idiomatic Julia performance engineering. The type barriers (`_build_index_out`, `_alloc_and_fill_col`) correctly isolate the hot loops behind function barriers where the compiler can specialize on column element types.

## Finding 8: String pairs overload delegates cleanly

- **Severity**: Low (positive finding)
- **File**: `src/resample.jl` lines 188-197
- **Current approach**: The `String => Function` overload converts to `Symbol => Function` and delegates. This is clean and avoids code duplication.
- **Minor note**: The conversion `Tuple(Symbol(col) => fn for (col, fn) in col_agg_pairs)` creates a Tuple via generator. This is fine for the small number of pairs expected.

## Finding 9: Missing column validation asymmetry

- **Severity**: Low
- **File**: `src/resample.jl` lines 164-168 vs 180-182
- **Current approach**: Default OHLCV mode (no pairs) requires at least one OHLCV column to exist and silently skips missing ones. Explicit Symbol pairs mode requires ALL specified columns to exist and throws `ArgumentError` for any missing column.
- **Assessment**: This is correct behavior -- different semantics for different use cases. Default mode is "best effort" (some columns may not exist), explicit mode is "user specified these so they must exist." The docstring documents this.

## Finding 10: _build_groupindices in apply.jl could use @inbounds

- **Severity**: Low
- **File**: `src/apply.jl` lines 138-146
- **Current approach**: The loop `gi[j:ep[i]] .= ep[i]` does bounds checking on every iteration.
- **Impact**: Minor performance difference since `apply()` uses DataFrames `groupby`/`combine` which dominates runtime.
- **Suggested improvement**: Add `@inbounds` if profiling shows it matters; not urgent.

## Finding 11: No test for DateTime index type

- **Severity**: Low
- **File**: `test/resample.jl`
- **Current approach**: All tests use `Date` index. No tests verify `DateTime` or `Time` index types.
- **Suggested improvement**: Add at least one `DateTime` test to verify the generic path works.

---

## Summary

| Severity | Count | Key Items |
|----------|-------|-----------|
| High     | 1     | Empty TSFrame BoundsError (dead code path) |
| Medium   | 2     | Type inference from first group; missing edge case tests |
| Low      | 8     | renamecols inconsistency doc, DateTime tests, positive findings |

### Overall Assessment

The implementation is **well-engineered** with idiomatic Julia patterns:
- Type barriers for specialization are correctly applied
- `copycols=false` usage is safe in all cases
- The multi-dispatch API (default OHLCV / Symbol pairs / String pairs) is clean
- Test coverage is good for the main paths (42 tests)

The one **actionable high-severity issue** is the empty-TSFrame dead code path. The guard in `_resample_core` can never be reached because `endpoints()` crashes first on empty input. This should be fixed by adding an early guard before calling `endpoints()`, and adding a corresponding test.
