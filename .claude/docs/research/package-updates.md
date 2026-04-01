# TSFrames.jl Package Update Research

Research date: 2026-04-01

## 1. Julia Version

| Version | Status | Notes |
|---------|--------|-------|
| 1.10 LTS | LTS (still supported) | Minimum for DataFrames 1.8 |
| 1.11.9 | Maintained | Released 2026-02-08 |
| 1.12.5 | Latest stable | Released 2026-02-09 |
| 1.13 | Pre-release | In testing |

**Current TSFrames compat**: `julia = "1.6, 1.7, 1.8, 1.9, 1.10"`
**CRITICAL**: DataFrames 1.8.0 requires Julia >= 1.10. TSFrames lists Julia 1.6-1.9 which would force resolution to DataFrames < 1.8.

**Recommendation**: `julia = "1.10, 1.11, 1.12"` (drop 1.6-1.9, align with DataFrames 1.8 requirement)

## 2. Package Version Summary

| Package | TSFrames compat | Manifest | Latest | Action Needed |
|---------|-----------------|----------|--------|---------------|
| DataFrames | "1.3.2" | 1.8.1 | **1.8.1** (2024-10-17) | Widen to "1" or "1.3, 1.4, 1.5, 1.6, 1.7, 1.8" |
| RecipesBase | "1.2.1" | 1.3.4 | **1.3.0** (2024-09-27) | Widen to "1.2, 1.3" |
| RollingFunctions | "0.6.2, 0.7" | 0.7.0 | **0.8.1** (2024-11-20) | Add 0.8: "0.6.2, 0.7, 0.8" |
| ShiftedArrays | "1.0.0, 2" | 2.0.0 | **2.0.0** | OK as-is |
| StatsBase | "0.33, 0.34" | 0.34.10 | **0.34.10** (2025-01-12) | OK as-is |
| Tables | "1" | 1.12.1 | **1.12.1** (2024-06-04) | OK as-is |
| Documenter | "0.27.15" | (docs only) | **1.17.0** (2025-02-20) | **MAJOR upgrade needed** |

## 3. DataFrames.jl Details

### Version History (recent)
- v1.8.1 (2024-10-17) - latest
- v1.8.0 (2024-09-11) - **breaking: requires Julia 1.10+**
- v1.7.1 (2024-08-25)
- v1.7.0 (2023-09-23)
- No v2.0 exists. Only 1.x series.

### Breaking Changes in v1.8.0
1. **Julia 1.10 minimum** - most impactful for TSFrames
2. DataFrame hashing now includes column names (may affect tests)
3. PrettyTables.jl v3 support added
4. Removed long-deprecated `by` and `aggregate` functions (deprecated since before 1.0)

### Impact on TSFrames
- TSFrames current compat `"1.3.2"` accepts all 1.x. The manifest already uses 1.8.1.
- The real constraint is Julia version: must be >= 1.10 for DataFrames 1.8.
- `by` and `aggregate` removal: need to check if TSFrames uses these (unlikely, they were deprecated long ago).

## 4. RollingFunctions.jl Details

### Version History
- v0.8.1 (2024-11-20) - latest, removed unnecessary dependencies
- v0.8.0 (2024-09-19) - bug fixes (type preservation, padding)
- v0.7.0 (2023-10-25)
- v0.6.2 (2023-03-27)

### Changes in v0.8.x
- Fixed: rolling functions now respect type (no longer converts to float unnecessarily)
- Fixed: padding example from readme
- Removed unnecessary dependencies
- No known API-breaking changes, mostly bug fixes

### Impact on TSFrames
- Adding "0.8" to compat should be safe. Test to confirm.
- v1.0 preview exists as "WindowedFunctions.jl" but is a separate package.

## 5. RecipesBase.jl Details

### Version History
- v1.3.0 (2024-09-27) - latest, added @layout macro
- v1.2.1 (2023-11-25)
- v1.2.0 (2023-11-23)

### Impact on TSFrames
- Minor feature additions only. No breaking changes.
- Current compat "1.2.1" is too narrow; widen to "1.2, 1.3".

## 6. Documenter.jl Migration (0.27 -> 1.x)

### CRITICAL: This is the biggest migration effort.

### Version History
- v1.17.0 (2025-02-20) - latest
- v1.0.0 (2023-09-15) - major rewrite
- v0.27.x - last 0.x series

### Breaking Changes (0.27 -> 1.0)

1. **`strict` keyword REMOVED**
   - Current TSFrames make.jl uses `strict=false`
   - Replace with `warnonly=true` (equivalent behavior)
   - Or remove entirely and use `warnonly = [:cross_references, :missing_docs]` for specific categories

2. **`repo` keyword format changed**
   - Current: `repo="https://github.com/xKDR/TSFrames.jl/blob/{commit}{path}#{line}"`
   - New: Use `remotes` or just `repo="github.com/xKDR/TSFrames.jl"` (Documenter auto-resolves)
   - The old URL template format may not work

3. **Markdown backend removed**
   - Only HTML output supported natively (markdown via DocumenterMarkdown)
   - TSFrames uses HTML only, so no impact

4. **Plugins keyword**
   - Plugins must be passed via `plugins` keyword, not positional args
   - TSFrames doesn't use plugins, so no impact

5. **Unrecognized keywords cause errors**
   - Previously silently ignored, now throws error
   - `strict=false` will cause an error in Documenter >= 1.0

