# Benchmark: subset() function
#
# Standalone script to measure subset() performance.
# Used to measure baseline (DataFrames.subset, O(n)) vs optimized
# (searchsortedfirst/searchsortedlast, O(log n)).
#
# Usage:
#   julia --project=benchmark benchmark/bench_subset.jl

using TSFrames, Dates, BenchmarkTools, Random

# Generate sorted test data
const N = 100_000
const rng = MersenneTwister(42)

dates = Date(2020, 1, 1) .+ Day.(0:N-1)
ts_date = TSFrame(rand(rng, N, 3), dates)

from = dates[10_000]
to   = dates[90_000]

# Integer index variant
ts_int = TSFrame(rand(rng, N, 3), collect(1:N))
i_from = 10_000
i_to   = 90_000

println("=== subset() benchmark (n = $N) ===")

println("\n[Date index] subset(ts, from, to):")
@btime subset($ts_date, $from, $to)

println("\n[Date index] subset(ts, :, to):")
@btime subset($ts_date, :, $to)

println("\n[Date index] subset(ts, from, :):")
@btime subset($ts_date, $from, :)

println("\n[Int index] subset(ts, from, to):")
@btime subset($ts_int, $i_from, $i_to)

# Small-window query: highlights the O(n) -> O(log n + k) improvement
# where k = window size. Original DataFrames.subset always pays O(n).
println("\n[Small window] subset(ts, mid, mid+10):")
mid = dates[N ÷ 2]
mid_plus = dates[N ÷ 2 + 10]
@btime subset($ts_date, $mid, $mid_plus)

# Edge cases
println("\n[Edge] empty result (from > to, swapped Dates):")
@btime subset($ts_date, $to, $from)

println("\n[Edge] from before all data:")
early = dates[1] - Day(100)
@btime subset($ts_date, $early, :)
