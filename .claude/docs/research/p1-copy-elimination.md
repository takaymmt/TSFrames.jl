# P1: copy(ts.coredata) Elimination in apply() and resample()

Date: 2026-04-02
Status: Research complete, ready for implementation decision

---

## Problem Statement

In `apply()` and `_resample_core()`, `copy(ts.coredata)` is called to create a mutable
copy of the DataFrame so that a temporary grouping column can be added via
`sdf[!, tmp_col] = groupindices`. This copy accounts for:

- **47% of total time** for `apply(Week, first)` (per profiling)
- **24% of total time** for `apply(Week, sum)`
- **10% of total time** in benchmark (0.74ms out of 7.57ms for 1M rows)

The discrepancy between profile (47%) and benchmark (10%) is because profiling
over-counts memory allocation overhead relative to wall-clock time. Regardless,
eliminating this copy is a significant win.

---

## Why the copy exists

```julia
sdf = copy(ts.coredata)          # Must not mutate ts.coredata
sdf[!, tmp_col] = groupindices   # Adds column IN-PLACE
gd = groupby(sdf, tmp_col)       # groupby needs the column to exist in the DF
```

`TSFrame.coredata` is the user's data. Mutating it (adding/removing columns) would
be a breaking side effect. The copy protects against this.

---

## Approach Evaluation

### Approach A: Direct @view iteration (bypass groupby/combine entirely)

**Concept**: Use the `endpoints` vector directly. Iterate over groups using
`@view col[start:end]` slices, applying the aggregation function to each slice.
Build the output DataFrame manually.

```julia
function _apply_direct(ts, ep, fun, index_at; renamecols)
    idx = TSFrames.index(ts)
    n_groups = length(ep)
    
    # Pre-allocate index output
    index_out = Vector{eltype(idx)}(undef, n_groups)
    
    # Pre-allocate per-column outputs
    data_cols = names(ts.coredata, Not(:Index))
    col_outputs = Dict{String, Vector}()
    for cn in data_cols
        src = ts.coredata[!, cn]
        # Infer output type from fun applied to a small view
        sample_val = fun(@view src[1:min(2, length(src))])
        col_outputs[cn] = Vector{typeof(sample_val)}(undef, n_groups)
    end
    
    # Single pass over groups
    j = 1
    for (g, e) in enumerate(ep)
        rng = j:e
        index_out[g] = index_at(@view idx[rng])
        for cn in data_cols
            src = ts.coredata[!, cn]
            col_outputs[cn][g] = fun(@view src[rng])
        end
        j = e + 1
    end
    
    # Build result DataFrame
    df = DataFrame(:Index => index_out)
    for cn in data_cols
        col_name = renamecols ? string(cn, "_", nameof(fun)) : cn
        df[!, col_name] = col_outputs[cn]
    end
    TSFrame(df, :Index)
end
```

**Pros:**
- Eliminates copy(coredata) entirely (0 bytes copied)
- Eliminates groupby() overhead (hash computation, 14-27% of time)
- Eliminates combine() overhead (6-30% of time)
- `@view col[j:e]` on a contiguous Vector is essentially free (no allocation)
- Julia's `first`, `last`, `sum`, `maximum`, `minimum` are all type-stable on `SubArray{T,1}` (returns `T`)
- Column-major friendly: each column is processed sequentially in memory
- `@inbounds` can be added to the inner loop for 5-10% additional gain
- Function specialization via `where {F<:Function}` means Julia JIT-compiles a separate version per function

**Cons:**
- `fun` applied to `@view` must return a scalar (not a vector) -- this is already the contract of `apply()`
- Type inference for output columns requires a "sample call" to `fun` (see `sample_val` above), or we can use `Base.return_types` (less robust)
- More code to maintain than the groupby/combine approach
- Does not leverage DataFrames' built-in optimizations for special aggregation functions (e.g., `groupreduce!` for `sum`)
- For `sum`, DataFrames uses optimized SIMD `groupreduce!` which processes all rows in one pass; our per-group `sum(@view ...)` may be slightly slower due to function call overhead per group

**Type stability analysis:**
- `first(@view v[1:n])` -> returns `eltype(v)` -- type-stable
- `last(@view v[1:n])` -> returns `eltype(v)` -- type-stable
- `sum(@view v[1:n])` -> returns promotion type -- type-stable for homogeneous vectors
- `maximum(@view v[1:n])` -> returns `eltype(v)` -- type-stable
- `minimum(@view v[1:n])` -> returns `eltype(v)` -- type-stable
- `Statistics.mean(@view v[1:n])` -> returns `Float64` for numeric -- type-stable
- `Statistics.std(@view v[1:n])` -> returns `Float64` -- type-stable

All common aggregation functions are type-stable on SubArray views.

