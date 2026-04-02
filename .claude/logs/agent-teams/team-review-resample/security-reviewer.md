# Work Log: Security Reviewer

## Summary

Completed security review of the resample() implementation and related files in TSFrames.jl. Found 0 critical, 0 high, 2 medium, and 6 low severity issues. The code is well-structured with good type specialization. No vulnerabilities that could lead to data corruption under normal use. Two medium findings (BenchmarkTools in [deps], @inbounds without defensive assertions) should be addressed.

## Review Scope

- `src/resample.jl` (198 lines, new file) -- core resample implementation
- `src/apply.jl` (172 lines, modified) -- apply() with new `_build_groupindices` helper
- `src/to_period.jl` (48 lines, modified) -- frequency conversion with @eval macro
- `src/TSFrames.jl` (98 lines) -- module definition, exports, includes
- `test/resample.jl` (183 lines, new file) -- test suite for resample
- `src/endpoints.jl` (382 lines) -- upstream dependency reviewed for correctness guarantees
- `src/TSFrame.jl` (442 lines) -- constructor reviewed for validation
- `Project.toml` (34 lines) -- dependency check

## Findings

### Medium Severity (2)
1. **@inbounds without defensive assertions** (`src/resample.jl:72,95`): Hot loops skip bounds checking and rely entirely on `endpoints()` returning correct values. A bug in endpoints or future refactor could cause silent OOB access. Recommend debug-mode assertions.
2. **BenchmarkTools in [deps]** (`Project.toml:9`): Listed as a runtime dependency but never imported in source. Increases install footprint and attack surface unnecessarily. Should be in [extras].

### Low Severity (6)
3. No test for empty/single-row TSFrame edge cases in resample
4. `get_tmp_colname` unbounded loop (pre-existing in apply.jl)
5. `@eval` in to_period.jl is safe (compile-time constant data only)
6. User-supplied functions can mutate views (inherent to Julia, not fixable without perf cost)
7. `copycols=false` in TSFrame construction is intentional and matches conventions
8. No validation that `index_at` returns a scalar value

## Issues Encountered

- None. All files were accessible and the codebase was well-organized. The `endpoints()` function required careful review to verify the safety assumptions in `@inbounds` usage.
