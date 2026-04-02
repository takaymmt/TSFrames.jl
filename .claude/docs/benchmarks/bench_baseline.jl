"""
TSFrames.jl Baseline Benchmark
Date: 2026-04-02
Purpose: Profile apply(), endpoints(), to_period() to identify bottlenecks.
Run: julia --project .claude/docs/benchmarks/bench_baseline.jl
"""

using TSFrames, DataFrames, Dates, BenchmarkTools, Random, Statistics
import DataFrames: groupby, combine, Not

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 10
BenchmarkTools.DEFAULT_PARAMETERS.samples = 100

# ── Data Generation ──────────────────────────────────────────────────────────

function generate_ohlcv(n::Int)
    rng = MersenneTwister(42)
    dates = collect(Date(2000, 1, 1):Day(1):Date(2000, 1, 1) + Day(n - 1))
    df = DataFrame(
        Open   = 100.0 .+ cumsum(randn(rng, n)),
        High   = 100.0 .+ cumsum(randn(rng, n)) .+ 1.0,
        Low    = 100.0 .+ cumsum(randn(rng, n)) .- 1.0,
        Close  = 100.0 .+ cumsum(randn(rng, n)),
        Volume = rand(rng, 1000:10000, n),
    )
    TSFrame(df, dates)
end

nrows(ts::TSFrame) = DataFrames.nrow(ts.coredata)

println("Generating 1M row OHLCV data...")
ts = generate_ohlcv(1_000_000)
println("  rows: $(nrows(ts))")

# ── 1. endpoints() ───────────────────────────────────────────────────────────

println("\n=== endpoints() ===")
b_ep_week  = @benchmark endpoints($ts, Week(1))
b_ep_month = @benchmark endpoints($ts, Month(1))

println("  endpoints(Week ):  ", median(b_ep_week))
println("  endpoints(Month):  ", median(b_ep_month))

# ── 2. apply() ───────────────────────────────────────────────────────────────

println("\n=== apply() ===")
b_apply_week_first  = @benchmark apply($ts, Week(1),  first)
b_apply_month_first = @benchmark apply($ts, Month(1), first)
b_apply_week_sum    = @benchmark apply($ts, Week(1),  sum)

println("  apply(Week,  first): ", median(b_apply_week_first))
println("  apply(Month, first): ", median(b_apply_month_first))
println("  apply(Week,  sum  ): ", median(b_apply_week_sum))

# ── 3. to_weekly() / to_monthly() ────────────────────────────────────────────

println("\n=== to_weekly() / to_monthly() ===")
b_toweekly  = @benchmark to_weekly($ts)
b_tomonthly = @benchmark to_monthly($ts)

println("  to_weekly():  ", median(b_toweekly))
println("  to_monthly(): ", median(b_tomonthly))

# ── 4. apply() Internals Breakdown ───────────────────────────────────────────

println("\n=== apply() Internals Breakdown (1M rows, Week) ===")

ep = endpoints(ts, Week(1))

b_endpoints = @benchmark endpoints($ts, Week(1))

b_fill_loop = @benchmark begin
    j = 1
    groupindices = Int[]
    for i in eachindex($ep)
        append!(groupindices, fill($ep[i], $ep[i] - j + 1))
        j = $ep[i] + 1
    end
end

groupindices = let j2 = 1, gi = Int[]
    for i in eachindex(ep)
        append!(gi, fill(ep[i], ep[i] - j2 + 1))
        j2 = ep[i] + 1
    end
    gi
end

b_copy = @benchmark copy($ts.coredata)

sdf = copy(ts.coredata)
tmp_col = "tmp0191"
sdf[!, tmp_col] = groupindices

b_groupby = @benchmark groupby($sdf, $tmp_col)

gd = groupby(sdf, tmp_col)
b_combine = @benchmark combine(
    $gd,
    :Index => first => :Index,
    Not(["Index", $tmp_col]) .=> first;
    keepkeys = false,
    renamecols = true,
)

println("  endpoints():    ", median(b_endpoints))
println("  fill+append!:   ", median(b_fill_loop))
println("  copy(coredata): ", median(b_copy))
println("  groupby():      ", median(b_groupby))
println("  combine():      ", median(b_combine))

# ── 5. Alternative: pre-allocated groupindices ───────────────────────────────

println("\n=== Alternative: Pre-allocated groupindices ===")

b_prealloc = @benchmark begin
    ep2 = endpoints($ts, Week(1))
    gi  = Vector{Int}(undef, nrows($ts))
    j   = 1
    for i in eachindex(ep2)
        gi[j:ep2[i]] .= ep2[i]
        j = ep2[i] + 1
    end
    gi
end

println("  pre-alloc:    ", median(b_prealloc))
println("  fill+append!: ", median(b_fill_loop))
println("  speedup:      $(round(median(b_fill_loop).time / median(b_prealloc).time, digits=2))x")

# ── Summary ───────────────────────────────────────────────────────────────────

println("\n=== Full Benchmark Summary (1M rows, medians) ===")
println("""
┌──────────────────────────┬────────────────┬──────────────────┐
│ Operation                │ Time           │ Allocations      │
├──────────────────────────┼────────────────┼──────────────────┤
│ endpoints(Week)          │ $(rpad(string(round(median(b_ep_week).time/1e6,  digits=2)) * " ms", 14)) │ $(rpad(string(median(b_ep_week).allocs)  * " allocs", 16)) │
│ endpoints(Month)         │ $(rpad(string(round(median(b_ep_month).time/1e6, digits=2)) * " ms", 14)) │ $(rpad(string(median(b_ep_month).allocs) * " allocs", 16)) │
│ apply(Week,  first)      │ $(rpad(string(round(median(b_apply_week_first).time/1e6,  digits=2)) * " ms", 14)) │ $(rpad(string(median(b_apply_week_first).allocs)  * " allocs", 16)) │
│ apply(Month, first)      │ $(rpad(string(round(median(b_apply_month_first).time/1e6, digits=2)) * " ms", 14)) │ $(rpad(string(median(b_apply_month_first).allocs) * " allocs", 16)) │
│ apply(Week,  sum)        │ $(rpad(string(round(median(b_apply_week_sum).time/1e6, digits=2)) * " ms", 14)) │ $(rpad(string(median(b_apply_week_sum).allocs) * " allocs", 16)) │
│ to_weekly()              │ $(rpad(string(round(median(b_toweekly).time/1e6,  digits=2)) * " ms", 14)) │ $(rpad(string(median(b_toweekly).allocs)  * " allocs", 16)) │
│ to_monthly()             │ $(rpad(string(round(median(b_tomonthly).time/1e6, digits=2)) * " ms", 14)) │ $(rpad(string(median(b_tomonthly).allocs) * " allocs", 16)) │
└──────────────────────────┴────────────────┴──────────────────┘

apply() Internals (Week, first):
  endpoints():    $(round(median(b_endpoints).time/1e6, digits=2)) ms
  fill+append!:   $(round(median(b_fill_loop).time/1e6, digits=2)) ms  → pre-alloc: $(round(median(b_prealloc).time/1e6, digits=2)) ms ($(round(median(b_fill_loop).time/median(b_prealloc).time, digits=1))x speedup)
  copy(coredata): $(round(median(b_copy).time/1e6, digits=2)) ms
  groupby():      $(round(median(b_groupby).time/1e6, digits=2)) ms
  combine():      $(round(median(b_combine).time/1e6, digits=2)) ms
""")
