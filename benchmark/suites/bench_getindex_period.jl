# Benchmark: period-based getindex
#
# Tests:
#   - ts[Year(y)]                 — year window (O(log n) since v0.3.4)
#   - ts[Year(y), Month(m)]       — month window
#   - ts[Year(y), Month(m), Day(d)] — day window
#   - ts[from:to]                 — UnitRange slice
#   - ts[dt]                      — scalar DateTime lookup
#
# Note: Regression guard for the O(n)→O(log n) binary-search refactor
# introduced in v0.3.4 (getindex.jl _binary_period_range / _period_window).

using BenchmarkTools, Dates, DataFrames, Random
using TSFrames

const BENCH_GETINDEX_PERIOD = BenchmarkGroup()

for (label, n) in [("small", 1_000), ("medium", 25_000), ("large", 1_000_000)]
    rng = MersenneTwister(42)

    # Minute-resolution DateTime index spanning multiple years
    datetimes = DateTime(2000, 1, 1) .+ Minute.(0:n-1)
    prices = cumsum(randn(rng, n)) .+ 100.0
    ts = TSFrame(DataFrame(Index=datetimes, close=prices); issorted=true, copycols=false)

    # Anchor points guaranteed to be inside the series
    mid_year  = year(datetimes[div(n, 2)])
    mid_month = month(datetimes[div(n, 2)])
    mid_day   = day(datetimes[div(n, 2)])
    mid_dt    = datetimes[div(n, 2)]

    grp = BenchmarkGroup()

    grp["year"]       = @benchmarkable $ts[Year($mid_year)]
    grp["year_month"] = @benchmarkable $ts[Year($mid_year), Month($mid_month)]
    grp["year_month_day"] = @benchmarkable $ts[Year($mid_year), Month($mid_month), Day($mid_day)]

    # Scalar DateTime lookup (single row, used in iteration)
    grp["scalar_dt"]  = @benchmarkable $ts[$mid_dt]

    # UnitRange slice (sanity check that integer path is still fast)
    lo = div(n, 4)
    hi = div(3n, 4)
    grp["range_slice"] = @benchmarkable $ts[$lo:$hi]

    BENCH_GETINDEX_PERIOD[label] = grp
end
