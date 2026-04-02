# Benchmark: vcat() function
#
# Tests:
#   - vcat(ts1, ts2) with same columns (union)
#   - vcat(ts1, ts2; colmerge=:intersect) with different columns

using BenchmarkTools, Dates, DataFrames, Random
using TSFrames

const BENCH_VCAT = BenchmarkGroup()

for (label, n) in [("small", 100), ("medium", 10_000), ("large", 1_000_000)]
    rng1 = MersenneTwister(42)
    rng2 = MersenneTwister(43)

    # ts1: first n days, columns x1
    dates1 = Date(2000, 1, 1) .+ Day.(0:n-1)
    ts1 = TSFrame(DataFrame(Index=dates1, x1=cumsum(randn(rng1, n)) .+ 100.0); issorted=true, copycols=false)

    # ts2: next n days, columns x1 (same schema)
    dates2 = Date(2000, 1, 1) .+ Day.(n:2n-1)
    ts2_same = TSFrame(DataFrame(Index=dates2, x1=cumsum(randn(rng2, n)) .+ 100.0); issorted=true, copycols=false)

    # ts2_diff: next n days, columns x2 (different schema)
    ts2_diff = TSFrame(DataFrame(Index=dates2, x2=cumsum(randn(rng2, n)) .+ 100.0); issorted=true, copycols=false)

    grp = BenchmarkGroup()

    grp["same_cols_union"]     = @benchmarkable vcat($ts1, $ts2_same)
    grp["diff_cols_union"]     = @benchmarkable vcat($ts1, $ts2_diff)
    grp["diff_cols_intersect"] = @benchmarkable vcat($ts1, $ts2_diff; colmerge=:intersect)

    BENCH_VCAT[label] = grp
end
