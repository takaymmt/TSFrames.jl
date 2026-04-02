# Security Review: resample() Implementation in TSFrames.jl

**Date**: 2026-04-03
**Reviewer**: Security Reviewer (Opus subagent)
**Scope**: `src/resample.jl` (new), `src/apply.jl` (modified), `src/to_period.jl` (modified), `test/resample.jl` (new), `Project.toml` (modified)

---

## Executive Summary

The resample() implementation is well-structured with good type specialization and performance characteristics. No critical vulnerabilities were found. There are several medium and low severity findings related to `@inbounds` safety, dependency hygiene, edge-case handling, and a theoretical infinite-loop vector in `get_tmp_colname`. Overall the code is production-quality for a numerical computing library.

---

## Findings

### Finding 1: `@inbounds` in `_build_index_out` and `_alloc_and_fill_col` relies on `endpoints()` correctness

- **Severity**: Medium
- **File**: `src/resample.jl`, lines 72-76 and 95-98
- **Description**: Both hot loops use `@inbounds` to skip bounds checking. The loop accesses `idx[j:ep[g]]` and `src[j:ep[g]]` where `j` and `ep[g]` are derived from the `endpoints()` function. If `endpoints()` ever returns values that are out of range (e.g., exceeding `length(idx)`), negative, or non-monotonically-increasing, this would cause silent memory corruption or segfault rather than a clean BoundsError.

  The `endpoints()` function in `src/endpoints.jl` does validate `on.value > 0` and handles edge cases, but there is no defensive check in `_resample_core` that validates the `ep` vector before passing it to `@inbounds` loops. A bug in `endpoints()`, or a future refactor, could introduce silent OOB access.

  Additionally, if `ep` contains consecutive equal values (which shouldn't happen normally but could from a bug), `j > ep[g]` would create an empty range which is benign, but `j` advancing past the end of the array in subsequent iterations would be problematic under `@inbounds`.

- **Recommended Fix**: Add a debug-mode assertion (using `@assert` or a conditional check gated behind a `DEBUG` constant) before the `@inbounds` loops to validate:
  1. `all(ep .>= 1)`
  2. `last(ep) == length(idx)` (or `length(src)`)
  3. `issorted(ep)` and `allunique(ep)`

  This preserves the zero-overhead property in release mode while catching invariant violations during development.

---

### Finding 2: BenchmarkTools in `[deps]` instead of `[extras]`

- **Severity**: Medium
- **File**: `Project.toml`, line 9
- **Description**: `BenchmarkTools` is listed in the `[deps]` section but is never imported in any source file under `src/`. It is only referenced in `.claude/docs/benchmarks/` files. This means every user who adds TSFrames.jl to their project will download and precompile BenchmarkTools (and its transitive dependencies), increasing install time and package load time unnecessarily.

  From a security perspective, unnecessary dependencies increase the attack surface -- if BenchmarkTools or any of its dependencies were compromised, all TSFrames users would be affected even though the functionality is unused at runtime.

- **Recommended Fix**: Move `BenchmarkTools` from `[deps]` to `[extras]` and add it to the test targets, or remove it entirely if only used for ad-hoc benchmarking outside the package.

---

### Finding 3: No empty-TSFrame test for `resample()`

- **Severity**: Low
- **File**: `src/resample.jl`, lines 125-133 and `test/resample.jl`
- **Description**: The code has an explicit empty-TSFrame handler in `_resample_core` (lines 125-133) that returns an empty TSFrame when `endpoints()` returns an empty vector. However, there is no test exercising this path. The empty-TSFrame path contains logic that could silently break (e.g., if `eltype(idx)` changes behavior for empty vectors, or if `eltype(coredata[!, col])` fails on a column with `Missing` type).

  Additionally, the `_alloc_and_fill_col` function (line 90) computes `fn(@view src[1:ep[1]])` as its first operation. If `ep` is somehow non-empty but `ep[1] == 0`, this would be a zero-length or invalid view. The empty check at line 125 guards against `n == 0`, but not against pathological `ep` values.

- **Recommended Fix**: Add test cases for:
  1. Empty TSFrame input (0 rows)
  2. Single-row TSFrame input (1 row, 1 group)
  3. TSFrame where all rows belong to one period group

---

### Finding 4: `get_tmp_colname` theoretical infinite loop

- **Severity**: Low
- **File**: `src/apply.jl`, lines 164-171
- **Description**: The `get_tmp_colname` function increments `idx` in a `while` loop looking for a column name not in `cols`. Since `idx` is an `Int`, this could theoretically loop up to `typemax(Int)` times (~9.2e18 iterations) if the column set somehow contained all possible names `"tmp01910"`, `"tmp01911"`, ... This is practically impossible but violates the principle of bounded computation.

  This is a pre-existing issue (not introduced by the resample PR) but worth noting since `apply.jl` is in scope.

- **Recommended Fix**: Add a loop bound (e.g., `if idx > 10_000; error("..."); end`) or use a UUID-based naming strategy.

---

### Finding 5: `@eval` macro in `to_period.jl` -- metaprogramming safety

- **Severity**: Low
- **File**: `src/to_period.jl`, lines 30-47
- **Description**: The `@eval` loop generates 11 convenience functions from a hardcoded list of `(fname, PType)` pairs. This is a standard Julia metaprogramming pattern and is safe because:
  1. The input data is a compile-time constant literal array
  2. No user input flows into the `@eval`
  3. The generated code is simple delegation to `endpoints()`

  There is no injection risk here. The pattern is equivalent to manually writing 11 functions.

- **Recommended Fix**: None required. This is safe as-is.

---

### Finding 6: User-supplied aggregation function execution

- **Severity**: Low
- **File**: `src/resample.jl`, lines 84-100 (and lines 173-184)
- **Description**: The `resample()` API accepts arbitrary `Function` objects as aggregation functions (e.g., `:Open => my_func`). These functions are called with `@view` slices of column data. A malicious or buggy function could:
  1. Throw exceptions (handled by Julia's normal exception propagation)
  2. Mutate the view's underlying data (views are mutable by default)
  3. Perform side effects (I/O, network calls, etc.)

  This is inherent to Julia's design -- functions are first-class and there is no sandboxing mechanism. This is the same risk as `combine()`, `map()`, or any higher-order function in the ecosystem. It is not specific to this implementation.

- **Recommended Fix**: No fix needed for a data processing library. Document that user-supplied functions should be pure and not mutate their input. If immutability is desired, consider wrapping column slices in `ReadOnlyArrays` (from ReadOnlyArrays.jl), but this would add a dependency and reduce performance.

---

### Finding 7: `issorted=true, copycols=false` in TSFrame construction from resample

- **Severity**: Low
- **File**: `src/resample.jl`, line 152
- **Description**: The final `TSFrame(df, :Index; issorted=true, copycols=false)` call bypasses sorting and copying for performance. This is correct because:
  1. The index is built in order from `endpoints()` which returns sorted indices
  2. The data is freshly allocated in `_alloc_and_fill_col`

  However, if `copycols=false` means the caller could later mutate the internal arrays of the returned TSFrame (since no defensive copy was made). This is a documented behavior of TSFrame's constructor and is the standard pattern used throughout the codebase (e.g., `to_period.jl` line 27).

- **Recommended Fix**: None required. This matches existing codebase conventions.

---

### Finding 8: No validation that `index_at` returns a scalar

- **Severity**: Low
- **File**: `src/resample.jl`, lines 64-77
- **Description**: The `index_at` parameter is typed as `Function` and is called with a view of the index. The code assumes it returns a single scalar value (e.g., `first` returns one element, `last` returns one element). If a user passes a function that returns a vector (e.g., `collect`), the resulting index would contain vectors instead of scalar timestamps, leading to a confusing error downstream when TSFrame's constructor rejects the non-scalar index.

  The error would be caught (TSFrame constructor validates index type), but the error message would be unclear.

- **Recommended Fix**: Add a check or documentation note that `index_at` must return a scalar of the same type as the index elements. Consider: `@assert result isa eltype(idx) "index_at must return a single $(eltype(idx)) value"`.

---

## Summary Table

| # | Severity | File | Issue |
|---|----------|------|-------|
| 1 | Medium | `src/resample.jl:72,95` | `@inbounds` relies on `endpoints()` correctness without assertion |
| 2 | Medium | `Project.toml:9` | BenchmarkTools in `[deps]` but unused in source -- bloats install |
| 3 | Low | `test/resample.jl` | No test for empty TSFrame / single-row edge cases |
| 4 | Low | `src/apply.jl:164-171` | `get_tmp_colname` has no iteration bound (pre-existing) |
| 5 | Low | `src/to_period.jl:30-47` | `@eval` metaprogramming is safe (no user input flows in) |
| 6 | Low | `src/resample.jl:84-100` | User functions can mutate views (inherent to Julia design) |
| 7 | Low | `src/resample.jl:152` | `copycols=false` is intentional and matches codebase conventions |
| 8 | Low | `src/resample.jl:64-77` | No validation that `index_at` returns a scalar |

---

## Verdict

**PASS with recommendations.** No critical or high severity issues found. The two medium-severity findings (BenchmarkTools in deps, and @inbounds safety) should be addressed before release. The low-severity items are informational and can be addressed at the maintainer's discretion.
