"""
TSFrames.jl Profile Analysis
Date: 2026-04-02
Purpose: Use Julia Profile module to identify hotspots in apply() and endpoints()
Run: julia --project .claude/docs/benchmarks/profile_apply.jl
"""

using TSFrames, DataFrames, Dates, Random, Profile, Statistics
import DataFrames: nrow, groupby, combine, Not

# ── Generate 1M row OHLCV data ────────────────────────────────────────────────
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

println("Generating 1M row OHLCV data...")
ts = generate_ohlcv(1_000_000)
println("Done. Rows: $(DataFrames.nrow(ts.coredata))")

# ── Warm up (avoid JIT compilation in profile) ────────────────────────────────
println("\nWarming up...")
for _ in 1:3
    apply(ts, Week(1), first)
    apply(ts, Week(1), sum)
    endpoints(ts, Week(1))
end
println("Warmup done.")

# ── Profile apply(Week, first) ────────────────────────────────────────────────
println("\n=== Profiling apply(Week, first) ===")
Profile.clear()
@profile for _ in 1:50
    apply(ts, Week(1), first)
end
println("\n--- Profile output (flat, sorted by count) ---")
Profile.print(format=:flat, sortedby=:count, mincount=5)

# ── Profile apply(Week, sum) ──────────────────────────────────────────────────
println("\n=== Profiling apply(Week, sum) ===")
Profile.clear()
@profile for _ in 1:20
    apply(ts, Week(1), sum)
end
println("\n--- Profile output (flat, sorted by count) ---")
Profile.print(format=:flat, sortedby=:count, mincount=5)

# ── Profile endpoints() alone ─────────────────────────────────────────────────
println("\n=== Profiling endpoints(Week) ===")
Profile.clear()
@profile for _ in 1:500
    endpoints(ts, Week(1))
end
println("\n--- Profile output (flat, sorted by count) ---")
Profile.print(format=:flat, sortedby=:count, mincount=5)

# ── Profile to_weekly() ───────────────────────────────────────────────────────
println("\n=== Profiling to_weekly() ===")
Profile.clear()
@profile for _ in 1:200
    to_weekly(ts)
end
println("\n--- Profile output (flat, sorted by count) ---")
Profile.print(format=:flat, sortedby=:count, mincount=5)

println("\nProfiling complete.")
