# Benchmark: subset() function
#
# Tests:
#   - subset(ts, from, to)          — Date index, full overlap
#   - subset(ts, from, :)           — Date index, open right
#   - subset(ts, :, to)             — Date index, open left
#   - subset(ts, from, to)          — Int index
#
# Note: Establishes baseline before planned O(n)->O(log n) binary-search
# optimisation (review item H5).

using BenchmarkTools, Dates, DataFrames, Random
using TSFrames

const BENCH_SUBSET = BenchmarkGroup()

for (label, n) in [("small", 1_000), ("medium", 25_000), ("large", 1_000_000)]
    rng = MersenneTwister(42)

    # --- Date-indexed TSFrame ---
    dates = Date(2000, 1, 1) .+ Day.(0:n-1)
    prices = cumsum(randn(rng, n)) .+ 100.0
    ts_date = TSFrame(DataFrame(Index=dates, close=prices); issorted=true, copycols=false)

    # Query window: middle 50 % of the range
    q_start = dates[div(n, 4)]
    q_end   = dates[div(3n, 4)]

    # --- Int-indexed TSFrame ---
    ts_int = TSFrame(DataFrame(Index=collect(1:n), close=prices); issorted=true, copycols=false)
    i_start = div(n, 4)
    i_end   = div(3n, 4)

    grp = BenchmarkGroup()

    grp["date_both"]  = @benchmarkable TSFrames.subset($ts_date, $q_start, $q_end)
    grp["date_left"]  = @benchmarkable TSFrames.subset($ts_date, $q_start, :)
    grp["date_right"] = @benchmarkable TSFrames.subset($ts_date, :, $q_end)
    grp["int_both"]   = @benchmarkable TSFrames.subset($ts_int,  $i_start, $i_end)

    BENCH_SUBSET[label] = grp
end
