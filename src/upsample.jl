"""
# Upsampling
```julia
upsample(ts::TSFrame,
      period::T
    where {T<:Union{DatePeriod, TimePeriod}}
```
Converts `ts` into an object of higher frequency than the original (ex.
from monthly series to daily.) `period` is any of `Period` types in the
`Dates` module.

By default, the added rows contain `missing` data. Returns an empty `TSFrame`
when `ts` is empty. Throws `DomainError` if `period.value <= 0`.

# Examples
```jldoctest; setup = :(using TSFrames, DataFrames, Dates, Random, Statistics)
julia> using Random, Statistics;
julia> random(x) = rand(MersenneTwister(123), x);
julia> dates = collect(DateTime(2017,1,1):Day(1):DateTime(2018,3,10));

julia> ts = TSFrame(random(length(dates)), dates)
julia> show(ts[1:10])
(10 x 1) TSFrame with DateTime Index

 Index                x1        
 DateTime             Float64   
────────────────────────────────
 2017-01-01T00:00:00  0.768448
 2017-01-02T00:00:00  0.940515
 2017-01-03T00:00:00  0.673959
 2017-01-04T00:00:00  0.395453
 2017-01-05T00:00:00  0.313244
 2017-01-06T00:00:00  0.662555
 2017-01-07T00:00:00  0.586022
 2017-01-08T00:00:00  0.0521332
 2017-01-09T00:00:00  0.26864
 2017-01-10T00:00:00  0.108871

 julia> upsample(ts, Hour(1))
(10393 x 1) TSFrame with DateTime Index

 Index                x1              
 DateTime             Float64?        
──────────────────────────────────────
 2017-01-01T00:00:00        0.768448
 2017-01-01T01:00:00  missing         
 2017-01-01T02:00:00  missing         
 2017-01-01T03:00:00  missing         
          ⋮                  ⋮
 2018-03-09T21:00:00  missing         
 2018-03-09T22:00:00  missing         
 2018-03-09T23:00:00  missing         
 2018-03-10T00:00:00        0.0338698
                    10385 rows omitted

upsample(ts, Hour(12))
(867 x 1) TSFrame with DateTime Index

Index                x1              
DateTime             Float64?        
──────────────────────────────────────
2017-01-01T00:00:00        0.768448
2017-01-01T12:00:00  missing         
2017-01-02T00:00:00        0.940515
2017-01-02T12:00:00  missing         
        ⋮                  ⋮
2018-03-08T12:00:00  missing         
2018-03-09T00:00:00        0.375126
2018-03-09T12:00:00  missing         
2018-03-10T00:00:00        0.0338698
                    859 rows omitted
"""
function upsample(ts::TSFrame, period::T) where {T<:Union{DatePeriod, TimePeriod}}
    # Empty guard: return a fresh empty TSFrame (no aliasing of input).
    if isempty(index(ts))
        return TSFrame(copy(ts.coredata), :Index; issorted=true, copycols=false)
    end
    if period.value <= 0
        throw(DomainError(period.value, "`period.value` needs to be greater than 0"))
    end

    src_idx = index(ts)
    n_src = length(src_idx)
    grid = collect(first(src_idx):period:last(src_idx))

    # Build a merged, sorted, deduplicated index that preserves every source
    # timestamp (matching the original outerjoin semantics) plus every grid
    # point produced by the requested period. Both inputs are already sorted,
    # so a single linear merge is O(n_src + length(grid)).
    out_idx, src_pos = _merge_sorted_with_positions(src_idx, grid)
    m = length(out_idx)

    # Source columns excluding the Index column (always at position 1).
    src_df = ts.coredata
    col_names = propertynames(src_df)
    n_data = length(col_names) - 1

    # Construct the resulting DataFrame directly: Index column + data columns.
    out_df = DataFrame()
    out_df[!, :Index] = out_idx
    @inbounds for j in 1:n_data
        src_col = src_df[!, j + 1]
        out_df[!, col_names[j + 1]] = _scatter_column(src_col, src_pos, m)
    end

    TSFrame(out_df, :Index; issorted=true, copycols=false)
end

# Merge two already-sorted index vectors into a single sorted, deduplicated
# vector. Returns the merged vector together with `src_pos`, where
# `src_pos[k]` is the source row index that maps to merged position `k`,
# or 0 if that position came purely from the grid.
function _merge_sorted_with_positions(src_idx::AbstractVector, grid::AbstractVector)
    n = length(src_idx)
    g = length(grid)
    out = Vector{eltype(src_idx)}(undef, n + g)
    src_pos = Vector{Int}(undef, n + g)

    i = 1   # source pointer
    j = 1   # grid pointer
    k = 0   # output pointer

    @inbounds while i <= n && j <= g
        a = src_idx[i]
        b = grid[j]
        if a < b
            k += 1
            out[k] = a
            src_pos[k] = i
            i += 1
        elseif a > b
            k += 1
            out[k] = b
            src_pos[k] = 0
            j += 1
        else
            # Equal: keep the source row (so its value is carried over) and
            # consume both pointers, dropping the duplicate from the grid.
            k += 1
            out[k] = a
            src_pos[k] = i
            i += 1
            j += 1
        end
    end
    @inbounds while i <= n
        k += 1
        out[k] = src_idx[i]
        src_pos[k] = i
        i += 1
    end
    @inbounds while j <= g
        k += 1
        out[k] = grid[j]
        src_pos[k] = 0
        j += 1
    end

    resize!(out, k)
    resize!(src_pos, k)
    return out, src_pos
end

# Build a single output column with the same length as `src_pos`. Positions
# with `src_pos[k] == 0` become `missing`; other positions copy `src_col[src_pos[k]]`.
# Defined as a function barrier so the inner loop is type-stable in `eltype(src_col)`.
function _scatter_column(src_col::AbstractVector, src_pos::Vector{Int}, m::Int)
    T = eltype(src_col)
    # If T already permits Missing, we can keep the same eltype; otherwise widen.
    out = Vector{Union{Missing, T}}(missing, m)
    @inbounds for k in 1:m
        p = src_pos[k]
        if p != 0
            out[k] = src_col[p]
        end
    end
    return out
end