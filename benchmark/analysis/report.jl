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

# ── Constants ───────────────────────────────────────────────────────────────

# Custom sort order for dataset sizes: small → medium → large
const SIZE_ORDER = Dict{String, Int}(
    "small"  => 1,
    "medium" => 2,
    "large"  => 3,
)

# Group descriptions for documentation
const GROUP_DESCRIPTIONS = Dict{String, String}(
    "apply"                  => "Period-based aggregation (last/first/mean/sum) over time series",
    "construction"           => "TSFrame construction from various input types",
    "endpoints"              => "Finding period endpoints (last date of each week/month/quarter/year)",
    "join"                   => "Time-series join operations (inner/outer/left)",
    "lag_lead_diff"          => "Lag, lead, diff, and pctchange operations",
    "resample_vs_to_period"  => "Comparison of resample() vs to_period() for period-based aggregation",
    "rollapply"              => "Rolling window operations (mean/sum/std)",
    "vcat"                   => "Vertical concatenation of TSFrame objects",
)

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


# ── Helper: Extract size prefix and leaf from a path ─────────────────────────

"""
    _extract_size_and_leaf(path::String) -> (size::String, leaf::String)

Extract the dataset size prefix and the display leaf from a benchmark path.
- `"large/monthly"` → `("large", "monthly")`
- `"large/to_period/monthly"` → `("large", "to_period/monthly")`
- `"unknown_format"` → `("", "unknown_format")`
"""
function _extract_size_and_leaf(path::String)
    parts = split(path, "/")
    first_part = string(parts[1])
    if haskey(SIZE_ORDER, first_part) && length(parts) >= 2
        return (first_part, join(parts[2:end], "/"))
    end
    return ("", path)
end

"""
    _size_sort_key(path::String) -> Tuple

Return a sort key that orders by size (small → medium → large), then by leaf name.
"""
function _size_sort_key(path::String)
    (sz, leaf) = _extract_size_and_leaf(path)
    return (get(SIZE_ORDER, sz, 99), leaf)
end

# ── Helper: Speedup cell formatting (markdown) ──────────────────────────────

"""
    _format_speedup_cell_md(t, baseline_time, is_baseline) -> (cell::String, has_warning::Bool)

Format a table cell with optional speedup comparison (markdown format).
Returns the cell string and whether a ⚠ warning was added.
"""
function _format_speedup_cell_md(t, baseline_time, is_baseline::Bool)
    if is_baseline
        return (format_time(t), false)
    end

    if baseline_time !== nothing && baseline_time > 1.0
        # Normal comparison: baseline is meaningful (> 1.0 ns)
        speedup = baseline_time / t
        if speedup > 1.05
            return ("**$(format_time(t)) ($(round(speedup, digits=1))x faster)**", false)
        elseif speedup < (1.0 / 1.05)
            slowdown = t / baseline_time
            return ("_$(format_time(t)) ($(round(slowdown, digits=1))x slower)_", false)
        else
            return ("$(format_time(t)) (~1.0x)", false)
        end
    elseif baseline_time !== nothing && baseline_time <= 1.0
        # Baseline is 0 or near-zero (< 1.0 ns) — measurement artifact
        return ("$(format_time(t)) ⚠", true)
    else
        # No baseline available
        return (format_time(t), false)
    end
end

