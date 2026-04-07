#!/usr/bin/env julia
# benchmark/run.jl — Benchmark runner
#
# Usage:
#   julia benchmark/run.jl [options]
#
# Options:
#   --save <path>              Save results to JSON file
#   --desc <text>              Description for .meta.json sidecar
#   --group <g1,g2,...>        Run specific benchmark groups only
#   --report <f1> <f2> ...    Generate Markdown report from JSON files
#   --tune                     Tune benchmark parameters before running
#   --verbose                  Show detailed progress
#
# Examples:
#   # Run all and save
#   julia benchmark/run.jl --save benchmark/results/baseline.json
#
#   # Run specific groups
#   julia benchmark/run.jl --group resample_vs_to_period,apply --save benchmark/results/latest.json
#
#   # Generate report from multiple results
#   julia benchmark/run.jl --report benchmark/results/v0.2.2.json benchmark/results/v0.3.5.json
#
# To compare two JSON result files:
#   julia benchmark/analysis/compare.jl baseline.json latest.json

using Dates
using BenchmarkTools

include(joinpath(@__DIR__, "utils.jl"))

# ── Argument Parsing ─────────────────────────────────────────────────────────

function parse_args(args)
    config = Dict{Symbol, Any}(
        :save     => nothing,
        :groups   => nothing,
        :report   => nothing,
        :output   => nothing,
        :tune     => false,
        :verbose  => false,
        :desc     => "",
    )

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--save"
            i += 1
            config[:save] = args[i]
        elseif arg == "--group"
            i += 1
            config[:groups] = split(args[i], ",")
        elseif arg == "--report"
            files = String[]
            i += 1
            while i <= length(args) && !startswith(args[i], "--")
                push!(files, args[i])
                i += 1
            end
            config[:report] = files
            continue
        elseif arg == "--output"
            i += 1
            config[:output] = args[i]
        elseif arg == "--desc"
            i += 1
            config[:desc] = args[i]
        elseif arg == "--tune"
            config[:tune] = true
        elseif arg == "--verbose"
            config[:verbose] = true
        else
            @warn "Unknown argument: $arg"
        end
        i += 1
    end

    return config
end

# ── Helpers ──────────────────────────────────────────────────────────────────

const _verbose = Ref(false)

function log_msg(msg::String; verbose::Bool=false, level::Symbol=:info)
    # When verbose=true is passed, only print if _verbose[] is set
    if verbose && !_verbose[]
        return
    end
    timestamp = Dates.format(now(), "HH:MM:SS")
    prefix = level == :info ? "INFO" : (level == :warn ? "WARN" : "ERR ")
    println("[$timestamp] $prefix  $msg")
end


# ── Run Benchmarks ───────────────────────────────────────────────────────────

function run_benchmarks(config)
    log_msg("Loading benchmark suite...")

    # Load the suite (include defines SUITE in a new world; use invokelatest to access it)
    include(joinpath(@__DIR__, "benchmarks.jl"))

    suite = Base.invokelatest(() -> SUITE)

    # Filter groups if requested
    if config[:groups] !== nothing
        filtered = BenchmarkTools.BenchmarkGroup()
        for g in config[:groups]
            g = strip(g)
            if haskey(suite, g)
                filtered[g] = suite[g]
            else
                log_msg("Group '$g' not found in suite. Available: $(join(keys(suite), ", "))", level=:warn)
            end
        end
        suite = filtered
    end

    # Report what we're running
    all_leaves = collect_leaves(suite)
    log_msg("Running $(length(all_leaves)) benchmarks across $(length(keys(suite))) groups")

    if config[:verbose]
        for k in sort(collect(keys(suite)))
            leaves = collect_leaves(suite[k], string(k))
            log_msg("  $k: $(length(leaves)) benchmarks", verbose=true)
        end
    end

    # Tune if requested
    if config[:tune]
        log_msg("Tuning benchmark parameters...")
        tune!(suite)
        log_msg("Tuning complete.")
    end

    # Run
    log_msg("Running benchmarks (this may take several minutes)...")
    results = run(suite; verbose=config[:verbose])
    log_msg("Benchmarks complete.")

    # Print summary
    println("\n", "="^60)
    println("  Benchmark Results Summary")
    println("="^60)
    for group_key in sort(collect(keys(results)))
        println("\n--- $group_key ---")
        print_group_summary(results[group_key], "  ")
    end

    # Save if requested
    if config[:save] !== nothing
        save_results(results, config[:save]; description=config[:desc])
        log_msg("Results saved to: $(config[:save])")
    end

    return results
end

function print_group_summary(bg, indent="")
    for k in sort(collect(keys(bg)))
        child = bg[k]
        if child isa BenchmarkTools.BenchmarkGroup
            println("$(indent)$k:")
            print_group_summary(child, indent * "  ")
        else
            t = child
            med = BenchmarkTools.median(t)
            min_t = BenchmarkTools.minimum(t)
            println("$(indent)$k: $(format_time(min_t.time)) (median: $(format_time(med.time)), $(min_t.allocs) allocs, $(format_bytes(min_t.memory)))")
        end
    end
end


# ── Save / Load ──────────────────────────────────────────────────────────────

function save_results(results, path::String; description::String="")
    # Ensure directory exists
    dir = dirname(path)
    if !isempty(dir) && !isdir(dir)
        mkpath(dir)
    end

    # Serialize using BenchmarkTools' built-in JSON serialization
    BenchmarkTools.save(path, results)

    # Generate sidecar .meta.json
    fname = replace(basename(path), r"\.json$" => "")

    # Parse filename to determine version/suffix/status
    m_ver = match(r"^v(\d+\.\d+\.\d+)$", fname)
    m_tmp = match(r"^tmp-(\w+)$", fname)

    if m_ver !== nothing
        save_meta(path;
                  version=String(m_ver.captures[1]),
                  suffix="",
                  status="release",
                  description=description)
    elseif m_tmp !== nothing
        # For temporary files, use current project version as the version context
        save_meta(path;
                  version="0.0.0",
                  suffix=String(m_tmp.captures[1]),
                  status="temporary",
                  description=description)
    else
        # Fallback: save meta with unknown status
        save_meta(path;
                  version="0.0.0",
                  suffix="",
                  status="unknown",
                  description=description)
    end
end


# ── Report Mode ──────────────────────────────────────────────────────────────

function run_report(files; output=nothing)
    if isempty(files)
        error("Report requires at least 1 file.")
    end

    # Delegate to analysis/report.jl
    include(joinpath(@__DIR__, "analysis", "report.jl"))
    Base.invokelatest(generate_report, files; output=output)
end

# ── Main ─────────────────────────────────────────────────────────────────────

function main()
    config = parse_args(ARGS)
    _verbose[] = config[:verbose]

    if config[:report] !== nothing
        run_report(config[:report]; output=config[:output])
    else
        run_benchmarks(config)
    end
end

main()
