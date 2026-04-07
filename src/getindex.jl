"""
# Indexing

`TSFrame` can be indexed using row and column indices. The row selector
could be an integer, a range, an array or it could also be a `Date`
object or an ISO-formatted date string ("2007-04-10"). There are
methods to subset on year, year-month, and year-quarter. The latter
two subset `coredata` by matching on the index column.

Column selector could be an integer or any other selector which
`DataFrame` indexing supports. You can use a Symbols to fetch specific
columns (ex: `ts[[:x1, :x2]]`). For fetching column values
as `Vector`, use `Colon` with column name: `ts[:, :x1]`. For Matrix
output, use the constructor: `Matrix(ts)`.

For fetching the index column vector use the `index()` method.

# Examples

```jldoctest; setup = :(using TSFrames, DataFrames, Dates, Random, Statistics)
julia> using Random;

julia> random(x) = rand(MersenneTwister(123), x);

julia> ts = TSFrame([random(10) random(10) random(10)])
julia> show(ts)

# first row
julia> ts[1]
(1 x 3) TSFrame with Int64 Index

 Index  x1        x2        x3
 Int64  Float64   Float64   Float64
─────────────────────────────────────
     1  0.768448  0.768448  0.768448

# first five rows
julia> ts[1:5]
(5 x 3) TSFrame with Int64 Index

 Index  x1        x2        x3
 Int64  Float64   Float64   Float64
─────────────────────────────────────
     1  0.768448  0.768448  0.768448
     2  0.940515  0.940515  0.940515
     3  0.673959  0.673959  0.673959
     4  0.395453  0.395453  0.395453
     5  0.313244  0.313244  0.313244

# first five rows, x2 column; returns a vector
julia> ts[1:5, :x2]
5-element Vector{Float64}:
 0.7684476751965699
 0.940515000715187
 0.6739586945680673
 0.3954531123351086
 0.3132439558075186

julia> ts[1:5, 2:3]
(5 x 2) TSFrame with Int64 Index

 Index  x2        x3
 Int64  Float64   Float64
───────────────────────────
     1  0.768448  0.768448
     2  0.940515  0.940515
     3  0.673959  0.673959
     4  0.395453  0.395453
     5  0.313244  0.313244

# individual rows
julia> ts[[1, 9]]
(2 x 3) TSFrame with Int64 Index

 Index  x1        x2        x3
 Int64  Float64   Float64   Float64
─────────────────────────────────────
     1  0.768448  0.768448  0.768448
     9  0.26864   0.26864   0.26864

julia> ts[:, :x1]            # returns a Vector
10-element Vector{Float64}:
 0.7684476751965699
 0.940515000715187
 0.6739586945680673
 0.3954531123351086
 0.3132439558075186
 0.6625548164736534
 0.5860221243068029
 0.05213316316865657
 0.26863956854495097
 0.10887074134844155


julia> ts[:, [:x1, :x2]]
(10 x 2) TSFrame with Int64 Index

 Index  x1         x2
 Int64  Float64    Float64
─────────────────────────────
     1  0.768448   0.768448
     2  0.940515   0.940515
     3  0.673959   0.673959
     4  0.395453   0.395453
     5  0.313244   0.313244
     6  0.662555   0.662555
     7  0.586022   0.586022
     8  0.0521332  0.0521332
     9  0.26864    0.26864
    10  0.108871   0.108871


julia> dates = collect(Date(2007):Day(1):Date(2008, 2, 22));
julia> ts = TSFrame(random(length(dates)), dates)
julia> show(ts[1:10])
(10 x 1) TSFrame with Date Index

 Index       x1
 Date        Float64
───────────────────────
 2007-01-01  0.768448
 2007-01-02  0.940515
 2007-01-03  0.673959
 2007-01-04  0.395453
 2007-01-05  0.313244
 2007-01-06  0.662555
 2007-01-07  0.586022
 2007-01-08  0.0521332
 2007-01-09  0.26864
 2007-01-10  0.108871

julia> ts[Date(2007, 01, 01)]
(1 x 1) TSFrame with Dates.Date Index

 Index       x1
 Date        Float64
──────────────────────
 2007-01-01  0.768448


julia> ts[[Date(2007, 1, 1), Date(2007, 1, 2)]]
(2 x 1) TSFrame with Date Index

 Index       x1       
 Date        Float64  
──────────────────────
 2007-01-01  0.768448
 2007-01-02  0.940515


julia> ts[[Date(2007, 1, 1), Date(2007, 1, 2)], :x1]
2-element Vector{Float64}:
 0.7684476751965699
 0.940515000715187


julia> ts[Date(2007)]
(1 x 1) TSFrame with Dates.Date Index

 Index       x1
 Date        Float64
──────────────────────
 2007-01-01  0.768448


julia> ts[Year(2007)]
(365 x 1) TSFrame with Dates.Date Index

 Index       x1
 Date        Float64
───────────────────────
 2007-01-01  0.768448
 2007-01-02  0.940515
 2007-01-03  0.673959
 2007-01-04  0.395453
 2007-01-05  0.313244
 2007-01-06  0.662555
 2007-01-07  0.586022
 2007-01-08  0.0521332
     ⋮           ⋮
 2007-12-24  0.468421
 2007-12-25  0.0246652
 2007-12-26  0.171042
 2007-12-27  0.227369
 2007-12-28  0.695758
 2007-12-29  0.417124
 2007-12-30  0.603757
 2007-12-31  0.346659
       349 rows omitted


julia> ts[Year(2007), Month(11)]
(30 x 1) TSFrame with Date Index

 Index       x1
 Date        Float64
───────────────────────
 2007-11-01  0.214132
 2007-11-02  0.672281
 2007-11-03  0.373938
 2007-11-04  0.317985
 2007-11-05  0.110226
 2007-11-06  0.797408
 2007-11-07  0.095699
 2007-11-08  0.186565
 2007-11-09  0.586859
 2007-11-10  0.623613
 2007-11-11  0.62035
 2007-11-12  0.830895
 2007-11-13  0.72423
 2007-11-14  0.493046
 2007-11-15  0.767975
 2007-11-16  0.462157
 2007-11-17  0.779754
 2007-11-18  0.398596
 2007-11-19  0.941196
 2007-11-20  0.578657
 2007-11-21  0.702451
 2007-11-22  0.746427
 2007-11-23  0.301046
 2007-11-24  0.619772
 2007-11-25  0.425161
 2007-11-26  0.410939
 2007-11-27  0.0883656
 2007-11-28  0.135477
 2007-11-29  0.693611
 2007-11-30  0.557009


julia> ts[Year(2007), Quarter(2)];


julia> ts["2007-01-01"]
(1 x 1) TSFrame with Date Index

 Index       x1
 Date        Float64
──────────────────────
 2007-01-01  0.768448


julia> ts[1, :x1]  # returns a scalar
0.7684476751965699


julia> ts[1, "x1"]; # same as above

```
"""
###
## Internal helpers
###

