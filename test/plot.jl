# test/plot.jl
# Tests for TSFrames plot recipes (src/plot.jl).
#
# We do NOT depend on Plots.jl here. Instead, we exercise the recipes
# directly via RecipesBase.apply_recipe and assert the returned
# RecipeData carries the expected attributes and data shapes.
#
# The plot.jl file defines three @recipe overloads:
#   1. plot(ts, cols::Vector{Int})  — the terminal overload; emits
#      (index, Matrix) args together with label/xlabel/ylabel/etc.
#   2. plot(ts, cols::Vector{<:Union{String,Symbol}}) — converts to
#      column indices and delegates to (1).
#   3. plot(ts, col::Union{Int,String,Symbol}) — wraps in a vector and
#      delegates to (2) / (1).
#
# RecipesBase.apply_recipe only advances one recipe level per call, so
# we walk the result tree ourselves until no TSFrame remains in args.

using Dates, DataFrames, Test, TSFrames
using RecipesBase

# ── Helpers ────────────────────────────────────────────────────────────────

# Recursively apply recipes until no RecipeData.args contains a TSFrame.
# This mirrors what the Plots/RecipesPipeline driver does internally.
function _resolve_recipe(args...; plotattributes = Dict{Symbol,Any}())
    pending = RecipesBase.apply_recipe(plotattributes, args...)
    changed = true
    while changed
        changed = false
        next_pending = RecipesBase.RecipeData[]
        for rd in pending
            if any(arg -> arg isa TSFrame, rd.args)
                changed = true
                append!(next_pending, RecipesBase.apply_recipe(rd.plotattributes, rd.args...))
            else
                push!(next_pending, rd)
            end
        end
        pending = next_pending
    end
    return pending
end

# Resolve and extract the single terminal RecipeData.
function _resolve_single(args...)
    rds = _resolve_recipe(args...)
    @test length(rds) == 1
    return only(rds)
end

# ── Fixture TSFrame ────────────────────────────────────────────────────────
# 12 monthly rows with three numeric columns.
_plot_dates = collect(Date(2022, 1, 1):Month(1):Date(2022, 12, 1))
_plot_df = DataFrame(
    a = Float64.(1:12),
    b = Float64.(13:24),
    c = Float64.(25:36),
)
_plot_ts = TSFrame(_plot_df, _plot_dates)

# ── 1. Default recipe (no cols arg) ───────────────────────────────────────
@testset "plot: default recipe (no cols)" begin
    rd = _resolve_single(_plot_ts)

    # Terminal args shape: (index::Vector{Date}, y::Matrix)
    @test length(rd.args) == 2
    x, y = rd.args
    @test x isa AbstractVector
    @test y isa AbstractMatrix
    @test length(x) == DataFrames.nrow(_plot_ts.coredata)
    @test x == TSFrames.index(_plot_ts)

    # y should include all three columns, shape = (rows, ncols)
    @test size(y) == (DataFrames.nrow(_plot_ts.coredata), 3)
    @test y == Matrix(_plot_ts.coredata[!, [2, 3, 4]])  # skip :Index column

    # Core attributes
    attrs = rd.plotattributes
    @test attrs[:seriestype] == :line
    @test attrs[:xlabel] == :Index
    @test attrs[:ylabel] == "a, b, c"
    @test attrs[:label] == permutedims(["a", "b", "c"])
    @test attrs[:legend] == true
end

# ── 2. Vector{Int} cols selection ─────────────────────────────────────────
@testset "plot: Vector{Int} cols selection" begin
    cols = [1, 3]  # :a and :c (1-based over data columns, not Index)
    rd = _resolve_single(_plot_ts, cols)

    @test length(rd.args) == 2
    x, y = rd.args
    @test x == TSFrames.index(_plot_ts)
    @test size(y) == (DataFrames.nrow(_plot_ts.coredata), length(cols))
    # plot.jl does `ts.coredata[!, cols .+ 1]` to skip the Index column.
    @test y == Matrix(_plot_ts.coredata[!, cols .+ 1])

    attrs = rd.plotattributes
    @test attrs[:seriestype] == :line
    @test attrs[:xlabel] == :Index
    @test attrs[:ylabel] == "a, c"
    @test attrs[:label] == permutedims(["a", "c"])
    @test attrs[:legend] == true
end

