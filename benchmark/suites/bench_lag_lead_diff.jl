# Benchmark: lag(), lead(), diff(), pctchange()
#
# Tests:
#   - lag(ts), lag(ts, 5), lag(ts, -3)
#   - lead(ts), lead(ts, 5)
#   - diff(ts), diff(ts, 5)
#   - pctchange(ts), pctchange(ts, 5)

using BenchmarkTools, Dates, DataFrames, Random
using TSFrames

const BENCH_LAG_LEAD_DIFF = BenchmarkGroup()

for (label, n) in [("small", 1_000), ("medium", 25_000), ("large", 1_000_000)]
    rng = MersenneTwister(42)
    dates = Date(2000, 1, 1) .+ Day.(0:n-1)
    close_prices = cumsum(randn(rng, n)) .+ 100.0
    volume = abs.(randn(rng, n)) .* 1_000_000
    ts = TSFrame(DataFrame(Index=dates, close=close_prices, volume=volume); issorted=true, copycols=false)

    grp = BenchmarkGroup()

    # lag
    grp["lag_1"]  = @benchmarkable lag($ts)
    grp["lag_5"]  = @benchmarkable lag($ts, 5)
    grp["lag_neg3"] = @benchmarkable lag($ts, -3)

    # lead
    grp["lead_1"] = @benchmarkable lead($ts)
    grp["lead_5"] = @benchmarkable lead($ts, 5)

    # diff
    grp["diff_1"] = @benchmarkable diff($ts)
    grp["diff_5"] = @benchmarkable diff($ts, 5)

    # pctchange
    grp["pctchange_1"] = @benchmarkable pctchange($ts)
    grp["pctchange_5"] = @benchmarkable pctchange($ts, 5)

    BENCH_LAG_LEAD_DIFF[label] = grp
end
