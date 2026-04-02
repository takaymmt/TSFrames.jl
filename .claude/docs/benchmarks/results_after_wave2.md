# TSFrames.jl Benchmark Results — After Wave 2 (resample Phase 2)

Date: 2026-04-03
Changes: resample() with @view type-barrier implementation (_build_index_out + _alloc_and_fill_col)

---

## resample() — New function (1M rows, 142,858 weekly groups / ~33 monthly groups)

| Operation                     | Time     | Allocs | Notes                         |
|-------------------------------|----------|--------|-------------------------------|
| resample(Week,  default OHLCV)| 1.54 ms  | 73     | 5 columns, 142K groups        |
| resample(Month, default OHLCV)| 1.65 ms  | 73     | 5 columns, ~33 groups         |
| resample(Week,  explicit 5)   | 1.58 ms  | 76     | same as default               |
| resample(Week,  2 pairs)      | 907 μs   | 53     | Close+Volume only             |

---

## apply() — Existing function (unchanged from Wave 1)

| Operation           | Time    | Allocs | Notes                  |
|---------------------|---------|--------|------------------------|
| apply(Week,  first) | 5.36 ms | 659    | 5 columns via combine  |
| apply(Month, first) | 9.63 ms | 659    |                        |
| apply(Week,  sum)   | 17.2 ms | 659    |                        |

---

## Key Insight: Type Barrier Pattern

The 570K→73 alloc reduction came from two type-barrier helper functions:

### Problem
`index(ts)` returns `ts.coredata[!, :Index]` which has static type `AbstractVector`
(DataFrames cannot infer column types at compile time). Consequently:

- `eltype(idx)` → `Any` (static inference)  
- `Vector{eltype(idx)}(undef, n)` → `Vector{Any}` in compiled IR
- `index_out[g] = first(@view idx[j:ep[g]])` → boxes `Date` as `Any` per group
- 142,858 groups × ~4 allocs/group = ~570K allocs

### Fix: `_build_index_out(idx::V, ...) where {V<:AbstractVector}`
- `idx::V = Vector{Date}` concrete inside the method
- `eltype(V) = Date` statically known
- `out::Vector{Date}` — no boxing, no per-element allocs
- One dynamic dispatch from `_resample_core` → negligible

### Fix: `_alloc_and_fill_col(src::V, ..., fn::F, ...) where {V<:AbstractVector, F<:Function}`
- `src::V = Vector{Float64}` concrete inside the method
- `fn::F = typeof(first)` concrete → hot loop type-stable
- Called once per column (5 calls) — dispatch overhead negligible

---

## resample() vs apply() Comparison (Week, 5 OHLCV columns, 1M rows)

| Function     | Time    | Allocs | Speedup vs apply |
|--------------|---------|--------|-----------------|
| apply(first) | 5.36 ms | 659    | 1x (baseline)   |
| resample()   | 1.54 ms | 73     | **3.5x faster** |

resample() is 3.5x faster than apply() with 9x fewer allocations, and bypasses
groupby()/combine() entirely via direct @view slice iteration.

---

## Remaining apply() Internals (for reference)

| Step              | Time    | %    |
|-------------------|---------|------|
| endpoints()       | 0.42 ms |  8%  |
| pre-alloc         | 0.74 ms | 14%  |
| copy(coredata)    | 0.74 ms | 14%  |
| groupby()         | 1.89 ms | 35%  |
| combine()         | 2.36 ms | 44%  |

apply() still uses groupby()/combine() and copy(coredata). Future optimization
(Wave 3) could apply the same @view type-barrier approach to apply() for a
~3x speedup, at the cost of losing DataFrames' built-in combine behavior.
