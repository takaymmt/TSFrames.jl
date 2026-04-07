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
        else  # is_gap[i] && !ismissing(v[i]): gap row already has value, reset run
            consec = 0
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
        else  # is_gap[i] && !ismissing(v[i]): gap row already has value, reset run
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
# Processes contiguous gap-missing segments in O(n) time by finding anchors once per segment.
function _apply_interpolate_gaps!(combined::DataFrame, is_gap::AbstractVector{Bool})
    idx_col = combined[!, :Index]
    for col in names(combined, Not(:Index))
        v = combined[!, col]
        ElemT = nonmissingtype(eltype(v))
        ElemT <: Number || continue  # skip non-numeric columns
        _interpolate_column!(v, idx_col, is_gap, ElemT)
    end
end

# Fill one column: find contiguous gap-missing segments and interpolate each segment in O(n).
function _interpolate_column!(v::AbstractVector, idx_col, is_gap::AbstractVector{Bool}, ::Type{ElemT}) where {ElemT}
    n = length(v)
    i = 1
    while i <= n
        # Advance past non-gap or already-filled positions
        if !(is_gap[i] && ismissing(v[i]))
            i += 1
            continue
        end
        # Found the start of a contiguous gap-missing segment; extend to seg_end
        seg_end = i
        while seg_end < n && is_gap[seg_end + 1] && ismissing(v[seg_end + 1])
            seg_end += 1
        end
        # Segment is [i, seg_end]; find anchors once
        lo = i - 1
        while lo >= 1 && ismissing(v[lo])
            lo -= 1
        end
        hi = seg_end + 1
        while hi <= n && ismissing(v[hi])
            hi += 1
        end
        # Fill all positions in the segment
        if lo >= 1 && hi <= n
            t_lo  = Dates.value(idx_col[lo])
            t_hi  = Dates.value(idx_col[hi])
            denom = t_hi - t_lo
            if denom == 0
                for k in i:seg_end; v[k] = v[lo]; end
            elseif ElemT <: AbstractFloat
                v_lo = v[lo]; v_hi = v[hi]; span = v_hi - v_lo
                for k in i:seg_end
                    frac = (Dates.value(idx_col[k]) - t_lo) / denom
                    v[k] = v_lo + frac * span
                end
            else
                v_lo = v[lo]; v_hi = v[hi]; span = v_hi - v_lo
                for k in i:seg_end
                    frac = (Dates.value(idx_col[k]) - t_lo) / denom
                    v[k] = round(ElemT, v_lo + frac * span)
                end
            end
        elseif lo >= 1
            for k in i:seg_end; v[k] = v[lo]; end
        elseif hi <= n
            for k in i:seg_end; v[k] = v[hi]; end
        end
        i = seg_end + 1
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

# Two-pointer sorted merge of result rows and gap labels.
# Both inputs are already sorted, so we avoid O((n+g) log(n+g)) vcat+sort!.
# Returns (combined::DataFrame, is_gap::BitVector) so callers can skip the
# Set-based gap-row lookup in _apply_fill_to_gaps!.
function _merge_sorted_with_gaps(coredata::DataFrame, gap_labels::AbstractVector)
    isempty(gap_labels) && return (copy(coredata), falses(DataFrames.nrow(coredata)))

    n = DataFrames.nrow(coredata)
    g = length(gap_labels)
    total = n + g

    idx_col = coredata[!, :Index]
    T_idx = eltype(idx_col)
    new_idx = Vector{T_idx}(undef, total)
    is_gap = falses(total)

    data_cols = names(coredata, Not(:Index))
    # Pre-allocate promoted columns (allow Missing for gap rows)
    col_data = Dict{String, AbstractVector}()
    for col in data_cols
        v = coredata[!, col]
        col_T = eltype(v)
        promoted_T = col_T >: Missing ? col_T : Union{Missing, col_T}
        col_data[col] = Vector{promoted_T}(missing, total)
    end

    # Two-pointer sorted merge — stable: existing rows precede gap rows on ties.
    i, j, k = 1, 1, 1
    while i <= n && j <= g
        if idx_col[i] <= gap_labels[j]
            new_idx[k] = idx_col[i]
            for col in data_cols
                col_data[col][k] = coredata[i, col]
            end
            i += 1
        else
            new_idx[k] = gap_labels[j]
            is_gap[k] = true
            j += 1
        end
        k += 1
    end
    while i <= n
        new_idx[k] = idx_col[i]
        for col in data_cols
            col_data[col][k] = coredata[i, col]
        end
        i += 1; k += 1
    end
    while j <= g
        new_idx[k] = gap_labels[j]
        is_gap[k] = true
        j += 1; k += 1
    end

    combined = DataFrame(:Index => new_idx; copycols=false)
    for col in data_cols
        combined[!, col] = col_data[col]
    end
    return combined, is_gap
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
# `is_gap` is supplied by `_merge_sorted_with_gaps`, eliminating the need for a
# Set-based lookup over `gap_labels`.
function _apply_fill_to_gaps!(combined::DataFrame, is_gap::AbstractVector{Bool},
                              effective::Union{Symbol,<:Real}, fill_limit::Union{Int,Nothing})
    effective === :missing && return

    # Pre-flight type validation for constant fill to avoid mid-mutation crash
    if effective isa Real
        for col in names(combined, Not(:Index))
            v = combined[!, col]
            col_T = nonmissingtype(eltype(v))
            try
                convert(col_T, effective)
            catch
                throw(ArgumentError(
                    "fill_gaps: cannot fill column `$col` (element type $col_T) with value $effective"
                ))
            end
        end
    end

    # Pre-flight type validation for :zero — same UX as Real constant fill.
    if effective === :zero
        for col in names(combined, Not(:Index))
            v = combined[!, col]
            col_T = nonmissingtype(eltype(v))
            col_T <: Number || throw(ArgumentError(
                "fill_gaps=:zero: cannot fill column `$col` (element type $col_T) with zero; " *
                "use :ffill, :bfill, or :missing instead"
            ))
        end
    end

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

    eltype(idx) <: Union{Date,DateTime} || throw(ArgumentError(
        "fill_gaps requires a Date or DateTime index; got $(eltype(idx))"
    ))

    gap_labels = _detect_gap_labels(idx, period, index_at)
    isempty(gap_labels) && return result

    combined, is_gap = _merge_sorted_with_gaps(result.coredata, gap_labels)
    effective = _normalize_fill_strategy(fill_strategy)
    _apply_fill_to_gaps!(combined, is_gap, effective, fill_limit)

    TSFrame(combined, :Index; issorted=true, copycols=false)
end
