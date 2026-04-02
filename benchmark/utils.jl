# benchmark/utils.jl — Shared utilities for benchmark scripts
# include() this file from run.jl, analysis/compare.jl, analysis/report.jl

using BenchmarkTools

# ── Load / Save ─────────────────────────────────────────────────────────────

"""
    load_result(path::String)

Load a BenchmarkTools result from a JSON file.
Returns the first (and typically only) BenchmarkGroup stored in the file.
"""
function load_result(path::String)
    if !isfile(path)
        error("Results file not found: $path")
    end
    BenchmarkTools.load(path)[1]
end

# ── Formatting ──────────────────────────────────────────────────────────────

"""
    format_time(ns::Real)

Human-readable time string from nanoseconds.
Automatically selects ns / us / ms / s unit.
"""
function format_time(ns::Real)
    if ns < 1_000
        return "$(round(ns, digits=1)) ns"
    elseif ns < 1_000_000
        return "$(round(ns / 1_000, digits=2)) us"
    elseif ns < 1_000_000_000
        return "$(round(ns / 1_000_000, digits=2)) ms"
    else
        return "$(round(ns / 1_000_000_000, digits=2)) s"
    end
end

"""
    format_bytes(bytes::Real)

Human-readable byte size string.
Automatically selects bytes / KiB / MiB / GiB unit.
"""
function format_bytes(bytes::Real)
    if bytes < 1024
        return "$(round(Int, bytes)) bytes"
    elseif bytes < 1024^2
        return "$(round(bytes / 1024, digits=1)) KiB"
    elseif bytes < 1024^3
        return "$(round(bytes / 1024^2, digits=1)) MiB"
    else
        return "$(round(bytes / 1024^3, digits=2)) GiB"
    end
end

# ── BenchmarkGroup Traversal ────────────────────────────────────────────────

"""
    collect_leaves(bg, prefix="") -> Vector{Pair{String, Any}}

Recursively collect all leaf benchmarks from a BenchmarkGroup.
Returns a vector of `"path" => trial_object` pairs, sorted by key at each level.
"""
function collect_leaves(bg, prefix="")
    leaves = Pair{String, Any}[]
    for k in sort(collect(keys(bg)))
        full = isempty(prefix) ? string(k) : "$prefix/$k"
        child = bg[k]
        if child isa BenchmarkTools.BenchmarkGroup
            append!(leaves, collect_leaves(child, full))
        else
            push!(leaves, full => child)
        end
    end
    leaves
end

"""
    navigate_leaf(bg, path::String)

Navigate a BenchmarkGroup by a slash-separated path string.
Returns the leaf object, or `nothing` if the path does not exist.
"""
function navigate_leaf(bg, path::String)
    parts = split(path, "/")
    current = bg
    for p in parts
        if current isa BenchmarkTools.BenchmarkGroup && haskey(current, p)
            current = current[p]
        else
            return nothing
        end
    end
    return current
end
