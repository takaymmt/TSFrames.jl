# Benchmark: resample() vs to_period() comparison
#
# Compares equivalent operations:
#   to_weekly(ts)    vs  resample(ts, Week(1), :close => last)
#   to_monthly(ts)   vs  resample(ts, Month(1), :close => last)
#   to_quarterly(ts) vs  resample(ts, Quarter(1), :close => last)
#   to_yearly(ts)    vs  resample(ts, Year(1), :close => last)
#
# Also benchmarks OHLCV resample patterns with various aggregations.
#
# Note: to_period functions take the last row per period (all columns),
# while resample() applies per-column aggregation functions.
# The comparison is conceptual: both downsample to the same period.
#
# Compatibility: if TSFrames does not export `resample`, the resample_*
# sub-groups are omitted and BENCH_RESAMPLE_VS_TO_PERIOD contains only
# the to_period group.  This allows the suite to run against older
# versions of TSFrames without modification.

using BenchmarkTools, Dates, DataFrames, Random, Statistics
using TSFrames

const _HAS_RESAMPLE = isdefined(TSFrames, :resample)

const BENCH_RESAMPLE_VS_TO_PERIOD = BenchmarkGroup()

for (label, n) in [("small", 100), ("medium", 10_000), ("large", 1_000_000)]
    rng = MersenneTwister(42)
    dates = Date(2000, 1, 1) .+ Day.(0:n-1)
    close_prices = cumsum(randn(rng, n)) .+ 100.0
    volume = abs.(randn(rng, n)) .* 1_000_000

    # Single-column TSFrame for to_period vs resample(:close => last)
    ts = TSFrame(DataFrame(Index=dates, close=close_prices, volume=volume); issorted=true, copycols=false)

    grp = BenchmarkGroup()

    # -- to_period() variants --
    tp = BenchmarkGroup()
    tp["weekly"]    = @benchmarkable to_weekly($ts)
    tp["monthly"]   = @benchmarkable to_monthly($ts)
    tp["quarterly"] = @benchmarkable to_quarterly($ts)
    tp["yearly"]    = @benchmarkable to_yearly($ts)
    grp["to_period"] = tp

    if _HAS_RESAMPLE
        # -- resample() with last — conceptual equivalent to to_period --
        rs = BenchmarkGroup()
        rs["weekly_last"]    = @benchmarkable resample($ts, Week(1), :close => last, :volume => last)
        rs["monthly_last"]   = @benchmarkable resample($ts, Month(1), :close => last, :volume => last)
        rs["quarterly_last"] = @benchmarkable resample($ts, Quarter(1), :close => last, :volume => last)
        rs["yearly_last"]    = @benchmarkable resample($ts, Year(1), :close => last, :volume => last)
        grp["resample_last"] = rs

        # -- resample() with mean --
        rm = BenchmarkGroup()
        rm["weekly_mean"]  = @benchmarkable resample($ts, Week(1), :close => mean, :volume => mean)
        rm["monthly_mean"] = @benchmarkable resample($ts, Month(1), :close => mean, :volume => mean)
        grp["resample_mean"] = rm

        # -- OHLCV resample (default auto-detect) --
        rng2 = MersenneTwister(42)
        open_prices  = cumsum(randn(rng2, n)) .+ 100.0
        high_prices  = open_prices .+ abs.(randn(rng2, n))
        low_prices   = open_prices .- abs.(randn(rng2, n))
        close_prices2 = cumsum(randn(rng2, n)) .+ 100.0
        vol          = abs.(randn(rng2, n)) .* 1_000_000

        ts_ohlcv = TSFrame(
            DataFrame(Index=dates, Open=open_prices, High=high_prices, Low=low_prices, Close=close_prices2, Volume=vol);
            issorted=true, copycols=false
        )

        ohlcv = BenchmarkGroup()
        ohlcv["monthly_default"] = @benchmarkable resample($ts_ohlcv, Month(1))
        ohlcv["weekly_default"]  = @benchmarkable resample($ts_ohlcv, Week(1))
        ohlcv["monthly_explicit"] = @benchmarkable resample($ts_ohlcv, Month(1),
            :Open => first, :High => maximum, :Low => minimum, :Close => last, :Volume => sum)
        grp["resample_ohlcv"] = ohlcv
    end

    BENCH_RESAMPLE_VS_TO_PERIOD[label] = grp
end