"""
    _format_speedup_cell_html(t, baseline_time, is_baseline) -> (cell::String, has_warning::Bool)

Format a table cell with optional speedup comparison (HTML format).
Returns the cell string and whether a ⚠ warning was added.
"""
function _format_speedup_cell_html(t, baseline_time, is_baseline::Bool)
    if is_baseline
        return (format_time(t), false)
    end

    if baseline_time !== nothing && baseline_time > 1.0
        speedup = baseline_time / t
        if speedup > 1.05
            return ("<strong>$(format_time(t)) ($(round(speedup, digits=1))x faster)</strong>", false)
        elseif speedup < (1.0 / 1.05)
            slowdown = t / baseline_time
            return ("<em>$(format_time(t)) ($(round(slowdown, digits=1))x slower)</em>", false)
        else
            return ("$(format_time(t)) (~1.0x)", false)
        end
    elseif baseline_time !== nothing && baseline_time <= 1.0
        return ("$(format_time(t)) ⚠", true)
    else
        return (format_time(t), false)
    end
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

    # Dataset size legend
    println(out, "## Dataset Sizes")
    println(out, "")
    println(out, "| Label | Rows | Notes |")
    println(out, "|-------|------|-------|")
    println(out, "| small | 1,000 | |")
    println(out, "| medium | 25,000 | |")
    println(out, "| large | 1,000,000 | rollapply uses 100,000 for large |")
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
            if string(tg) == "resample_vs_to_period"
                _write_resample_comparison_table(out, group_results, col_labels)
            else
                _write_group_table(out, string(tg), group_results, col_labels, has_comparison)
            end
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

    # Group description
    if haskey(GROUP_DESCRIPTIONS, group_name)
        println(out, GROUP_DESCRIPTIONS[group_name])
        println(out, "")
    end

    # Union-based leaf path discovery: collect paths from ALL files, not just baseline
    all_paths_set = Set{String}()
    for r in group_results
        if r !== nothing
            for (p, _) in collect_leaves(r)
                push!(all_paths_set, p)
            end
        end
    end

    if isempty(all_paths_set)
        println(out, "_No data available._")
        println(out, "")
        return
    end

    # Sort paths by size order (small → medium → large), then by leaf name
    all_paths = sort(collect(all_paths_set); by=_size_sort_key)

    # Table header
    header_parts = ["Benchmark"]
    for label in col_labels
        push!(header_parts, label)
    end
    println(out, "| ", join(header_parts, " | "), " |")
    println(out, "|", join(fill("---", length(header_parts)), "|"), "|")

    # Track if any ⚠ warnings are emitted
    any_warning = false

    # Table rows, grouped by size with separator rows
    baseline_result = group_results[1]
    num_cols = length(col_labels)
    current_size = ""

    for path in all_paths
        (sz, leaf) = _extract_size_and_leaf(path)

        # Insert size separator row when size group changes
        if sz != current_size && !isempty(sz)
            current_size = sz
            separator_padding = join(fill("", num_cols), " | ")
            println(out, "| **── $sz ──** | $separator_padding |")
        end

        row = [leaf]

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
            leaf_node = navigate_leaf(gr, path)
            if leaf_node === nothing
                push!(row, "N/A")
                continue
            end
            t = BenchmarkTools.minimum(leaf_node).time

            (cell, warned) = _format_speedup_cell_md(t, baseline_time, idx == 1)
            if warned
                any_warning = true
            end
            push!(row, cell)
        end

        println(out, "| ", join(row, " | "), " |")
    end

    println(out, "")

    # Footnote for ⚠ warnings
    if any_warning
        println(out, "> **⚠ Note**: Cells marked with ⚠ have a baseline time of 0 ns or near-zero, which is a")
        println(out, "> measurement artifact (timer quantization at sub-nanosecond scale in v0.2.2). The comparison")
        println(out, "> ratio is not meaningful for these rows.")
        println(out, "")
    end
end


# ── Special: resample_vs_to_period HTML comparison table ─────────────────────

