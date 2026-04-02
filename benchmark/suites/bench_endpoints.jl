# Benchmark: endpoints() function
#
# Tests endpoints() with various period types:
#   - endpoints(ts, Month(1))
#   - endpoints(ts, Week(1))
#   - endpoints(ts, Year(1))
#   - endpoints(ts, Quarter(1))

using BenchmarkTools, Dates, DataFrames, Random
using TSFrames

const BENCH_ENDPOINTS = BenchmarkGroup()

for (label, n) in [("small", 100), ("medium", 10_000), ("large", 1_000_000)]
    rng = MersenneTwister(42)
    dates = Date(2000, 1, 1) .+ Day.(0:n-1)
    close_prices = cumsum(randn(rng, n)) .+ 100.0
    ts = TSFrame(DataFrame(Index=dates, close=close_prices); issorted=true, copycols=false)

    grp = BenchmarkGroup()

    grp["weekly"]    = @benchmarkable endpoints($ts, Week(1))
    grp["monthly"]   = @benchmarkable endpoints($ts, Month(1))
    grp["quarterly"] = @benchmarkable endpoints($ts, Quarter(1))
    grp["yearly"]    = @benchmarkable endpoints($ts, Year(1))

    # Also test Symbol-based API
    grp["symbol_months"] = @benchmarkable endpoints($ts, :months)
    grp["symbol_weeks"]  = @benchmarkable endpoints($ts, :weeks)

    BENCH_ENDPOINTS[label] = grp
end
