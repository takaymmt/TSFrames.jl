#!/usr/bin/env julia
# benchmark/analysis/compare.jl — N-way benchmark comparison
#
# Usage:
#   julia benchmark/analysis/compare.jl <baseline.json> <result1.json> [result2.json ...] [options]
#
# Options:
#   --label <l1,l2,...>     Labels for each file (default: filenames)
#   --threshold <ratio>     Regression threshold (default: 1.05 = 5% slower)
#   --group <name>          Filter to specific benchmark group
#   --output <path>         Save comparison report to file
#
# Example:
#   julia benchmark/analysis/compare.jl \
#     results/baseline.json \
#     results/after_p1.json \
#     results/after_p2.json \
#     --label "baseline,P1: @view apply,P2: gap-aware resample"

using BenchmarkTools

include(joinpath(@__DIR__, "..", "utils.jl"))

# ── Argument Parsing ─────────────────────────────────────────────────────────

function parse_compare_args(args)
    config = Dict{Symbol, Any}(
        :files     => String[],
        :labels    => nothing,
        :threshold => 1.05,
        :group     => nothing,
        :output    => nothing,
    )

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--label"
            i += 1
            config[:labels] = split(args[i], ",")
        elseif arg == "--threshold"
            i += 1
            config[:threshold] = parse(Float64, args[i])
        elseif arg == "--group"
            i += 1
            config[:group] = args[i]
        elseif arg == "--output"
            i += 1
            config[:output] = args[i]
        elseif !startswith(arg, "--")
            push!(config[:files], arg)
        else
            @warn "Unknown argument: $arg"
        end
        i += 1
    end

    return config
end

# ── Helpers ──────────────────────────────────────────────────────────────────

# Get minimum time from a Trial or BenchmarkGroup leaf
function get_min_time(trial)
    BenchmarkTools.minimum(trial).time
end

# ── Comparison Logic ─────────────────────────────────────────────────────────

function compare_results(config)
    files = config[:files]
    if length(files) < 2
        error("Need at least 2 files to compare. Got $(length(files)).")
    end

    # Load all results
    results = [load_result(f) for f in files]

    # Assign labels
    labels = if config[:labels] !== nothing
        if length(config[:labels]) != length(files)
            error("Number of labels ($(length(config[:labels]))) must match number of files ($(length(files)))")
        end
        [strip(l) for l in config[:labels]]
    else
        [basename(f) for f in files]
    end

    threshold = config[:threshold]

    # Optionally filter to a group
    if config[:group] !== nothing
        g = config[:group]
        results = map(results) do r
            if haskey(r, g)
                r[g]
            else
                error("Group '$g' not found. Available: $(join(keys(r), ", "))")
            end
        end
    end

    # Collect output
    output = IOBuffer()

    println(output, "=== Benchmark Comparison ===")
    println(output, "Baseline: $(labels[1]) ($(files[1]))")
    println(output, "Threshold: $(round((threshold - 1) * 100, digits=1))% regression detection")
    println(output, "")

    # Get baseline leaves
    baseline_leaves = collect_leaves(results[1])

    # Track stats per result
    stats = [Dict(:improvements => 0, :regressions => 0, :invariant => 0) for _ in 2:length(results)]

    # Group leaves by top-level group
    groups = Dict{String, Vector{String}}()
    for (path, _) in baseline_leaves
        parts = split(path, "/")
        top = parts[1]
        if !haskey(groups, top)
            groups[top] = String[]
        end
        push!(groups[top], path)
    end

    for group_name in sort(collect(keys(groups)))
        println(output, "Group: $group_name")
        paths = groups[group_name]

        for path in sort(paths)
            # Get baseline time
            baseline_trial = navigate_leaf(results[1], path)
            if baseline_trial === nothing
                continue
            end
            baseline_time = get_min_time(baseline_trial)

            println(output, "  $path")
            println(output, "    $(rpad(labels[1], 20)) -> $(format_time(baseline_time))  (1.0x)")

            for idx in 2:length(results)
                trial = navigate_leaf(results[idx], path)
                if trial === nothing
                    println(output, "    $(rpad(labels[idx], 20)) -> N/A")
                    continue
                end

                t = get_min_time(trial)
                ratio = t / baseline_time
                speedup = baseline_time / t

                status, marker = if ratio < (1.0 / threshold)
                    stats[idx-1][:improvements] += 1
                    pct = round((1 - ratio) * 100, digits=1)
                    ("improvement (-$(pct)%)", "v")
                elseif ratio > threshold
                    stats[idx-1][:regressions] += 1
                    pct = round((ratio - 1) * 100, digits=1)
                    ("REGRESSION (+$(pct)%)", "X")
                else
                    stats[idx-1][:invariant] += 1
                    ("invariant", "~")
                end

                println(output, "    $(rpad(labels[idx], 20)) -> $(format_time(t))  ($(round(ratio, digits=2))x) $marker $status")
            end
        end
        println(output)
    end

    # Summary
    println(output, "Summary:")
    for idx in 2:length(results)
        s = stats[idx-1]
        println(output, "  $(labels[idx]):  $(s[:improvements]) improvements, $(s[:regressions]) regressions, $(s[:invariant]) invariant")
    end

    report = String(take!(output))
    print(report)

    # Save if requested
    if config[:output] !== nothing
        dir = dirname(config[:output])
        if !isempty(dir) && !isdir(dir)
            mkpath(dir)
        end
        open(config[:output], "w") do f
            write(f, report)
        end
        println("\nReport saved to: $(config[:output])")
    end
end

# ── Main ─────────────────────────────────────────────────────────────────────

function main()
    config = parse_compare_args(ARGS)
    compare_results(config)
end

# Only run main when executed directly (not included)
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
