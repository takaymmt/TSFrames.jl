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

# Default OHLCV aggregation rules (canonical financial bar construction)
const _OHLCV_DEFAULT_AGG = (
    :Open   => first,
    :High   => maximum,
    :Low    => minimum,
    :Close  => last,
    :Volume => sum,
)

# Internal: shared implementation for all resample dispatch methods
function _resample_core(
    ts::TSFrame,
    period::T,
    col_agg_pairs,
    index_at::Function,
    renamecols::Bool,
) where {T<:Dates.Period}
    ep  = endpoints(ts, period)
    gi  = _build_groupindices(ep, DataFrames.nrow(ts.coredata))

    tmp_col = get_tmp_colname(names(ts.coredata))
    sdf = copy(ts.coredata)
    sdf[!, tmp_col] = gi
    gd  = groupby(sdf, tmp_col)

    col_specs = renamecols ?
        [col => fn            for (col, fn) in col_agg_pairs] :
        [col => fn => col     for (col, fn) in col_agg_pairs]

    df = combine(gd, :Index => index_at => :Index, col_specs...; keepkeys=false)
    TSFrame(df, :Index)
end

# 1. Default OHLCV (no pairs — auto-detect)
function resample(
    ts::TSFrame,
    period::T;
    index_at::Function = first,
    renamecols::Bool   = false,
) where {T<:Dates.Period}
    col_syms = Symbol.(names(ts.coredata))
    pairs    = [(col => fn) for (col, fn) in _OHLCV_DEFAULT_AGG if col in col_syms]
    isempty(pairs) && throw(ArgumentError(
        "No standard OHLCV columns (Open, High, Low, Close, Volume) found. " *
        "Use resample(ts, period, :col => fn, ...) to specify columns explicitly."
    ))
    _resample_core(ts, period, pairs, index_at, renamecols)
end

# 2. Explicit Symbol => Function pairs
function resample(
    ts::TSFrame,
    period::T,
    col_agg_pairs::Pair{Symbol,<:Function}...;
    index_at::Function = first,
    renamecols::Bool   = false,
) where {T<:Dates.Period}
    col_syms = Symbol.(names(ts.coredata))
    for (col, _) in col_agg_pairs
        col in col_syms || throw(ArgumentError("Column :$col not found in TSFrame"))
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