function _write_resample_comparison_table(out, group_results, col_labels)
    group_name = "resample_vs_to_period"
    println(out, "## $group_name")
    println(out, "")

    if haskey(GROUP_DESCRIPTIONS, group_name)
        println(out, GROUP_DESCRIPTIONS[group_name])
        println(out, "")
    end

    # Collect all leaf paths from all versions to discover period names and sizes
    all_paths_set = Set{String}()
    for r in group_results
        if r !== nothing
            for (p, _) in collect_leaves(r)
                push!(all_paths_set, p)
            end
        end
    end

    if isempty(all_paths_set)
        println(out, "_No data available._")
        println(out, "")
        return
    end

    # Discover unique sizes and periods from to_period/* and resample_last/* paths
    sizes_set = Set{String}()
    periods_set = Set{String}()
    for p in all_paths_set
        parts = split(p, "/")
        if length(parts) >= 2
            sz = string(parts[1])
            if haskey(SIZE_ORDER, sz)
                push!(sizes_set, sz)
                # Extract period from paths like "small/to_period/weekly" or "small/resample_last/weekly_last"
                if length(parts) >= 3
                    subgroup = string(parts[2])
                    period_raw = string(parts[3])
                    if subgroup == "to_period"
                        push!(periods_set, period_raw)
                    end
                end
            end
        end
    end

    # Sort sizes by custom order
    sizes = sort(collect(sizes_set); by=s -> get(SIZE_ORDER, s, 99))
    # Sort periods: weekly, monthly, quarterly, yearly
    period_order = Dict("weekly" => 1, "monthly" => 2, "quarterly" => 3, "yearly" => 4)
    periods = sort(collect(periods_set); by=p -> get(period_order, p, 99))

    num_versions = length(col_labels)
    total_cols = 1 + 2 * num_versions  # Benchmark + (to_period, resample) * N

    # Track if any ⚠ warnings are emitted
    any_warning = false

    # Build HTML table
    println(out, "<table>")
    println(out, "<thead>")

    # Row 1: version headers with colspan=2
    print(out, "<tr>")
    print(out, "<th rowspan=\"2\">Benchmark</th>")
    for label in col_labels
        print(out, "<th colspan=\"2\">$label</th>")
    end
    println(out, "</tr>")

    # Row 2: sub-headers (to_period / resample)
    print(out, "<tr>")
    for _ in col_labels
        print(out, "<th>to_period</th><th>resample</th>")
    end
    println(out, "</tr>")

    println(out, "</thead>")
    println(out, "<tbody>")

    baseline_result = group_results[1]

    for sz in sizes
        # Size separator row
        println(out, "<tr><td colspan=\"$total_cols\"><strong>── $sz ──</strong></td></tr>")

        for period in periods
            tp_path = "$sz/to_period/$period"
            # resample_last uses "{period}_last" naming convention
            rs_path = "$sz/resample_last/$(period)_last"

            print(out, "<tr>")
            print(out, "<td>$period</td>")

            # Get baseline times for to_period and resample
            baseline_tp_time = nothing
            baseline_rs_time = nothing
            if baseline_result !== nothing
                bl_tp = navigate_leaf(baseline_result, tp_path)
                if bl_tp !== nothing
                    baseline_tp_time = BenchmarkTools.minimum(bl_tp).time
                end
                bl_rs = navigate_leaf(baseline_result, rs_path)
                if bl_rs !== nothing
                    baseline_rs_time = BenchmarkTools.minimum(bl_rs).time
                end
            end

            for (idx, gr) in enumerate(group_results)
                # to_period cell
                if gr !== nothing
                    tp_leaf = navigate_leaf(gr, tp_path)
                    if tp_leaf !== nothing
                        t = BenchmarkTools.minimum(tp_leaf).time
                        (cell, warned) = _format_speedup_cell_html(t, baseline_tp_time, idx == 1)
                        if warned; any_warning = true; end
                        print(out, "<td>$cell</td>")
                    else
                        print(out, "<td></td>")
                    end
                else
                    print(out, "<td></td>")
                end

                # resample cell
                if gr !== nothing
                    rs_leaf = navigate_leaf(gr, rs_path)
                    if rs_leaf !== nothing
                        t = BenchmarkTools.minimum(rs_leaf).time
                        (cell, warned) = _format_speedup_cell_html(t, baseline_rs_time, idx == 1)
                        if warned; any_warning = true; end
                        print(out, "<td>$cell</td>")
                    else
                        print(out, "<td></td>")
                    end
                else
                    print(out, "<td></td>")
                end
            end

            println(out, "</tr>")
        end
    end

    println(out, "</tbody>")
    println(out, "</table>")
    println(out, "")

    # Also output remaining sub-groups that aren't to_period/resample_last
    # (e.g., resample_mean, resample_ohlcv)
    remaining_subgroups = Set{String}()
    for p in all_paths_set
        parts = split(p, "/")
        if length(parts) >= 3
            sz = string(parts[1])
            subgroup = string(parts[2])
            if haskey(SIZE_ORDER, sz) && subgroup != "to_period" && subgroup != "resample_last"
                push!(remaining_subgroups, subgroup)
            end
        end
    end

    if !isempty(remaining_subgroups)
        println(out, "### Additional resample benchmarks")
        println(out, "")

        # Collect remaining paths and display as a standard markdown table
        remaining_paths = String[]
        for p in all_paths_set
            parts = split(p, "/")
            if length(parts) >= 3
                sz = string(parts[1])
                subgroup = string(parts[2])
                if haskey(SIZE_ORDER, sz) && subgroup != "to_period" && subgroup != "resample_last"
                    push!(remaining_paths, p)
                end
            end
        end
        sort!(remaining_paths; by=_size_sort_key)

        # Table header
        header_parts = ["Benchmark"]
        for label in col_labels
            push!(header_parts, label)
        end
        println(out, "| ", join(header_parts, " | "), " |")
        println(out, "|", join(fill("---", length(header_parts)), "|"), "|")

        current_size = ""
        num_cols = length(col_labels)

        for path in remaining_paths
            (sz, leaf) = _extract_size_and_leaf(path)

            if sz != current_size && !isempty(sz)
                current_size = sz
                separator_padding = join(fill("", num_cols), " | ")
                println(out, "| **── $sz ──** | $separator_padding |")
            end

            row = [leaf]

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
                leaf_node = navigate_leaf(gr, path)
                if leaf_node === nothing
                    push!(row, "N/A")
                    continue
                end
                t = BenchmarkTools.minimum(leaf_node).time

                (cell, warned) = _format_speedup_cell_md(t, baseline_time, idx == 1)
                if warned; any_warning = true; end
                push!(row, cell)
            end

            println(out, "| ", join(row, " | "), " |")
        end

        println(out, "")
    end

    # Footnote for ⚠ warnings
    if any_warning
        println(out, "> **⚠ Note**: Cells marked with ⚠ have a baseline time of 0 ns or near-zero, which is a")
        println(out, "> measurement artifact (timer quantization at sub-nanosecond scale in v0.2.2). The comparison")
        println(out, "> ratio is not meaningful for these rows.")
        println(out, "")
    end
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
