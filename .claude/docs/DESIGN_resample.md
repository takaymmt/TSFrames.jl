# Design: resample() Feature for TSFrames.jl

Date: 2026-04-02

## Recommended Function Signatures

### 1. `resample()` — Per-column aggregation (NEW function)

```julia
function resample(
    ts::TSFrame,
    period::T,
    col_agg_pairs::Pair{Symbol, <:Function}...;
    index_at::Function = first,
    renamecols::Bool = false
) where {T <: Dates.Period}
```

Usage:
```julia
resample(ts, Week(1),
    :Open => first, :High => maximum, :Low => minimum,
    :Close => last, :Volume => sum)
```

### 2. `resample_ohlcv()` — OHLCV convenience function

```julia
function resample_ohlcv(
    ts::TSFrame,
    period::T;
    index_at::Function = first,
    open::Symbol = :Open, high::Symbol = :High,
    low::Symbol = :Low, close::Symbol = :Close,
    volume::Symbol = :Volume
) where {T <: Dates.Period}
```

### 3. String-key overload

```julia
function resample(ts::TSFrame, period::T, col_agg_pairs::Pair{String, <:Function}...;
                  index_at::Function=first, renamecols::Bool=false) where {T<:Dates.Period}
```

## Design Decision: New Function vs Overload

**New `resample()` function**, NOT overloading `apply()`. Rationale:
- `apply(ts, period, fun)` third arg is `Function`; adding `Pair` varargs creates confusing dispatch
- Different semantics (uniform vs per-column) deserve different names
- Zero backward compatibility risk
- Share internal infrastructure via extracted helper `_build_groupindices()`

## Internal Implementation (5 steps)

1. **Extract `_build_groupindices(ep, nrows)`** — shared helper converting `endpoints()` output
   into per-row group-index vector. Pre-allocate `Vector{Int}(undef, nrows)` (fixes current `fill+append!`).

2. **Refactor `apply()` to use the shared helper** — pure internal refactor, identical behavior.

3. **Implement `resample()`** — `endpoints()` → `_build_groupindices()` → `groupby` → `combine`
   with per-column pairs. Maps `:col => func` to DataFrames `:col => func => :col`.

4. **Implement `resample_ohlcv()`** — builds pairs from keyword args, delegates to `resample()`.

5. **Wire up exports** — `include("resample.jl")` + `export resample, resample_ohlcv`.

## File Organization

| File | Action |
|------|--------|
| `src/apply.jl` | Extract `_build_groupindices()`, refactor `apply()` |
| `src/resample.jl` | NEW — `resample()` + `resample_ohlcv()` |
| `src/TSFrames.jl` | Add include + exports |
| `test/resample.jl` | NEW — all resample tests |
| `test/runtests.jl` | Add include |

## Risks

1. `Base.first` vs `DataFrames.first` ambiguity — document clearly, test explicitly
2. `copy(ts.coredata)` per call — existing issue in `apply()`, defer optimization
3. DataFrames `combine` API changes — low likelihood, mitigated by CI
