# Benchmark: resample() with fill_gaps strategies
#
# Measures performance of the gap-filling code paths:
#   fill_gaps=true (:missing)  — insert gap rows only
#   fill_gaps=:ffill           — forward fill
#   fill_gaps=:bfill           — backward fill
#   fill_gaps=:zero            — fill with zero
#   fill_gaps=:interpolate     — linear interpolation
#
# Three data sizes × gap density levels × fill strategies.
# Compatibility: if TSFrames does not export `resample` or the fill_gaps
# keyword is not supported, BENCH_RESAMPLE_FILL_GAPS is left empty.

using BenchmarkTools, Dates, DataFrames, Random, Statistics
using TSFrames

const _HAS_RESAMPLE_FILL_GAPS = isdefined(TSFrames, :resample)

const BENCH_RESAMPLE_FILL_GAPS = BenchmarkGroup()

if _HAS_RESAMPLE_FILL_GAPS
    for (label, n) in [("small", 1_000), ("medium", 25_000), ("large", 1_000_000)]
        rng = MersenneTwister(42)

        # Sparse daily data with ~20% gaps: sample n*0.8 of n daily dates
        all_dates = Date(2000, 1, 1) .+ Day.(0:n-1)
        n_keep = round(Int, n * 0.8)
        sampled_idx = sort(randperm(rng, n)[1:n_keep])
        dates = all_dates[sampled_idx]
        close_prices = cumsum(randn(rng, n_keep)) .+ 100.0

        ts = TSFrame(DataFrame(Index=dates, close=close_prices); issorted=true, copycols=false)

        grp = BenchmarkGroup()

        grp["missing"]     = @benchmarkable resample($ts, Month(1), :close => last; fill_gaps=true)
        grp["ffill"]       = @benchmarkable resample($ts, Month(1), :close => last; fill_gaps=:ffill)
        grp["bfill"]       = @benchmarkable resample($ts, Month(1), :close => last; fill_gaps=:bfill)
        grp["zero"]        = @benchmarkable resample($ts, Month(1), :close => last; fill_gaps=:zero)
        grp["interpolate"] = @benchmarkable resample($ts, Month(1), :close => last; fill_gaps=:interpolate)

        BENCH_RESAMPLE_FILL_GAPS[label] = grp
    end
end
