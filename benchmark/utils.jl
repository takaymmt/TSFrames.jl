# benchmark/utils.jl — Shared utilities for benchmark scripts
# include() this file from run.jl, analysis/compare.jl, analysis/report.jl

using BenchmarkTools
using Dates

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

# ── NATO Phonetic Alphabet ────────────────────────────────────────────────

const NATO_RANK = Dict{String, Int}(
    "alpha"    => 1,
    "bravo"    => 2,
    "charlie"  => 3,
    "delta"    => 4,
    "echo"     => 5,
    "foxtrot"  => 6,
    "golf"     => 7,
    "hotel"    => 8,
    "india"    => 9,
    "juliet"   => 10,
    "kilo"     => 11,
    "lima"     => 12,
    "mike"     => 13,
    "november" => 14,
    "oscar"    => 15,
    "papa"     => 16,
    "quebec"   => 17,
    "romeo"    => 18,
    "sierra"   => 19,
    "tango"    => 20,
    "uniform"  => 21,
    "victor"   => 22,
    "whiskey"  => 23,
    "xray"     => 24,
    "yankee"   => 25,
    "zulu"     => 26,
)

# ── Meta JSON (Sidecar) ──────────────────────────────────────────────────

"""
    save_meta(path; version, suffix="", status="release", description="", timestamp=nothing)

Write a `.meta.json` sidecar file next to a benchmark result JSON.
`path` should be the path to the `.json` file; the meta file will be
`path` with `.json` replaced by `.meta.json`.
"""
function save_meta(path::String;
                   version::String,
                   suffix::String="",
                   status::String="release",
                   description::String="",
                   timestamp::Union{String,Nothing}=nothing)
    meta_path = replace(path, r"\.json$" => ".meta.json")
    ts = timestamp !== nothing ? timestamp : Dates.format(Dates.now(), "yyyy-mm-ddTHH:MM:SS")
    label = isempty(suffix) ? "v$version" : "tmp-$suffix"

    # Write JSON manually to avoid adding a JSON dependency
    open(meta_path, "w") do io
        println(io, "{")
        println(io, "  \"version\": \"$version\",")
        println(io, "  \"suffix\": \"$suffix\",")
        println(io, "  \"status\": \"$status\",")
        println(io, "  \"label\": \"$label\",")
        println(io, "  \"description\": \"$(escape_string(description))\",")
        println(io, "  \"timestamp\": \"$ts\"")
        println(io, "}")
    end
    return meta_path
end

"""
    load_meta(path::String) -> Dict{String, Any}

Load a `.meta.json` sidecar file. If the meta file does not exist,
infer metadata from the filename.
"""
function load_meta(path::String)
    meta_path = replace(path, r"\.json$" => ".meta.json")
    if isfile(meta_path)
        return _parse_simple_json(read(meta_path, String))
    end
    # Infer from filename
    return _infer_meta_from_filename(path)
end

"""
    _parse_simple_json(text::String) -> Dict{String, Any}

Minimal JSON parser for flat `{key: value}` objects (strings only).
Avoids adding a JSON package dependency.
"""
function _parse_simple_json(text::String)
    result = Dict{String, Any}()
    for m in eachmatch(r"\"(\w+)\"\s*:\s*\"([^\"]*)\"", text)
        result[m.captures[1]] = m.captures[2]
    end
    return result
end

"""
    _infer_meta_from_filename(path::String) -> Dict{String, Any}

Infer metadata from the benchmark result filename.
Handles patterns: `v0.3.1.json`, `tmp-alpha.json`.
"""
function _infer_meta_from_filename(path::String)
    fname = basename(path)
    name = replace(fname, r"\.json$" => "")

    # Match versioned file: v1.2.3
    m = match(r"^v(\d+\.\d+\.\d+)$", name)
    if m !== nothing
        return Dict{String, Any}(
            "version" => m.captures[1],
            "suffix"  => "",
            "status"  => "release",
            "label"   => name,
            "description" => "",
        )
    end

    # Match temporary file: tmp-alpha
    m = match(r"^tmp-(\w+)$", name)
    if m !== nothing
        return Dict{String, Any}(
            "version" => "0.0.0",
            "suffix"  => m.captures[1],
            "status"  => "temporary",
            "label"   => name,
            "description" => "",
        )
    end

    # Fallback: use filename as label, no version info
    return Dict{String, Any}(
        "version" => "0.0.0",
        "suffix"  => "",
        "status"  => "unknown",
        "label"   => name,
        "description" => "",
    )
end

"""
    parse_result_key(path::String) -> Tuple{Int, Int, Int, Bool, Int}

Parse a benchmark result file path into a sort key:
`(major, minor, patch, is_temporary, nato_rank)`.

Uses `.meta.json` if available, otherwise infers from filename.
"""
function parse_result_key(path::String)
    meta = load_meta(path)
    ver_str = get(meta, "version", "0.0.0")
    parts = split(ver_str, ".")
    major = length(parts) >= 1 ? parse(Int, parts[1]) : 0
    minor = length(parts) >= 2 ? parse(Int, parts[2]) : 0
    patch = length(parts) >= 3 ? parse(Int, parts[3]) : 0

    status = get(meta, "status", "unknown")
    is_temporary = status == "temporary"

    suffix = get(meta, "suffix", "")
    nato_rank = get(NATO_RANK, lowercase(suffix), 0)

    return (major, minor, patch, is_temporary, nato_rank)
end

"""
    sort_result_files(files::Vector{String}) -> Vector{String}

Sort benchmark result files by version, then release before temporary,
then by NATO rank for temporary files.
"""
function sort_result_files(files::Vector{String})
    # Sort by (major, minor, patch, is_temporary, nato_rank)
    # is_temporary=false (release) sorts before is_temporary=true (temporary)
    sort(files; by = f -> parse_result_key(f))
end
