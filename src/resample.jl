"""
# resample — Period-based resampling with per-column aggregation rules

```julia
# Default: auto-detect OHLCV columns and apply standard aggregation
resample(ts::TSFrame, period::T; index_at=first, renamecols=false)

# Custom per-column aggregation (Symbol keys)
resample(ts::TSFrame, period::T, col_agg_pairs::Pair{Symbol,<:Function}...; index_at=first, renamecols=false)

# Custom per-column aggregation (String keys)
resample(ts::TSFrame, period::T, col_agg_pairs::Pair{String,<:Function}...; index_at=first, renamecols=false)
```

Resample `ts` to lower frequency by applying per-column aggregation functions within each period.

## Default OHLCV behavior (no pairs specified)
When called without explicit column-function pairs, `resample` looks for standard OHLCV
columns and applies the canonical financial aggregation rules:
- `:Open`   → `first`   (opening price of the period)
- `:High`   → `maximum` (highest price of the period)
- `:Low`    → `minimum` (lowest price of the period)
- `:Close`  → `last`    (closing price of the period)
- `:Volume` → `sum`     (total volume of the period)

Columns that are not present are silently skipped. At least one must exist.

## Keyword arguments
- `index_at`: function to select the period label from the index values (`first` or `last`)
- `renamecols`: if `false` (default), output columns keep the original names;
  if `true`, DataFrames auto-generates names like `Open_first`.

## Examples
```jldoctest; setup = :(using TSFrames, DataFrames, Dates, Random)
julia> dates = collect(Date(2020,1,1):Day(1):Date(2020,3,31));
julia> df = DataFrame(Open=rand(91), High=rand(91).+1, Low=rand(91).-1, Close=rand(91), Volume=rand(1:1000,91));
julia> ts = TSFrame(df, dates);

julia> weekly = resample(ts, Week(1))
# Returns weekly OHLCV with Open=first, High=max, Low=min, Close=last, Volume=sum

julia> resample(ts, Month(1), :Open => first, :Close => last)
# Custom: only Open and Close, monthly

julia> resample(ts, Week(1), "Open" => first, "Volume" => sum)
# String keys also work
```
"""

# Default OHLCV aggregation rules (canonical financial bar construction).
# Stored as a typed Tuple so _resample_core can specialize on the concrete type.
const _OHLCV_DEFAULT_AGG = (
    :Open   => first,
    :High   => maximum,
    :Low    => minimum,
    :Close  => last,
    :Volume => sum,
)

# Type-barrier: builds the index output vector.
# V<:AbstractVector forces Julia to specialise on the concrete index type (e.g.
# Vector{Date}), so eltype(V) is statically known, @view is stack-allocated,
# and index_at() returns a concrete element — no per-element boxing.
@inline function _build_index_out(
    idx::V,
    ep::Vector{Int},
    index_at::IA,
    n::Int,
) where {V<:AbstractVector, IA<:Function}
    out = Vector{eltype(V)}(undef, n)
    j   = 1
    @inbounds for g in 1:n
        out[g] = index_at(@view idx[j:ep[g]])
        j = ep[g] + 1
    end
    out
end

# Type-barrier: allocates the output vector and fills all n groups.
# V<:AbstractVector + F<:Function force Julia to JIT-compile a separate method
# for each (column type, aggregation function) pair, making every fn() call in
# the hot loop type-stable — no boxing, no dynamic dispatch per group.
# Called once per column from _resample_core.
@inline function _alloc_and_fill_col(
    src::V,
    ep::Vector{Int},
    fn::F,
    n::Int,
) where {V<:AbstractVector, F<:Function}
    first_val = fn(@view src[1:ep[1]])
    out_T     = typeof(first_val)
    dst       = Vector{out_T}(undef, n)
    dst[1]    = first_val
    j = ep[1] + 1
    @inbounds for g in 2:n
        dst[g] = fn(@view src[j:ep[g]])
        j = ep[g] + 1
    end
    dst
end