6. **Local link validation**
   - Documenter now validates local links; broken links fail the build
   - May need `warnonly = :cross_references` initially

7. **Minimum Julia version**: 1.6 for Documenter 1.0 (no issue with recommended 1.10+)

### Required Changes to docs/make.jl

```julia
# BEFORE (0.27)
makedocs(;
    strict=false,
    repo="https://github.com/xKDR/TSFrames.jl/blob/{commit}{path}#{line}",
    ...
)

# AFTER (1.x)
makedocs(;
    warnonly=true,  # or remove for strict builds
    repo="github.com/xKDR/TSFrames.jl",  # simplified
    ...
)
```

### Required Changes to docs/Project.toml

```toml
[compat]
Documenter = "1"  # was "0.27.15"
```

## 7. GitHub Actions Updates

### Current vs Latest

| Action | Current | Latest | Recommendation |
|--------|---------|--------|---------------|
| actions/checkout | v2 | **v6.0.2** | Upgrade to v4 (stable, widely used) |
| julia-actions/setup-julia | @latest | **v2.7.0** | Pin to v2 |
| julia-actions/cache | v1 | **v3.0.2** | Upgrade to v2 (v3 has breaking change: caches on failure) |
| julia-actions/julia-buildpkg | v1 | **v1.7.0** | Keep v1 (compatible) |
| julia-actions/julia-runtest | v1 | **v1.11.4** | Keep v1 (compatible) |
| julia-actions/julia-processcoverage | v1 | v1 (latest) | Keep v1 |
| codecov/codecov-action | v1 | **v5.5.4 / v6.0.0** | Upgrade to v5 (v6 requires node24) |
| julia-actions/julia-docdeploy | @latest | **v1.3.1** | Pin to v1 |

### Key Notes
- **actions/checkout v2 is very old** (2020 era). v4 is the safe upgrade target. v6 is latest but v4 is widely adopted.
- **codecov/codecov-action v1 is deprecated**. Must upgrade to at least v4 or v5.
- **julia-actions/cache v3** now caches even when jobs fail (behavior change). v2 may be safer default.
- **Using `@latest` tag is risky** for reproducibility. Pin to specific major versions.

## 8. Recommended Project.toml [compat] Section

```toml
[compat]
DataFrames = "1.3, 1.4, 1.5, 1.6, 1.7, 1.8"
RecipesBase = "1.2, 1.3"
RollingFunctions = "0.6.2, 0.7, 0.8"
ShiftedArrays = "1, 2"
StatsBase = "0.33, 0.34"
Tables = "1"
julia = "1.10, 1.11, 1.12"
```

Alternative (simpler, if willing to drop old version support):
```toml
[compat]
DataFrames = "1"
RecipesBase = "1"
RollingFunctions = "0.7, 0.8"
ShiftedArrays = "2"
StatsBase = "0.34"
Tables = "1"
julia = "1.10, 1.11, 1.12"
```

## 9. Priority Order for Updates

1. **Julia compat** (1.10+) - unblocks DataFrames 1.8
2. **Documenter.jl** (0.27 -> 1.x) - biggest migration, docs broken otherwise
3. **GitHub Actions** - security and compatibility
4. **RollingFunctions compat** (add 0.8) - minor
5. **RecipesBase compat** (add 1.3) - minor
6. **CI matrix** - test on Julia 1.10, 1.11, 1.12

## 10. Risk Assessment

| Change | Risk | Notes |
|--------|------|-------|
| Julia 1.10+ | LOW | Package already builds on 1.12.5 |
| DataFrames compat widen | LOW | API stable across 1.x |
| RollingFunctions 0.8 | LOW | Bug fixes only, test to confirm |
| Documenter 1.x | MEDIUM | make.jl needs changes, may uncover doc issues |
| GitHub Actions update | LOW | Standard upgrades, well-tested |

## Sources

- [DataFrames.jl Releases](https://github.com/JuliaData/DataFrames.jl/releases)
- [Documenter.jl Release Notes](https://documenter.juliadocs.org/stable/release-notes/)
- [Documenter.jl CHANGELOG](https://github.com/JuliaDocs/Documenter.jl/blob/master/CHANGELOG.md)
- [Documenter 1.0 Announcement](https://discourse.julialang.org/t/ann-documenter-1-0/103888)
- [RollingFunctions.jl Releases](https://github.com/JeffreySarnoff/RollingFunctions.jl/releases)
- [RecipesBase.jl Releases](https://github.com/JuliaPlots/RecipesBase.jl/releases)
- [StatsBase.jl Releases](https://github.com/JuliaStats/StatsBase.jl/releases)
- [ShiftedArrays.jl Releases](https://github.com/JuliaArrays/ShiftedArrays.jl/releases)
- [Tables.jl Releases](https://github.com/JuliaData/Tables.jl/releases)
- [actions/checkout Releases](https://github.com/actions/checkout/releases)
- [julia-actions/setup-julia Releases](https://github.com/julia-actions/setup-julia/releases)
- [julia-actions/cache Releases](https://github.com/julia-actions/cache/releases)
- [codecov/codecov-action Releases](https://github.com/codecov/codecov-action/releases)
- [julia-actions/julia-docdeploy Releases](https://github.com/julia-actions/julia-docdeploy/releases)
- [Julia Downloads](https://julialang.org/downloads/)
- [TSFrames.jl Issues](https://github.com/xKDR/TSFrames.jl/issues)
