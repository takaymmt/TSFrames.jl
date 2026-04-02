# PkgBenchmark.jl entry point
# SUITE is the required constant

using BenchmarkTools
using Dates
using DataFrames
using Random
using Statistics

using TSFrames

include("suites/bench_construction.jl")
include("suites/bench_apply.jl")
include("suites/bench_resample_vs_to_period.jl")
include("suites/bench_endpoints.jl")
include("suites/bench_lag_lead_diff.jl")
include("suites/bench_rollapply.jl")
include("suites/bench_join.jl")
include("suites/bench_vcat.jl")

const SUITE = BenchmarkGroup()
SUITE["construction"]  = BENCH_CONSTRUCTION
SUITE["apply"]         = BENCH_APPLY
SUITE["endpoints"]     = BENCH_ENDPOINTS
SUITE["lag_lead_diff"] = BENCH_LAG_LEAD_DIFF
SUITE["rollapply"]     = BENCH_ROLLAPPLY
SUITE["join"]          = BENCH_JOIN
# Only register groups that have benchmarks (probe-guards for version compat)
isempty(BENCH_VCAT)               || (SUITE["vcat"]               = BENCH_VCAT)
isempty(BENCH_RESAMPLE_VS_TO_PERIOD) || (SUITE["resample_vs_to_period"] = BENCH_RESAMPLE_VS_TO_PERIOD)
