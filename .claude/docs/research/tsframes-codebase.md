# TSFrames.jl Codebase Analysis

**Date**: 2026-04-01
**Version**: 0.2.2
**License**: MIT (xKDR Forum, 2022)
**Repository**: git@github.com:takaymmt/TSFrames.jl.git (fork of xKDR/TSFrames.jl)

---

## 1. Package Purpose

TSFrames.jl is a Julia package for handling time series data. It wraps `DataFrames.jl` with a dedicated `TSFrame` struct that enforces a sorted temporal index (supporting `Int` and `TimeType` indices). The package provides a convenient interface for common time series operations: subsetting by date ranges, lag/lead, rolling functions, period conversion, joins, and plotting via RecipesBase.

The package is Tables.jl-compatible, allowing interoperability with CSV.jl, MarketData.jl, and any other Tables.jl sink/source.

---

## 2. Directory Structure

```
TSFrames.jl/
  Project.toml          # Package metadata and dependencies
  Manifest.toml         # Local manifest (NOT tracked in git, julia 1.12.5)
  Artifacts.toml        # IBM sample data artifact
  README.md             # Package documentation with examples
  Benchmark.md          # Performance benchmarks
  LICENSE               # MIT
  ts-plot.svg           # Example plot image
  src/                  # 21 source files, 3,634 LOC
    TSFrames.jl         # Module definition, imports, exports (102 lines)
    TSFrame.jl          # Core struct + constructors (440 lines)
    utils.jl            # Utility functions: describe, head, tail, show, etc. (689 lines)
    getindex.jl         # Indexing operations (498 lines)
    endpoints.jl        # Endpoint detection by period (388 lines)
    join.jl             # Join operations (inner, outer, left, right) (305 lines)
    apply.jl            # Apply functions over TSFrame (163 lines)
    vcat.jl             # Vertical concatenation / rbind (158 lines)
    subset.jl           # Date-range subsetting (152 lines)
    rollapply.jl        # Rolling window functions (94 lines)
    pctchange.jl        # Percentage change calculations (88 lines)
    lead.jl             # Lead shifting (86 lines)
    diff.jl             # Differencing (84 lines)
    lag.jl              # Lag shifting (78 lines)
    upsample.jl         # Upsampling [NOT INCLUDED IN MODULE] (75 lines)
    plot.jl             # RecipesBase plot recipes (75 lines)
    to_period.jl        # Period conversion (daily->monthly, etc.) (71 lines)
    matrix.jl           # Matrix conversion (47 lines)
    broadcasting.jl     # Broadcasting support (21 lines)
    tables.jl           # Tables.jl interface (17 lines)
    getproperty.jl      # Property access (3 lines)
  test/                 # 21 test files, 2,531 LOC
    runtests.jl         # Test runner (86 lines)
    dataobjects.jl      # Shared test data (22 lines)
    [1:1 mapping with src/ files]
  docs/                 # Documenter.jl documentation
    make.jl             # Documentation build script
    Project.toml        # Docs dependencies
    src/
      index.md
      demo_finance.md
      user_guide.md
      api.md
  .github/workflows/   # CI/CD
    ci.yml              # Tests on Julia '1' (latest), 3 OS
    documentation.yml   # Documenter.jl deploy
    CompatHelper.yml    # Automatic compat bumps
    TagBot.yml          # Automatic tagging
```

---

## 3. Dependencies (from Project.toml)

### Direct Dependencies

| Package | UUID | Compat Spec | Manifest Version |
|---------|------|-------------|------------------|
| DataFrames | a93c6f00-... | 1.3.2 | 1.8.1 |
| Dates | ade2ca70-... | (stdlib) | 1.11.0 |
| Random | 9a3f8284-... | (stdlib) | 1.11.0 |
| RecipesBase | 3cdcf5f2-... | 1.2.1 | 1.3.4 |
| RollingFunctions | b0e4dd01-... | 0.6.2, 0.7 | 0.7.0 |
| ShiftedArrays | 1277b4bf-... | 1.0.0, 2 | 2.0.0 |
| Statistics | 10745b16-... | (stdlib) | 1.11.1 |
| StatsBase | 2913bbd2-... | 0.33, 0.34 | 0.34.10 |
| Tables | bd369af6-... | 1 | 1.12.1 |
| Artifacts | 56f22d72-... | (stdlib) | 1.11.0 |

