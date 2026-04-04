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
- `fill_gaps`: strategy for filling periods with no source data (default: `false`).
  - `false`      — no gap filling (default).
  - `true`       — backward compatible, same as `:missing`.
  - `:missing`   — insert gap rows filled with `missing`.
  - `:ffill`     — forward fill gap rows from the preceding non-missing value.
  - `:bfill`     — backward fill gap rows from the following non-missing value.
  - `:zero`      — fill gap rows with zero (typed via `zero(nonmissingtype(eltype(col)))`).
  - `<Real>`     — fill gap rows with that numeric constant (e.g. `fill_gaps=0.0`).
  - `:interpolate` — linear interpolation between surrounding non-missing values (numeric columns only).
  **Note**: only *newly inserted* gap rows are affected; pre-existing `missing` values are preserved.
- `fill_limit`: maximum number of consecutive gap rows to fill for `:ffill`/`:bfill`
  (default: `nothing` = no limit). Ignored for other strategies.
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

# Valid symbolic fill strategies
const _VALID_FILL_SYMBOLS = (:missing, :ffill, :bfill, :zero, :interpolate)

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
    fill_gaps::Union{Bool,Symbol,<:Real} = false,
    fill_limit::Union{Int,Nothing}       = nothing,
    index_at::Function                    = first,
    renamecols::Bool                      = false,
) where {T<:Dates.Period}
    any(hasproperty(ts.coredata, col) for (col, _) in _OHLCV_DEFAULT_AGG) ||
        throw(ArgumentError(
            "No standard OHLCV columns (Open, High, Low, Close, Volume) found. " *
            "Use resample(ts, period, :col => fn, ...) to specify columns explicitly."
        ))
    if fill_limit !== nothing && fill_limit < 1
        throw(ArgumentError("fill_limit must be a positive integer or nothing, got $fill_limit"))
    end
    result = _resample_core(ts, period, _OHLCV_DEFAULT_AGG, index_at, renamecols)
    fill_gaps !== false ? _fill_period_gaps(result, ts, period, index_at, fill_gaps, fill_limit) : result
end

# 2. Explicit Symbol => Function pairs
function resample(
    ts::TSFrame,
    period::T,
    col_agg_pairs::Pair{Symbol,<:Function}...;
    fill_gaps::Union{Bool,Symbol,<:Real} = false,
    fill_limit::Union{Int,Nothing}       = nothing,
    index_at::Function                    = first,
    renamecols::Bool                      = false,
) where {T<:Dates.Period}
    for (col, _) in col_agg_pairs
        hasproperty(ts.coredata, col) ||
            throw(ArgumentError("Column :$col not found in TSFrame"))
    end
    if fill_limit !== nothing && fill_limit < 1
        throw(ArgumentError("fill_limit must be a positive integer or nothing, got $fill_limit"))
    end
    result = _resample_core(ts, period, col_agg_pairs, index_at, renamecols)
    fill_gaps !== false ? _fill_period_gaps(result, ts, period, index_at, fill_gaps, fill_limit) : result
end

# 3. String => Function pairs (convenience overload)
function resample(
    ts::TSFrame,
    period::T,
    col_agg_pairs::Pair{String,<:Function}...;
    fill_gaps::Union{Bool,Symbol,<:Real} = false,
    fill_limit::Union{Int,Nothing}       = nothing,
    index_at::Function                    = first,
    renamecols::Bool                      = false,
) where {T<:Dates.Period}
    if fill_limit !== nothing && fill_limit < 1
        throw(ArgumentError("fill_limit must be a positive integer or nothing, got $fill_limit"))
    end
    sym_pairs = Tuple(Symbol(col) => fn for (col, fn) in col_agg_pairs)
    resample(ts, period, sym_pairs...; fill_gaps=fill_gaps, fill_limit=fill_limit, index_at=index_at, renamecols=renamecols)
end

# ── Gap-fill helper functions ─────────────────────────────────────────────
# These operate only on positions marked as gap rows (is_gap[i] == true),
# preserving pre-existing missing values in non-gap rows.

# Forward fill: for each gap row, copy from the preceding non-missing value.
function _apply_ffill_gaps!(v::AbstractVector, is_gap::AbstractVector{Bool}, limit::Union{Int,Nothing})
    consec = 0
    for i in 2:length(v)
        if is_gap[i] && ismissing(v[i])
            if !ismissing(v[i-1])
                if limit === nothing || consec < limit
                    v[i] = v[i-1]
                    consec += 1
                end
            end
        elseif !is_gap[i]
            consec = 0  # reset on real (non-gap) data points
        end
    end
end

# Backward fill: iterate in reverse, copy from the following non-missing value.
function _apply_bfill_gaps!(v::AbstractVector, is_gap::AbstractVector{Bool}, limit::Union{Int,Nothing})
    consec = 0
    for i in (length(v)-1):-1:1
        if is_gap[i] && ismissing(v[i])
            if !ismissing(v[i+1])
                if limit === nothing || consec < limit
                    v[i] = v[i+1]
                    consec += 1
                end
            end
        elseif !is_gap[i]
            consec = 0
        end
    end
end

# Constant fill: replace missing gap rows with a fixed value.
function _apply_constant_fill_gaps!(v::AbstractVector, is_gap::AbstractVector{Bool}, fill_val)
    for i in eachindex(v)
        if is_gap[i] && ismissing(v[i])
            v[i] = fill_val
        end
    end
end