# Locate `dt` in the TSFrame index, throwing KeyError if not present.
# Centralises the searchsortedfirst + bounds-check + equality guard used
# by every TimeType-based getindex method.
@inline function _exact_index_or_throw(ts::TSFrame, dt)
    idx_vec = index(ts)
    i = searchsortedfirst(idx_vec, dt)
    (i > length(idx_vec) || idx_vec[i] != dt) && throw(KeyError(dt))
    return i
end

###
## Row-Column interfaces
###

### Inputs: row scalar, column scalar; Output: scalar
function Base.getindex(ts::TSFrame, i::Int, j::Int)
    return ts.coredata[i,j+1]
end

function Base.getindex(ts::TSFrame, i::Int, j::Union{Symbol, String})
    return ts.coredata[i, j]
end

function Base.getindex(ts::TSFrame, dt::T, j::Int) where {T<:TimeType}
    i = _exact_index_or_throw(ts, dt)
    ts.coredata[i, j+1]
end

function Base.getindex(ts::TSFrame, dt::T, j::Union{String, Symbol}) where {T<:TimeType}
    i = _exact_index_or_throw(ts, dt)
    ts.coredata[i, j]
end
###

### Inputs: row scalar, column vector; Output: TSFrame
function Base.getindex(ts::TSFrame, i::Int, j::AbstractVector{Int})
    TSFrame(ts.coredata[[i], Cols(:Index, j.+1)]) # increment: account for Index