**Performance estimate:**
- Eliminates: copy (0.74ms) + groupby (1.96ms) + combine (2.20ms) = 4.90ms
- Adds: per-group view iteration (~0.3-0.5ms for first, ~1.5-2.0ms for sum)
- Net improvement for `first`: ~4.0-4.5ms savings on 7.57ms total = **2-3x speedup**
- Net improvement for `sum`: ~2.5-3.0ms savings on 26.02ms total = **1.1-1.2x speedup** (sum is dominated by actual computation)

---

### Approach B: DataFrames groupby without temp column

**Concept**: Construct a `GroupedDataFrame` directly from pre-computed group indices,
bypassing the need for a temp column (and thus no copy).

**Findings from DataFrames.jl source analysis:**

The `GroupedDataFrame` struct has these fields:
```julia
mutable struct GroupedDataFrame{T<:AbstractDataFrame}
    parent::T
    cols::Vector{Symbol}     # column names used for grouping
    groups::Vector{Int}      # group index per row (0 = skipped)
    idx::Union{Vector{Int}, Nothing}    # permutation vector (lazy)
    starts::Union{Vector{Int}, Nothing} # group start positions (lazy)
    ends::Union{Vector{Int}, Nothing}   # group end positions (lazy)
    ngroups::Int
    keymap::Union{Dict{Any, Int}, Nothing}  # lazy
    lazy_lock::Threads.ReentrantLock
end
```

The struct is explicitly **not meant for direct construction**. The `groupby` function
computes `groups` via internal `group_rows()` which returns `rperm`, `starts`, `stops`.

**Key problem**: Even if we construct a `GroupedDataFrame` manually, `combine()` expects
the grouping columns to exist in the parent DataFrame. The `cols` field must reference
real columns. So we'd still need the temp column in the DataFrame.

**Verdict: NOT VIABLE** without forking/monkey-patching DataFrames.jl internals. The
coupling between GroupedDataFrame and its parent DataFrame's column structure is too tight.

---

### Approach C: Shallow DataFrame with copycols=false

**Concept**: Instead of `copy(ts.coredata)`, create a new DataFrame that shares
column vectors with the original, then add the temp column to the new DF.

```julia
# Current: copies all column data
sdf = copy(ts.coredata)

# Proposed: shares column vectors (zero-copy for existing columns)
sdf = DataFrame(ts.coredata; copycols=false)
sdf[!, tmp_col] = groupindices  # only the new column is allocated
```

**How `DataFrame(source; copycols=false)` works:**
- Creates a new DataFrame object with the same column vectors (pointers, not copies)
- Adding a new column via `sdf[!, tmp_col] = ...` adds to the NEW DataFrame only
- The original `ts.coredata` is NOT mutated (it still has its original columns)
- This is safe because `sdf[!, tmp_col] =` modifies the DataFrame's column list,
  not the column data. The column vectors are shared read-only.

**Critical safety check:**
- `groupby(sdf, tmp_col)` creates views, does NOT mutate columns
- `combine(gd, ...)` reads column data, does NOT mutate source columns
- Neither operation writes to the shared column vectors
- The only mutation is adding `tmp_col` to `sdf`'s column list (not `ts.coredata`'s)

**This is SAFE for our use case.**

**Pros:**
- Minimal code change (1 line: `copy(ts.coredata)` -> `DataFrame(ts.coredata; copycols=false)`)
- Eliminates ~0.74ms copy overhead (1M rows, 5 columns)
- No change to groupby/combine logic
- Well-supported DataFrames.jl API
- Zero risk of breaking existing tests

**Cons:**
- Still has groupby() and combine() overhead (4.16ms combined)
- Shared columns mean that if future code mutates sdf's column data, it would
  corrupt ts.coredata -- but current code does not do this
- Less dramatic improvement than Approach A

**Performance estimate:**
- Eliminates: copy (0.74ms)
- No other changes
- Net improvement: **0.74ms savings on 7.57ms = ~10% speedup for first**
- Net improvement: **0.74ms savings on 26.02ms = ~3% speedup for sum**

---

### Approach D: Hybrid -- Approach C for apply(), Approach A for resample()

**Concept**: Use `copycols=false` (Approach C) as a quick win for the general `apply()`
function which must handle arbitrary `fun`. For `resample()` which knows the specific
aggregation functions, use the direct @view approach (Approach A) for maximum performance.

This is the best of both worlds:
- `apply()` remains general-purpose with minimal code change
- `resample()` gets maximum optimization since it knows the exact functions

---

## Comparison Matrix