# Linear interpolation for gap rows (numeric columns only).
# Uses time-weighted interpolation between the nearest non-missing anchors.
function _apply_interpolate_gaps!(combined::DataFrame, is_gap::AbstractVector{Bool})
    n = size(combined, 1)
    idx_col = combined[!, :Index]

    for col in names(combined, Not(:Index))
        v = combined[!, col]
        ElemT = nonmissingtype(eltype(v))
        ElemT <: Number || continue  # skip non-numeric columns

        for i in 1:n
            (is_gap[i] && ismissing(v[i])) || continue

            # Find left anchor (nearest preceding non-missing value)
            lo = i - 1
            while lo >= 1 && ismissing(v[lo])
                lo -= 1
            end
            # Find right anchor (nearest following non-missing value)
            hi = i + 1
            while hi <= n && ismissing(v[hi])
                hi += 1
            end

            if lo >= 1 && hi <= n
                t_lo = Dates.value(idx_col[lo])
                t_hi = Dates.value(idx_col[hi])
                t_i  = Dates.value(idx_col[i])
                denom = t_hi - t_lo
                if denom == 0
                    v[i] = v[lo]  # duplicate timestamps: use left anchor
                else
                    frac = (t_i - t_lo) / denom
                    v[i] = ElemT <: AbstractFloat ?
                        v[lo] + frac * (v[hi] - v[lo]) :
                        round(ElemT, v[lo] + frac * (v[hi] - v[lo]))
                end
            elseif lo >= 1
                v[i] = v[lo]  # extrapolate left if no right anchor
            elseif hi <= n
                v[i] = v[hi]  # extrapolate right if no left anchor
            end
        end
    end
end

# ── Sub-functions for _fill_period_gaps ───────────────────────────────────

# Two-pointer sweep over calendar boundaries: detect periods with no source data.
# Gap labels use calendar-aligned period starts (consistent with SQL time-series DBs).
function _detect_gap_labels(idx, period::T, index_at::IA) where {T<:Dates.Period, IA<:Function}
    # First calendar-aligned period boundary (same floor/trunc logic as endpoints()).
    first_boundary = period isa Week ? floor(first(idx), typeof(period)) : trunc(first(idx), typeof(period))

    gap_labels = eltype(idx)[]
    j = 1
    for lo in first_boundary:period:last(idx)
        hi = lo + period
        while j <= length(idx) && idx[j] < lo
            j += 1
        end
        if j > length(idx) || idx[j] >= hi
            # Gap label for index_at=last: last moment of the period.
            # Date index: subtract 1 day; DateTime index: subtract 1 millisecond.
            label = index_at === last ? (eltype(idx) == Date ? hi - Day(1) : hi - Millisecond(1)) : lo
            push!(gap_labels, label)
        end
    end
    return gap_labels
end

# Build gap rows, widen result columns to Union{Missing,T}, and return sorted combined DataFrame.
# Result columns are fresh allocations from _resample_core, safe to mutate in-place.
function _insert_gap_rows(result::TSFrame, gap_labels::AbstractVector)
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
    return combined
end

# Normalize fill_strategy: true (backward compat) → :missing.
# Validate symbolic strategies; throw ArgumentError for unknown symbols.
function _normalize_fill_strategy(fill_strategy::Union{Bool,Symbol,<:Real})
    effective = fill_strategy === true ? :missing : fill_strategy
    if effective isa Symbol && effective ∉ _VALID_FILL_SYMBOLS
        throw(ArgumentError(
            "Invalid fill_gaps strategy: :$effective. " *
            "Valid symbols are: $(join(string.(':', collect(_VALID_FILL_SYMBOLS)), ", "))"
        ))
    end
    return effective
end

# Apply fill strategy to gap rows only; pre-existing missing values are preserved.
function _apply_fill_to_gaps!(combined::DataFrame, gap_labels::AbstractVector,
                              effective::Union{Symbol,<:Real}, fill_limit::Union{Int,Nothing})
    effective === :missing && return

    gap_label_set = Set(gap_labels)
    idx_vec = combined[!, :Index]
    is_gap = [idx_vec[i] in gap_label_set for i in 1:size(combined, 1)]

    for col in names(combined, Not(:Index))
        v = combined[!, col]
        if effective === :ffill
            _apply_ffill_gaps!(v, is_gap, fill_limit)
        elseif effective === :bfill
            _apply_bfill_gaps!(v, is_gap, fill_limit)
        elseif effective === :zero
            _apply_constant_fill_gaps!(v, is_gap, zero(nonmissingtype(eltype(v))))
        elseif effective isa Real
            _apply_constant_fill_gaps!(v, is_gap, effective)
        end
    end

    # :interpolate operates on the full DataFrame (needs Index column for time-weighting)
    if effective === :interpolate
        _apply_interpolate_gaps!(combined, is_gap)
    end
end

# ── Main orchestrator ────────────────────────────────────────────────────
# Insert missing rows for periods that have no data, then apply the fill strategy.
function _fill_period_gaps(
    result::TSFrame,
    ts::TSFrame,
    period::T,
    index_at::IA,
    fill_strategy::Union{Bool,Symbol,<:Real} = true,
    fill_limit::Union{Int,Nothing} = nothing,
) where {T<:Dates.Period, IA<:Function}
    idx = index(ts)
    isempty(idx) && return result

    gap_labels = _detect_gap_labels(idx, period, index_at)
    isempty(gap_labels) && return result

    combined = _insert_gap_rows(result, gap_labels)
    effective = _normalize_fill_strategy(fill_strategy)
    _apply_fill_to_gaps!(combined, gap_labels, effective, fill_limit)

    TSFrame(combined, :Index; issorted=true, copycols=false)
end
