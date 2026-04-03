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
```julia
dates = collect(Date(2020,1,1):Day(1):Date(2020,3,31))
df = DataFrame(Open=rand(91), High=rand(91).+1, Low=rand(91).-1, Close=rand(91), Volume=rand(1:1000,91))
ts = TSFrame(df, dates)

# Default: auto-detect OHLCV columns and apply standard aggregation
weekly = resample(ts, Week(1))

# Custom per-column aggregation with Symbol keys
resample(ts, Month(1), :Open => first, :Close => last)

# String keys also work
resample(ts, Week(1), "Open" => first, "Volume" => sum)
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
    idx      = index(ts)
    coredata = ts.coredata

    # ── Empty TSFrame edge case ───────────────────────────────────────────
    # Guard must come before endpoints() — endpoints() calls first(timestamps)
    # which throws BoundsError on an empty vector.
    if isempty(idx)
        df = DataFrame(:Index => eltype(idx)[])
        for (col, fn) in col_agg_pairs
            hasproperty(coredata, col) || continue
            col_out = renamecols ? Symbol(col, :_, nameof(fn)) : col
            df[!, col_out] = eltype(coredata[!, col])[]
        end
        return TSFrame(df, :Index; issorted=true, copycols=false)
    end

    ep = endpoints(ts, period)
    n  = length(ep)

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
    fill_gaps::Bool    = false,
    index_at::Function = first,
    renamecols::Bool   = false,
) where {T<:Dates.Period}
    any(hasproperty(ts.coredata, col) for (col, _) in _OHLCV_DEFAULT_AGG) ||
        throw(ArgumentError(
            "No standard OHLCV columns (Open, High, Low, Close, Volume) found. " *
            "Use resample(ts, period, :col => fn, ...) to specify columns explicitly."
        ))
    result = _resample_core(ts, period, _OHLCV_DEFAULT_AGG, index_at, renamecols)
    fill_gaps ? _fill_period_gaps(result, ts, period, index_at) : result
end

# 2. Explicit Symbol => Function pairs
function resample(
    ts::TSFrame,
    period::T,
    col_agg_pairs::Pair{Symbol,<:Function}...;
    fill_gaps::Bool    = false,
    index_at::Function = first,
    renamecols::Bool   = false,
) where {T<:Dates.Period}
    for (col, _) in col_agg_pairs
        hasproperty(ts.coredata, col) ||
            throw(ArgumentError("Column :$col not found in TSFrame"))
    end
    result = _resample_core(ts, period, col_agg_pairs, index_at, renamecols)
    fill_gaps ? _fill_period_gaps(result, ts, period, index_at) : result
end

# 3. String => Function pairs (convenience overload)
function resample(
    ts::TSFrame,
    period::T,
    col_agg_pairs::Pair{String,<:Function}...;
    fill_gaps::Bool    = false,
    index_at::Function = first,
    renamecols::Bool   = false,
) where {T<:Dates.Period}
    sym_pairs = Tuple(Symbol(col) => fn for (col, fn) in col_agg_pairs)
    resample(ts, period, sym_pairs...; fill_gaps=fill_gaps, index_at=index_at, renamecols=renamecols)
end

# Internal: insert missing rows for periods that have no data.
# Gap period labels use calendar-aligned period starts (consistent with SQL time-series DBs).
function _fill_period_gaps(
    result::TSFrame,
    ts::TSFrame,
    period::T,
    index_at::IA,
) where {T<:Dates.Period, IA<:Function}
    idx = index(ts)
    isempty(idx) && return result

    # First calendar-aligned period boundary (same floor/trunc logic as endpoints()).
    first_boundary = period isa Week ? floor(first(idx), typeof(period)) : trunc(first(idx), typeof(period))

    # Two-pointer sweep over calendar boundaries: detect periods with no source data.
    gap_labels = eltype(idx)[]
    j = 1
    for lo in first_boundary:period:last(idx)
        hi = lo + period
        # Advance j past timestamps belonging to earlier periods.
        while j <= length(idx) && idx[j] < lo
            j += 1
        end
        if j > length(idx) || idx[j] >= hi
            # Gap label for index_at=last: last moment of the period.
            # Date index: subtract 1 day; DateTime index: subtract 1 millisecond.
            # Other index types (e.g. sub-millisecond) are not supported by endpoints().
            label = index_at === last ? (eltype(idx) == Date ? hi - Day(1) : hi - Millisecond(1)) : lo
            push!(gap_labels, label)
        end
    end

    isempty(gap_labels) && return result

    # Build gap rows and widen result columns to Union{Missing,T} in one pass.
    # Result columns are fresh allocations from _resample_core, safe to mutate in-place.
    gap_df = DataFrame(:Index => gap_labels)
    for col in names(result.coredata, Not(:Index))
        col_T = eltype(result.coredata[!, col])
        promoted_T = col_T >: Missing ? col_T : Union{Missing, col_T}
        if !(col_T >: Missing)
            result.coredata[!, col] = convert(Vector{promoted_T}, result.coredata[!, col])
        end
        gap_df[!, col] = Vector{promoted_T}(missing, length(gap_labels))
    end

    combined = vcat(result.coredata, gap_df)
    sort!(combined, :Index)
    TSFrame(combined, :Index; issorted=true, copycols=false)
end
