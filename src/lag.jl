"""
# Lagging
```julia
lag(ts::TSFrame, lag_value::Int = 1)
```

Lag the `ts` object by the specified `lag_value`. The rows corresponding
to lagged values will be rendered as `missing`. Negative values of lag are
also accepted (see `TSFrames.lead`).

# Examples
```jldoctest; setup = :(using TSFrames, DataFrames, Dates, Random, Statistics)
julia> using Random, Statistics;

julia> random(x) = rand(MersenneTwister(123), x);

julia> dates = collect(Date(2017,1,1):Day(1):Date(2017,1,10));

julia> ts = TSFrame(random(length(dates)), dates);
julia> show(ts)
(10 x 1) TSFrame with Dates.Date Index

 Index       x1
 Date        Float64
───────────────────────
 2017-01-01  0.768448
 2017-01-02  0.940515
 2017-01-03  0.673959
 2017-01-04  0.395453
 2017-01-05  0.313244
 2017-01-06  0.662555
 2017-01-07  0.586022
 2017-01-08  0.0521332
 2017-01-09  0.26864
 2017-01-10  0.108871


julia> lag(ts)
(10 x 1) TSFrame with Date Index

 Index       x1
 Date        Float64?
─────────────────────────────
 2017-01-01  missing
 2017-01-02        0.768448
 2017-01-03        0.940515
 2017-01-04        0.673959
 2017-01-05        0.395453
 2017-01-06        0.313244
 2017-01-07        0.662555
 2017-01-08        0.586022
 2017-01-09        0.0521332
 2017-01-10        0.26864

julia> lag(ts, 2) # lags by 2 values
(10 x 1) TSFrame with Date Index

 Index       x1
 Date        Float64?
─────────────────────────────
 2017-01-01  missing
 2017-01-02  missing
 2017-01-03        0.768448
 2017-01-04        0.940515
 2017-01-05        0.673959
 2017-01-06        0.395453
 2017-01-07        0.313244
 2017-01-08        0.662555
 2017-01-09        0.586022
 2017-01-10        0.0521332

```
"""
function lag(ts::TSFrame, lag_value::Int = 1)
    isempty(index(ts)) && return TSFrame(copy(ts.coredata))

    n = TSFrames.nrow(ts)
    col_names = TSFrames.names(ts)
    sdf = DataFrame()
    for col in col_names
        sdf[!, col] = _shift_column(ts.coredata[!, col], lag_value, n)
    end
    _wrap_with_index(sdf, index(ts))
end

# Internal helper: shift a column by `k` positions, filling vacated slots
# with `missing`. Positive `k` shifts values down (lag); negative `k` shifts
# values up (lead). Returns a fresh Vector{Union{Missing, eltype(v)}}.
#
# V<:AbstractVector forces Julia to specialise on the concrete column type, so
# eltype(V) is statically known and the inner loops are type-stable with no
# per-element boxing — same pattern as _alloc_and_fill_col in utils.jl.
@inline function _shift_column(v::V, k::Int, n::Int) where {V<:AbstractVector}
    T = Union{Missing, eltype(V)}
    out = Vector{T}(undef, n)
    if k == 0
        @inbounds for i in 1:n
            out[i] = v[i]
        end
    elseif k > 0
        # lag: vacated slots [1:k] become missing, then out[k+1:n] = v[1:n-k]
        kk = min(k, n)
        @inbounds for i in 1:kk
            out[i] = missing
        end
        @inbounds for i in 1:(n - kk)
            out[i + kk] = v[i]
        end
    else
        # lead: out[1:n+k] = v[1-k:n], then vacated slots [n+k+1:n] become missing
        kk = min(-k, n)
        @inbounds for i in 1:(n - kk)
            out[i] = v[i + kk]
        end
        @inbounds for i in (n - kk + 1):n
            out[i] = missing
        end
    end
    return out
end