### Julia Version Compat

```
julia = "1.6, 1.7, 1.8, 1.9, 1.10"
```

**Note**: Julia 1.11 and 1.12 are NOT in compat, but the Manifest was generated with Julia 1.12.5.

### Test Dependencies

- Test (stdlib)

### Documentation Dependencies (docs/Project.toml)

- CSV, DataFrames, Documenter (compat: 0.27.15), MarketData, Plots, RecipesBase, Statistics, Impute, GLM, TSFrames

---

## 4. Core Architecture

### TSFrame Struct

```julia
struct TSFrame
    coredata :: DataFrame
end
```

- Single field wrapping a DataFrame
- Index is always stored in the first column named `:Index`
- Supports `Int` and `TimeType` (Date, DateTime, Time) indices
- Data is sorted by index on construction (unless `issorted=true`)
- Tables.jl compatible (row and column access)

### Key Design Patterns

1. **Delegation to DataFrames**: Most operations delegate to DataFrames.jl internally
2. **Index-first**: The Index column is always first in coredata
3. **Immutable approach**: Most operations return new TSFrame objects
4. **RecipesBase for plotting**: No direct Plots.jl dependency, uses recipes
5. **Type dispatch**: Heavy use of Julia's multiple dispatch for different index types

### Exported API

- **Construction**: `TSFrame` (multiple constructors)
- **Inspection**: `index`, `names`, `length`, `size`, `nr`/`nrow`, `nc`/`ncol`, `describe`, `show`, `summary`, `isregular`
- **Access**: `getindex`, `first`, `head`, `tail`, `lastindex`
- **Manipulation**: `apply`, `diff`, `lag`, `lead`, `pctchange`, `rollapply`
- **Time operations**: `to_period`, `to_yearly`, `to_quarterly`, `to_monthly`, `to_weekly`, `to_daily`, `to_hourly`, `to_minutes`, `to_seconds`, `to_milliseconds`, `to_microseconds`, `to_nanoseconds`
- **Combining**: `join` (with JoinInner/JoinOuter/JoinLeft/JoinRight/JoinBoth/JoinAll), `vcat`, `cbind`, `rbind`
- **Subsetting**: `subset`, `endpoints`
- **Conversion**: `convert`, `Matrix`, `DataFrame`, `plot`

---

## 5. Test Structure

### Test Coverage

19 test sets covering all major modules:

| Test Set | Lines | Coverage Focus |
|----------|-------|---------------|
| TSFrame() | 174 | Constructors |
| getindex() | 452 | Indexing operations |
| apply() | 586 | Apply functions (most extensive) |
| utils | 316 | Utility functions |
| endpoints() | 350 | Period endpoint detection |
| join | 151 | Join operations |
| subset | 78 | Date-range subsetting |
| vcat | 59 | Vertical concatenation |
| tables | 48 | Tables.jl interface |
| to_period() | 44 | Period conversion |
| rollapply() | 33 | Rolling window |
| pctchange | 30 | Percentage change |
| lag | 26 | Lag |
| lead | 25 | Lead |
| broadcasting | 22 | Broadcasting |
| diff | 20 | Differencing |
| matrix | 4 | Matrix conversion |
| index() | 3 | Index access |
| getproperty | 2 | Property access |

### Test/Source Ratio

- Source: 3,634 LOC
- Tests: 2,531 LOC
- Ratio: 0.70 (decent but some modules are thin)

### Weak Test Coverage Areas

