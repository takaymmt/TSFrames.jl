# Benchmark: rollapply() function
#
# Tests:
#   - rollapply(ts, mean, 5)              — bycolumn=true (default)
#   - rollapply(ts, sum, 20)              — bycolumn=true
#   - rollapply(ts, std, 10)              — bycolumn=true (small/medium only)
#   - rollapply(ts, identity, 5; bycolumn=false) — whole-window path
#
# Note: rollapply with large data is expensive, so large size uses
# a reduced row count for practical benchmark times.
# bycolumn=false exercises a separate code path (Vector{Any} + fun(TSFrame)).

using BenchmarkTools, Dates, DataFrames, Random, Statistics
using TSFrames

const BENCH_ROLLAPPLY = BenchmarkGroup()

# rollapply is O(n*w) and allocates per window, so we use smaller sizes
for (label, n) in [("small", 1_000), ("medium", 25_000), ("large", 100_000)]
    rng = MersenneTwister(42)
    dates = Date(2000, 1, 1) .+ Day.(0:n-1)
    close_prices = cumsum(randn(rng, n)) .+ 100.0
    ts = TSFrame(DataFrame(Index=dates, close=close_prices); issorted=true, copycols=false)

    grp = BenchmarkGroup()

    grp["mean_w5"]  = @benchmarkable rollapply($ts, mean, 5)
    grp["sum_w20"]  = @benchmarkable rollapply($ts, sum, 20)

    # std only for small/medium to avoid very long bench times
    if n <= 25_000
        grp["std_w10"] = @benchmarkable rollapply($ts, std, 10)
    end

    # bycolumn=false: whole-window function receives a TSFrame slice
    grp["bycolumn_false_w5"] = @benchmarkable rollapply($ts, ts -> TSFrames.nrow(ts), 5; bycolumn=false)

    BENCH_ROLLAPPLY[label] = grp
end
