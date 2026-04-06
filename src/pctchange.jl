"""
# Percent Change

```julia
pctchange(ts::TSFrame, periods::Int = 1)
```

Return the percentage change between successive row elements.
Default is the element in the next row. `periods` defines the number
of rows to be shifted over. The skipped rows are rendered as `missing`.

`pctchange` returns an error if column type does not have the method `/`.

# Computation

This implementation uses the absolute value of the lagged element in
the denominator:

    (x_t - x_{t-periods}) / abs(x_{t-periods})

# Note: Difference from pandas / R

This differs from the standard `pct_change` definition used by pandas
(`DataFrame.pct_change`) and R (e.g. `(x - dplyr::lag(x)) / dplyr::lag(x)`),
which divide by the signed lagged value:

    (x_t - x_{t-periods}) / x_{t-periods}

The two definitions agree when the lagged value is positive, but
differ in sign when the lagged value is negative. For a negative
previous value, the standard formula flips the sign of the result,
while this implementation does not (because `abs(...)` keeps the
denominator positive). If you need pandas/R-compatible behavior on
series that may contain negative values, compute the percent change
manually using `lag` (without `abs`).

# Examples
```jldoctest; setup = :(using TSFrames, DataFrames, Dates, Random, Statistics)
julia> using Random, Statistics;

julia> random(x) = rand(MersenneTwister(123), x);

julia> dates = collect(Date(2017,1,1):Day(1):Date(2017,1,10));

julia> ts = TSFrame(random(length(dates)), dates)
julia> show(ts)
(10 x 1) TSFrame with Date Index

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

# Pctchange over successive rows
julia> pctchange(ts)
(10 x 1) TSFrame with Date Index

 Index       x1
 Date        Float64?
────────────────────────────
 2017-01-01  missing
 2017-01-02        0.223915
 2017-01-03       -0.283415
 2017-01-04       -0.413238
 2017-01-05       -0.207886
 2017-01-06        1.11514
 2017-01-07       -0.115511
 2017-01-08       -0.911039
 2017-01-09        4.15295
 2017-01-10       -0.594733


# Pctchange over the third row
julia> pctchange(ts, 3)
(10 x 1) TSFrame with Date Index

 Index       x1
 Date        Float64?
─────────────────────────────
 2017-01-01  missing
 2017-01-02  missing
 2017-01-03  missing
 2017-01-04       -0.485387
 2017-01-05       -0.666944
 2017-01-06       -0.0169207
 2017-01-07        0.4819
 2017-01-08       -0.83357
 2017-01-09       -0.59454
 2017-01-10       -0.814221

```
"""

# Pctchange
function pctchange(ts::TSFrame, periods::Int = 1)
    if periods <= 0
        throw(ArgumentError("periods must be a positive int"))
    end
    data = ts.coredata[!, Not(:Index)]
    # copycols=false: ShiftedArrays.lag returns lazy views; the broadcast below
    # creates a fresh DataFrame so lagged_data never aliases ts.coredata.
    lagged_data = DataFrame(ShiftedArrays.lag.(eachcol(data), periods), TSFrames.names(ts); copycols=false)
    ddf = (data .- lagged_data) ./ abs.(lagged_data)
    _wrap_with_index(ddf, index(ts))
end