| Criterion | A: Direct @view | B: Manual GDF | C: copycols=false | D: Hybrid (A+C) |
|-----------|----------------|---------------|-------------------|------------------|
| Copy elimination | Full | Full | Full | Full |
| groupby elimination | Yes | No | No | resample only |
| combine elimination | Yes | No | No | resample only |
| Code change (LOC) | ~40-60 | N/A | ~1-2 | ~50-70 |
| Type stability | Good | N/A | Same as current | Good |
| Safety risk | Low | High | Low | Low |
| API compatibility | Full | N/A | Full | Full |
| Speedup (first, 1M) | 2-3x | N/A | 1.1x | 2-3x (resample) |
| Speedup (sum, 1M) | 1.1-1.2x | N/A | 1.03x | 1.1-1.2x (resample) |
| Maintenance cost | Medium | N/A | Minimal | Medium |

---

## Recommendation

### Phase 1 (Quick Win): Approach C -- copycols=false

**Implement first.** Single-line change, zero risk, immediate 10% improvement.

```julia
# In apply() and _resample_core():
sdf = DataFrame(ts.coredata; copycols=false)   # was: copy(ts.coredata)
```

Estimated effort: 5 minutes. Test with existing test suite.

### Phase 2 (Major Optimization): Approach A -- Direct @view for resample()

**Implement for `_resample_core()` only**, since resample() knows the exact
column-function pairs. This bypasses groupby+combine entirely.

Key implementation decisions:
1. **Type inference**: Use `fun(@view col[1:min(2,end)])` to determine output element type
2. **@inbounds**: Safe to use since `ep` indices come from `endpoints()` which guarantees bounds
3. **Column-major**: Process each column fully before moving to the next (cache-friendly)
4. **Function specialization**: Use `where {F<:Function}` in the inner loop function

Estimated effort: 2-3 hours. Requires new tests for the direct path.

### Phase 3 (Optional): Approach A for apply()

Only if benchmarks show Phase 2 delivers significant gains. `apply()` is more complex
because `fun` is arbitrary and `renamecols` behavior must match DataFrames' `combine`.

---

## Key Julia Performance Insights

1. **@view on contiguous Vector**: Creates a `SubArray` with zero allocation. The view
   is essentially a pointer + length. `fn(@view v[a:b])` is as fast as `fn(v[a:b])` but
   without the allocation.

2. **@inbounds**: Safe when iterating over `1:length(ep)` and using `ep[i]` values that
   are guaranteed to be in `1:nrow(ts)` by `endpoints()`. Saves ~5-10% per loop iteration.

3. **SIMD**: Julia's `sum` on a contiguous view already uses SIMD internally. Explicit
   `@simd` is not needed for standard aggregation functions.

4. **Column-major**: Julia arrays are column-major. Processing one full column at a time
   (as in Approach A) is cache-optimal. The current groupby/combine approach processes
   all columns per group, which is less cache-friendly for many columns.

5. **Function specialization**: `where {F<:Function}` in type parameter enables Julia
   to JIT-compile a separate method for each `fun` (first, sum, etc.), avoiding
   dynamic dispatch overhead.

6. **DataFrames groupby overhead**: Even with optimal key construction, `groupby()`
   performs hash-based grouping which is O(n) with significant constant factor.
   For our use case where groups are contiguous ranges, this hashing is pure waste.

---

## DataFrames.jl API Findings

- **No public API** to construct GroupedDataFrame from external group indices
- **`groupby()` requires** the grouping column to exist in the DataFrame
- **`DataFrame(src; copycols=false)`** creates a shallow copy sharing column vectors
- **`hcat(df1, df2; copycols=false)`** also shares column vectors
- **`insertcols!(df, col; copycols=false)`** adds a column without copying it (but still mutates df)
- **DataFrames >= 1.8** (our compat) supports all of these

---

## Sources

- [DataFrames.jl Functions Documentation](https://dataframes.juliadata.org/stable/lib/functions/)
- [DataFrames.jl Types Documentation](https://dataframes.juliadata.org/stable/lib/types/)
- [GroupedDataFrame source (groupeddataframe.jl)](https://github.com/JuliaData/DataFrames.jl/blob/a13db50a0cd8115691fe92e67b1301422c664401/src/groupeddataframe/groupeddataframe.jl)
- [Grouping implementation (grouping.jl)](https://github.com/JuliaData/DataFrames.jl/blob/a5fb9a4e8445d82c035b003da9ad40feb7c81dc4/src/groupeddataframe/grouping.jl)
- [Julia Discourse: Groupby on an expression or a vector](https://discourse.julialang.org/t/groupby-on-an-expression-or-a-vector/115409)
- [Julia Performance Tips](https://docs.julialang.org/en/v1/manual/performance-tips/)
- [Julia SubArrays documentation](https://docs.julialang.org/en/v1/devdocs/subarrays/)
- [Bogumil Kaminski: Working with GroupedDataFrame](https://bkamins.github.io/julialang/2024/03/01/gdf.html)
- [DataFrames.jl copycols behavior](https://discourse.julialang.org/t/copy-vs-view-of-dataframe-column/93182)