end

function Base.getindex(ts::TSFrame, i::Int, j::AbstractVector{T}) where {T<:Union{String, Symbol}}
    TSFrame(ts.coredata[[i], Cols(:Index, j)])
end

function Base.getindex(ts::TSFrame, dt::T, j::AbstractVector{Int}) where {T<:TimeType}
    i = _exact_index_or_throw(ts, dt)
    ts[i, j]
end

function Base.getindex(ts::TSFrame, dt::D, j::AbstractVector{T}) where {D<:TimeType, T<:Union{String, Symbol}}
    i = _exact_index_or_throw(ts, dt)
    ts[i, j]
end
###

### Inputs: row scalar, column range; Output: TSFrame
function Base.getindex(ts::TSFrame, i::Int, j::UnitRange)
    return TSFrame(ts.coredata[[i], Cols(:Index, 1 .+(j))])
end
###

### Inputs: row vector, column scalar; Output: vector
function Base.getindex(ts::TSFrame, i::AbstractVector{Int}, j::Int)
    ts.coredata[i, j+1] # increment: account for Index
end

function Base.getindex(ts::TSFrame, i::AbstractVector{Int}, j::Union{String, Symbol})
    ts.coredata[i, j]
end

function Base.getindex(ts::TSFrame, dt::AbstractVector{T}, j::Int) where {T<:TimeType}
    row_indices = [_exact_index_or_throw(ts, d) for d in dt]
    ts[row_indices, j]
end

function Base.getindex(ts::TSFrame, dt::AbstractVector{T}, j::Union{String, Symbol}) where {T<:TimeType}
    row_indices = [_exact_index_or_throw(ts, d) for d in dt]
    ts[row_indices, j]
end
###

### Inputs: row vector, column vector; Output: TSFrame
function Base.getindex(ts::TSFrame, i::AbstractVector{Int}, j::AbstractVector{Int})
    TSFrame(ts.coredata[i, Cols(:Index, j.+1)]) # increment: account for Index
end

function Base.getindex(ts::TSFrame, i::AbstractVector{Int}, j::AbstractVector{T}) where {T<:Union{String, Symbol}}
    TSFrame(ts.coredata[i, Cols(:Index, j)])
end

function Base.getindex(ts::TSFrame, dt::AbstractVector{T}, j::AbstractVector{Int}) where {T<:TimeType}
    row_indices = [_exact_index_or_throw(ts, d) for d in dt]
    ts[row_indices, j]
end

function Base.getindex(ts::TSFrame, dt::AbstractVector{D}, j::AbstractVector{T}) where {D<:TimeType, T<:Union{String, Symbol}}
    row_indices = [_exact_index_or_throw(ts, d) for d in dt]
    ts[row_indices, j]
end
###

### Inputs: row vector, column range; Output: TSFrame
function Base.getindex(ts::TSFrame, i::AbstractVector{Int}, j::UnitRange)
    ts[i, collect(j)]
end

function Base.getindex(ts::TSFrame, dt::AbstractVector{T}, j::UnitRange) where {T<:TimeType}
    ts[dt, collect(j)]
end
###


### Inputs: row range, column scalar: return a vector
function Base.getindex(ts::TSFrame, i::UnitRange, j::Int)
    ts[collect(i), j]
end

function Base.getindex(ts::TSFrame, i::UnitRange, j::Union{String, Symbol})
    ts[collect(i), j]
end
###

### Inputs: row range, column vector: return TSFrame
function Base.getindex(ts::TSFrame, i::UnitRange, j::AbstractVector{Int})
    ts[collect(i), j]
end

function Base.getindex(ts::TSFrame, i::UnitRange, j::AbstractVector{T}) where {T<:Union{String, Symbol}}
    ts[collect(i), j]
