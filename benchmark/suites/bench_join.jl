# Benchmark: join() function
#
# Tests:
#   - join(ts1, ts2; jointype=:JoinInner)
#   - join(ts1, ts2; jointype=:JoinOuter)
#   - join(ts1, ts2; jointype=:JoinLeft)
# With overlapping and non-overlapping date ranges.

using BenchmarkTools, Dates, DataFrames, Random
using TSFrames

const BENCH_JOIN = BenchmarkGroup()

for (label, n) in [("small", 100), ("medium", 10_000), ("large", 1_000_000)]
    rng1 = MersenneTwister(42)
    rng2 = MersenneTwister(43)

    # ts1: first n days
    dates1 = Date(2000, 1, 1) .+ Day.(0:n-1)
    ts1 = TSFrame(DataFrame(Index=dates1, x1=cumsum(randn(rng1, n)) .+ 100.0); issorted=true, copycols=false)

    # ts2: overlapping range (shifted by n/2 days)
    half = n >> 1
    dates2 = Date(2000, 1, 1) .+ Day.(half:half+n-1)
    ts2 = TSFrame(DataFrame(Index=dates2, x2=cumsum(randn(rng2, n)) .+ 100.0); issorted=true, copycols=false)

    grp = BenchmarkGroup()

    grp["inner"] = @benchmarkable join($ts1, $ts2; jointype=:JoinInner)
    grp["outer"] = @benchmarkable join($ts1, $ts2; jointype=:JoinOuter)
    grp["left"]  = @benchmarkable join($ts1, $ts2; jointype=:JoinLeft)

    BENCH_JOIN[label] = grp
end