# ── 3. Vector{Symbol} cols selection ──────────────────────────────────────
@testset "plot: Vector{Symbol} cols selection" begin
    rd_sym = _resolve_single(_plot_ts, [:a, :b])
    rd_int = _resolve_single(_plot_ts, [1, 2])

    # Symbol overload must yield the same terminal data as the Int overload.
    @test rd_sym.args == rd_int.args
    @test rd_sym.plotattributes[:seriestype] == :line
    @test rd_sym.plotattributes[:xlabel] == :Index
    @test rd_sym.plotattributes[:ylabel] == "a, b"
    @test rd_sym.plotattributes[:label] == permutedims(["a", "b"])
end

# ── 4. Vector{String} cols selection ──────────────────────────────────────
@testset "plot: Vector{String} cols selection" begin
    rd_str = _resolve_single(_plot_ts, ["b", "c"])
    rd_int = _resolve_single(_plot_ts, [2, 3])

    @test rd_str.args == rd_int.args
    @test rd_str.plotattributes[:ylabel] == "b, c"
    @test rd_str.plotattributes[:label] == permutedims(["b", "c"])
end

# ── 5. Single Symbol col selection ────────────────────────────────────────
@testset "plot: single Symbol col dispatches without error" begin
    rd_scalar = _resolve_single(_plot_ts, :b)
    rd_vec = _resolve_single(_plot_ts, [:b])

    @test rd_scalar.args == rd_vec.args
    @test rd_scalar.plotattributes[:ylabel] == "b"
    @test rd_scalar.plotattributes[:label] == permutedims(["b"])
    # y should be a 12x1 matrix
    _, y = rd_scalar.args
    @test size(y) == (DataFrames.nrow(_plot_ts.coredata), 1)
    @test y[:, 1] == _plot_ts.coredata[!, :b]
end

# ── 6. Single Int col selection ───────────────────────────────────────────
@testset "plot: single Int col dispatches without error" begin
    rd_scalar = _resolve_single(_plot_ts, 1)
    rd_vec = _resolve_single(_plot_ts, [1])
    @test rd_scalar.args == rd_vec.args
    @test rd_scalar.plotattributes[:ylabel] == "a"
end

# ── 7. Single String col selection ────────────────────────────────────────
@testset "plot: single String col dispatches without error" begin
    rd_scalar = _resolve_single(_plot_ts, "c")
    rd_vec = _resolve_single(_plot_ts, ["c"])
    @test rd_scalar.args == rd_vec.args
    @test rd_scalar.plotattributes[:ylabel] == "c"
end

# ── 8. Unknown / out-of-range column validation ──────────────────────────
@testset "plot: validation of unknown columns" begin
    @test_throws ArgumentError _resolve_recipe(_plot_ts, :nonexistent)
    @test_throws ArgumentError _resolve_recipe(_plot_ts, [:nonexistent])
    @test_throws ArgumentError _resolve_recipe(_plot_ts, "nonexistent")
    @test_throws ArgumentError _resolve_recipe(_plot_ts, ["nonexistent"])
    @test_throws ArgumentError _resolve_recipe(_plot_ts, [99])
    @test_throws ArgumentError _resolve_recipe(_plot_ts, [0])
    @test_throws ArgumentError _resolve_recipe(_plot_ts, 99)
end

# ── 9. Empty TSFrame (0 data columns) ────────────────────────────────────
@testset "plot: empty TSFrame (no data columns)" begin
    ts_empty = TSFrame(DataFrame(Index = collect(_plot_dates)))
    # Default recipe: cols defaults to 1:ncol(ts) == 1:0 (empty), so
    # validation passes and the Matrix() of an empty column selection
    # collapses to a 0x0 matrix (documented behavior of DataFrames).
    rd = _resolve_single(ts_empty)
    x, y = rd.args
    @test x == TSFrames.index(ts_empty)
    @test y isa AbstractMatrix
    @test size(y, 2) == 0
    # Explicit non-empty column on empty TSFrame must throw.
    @test_throws ArgumentError _resolve_recipe(ts_empty, [1])
    @test_throws ArgumentError _resolve_recipe(ts_empty, :a)
end

# ── 10. Single-column default (1-column TSFrame, no cols arg) ────────────
@testset "plot: single-column TSFrame default" begin
    ts_single = TSFrame(DataFrame(Index = collect(_plot_dates), A = 1.0:12.0))
    recs = _resolve_recipe(ts_single)
    @test length(recs) == 1
    @test size(recs[1].args[2]) == (length(_plot_dates), 1)
    @test recs[1].plotattributes[:ylabel] == "A"
    @test recs[1].plotattributes[:label] == permutedims(["A"])
end