end
###

### Inputs: row range, column range: return TSFrame
function Base.getindex(ts::TSFrame, i::UnitRange, j::UnitRange)
    ts[collect(i), collect(j)]
end


###
## Row indexing interfaces
###

function Base.getindex(ts::TSFrame, i::Int)
    ts[i, 1:TSFrames.ncol(ts)]
end

function Base.getindex(ts::TSFrame, i::UnitRange)
    ts[i, 1:TSFrames.ncol(ts)]
end

function Base.getindex(ts::TSFrame, i::AbstractVector{Int64})
    ts[i, 1:TSFrames.ncol(ts)]
end

function Base.getindex(ts::TSFrame, dt::AbstractVector{T}) where {T<:TimeType}
    ts[dt, 1:TSFrames.ncol(ts)]
end

function Base.getindex(ts::TSFrame, d::T) where {T<:TimeType}
    i = _exact_index_or_throw(ts, d)
    ts[[i], 1:TSFrames.ncol(ts)]
end

# By period
#
# Constant for quarter-to-month conversion.
const MONTHS_PER_QUARTER = 3

# Helper: binary range search for period-based indexing.
# Returns all rows where lo_dt <= Index < hi_exclusive_dt.
# Adapts DateTime boundaries to the actual index element type (Date or DateTime).
# Requires index(ts) to be sorted in ascending order (guaranteed by the TSFrame
# constructor invariant).
function _binary_period_range(ts::TSFrame, lo_dt::DateTime, hi_exclusive_dt::DateTime)
    T = eltype(index(ts))
    idx = index(ts)
    lo = T === Date ? Date(lo_dt) : lo_dt
    hi = T === Date ? Date(hi_exclusive_dt) : hi_exclusive_dt
    first_idx = searchsortedfirst(idx, lo)
    last_idx  = searchsortedfirst(idx, hi) - 1
    ts[first_idx:last_idx]
end

# Central dispatch for period-based binary-search queries.
# `step` is the duration of the query window (Year(1), Month(3), Day(1), etc.).
# `args` are the DateTime component integers (year, month, day, hour, …) already
# extracted via Dates.value().
#
# Explicit range checks prevent Hour(24)-style silent rollovers: Julia's DateTime
# constructor uniquely accepts hour=24 and rolls it to the next day, so we guard
# before calling it. Other out-of-range components (Month(13), Minute(61), etc.)
# are caught by the try/catch fallback.
function _period_window(ts::TSFrame, step::Period, args::Int...)
    n = length(args)
    n >= 2 && !(1 <= args[2] <= 12)  && return ts[1:0]   # month
    n >= 3 && !(1 <= args[3] <= 31)  && return ts[1:0]   # day (DateTime validates further)
    n >= 4 && !(0 <= args[4] <= 23)  && return ts[1:0]   # hour — guards Hour(24) rollover
    n >= 5 && !(0 <= args[5] <= 59)  && return ts[1:0]   # minute
    n >= 6 && !(0 <= args[6] <= 59)  && return ts[1:0]   # second
    n >= 7 && !(0 <= args[7] <= 999) && return ts[1:0]   # millisecond
    local lo::DateTime, hi::DateTime
    try
        lo = DateTime(args...)
        hi = lo + step
    catch e
        (e isa ArgumentError || e isa InexactError || e isa OverflowError) || rethrow()
        return ts[1:0]
    end
    _binary_period_range(ts, lo, hi)
end

# Helper: filter rows where the tuple of period extractors applied to
# the Index matches the given values.  Each extractor is the *type
# constructor* used as a function (e.g. `Year`, `Month`).  `_period_matches`
# is `@generated` so the compiler unrolls the per-extractor comparisons at
# compile time, eliminating the per-row tuple allocation that a runtime
# generator would otherwise produce.
@generated function _period_matches(extractors::E, values::V, x) where {E<:Tuple, V<:Tuple}
    N = length(E.parameters)
    N == 0 && return :true
    exprs = [:(extractors[$i](x) == values[$i]) for i in 1:N]
    return Expr(:&&, exprs...)
