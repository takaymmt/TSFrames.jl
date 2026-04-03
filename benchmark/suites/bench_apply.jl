# Benchmark: apply() function
#
# Tests apply() with various period/function combinations:
#   - apply(ts, Month(1), last)
#   - apply(ts, Week(1), mean)
#   - apply(ts, Month(1), sum)
#   - apply(ts, Year(1), first)

using BenchmarkTools, Dates, DataFrames, Random, Statistics
using TSFrames

const BENCH_APPLY = BenchmarkGroup()

for (label, n) in [("small", 1_000), ("medium", 25_000), ("large", 1_000_000)]
    rng = MersenneTwister(42)
    dates = Date(2000, 1, 1) .+ Day.(0:n-1)
    close_prices = cumsum(randn(rng, n)) .+ 100.0
    volume = abs.(randn(rng, n)) .* 1_000_000
    ts = TSFrame(DataFrame(Index=dates, close=close_prices, volume=volume); issorted=true, copycols=false)

    grp = BenchmarkGroup()

    # Monthly aggregations
    grp["monthly_last"]  = @benchmarkable apply($ts, Month(1), last)
    grp["monthly_first"] = @benchmarkable apply($ts, Month(1), first)
    grp["monthly_sum"]   = @benchmarkable apply($ts, Month(1), sum)
    grp["monthly_mean"]  = @benchmarkable apply($ts, Month(1), mean)

    # Weekly aggregations
    grp["weekly_last"]   = @benchmarkable apply($ts, Week(1), last)
    grp["weekly_mean"]   = @benchmarkable apply($ts, Week(1), mean)

    # Yearly aggregation
    grp["yearly_first"]  = @benchmarkable apply($ts, Year(1), first)

    BENCH_APPLY[label] = grp
end