# Internal: single-pass @view iteration — no copy, no groupby, no combine.
# Uses column-major access (outer=columns, inner=groups) for cache efficiency.
#
# Type parameters:
#   T  — Period type
#   P  — concrete type of col_agg_pairs (typed Tuple or varargs Tuple);
#        `where {P}` causes Julia to specialise this method per call site,
#        which enables union-splitting on the 5-way OHLCV tuple.
#   IA — concrete Function type for index_at; avoids dynamic dispatch in the
#        index-building loop.
function _resample_core(
    ts::TSFrame,
    period::T,
    col_agg_pairs::P,
    index_at::IA,
    renamecols::Bool,
) where {T<:Dates.Period, P, IA<:Function}
    ep       = endpoints(ts, period)
    n        = length(ep)
    idx      = index(ts)
    coredata = ts.coredata

    # ── Empty TSFrame edge case ───────────────────────────────────────────
    if n == 0
        df = DataFrame(:Index => eltype(idx)[])
        for (col, fn) in col_agg_pairs
            hasproperty(coredata, col) || continue
            col_out = renamecols ? Symbol(col, :_, nameof(fn)) : col
            df[!, col_out] = eltype(coredata[!, col])[]
        end
        return TSFrame(df, :Index; issorted=true, copycols=false)
    end

    # ── Build index output (type-barrier) ────────────────────────────────
    # _build_index_out specialises on typeof(idx) so the loop is type-stable.
    index_out = _build_index_out(idx, ep, index_at, n)

    # ── Build result DataFrame column by column ───────────────────────────
    df = DataFrame(:Index => index_out)

    for (col, fn) in col_agg_pairs
        hasproperty(coredata, col) || continue   # skip absent OHLCV columns
        src = coredata[!, col]
        # _alloc_and_fill_col is JIT-specialised on typeof(fn):
        # the inner loop over n groups is type-stable and allocation-free.
        dst     = _alloc_and_fill_col(src, ep, fn, n)
        col_out = renamecols ? Symbol(col, :_, nameof(fn)) : col
        df[!, col_out] = dst
    end

    TSFrame(df, :Index; issorted=true, copycols=false)
end

# 1. Default OHLCV (no pairs — auto-detect available OHLCV columns)
# Passes the full _OHLCV_DEFAULT_AGG tuple (concrete, typed) directly to
# _resample_core; absent columns are silently skipped via hasproperty.
function resample(
    ts::TSFrame,
    period::T;
    index_at::Function = first,
    renamecols::Bool   = false,
) where {T<:Dates.Period}
    any(hasproperty(ts.coredata, col) for (col, _) in _OHLCV_DEFAULT_AGG) ||
        throw(ArgumentError(
            "No standard OHLCV columns (Open, High, Low, Close, Volume) found. " *
            "Use resample(ts, period, :col => fn, ...) to specify columns explicitly."
        ))
    _resample_core(ts, period, _OHLCV_DEFAULT_AGG, index_at, renamecols)
end

# 2. Explicit Symbol => Function pairs
function resample(
    ts::TSFrame,
    period::T,
    col_agg_pairs::Pair{Symbol,<:Function}...;
    index_at::Function = first,
    renamecols::Bool   = false,
) where {T<:Dates.Period}
    for (col, _) in col_agg_pairs
        hasproperty(ts.coredata, col) ||
            throw(ArgumentError("Column :$col not found in TSFrame"))
    end
    _resample_core(ts, period, col_agg_pairs, index_at, renamecols)
end

# 3. String => Function pairs (convenience overload)
function resample(
    ts::TSFrame,
    period::T,
    col_agg_pairs::Pair{String,<:Function}...;
    index_at::Function = first,
    renamecols::Bool   = false,
) where {T<:Dates.Period}
    sym_pairs = Tuple(Symbol(col) => fn for (col, fn) in col_agg_pairs)
    resample(ts, period, sym_pairs...; index_at=index_at, renamecols=renamecols)
end
