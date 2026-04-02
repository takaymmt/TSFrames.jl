# Benchmark: vcat() function
#
# Tests:
#   - vcat(ts1, ts2) with same columns (union)
#   - vcat(ts1, ts2; colmerge=:intersect) with different columns
#
# Compatibility: TSFrames v0.2.2 vcat() is incompatible with DataFrames >= 1.4
# (insertcols! API change).  Probe tests detect this at load time and skip
# affected variants rather than erroring at benchmark runtime.

using BenchmarkTools, Dates, DataFrames, Random
using TSFrames

# One-time probe: detect which vcat variants actually work.
const _VCAT_PROBE = let
    _pa = TSFrame(DataFrame(Index=[Date(2000), Date(2001)], x1=[1.0, 2.0]); issorted=true)
    _pb_same = TSFrame(DataFrame(Index=[Date(2002), Date(2003)], x1=[3.0, 4.0]); issorted=true)
    _pb_diff = TSFrame(DataFrame(Index=[Date(2002), Date(2003)], x2=[3.0, 4.0]); issorted=true)
    _same_ok        = try; vcat(_pa, _pb_same);                    true; catch; false; end
    _diff_ok        = try; vcat(_pa, _pb_diff);                    true; catch; false; end
    _intersect_ok   = try; vcat(_pa, _pb_diff; colmerge=:intersect); true; catch; false; end
    (same_cols=_same_ok, diff_cols=_diff_ok, diff_cols_intersect=_intersect_ok)
end

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

    _VCAT_PROBE.same_cols             && (grp["same_cols_union"]     = @benchmarkable vcat($ts1, $ts2_same))
    _VCAT_PROBE.diff_cols             && (grp["diff_cols_union"]     = @benchmarkable vcat($ts1, $ts2_diff))
    _VCAT_PROBE.diff_cols_intersect   && (grp["diff_cols_intersect"] = @benchmarkable vcat($ts1, $ts2_diff; colmerge=:intersect))

    isempty(grp) || (BENCH_VCAT[label] = grp)
end
