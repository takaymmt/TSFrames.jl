# Benchmark: upsample() function
#
# Tests:
#   - upsample(ts, Hour(12))  — daily → twice-daily
#   - upsample(ts, Hour(6))   — daily → 4x-daily
#   - upsample(ts, Minute(30))— daily → 48x-daily (small/medium only)
#
# Note: Establishes baseline before planned outer-join→direct-construction
# optimisation (review item H7).
# Large size omits Minute(30) to keep benchmark times reasonable.

using BenchmarkTools, Dates, DataFrames, Random
using TSFrames

const BENCH_UPSAMPLE = BenchmarkGroup()

for (label, n) in [("small", 100), ("medium", 500), ("large", 2_000)]
    rng = MersenneTwister(42)

    # Daily data — DateTime index required for sub-day upsample
    datetimes = DateTime(2020, 1, 1) .+ Day.(0:n-1)
    prices = cumsum(randn(rng, n)) .+ 100.0
    ts = TSFrame(DataFrame(Index=datetimes, close=prices); issorted=true, copycols=false)

    grp = BenchmarkGroup()

    grp["hour12"] = @benchmarkable upsample($ts, Hour(12))
    grp["hour6"]  = @benchmarkable upsample($ts, Hour(6))

    # Minute(30) only for small/medium — large would produce 96k rows per call
    if n <= 500
        grp["min30"] = @benchmarkable upsample($ts, Minute(30))
    end

    BENCH_UPSAMPLE[label] = grp
end