- `matrix.jl`: Only 4 lines of tests for 47 lines of source
- `getproperty.jl`: Only 2 lines of tests
- `index.jl`: Only 3 lines of tests
- `broadcasting.jl`: Only 22 lines of tests (thin)
- No test for `upsample.jl` (it's not included in the module)

---

## 6. CI/CD Setup

### GitHub Actions Workflows

1. **CI** (`ci.yml`):
   - Tests on Julia `'1'` (latest stable) across ubuntu/windows/macos x64
   - Code coverage via codecov (using codecov-action@v1)
   - Uses `actions/checkout@v2` (outdated, current is v4)
   - Uses `julia-actions/cache@v1`, `julia-actions/julia-buildpkg@v1`, `julia-actions/julia-runtest@v1`
   - Uses `codecov/codecov-action@v1` (outdated, current is v4+)

2. **Documentation** (`documentation.yml`):
   - Builds and deploys docs on push/PR to main
   - Uses Documenter.jl via julia-docdeploy@latest
   - Uses `actions/checkout@v2` (outdated)

3. **CompatHelper** (`CompatHelper.yml`):
   - Daily cron to check dependency compat updates
   - Opens PRs when new versions of dependencies are released

4. **TagBot** (`TagBot.yml`):
   - Automatically creates GitHub releases when packages are registered

### CI Issues

- `actions/checkout@v2` is deprecated (should be v4)
- `codecov/codecov-action@v1` is deprecated (should be v4+)
- CI only tests Julia `'1'` (latest), not against specific older versions listed in compat
- No matrix for older Julia versions (1.6, 1.7, etc.) despite compat claims

---

## 7. Known Issues and TODOs

### In-Code TODOs

1. `src/TSFrame.jl:416` - `# FIXME: use Metadata.jl` (consider using Metadata.jl for metadata)
2. `src/getindex.jl:421` - `# XXX: ideally, Dates.YearMonth class should exist`
3. `docs/make.jl:22-23` - `doctest=false` and `strict=false` (TODO to enable)

### Dead Code

- `src/upsample.jl` exists but is NOT included in the module (`TSFrames.jl`) and NOT exported. This is dead code that should either be integrated or removed.

### Julia Compat Gap

- `Project.toml` lists `julia = "1.6, 1.7, 1.8, 1.9, 1.10"` but Julia 1.11 and 1.12 are not listed despite the Manifest being generated with 1.12.5. This means:
  - Users on Julia 1.11+ may face issues installing from the registry
  - The compat should be updated to include 1.11 and 1.12

### Outdated Dependency Compat

- `DataFrames = "1.3.2"` - Very old minimum, latest is 1.7+. The `=` syntax means only 1.3.x is officially supported (though Manifest has 1.8.1 installed). This should use broader compat like `"1"`.
- `RecipesBase = "1.2.1"` - Current installed is 1.3.4
- `StatsBase = "0.33, 0.34"` - Installed is 0.34.10

### Documentation Compat

- `docs/Project.toml` pins `Documenter = "0.27.15"` which is very old (current is 1.x). This likely causes build failures.

### CI/CD Outdated Actions

- `actions/checkout@v2` -> should be `@v4`
- `codecov/codecov-action@v1` -> should be `@v4`

### Missing Features / Gaps

- No `setindex!` support (immutable design)
- No resampling with aggregation (only upsampling exists as dead code)
- `doctest=false` means documentation examples are not verified
- No benchmarking in CI

---

## 8. Dependency Tree (Notable Transitive)

The `RollingFunctions` package pulls in a heavy dependency chain:
- RollingFunctions -> AccurateArithmetic -> VectorizationBase -> LoopVectorization
- This brings in: ArrayInterface, CPUSummary, HostCPUFeatures, SIMDTypes, SLEEFPirates, Static, StaticArrayInterface, etc.

This is a significant transitive dependency burden for what is essentially rolling mean/sum calculations.

---

## 9. Recent Activity

The last commit (2a6a16a) was a version and author update. The repository appears to be in maintenance mode with infrequent updates. Recent commits have been:
- Julia version compat updates (1.8, 1.9, 1.10)
- Documentation fixes
- Minor bug fixes

The original package is from xKDR Forum; this appears to be a personal fork.

---

## 10. Potential Update Risks and Concerns

### High Priority

1. **Julia compat**: Add 1.11 and 1.12 support to Project.toml
2. **DataFrames compat**: The `"1.3.2"` compat is restrictive; should be broadened
3. **Documenter.jl**: `0.27.15` is extremely old; upgrade needed for docs to build
4. **CI Actions**: `checkout@v2` and `codecov@v1` are deprecated

### Medium Priority

5. **Dead code**: `upsample.jl` should be integrated or removed
6. **Doctests disabled**: Should be enabled for documentation quality
7. **Heavy dependency chain**: RollingFunctions pulls LoopVectorization; consider lighter alternatives
8. **Test coverage gaps**: Some modules have minimal tests

### Low Priority

9. **Metadata.jl integration** (noted FIXME)
10. **CI version matrix**: Should test against all supported Julia versions
11. **Benchmark CI**: No automated benchmarking
