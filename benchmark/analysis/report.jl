#!/usr/bin/env julia
# benchmark/analysis/report.jl — Markdown report generator
#
# Usage:
#   julia benchmark/analysis/report.jl <baseline.json> [result1.json ...] [options]
#
# Options:
#   --labels <l1,l2,...>    Labels for columns
#   --output <path>         Write to file instead of stdout
#   --group <name>          Only include specific group
#
# Output example:
#
# ## resample_vs_to_period
#
# | Benchmark | baseline | after_p1 | after_p2 |
# |-----------|----------|----------|----------|
# | resample/monthly/mean | 45.2 ms | **12.1 ms (3.7x)** | **11.9 ms (3.8x)** |

using BenchmarkTools
using Dates

include(joinpath(@__DIR__, "..", "utils.jl"))

# ── Argument Parsing ─────────────────────────────────────────────────────────

function parse_report_args(args)
    config = Dict{Symbol, Any}(
        :files  => String[],
        :labels => nothing,
        :output => nothing,
        :group  => nothing,
    )

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--labels"
            i += 1
            config[:labels] = [strip(l) for l in split(args[i], ",")]
        elseif arg == "--output"
            i += 1
            config[:output] = args[i]
        elseif arg == "--group"
            i += 1
            config[:group] = args[i]
        elseif !startswith(arg, "--")
            push!(config[:files], arg)
        else
            @warn "Unknown argument: $arg"
        end
        i += 1
    end

    return config
end


# ── Report Generation ────────────────────────────────────────────────────────

function generate_report(files::Vector{String}; labels=nothing, output=nothing, group_filter=nothing)
    if isempty(files)
        error("Need at least 1 file for report.")
    end

    # Sort files by version / temporary status / NATO rank
    files = sort_result_files(files)

    # Load all results
    results = [load_result(f) for f in files]

    # Load metadata for WIP markers
    metas = [load_meta(f) for f in files]

    # Assign labels
    col_labels = if labels !== nothing
        if length(labels) != length(files)
            error("Number of labels ($(length(labels))) must match number of files ($(length(files)))")
        end
        labels
    else
        map(enumerate(files)) do (idx, f)
            label = replace(basename(f), ".json" => "")
            if get(metas[idx], "status", "") == "temporary"
                label *= " [WIP]"
            end
            label
        end
    end

    has_comparison = length(results) > 1

    # Optionally filter to a specific group
    if group_filter !== nothing
        results = map(results) do r
            if haskey(r, group_filter)
                r[group_filter]
            else
                error("Group '$group_filter' not found.")
            end
        end
    end

    out = IOBuffer()

    println(out, "# TSFrames.jl Benchmark Report")
    println(out, "")
    println(out, "Generated: $(Dates.format(Dates.now(), "yyyy-mm-dd HH:MM:SS"))")
    println(out, "")

    if group_filter !== nothing
        # Already filtered — output as single section
        _write_group_table(out, group_filter, results, col_labels, has_comparison)
    else
        # Iterate over top-level groups
        top_groups = sort(collect(keys(results[1])))
        for tg in top_groups
            group_results = map(results) do r
                haskey(r, tg) ? r[tg] : nothing
            end
            _write_group_table(out, string(tg), group_results, col_labels, has_comparison)
        end
    end

    report = String(take!(out))

    if output !== nothing
        dir = dirname(output)
        if !isempty(dir) && !isdir(dir)
            mkpath(dir)
        end
        open(output, "w") do f
            write(f, report)
        end
        println("Report written to: $output")
    else
        print(report)
    end

    return report
end

function _write_group_table(out, group_name, group_results, col_labels, has_comparison)
    println(out, "## $group_name")
    println(out, "")

    # Find the first non-nothing result to get leaf paths
    ref_idx = findfirst(r -> r !== nothing, group_results)
    if ref_idx === nothing
        println(out, "_No data available._")
        println(out, "")
        return
    end

    leaves = collect_leaves(group_results[ref_idx])
    all_paths = [p for (p, _) in leaves]

    # Table header — no separate Speedup column; speedup is embedded in each version cell
    header_parts = ["Benchmark"]
    for label in col_labels
        push!(header_parts, label)
    end
    println(out, "| ", join(header_parts, " | "), " |")
    println(out, "|", join(fill("---", length(header_parts)), "|"), "|")

    # Table rows
    baseline_result = group_results[1]
    for path in sort(all_paths)
        row = [path]

        baseline_time = nothing
        if baseline_result !== nothing
            bl = navigate_leaf(baseline_result, path)
            if bl !== nothing
                baseline_time = BenchmarkTools.minimum(bl).time
            end
        end

        for (idx, gr) in enumerate(group_results)
            if gr === nothing
                push!(row, "N/A")
                continue
            end
            leaf = navigate_leaf(gr, path)
            if leaf === nothing
                push!(row, "N/A")
                continue
            end
            t = BenchmarkTools.minimum(leaf).time

            if idx == 1
                # Baseline (first column) — plain format
                push!(row, format_time(t))
            else
                # Subsequent columns — show time with speedup vs baseline
                if baseline_time !== nothing && baseline_time > 0
                    speedup = baseline_time / t
                    if speedup > 1.05
                        cell = "**$(format_time(t)) ($(round(speedup, digits=1))x faster)**"
                    elseif speedup < (1.0 / 1.05)
                        slowdown = t / baseline_time
                        cell = "_$(format_time(t)) ($(round(slowdown, digits=1))x slower)_"
                    else
                        cell = "$(format_time(t)) (~1.0x)"
                    end
                    push!(row, cell)
                else
                    push!(row, format_time(t))
                end
            end
        end

        println(out, "| ", join(row, " | "), " |")
    end

    println(out, "")
end

# ── Main ─────────────────────────────────────────────────────────────────────

function main()
    config = parse_report_args(ARGS)

    if isempty(config[:files])
        println("""
Usage: julia benchmark/analysis/report.jl <baseline.json> [result1.json ...] [options]

Options:
  --labels <l1,l2,...>    Labels for columns
  --output <path>         Write to file instead of stdout
  --group <name>          Only include specific group
""")
        return
    end

    generate_report(
        config[:files];
        labels=config[:labels],
        output=config[:output],
        group_filter=config[:group],
    )
end

# Only run main when executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
