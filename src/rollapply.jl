"""
# Rolling Functions
```julia
rollapply(ts::TSFrame, fun::Function, windowsize::Int; bycolumn=true)
```
Apply function `fun` to rolling windows of `ts`. The output is a
`TSFrame` object with `(nrow(ts) - windowsize + 1)` rows indexed with
the last index value of each window.

The `bycolumn` argument should be set to `true` (default) if `fun` is
to be applied to each column separately, and to `false` if `fun` takes
a whole `TSFrame` as an input.

When `bycolumn=true` and `fun` is one of a small set of well-known
reductions (`mean`, `std`, `var`, `maximum`, `minimum`, `median`), the
implementation dispatches to the corresponding fast routine in
`RollingFunctions.jl`. For arbitrary functions (including `sum`), a
generic per-column rolling implementation is used (also backed by
`RollingFunctions.rolling`), avoiding the previous per-window DataFrame
allocations. The `bycolumn=false` path applies `fun` to a sliced
`TSFrame` window as before.

!!! note "Integer columns are widened to `Float64`"
    When `bycolumn=true` and `fun` is one of the fast-path functions
    listed above, integer columns will be widened to `Float64` in the
    output. This is a consequence of the underlying
    `RollingFunctions.jl` implementation, which always returns
    `Float64` arrays.

!!! note "Errors on oversized windows"
    `rollapply` throws an `ArgumentError` when `windowsize > nrow(ts)`.
    Previously this case emitted a warning and clamped the window to
    `nrow(ts)`; the explicit error makes the contract unambiguous.

# Examples
```jldoctest; setup = :(using TSFrames, DataFrames, Statistics, StatsModels, StatsBase, GLM, Dates)
julia> rollapply(TSFrame([1:10 11:20]), mean, 5)
6×2 TSFrame with Int64 Index
 Index  rolling_x1_mean  rolling_x2_mean
 Int64  Float64          Float64
─────────────────────────────────────────
     5              3.0             13.0
     6              4.0             14.0
     7              5.0             15.0
     8              6.0             16.0
     9              7.0             17.0
    10              8.0             18.0

julia> dates = Date(2001, 1, 1):Day(1):Date(2001, 1, 10);
julia> df = DataFrame(Index=dates, inrchf=1:10, usdchf=1:10, eurchf=1:10, gbpchf=1:10, jpychf=1:10);
julia> ts = TSFrame(df)
10×5 TSFrame with Date Index
 Index       inrchf  usdchf  eurchf  gbpchf  jpychf
 Date        Int64   Int64   Int64   Int64   Int64
────────────────────────────────────────────────────
 2001-01-01       1       1       1       1       1
 2001-01-02       2       2       2       2       2
 2001-01-03       3       3       3       3       3
 2001-01-04       4       4       4       4       4
 2001-01-05       5       5       5       5       5
 2001-01-06       6       6       6       6       6
 2001-01-07       7       7       7       7       7
 2001-01-08       8       8       8       8       8
 2001-01-09       9       9       9       9       9
 2001-01-10      10      10      10      10      10

julia> function regress(ts)     # defining function for multiple regressions
            ll = lm(@formula(inrchf ~ usdchf + eurchf + gbpchf + jpychf), ts.coredata[:, Not(:Index)])
            co = coef(ll)[coefnames(ll) .== "usdchf"]
            sd = Statistics.std(residuals(ll))
            return (co, sd)
       end

julia> rollapply(ts, regress, 5; bycolumn=false)    # doing multiple regressions
6×1 TSFrame with Date Index
 Index       rolling_regress
 Date        Tuple…
──────────────────────────────────
 2001-01-05  ([1.0], 9.93014e-17)
 2001-01-06  ([1.0], 1.27168e-15)
 2001-01-07  ([1.0], 4.86475e-16)
 2001-01-08  ([1.0], 7.43103e-16)
 2001-01-09  ([1.0], 7.45753e-15)
 2001-01-10  ([1.0], 9.28561e-15)
```
"""
# Mapping from common Julia reductions to their RollingFunctions equivalents.
# `Statistics.mean`/`std`/`var`/`median` and `Base.maximum`/`Base.minimum`
# are covered. `sum` does not have a `rollsum` in RollingFunctions, so it is
# intentionally absent here and is routed through the generic
# `rolling(sum, ...)` path inside the implementation.
const _ROLLING_FAST_FUNCS = IdDict{Function, Function}(
    Statistics.mean   => RollingFunctions.rollmean,
    Statistics.std    => RollingFunctions.rollstd,
    Statistics.var    => RollingFunctions.rollvar,
    Statistics.median => RollingFunctions.rollmedian,
    maximum           => RollingFunctions.rollmax,
    minimum           => RollingFunctions.rollmin,
)

function rollapply(ts::TSFrame, fun::Function, windowsize::Int; bycolumn=true)
    if windowsize < 1
        throw(ArgumentError("windowsize must be greater than or equal to 1"))
    end

    n = TSFrames.nrow(ts)

    # Empty TSFrame guard: return a fresh empty TSFrame (no aliasing).
    if n == 0
        return TSFrame(copy(ts.coredata), :Index; issorted=true, copycols=false)
    end

    if windowsize > n
        throw(ArgumentError("windowsize ($windowsize) exceeds nrow(ts) ($n)"))
    end

    if bycolumn
        return _rollapply_bycolumn(ts, fun, windowsize)
    else
        return _rollapply_byframe(ts, fun, windowsize)
    end
end

# Per-column rolling implementation. Uses RollingFunctions fast paths when
# possible and falls back to the generic `rolling(fun, vec, w)` for unknown
# functions. Either way we avoid slicing the TSFrame per window.
function _rollapply_bycolumn(ts::TSFrame, fun::Function, windowsize::Int)
    fast = get(_ROLLING_FAST_FUNCS, fun, nothing)

    src_cols = DataFrames.names(ts.coredata, Not(:Index))
    suffix = string("_", Symbol(fun))

    result_df = DataFrame()
    result_df.Index = TSFrames.index(ts)[windowsize:end]

    for col in src_cols
        v = ts.coredata[!, col]
        rolled = fast === nothing ?
            RollingFunctions.rolling(fun, v, windowsize) :
            fast(v, windowsize)
        result_df[!, Symbol("rolling_", col, suffix)] = rolled
    end

    return TSFrame(result_df; issorted=true, copycols=false)
end

# `bycolumn=false` path: behaviour-preserving rewrite of the original loop.
# Each window is materialised as a sliced TSFrame and `fun` is applied to it.
function _rollapply_byframe(ts::TSFrame, fun::Function, windowsize::Int)
    n_results = TSFrames.nrow(ts) - windowsize + 1
    res = Vector{Any}(undef, n_results)
    for (ri, endindex) in enumerate(windowsize:TSFrames.nrow(ts))
        currentWindow = ts[endindex - windowsize + 1:endindex]
        res[ri] = fun(currentWindow)
    end

    res_df = DataFrame(Index=TSFrames.index(ts)[windowsize:end], outputs=res)
    DataFrames.rename!(res_df, Dict(:outputs => string("rolling_", Symbol(fun))))
    return TSFrame(res_df; issorted=true, copycols=false)
end