end

function _filter_by_period(ts::TSFrame, extractors::Tuple, values::Tuple)
    sdf = filter(:Index => x -> _period_matches(extractors, values, x), ts.coredata)
    TSFrame(sdf; issorted=true, copycols=false)
end

function Base.getindex(ts::TSFrame, y::Year)
    _period_window(ts, Year(1), Dates.value(y), 1, 1)
end

function Base.getindex(ts::TSFrame, y::Year, q::Quarter)
    qv = Dates.value(q)
    1 <= qv <= 4 || return ts[1:0]
    m_start = (qv - 1) * MONTHS_PER_QUARTER + 1
    _period_window(ts, Month(3), Dates.value(y), m_start, 1)
end

# XXX: ideally, Dates.YearMonth class should exist
function Base.getindex(ts::TSFrame, y::Year, m::Month)
    _period_window(ts, Month(1), Dates.value(y), Dates.value(m), 1)
end

# Week-based indexing stays on the exact-match filter path because ISO week
# numbers do not map to a contiguous [lo, hi) datetime window within a month.
function Base.getindex(ts::TSFrame, y::Year, m::Month, w::Week)
    _filter_by_period(ts, (Year, Month, Week), (y, m, w))
end

function Base.getindex(ts::TSFrame, y::Year, m::Month, d::Day)
    _period_window(ts, Day(1), Dates.value(y), Dates.value(m), Dates.value(d))
end

function Base.getindex(ts::TSFrame, y::Year, m::Month, d::Day, h::Hour)
    _period_window(ts, Hour(1), Dates.value(y), Dates.value(m), Dates.value(d),
                   Dates.value(h))
end

function Base.getindex(ts::TSFrame, y::Year, m::Month, d::Day, h::Hour, min::Minute)
    _period_window(ts, Minute(1), Dates.value(y), Dates.value(m), Dates.value(d),
                   Dates.value(h), Dates.value(min))
end

function Base.getindex(ts::TSFrame, y::Year, m::Month, d::Day, h::Hour, min::Minute, sec::Second)
    _period_window(ts, Second(1), Dates.value(y), Dates.value(m), Dates.value(d),
                   Dates.value(h), Dates.value(min), Dates.value(sec))
end

function Base.getindex(ts::TSFrame, y::Year, m::Month, d::Day, h::Hour, min::Minute, sec::Second, ms::Millisecond)
    _period_window(ts, Millisecond(1), Dates.value(y), Dates.value(m), Dates.value(d),
                   Dates.value(h), Dates.value(min), Dates.value(sec), Dates.value(ms))
end

# By string timestamp
function Base.getindex(ts::TSFrame, i::String)
    d_date = Date(Dates.parse_components(i, Dates.dateformat"yyyy-mm-dd")...)
    d = eltype(index(ts)) <: DateTime ? DateTime(d_date) : d_date
    first_idx = _exact_index_or_throw(ts, d)
    last_idx = searchsortedlast(index(ts), d)
    ts[first_idx:last_idx]
end

###
## Column indexing with Colon
###

### Inputs: row colon, column scalar: return vector
function Base.getindex(ts::TSFrame, ::Colon, j::Int)
    ts[1:TSFrames.nrow(ts), j]
end

function Base.getindex(ts::TSFrame, ::Colon, j::Union{String, Symbol})
    ts[1:TSFrames.nrow(ts), j]
end
###

### Inputs: row colon, column vector: return TSFrame
function Base.getindex(ts::TSFrame, ::Colon, j::AbstractVector{Int})
    ts[1:TSFrames.nrow(ts), j]
end

function Base.getindex(ts::TSFrame, ::Colon, j::AbstractVector{T}) where {T<:Union{String, Symbol}}
    ts[1:TSFrames.nrow(ts), j]
end
###

### Inputs: row colon, column range: return TSFrame
function Base.getindex(ts::TSFrame, i::Colon, j::UnitRange)
    ts[1:TSFrames.nrow(ts), collect(j)]
end
###
