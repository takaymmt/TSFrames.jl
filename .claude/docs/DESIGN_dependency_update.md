# TSFrames.jl Dependency Update Plan

> Created: 2026-04-01
> Status: Draft
> Purpose: Modernize TSFrames.jl dependencies, Julia compat, CI, and docs tooling

## 1. Current State Summary

### Project.toml (root)

| Dependency       | Current Compat     | Manifest Resolved | Latest Known  |
|------------------|--------------------|-------------------|---------------|
| DataFrames       | `"1.3.2"`          | 1.8.1             | 1.8.1         |
| RecipesBase      | `"1.2.1"`          | 1.3.4             | ~1.3.x        |
| RollingFunctions | `"0.6.2, 0.7"`    | 0.7.0             | 0.8.1         |
| ShiftedArrays    | `"1.0.0, 2"`       | 2.0.0             | 2.x           |
| StatsBase        | `"0.33, 0.34"`     | 0.34.10           | 0.34.10       |
| Tables           | `"1"`              | (latest 1.x)      | 1.x           |
| julia            | `"1.6, 1.7, 1.8, 1.9, 1.10"` | built on 1.12.5 | 1.12.x |

### docs/Project.toml

| Dependency | Current Compat | Latest Known |
|------------|---------------|--------------|
| Documenter | `"0.27.15"`   | ~1.12.0      |

### CI Workflows

| Action              | Current Version | Latest Recommended |
|---------------------|----------------|-------------------|
| actions/checkout     | v2             | v4                |
| julia-actions/cache  | v1             | v2                |
| codecov/codecov-action | v1           | v5 (v6 beta)      |
| julia-actions/setup-julia | @latest  | @latest (OK)      |
| julia-actions/julia-buildpkg | v1    | v1 (OK)           |
| julia-actions/julia-runtest | v1     | v1 (OK)           |
| julia-actions/julia-processcoverage | v1 | v1 (OK)       |
| julia-actions/julia-docdeploy | @latest | @latest (OK)  |

### Dead Code

- `src/upsample.jl` exists but is NOT included in `src/TSFrames.jl` module

---

## 2. Update Sequence (Ordered Steps)

### Phase 1: Julia Compat + Core Dependencies (Low Risk)

**Step 1.1: Update Julia compat bounds**

File: `Project.toml`

```toml
# FROM:
julia = "1.6, 1.7, 1.8, 1.9, 1.10"

# TO:
julia = "1.6 - 1.12"
```

- **Risk**: LOW. Julia maintains strong backward compat within 1.x.
- **Caveat**: DataFrames.jl 1.8.0 requires Julia >= 1.10. If we expand DataFrames compat
  to include 1.8.x, the effective minimum Julia for the latest DataFrames becomes 1.10.
  However, older DataFrames 1.3.x-1.7.x still work on Julia 1.6, so the resolver handles this.
- **Verify**: `julia -e 'using Pkg; Pkg.activate("."); Pkg.resolve()'`

**Step 1.2: Expand DataFrames.jl compat**

File: `Project.toml`

```toml
# FROM:
DataFrames = "1.3.2"

# TO:
DataFrames = "1.3, 1.4, 1.5, 1.6, 1.7, 1.8"
```

- **Risk**: MEDIUM. Key breaking changes between 1.3 and 1.8:
  - v1.4: DataFrame became a mutable struct with metadata fields (serialization incompatible)
  - v1.4: `by` and `aggregate` fully removed (already deprecated)
  - v1.7: Broadcasting assignment into existing column replaces it (Julia 1.7+)
  - v1.8: Requires Julia >= 1.10; PrettyTables v3 support
  - TSFrames uses `DataFrame`, `nrow`, `ncol`, `select`, `rename!`, `sort!`, `getindex`,
    `vcat`, `innerjoin`/`outerjoin`/`leftjoin`/`rightjoin`, `allowmissing!`, `transform`,
    `subset` -- these are all stable APIs unlikely to break.
- **Verify**: Run full test suite after update.

**Step 1.3: Update RollingFunctions.jl compat**

File: `Project.toml`

```toml
# FROM:
RollingFunctions = "0.6.2, 0.7"

# TO:
RollingFunctions = "0.6.2, 0.7, 0.8"
```

- **Risk**: LOW (verified). TSFrames does `using RollingFunctions` but does NOT call any
  RollingFunctions API functions directly. The `rollapply.jl` implementation is entirely
  custom using DataFrames `mapcols`/`rename!`/`vcat` and manual windowing. RollingFunctions
  is only re-exported for user convenience. v0.8 API changes (`runmean` -> `running(mean, ...)`)
  do not affect TSFrames internally.
- **Verify**: Run `rollapply` tests specifically.

**Step 1.4: Expand RecipesBase compat**

File: `Project.toml`

```toml
# FROM:
RecipesBase = "1.2.1"

# TO:
RecipesBase = "1"
```

- **Risk**: LOW. RecipesBase has a stable `@recipe` macro API.
- **Verify**: Check plot recipe compilation.

**Step 1.5: Expand StatsBase compat**

File: `Project.toml`

```toml
# FROM:
StatsBase = "0.33, 0.34"

# TO:
StatsBase = "0.33, 0.34"
```

- **Risk**: NONE. Already covers latest (0.34.10). No change needed.

**Step 1.6: Regenerate Manifest.toml**

```bash
cd /Users/taka/proj/TSFrames.jl
julia -e 'using Pkg; Pkg.activate("."); Pkg.update()'
```

- **Risk**: LOW. Resolver will pick compatible versions.
- **Verify**: `julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate(); Pkg.precompile()'`

### Phase 2: Run Tests (Validation Gate)

**Step 2.1: Run full test suite**

```bash
cd /Users/taka/proj/TSFrames.jl
julia -e 'using Pkg; Pkg.activate("."); Pkg.test()'
```

- **Expected outcome**: All tests pass. If failures, diagnose before proceeding to Phase 3.
- **Key test areas to watch**:
  - `rollapply` tests (RollingFunctions API changes)
  - `join` tests (DataFrames join API)
  - `subset` tests (DataFrames subset API)
  - `vcat` tests (DataFrames vcat behavior)
  - `getindex` tests (DataFrame indexing)

### Phase 3: Documentation Tooling (Medium Risk)

**Step 3.1: Update docs/Project.toml for Documenter.jl 1.x**

File: `docs/Project.toml`

```toml
# FROM:
[compat]
Documenter = "0.27.15"

# TO:
[compat]
Documenter = "1"
```

- **Risk**: MEDIUM-HIGH. Documenter 1.0 has breaking changes.
- **Breaking changes that affect this project**:
  1. `strict` keyword removed -> replaced by `warnonly` (or just remove it; strict is now default)
  2. `repo` keyword in `makedocs`: URL format changed. Old `{commit}{path}#{line}` template
     may need updating or removal (Documenter can infer from git checkout).
  3. Plugin objects moved from positional to keyword args.
  4. Local link validation now enforced by default.

**Step 3.2: Update docs/make.jl**

File: `docs/make.jl`

```julia
# FROM:
makedocs(;
    modules=[TSFrames],
    authors="xKDR Forum",
    repo="https://github.com/xKDR/TSFrames.jl/blob/{commit}{path}#{line}",
    sitename="TSFrames.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://xKDR.github.io/TSFrames.jl",
        assets=String[],
    ),
    pages=[...],
    doctest=false,
    strict=false,
)

# TO:
makedocs(;
    modules=[TSFrames],
    authors="xKDR Forum",
    sitename="TSFrames.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://xKDR.github.io/TSFrames.jl",
        assets=String[],
    ),
    pages=[...],
    doctest=false,
    warnonly=true,
)
```

Key changes:
- **Remove `repo` keyword**: Documenter 1.x infers repository URL from the git checkout.
  The old `{commit}{path}#{line}` template syntax is no longer supported.
- **Replace `strict=false` with `warnonly=true`**: In Documenter 1.x, strict mode is
  the default. `warnonly=true` restores the old lenient behavior.
- **Risk**: If `repo` removal causes issues, can use the new `remotes` keyword or
  `Documenter.Remotes.GitHub("xKDR", "TSFrames.jl")` instead.

**Step 3.3: Build docs locally to verify**

```bash
cd /Users/taka/proj/TSFrames.jl
julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate(); Pkg.update()'
julia --project=docs docs/make.jl
```

- **Verify**: No errors during build; check `docs/build/index.html` renders correctly.

### Phase 4: CI Workflow Updates (Low Risk)

**Step 4.1: Update .github/workflows/CI.yml**

```yaml
# Changes:
# 1. actions/checkout@v2 -> actions/checkout@v4
# 2. julia-actions/cache@v1 -> julia-actions/cache@v2
# 3. codecov/codecov-action@v1 -> codecov/codecov-action@v5
# 4. Add Julia version matrix entries for 1.10 and 1 (latest)
```

Full target CI.yml:

```yaml
name: CI
on:
    push:
        branches: '**'
        tags: '*'
    pull_request:
        branches: '**'
jobs:
    test:
        name: Julia ${{ matrix.version }} - ${{ matrix.os }} - ${{ matrix.arch }} - ${{ github.event_name }}
        runs-on: ${{ matrix.os }}
        strategy:
            matrix:
                version: ['1.10', '1']
                os: [ubuntu-latest, windows-latest, macos-latest]
                arch: [x64]
        steps:
            - uses: actions/checkout@v4
            - uses: julia-actions/setup-julia@latest
              with:
                version: ${{ matrix.version }}
                arch: ${{ matrix.arch }}
            - uses: julia-actions/cache@v2
            - uses: julia-actions/julia-buildpkg@v1
            - uses: julia-actions/julia-runtest@v1
    codecov:
        name: Code Coverage
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4
            - uses: julia-actions/setup-julia@latest
              with:
                  version: '1'
            - uses: julia-actions/cache@v2
            - uses: julia-actions/julia-buildpkg@v1
            - uses: julia-actions/julia-runtest@v1
            - uses: julia-actions/julia-processcoverage@v1
            - uses: codecov/codecov-action@v5
              with:
                file: lcov.info
```

- **Risk**: LOW. These are infrastructure-only changes.
- **Note on Julia matrix**: Testing '1.10' (minimum for DataFrames 1.8) and '1' (latest stable).
  If we want to also support Julia 1.6-1.9 users (with older DataFrames), can add '1.6' to matrix.
  However, DataFrames 1.8.0 requires Julia 1.10+, so practical minimum is 1.10 for latest deps.
- **Decision point**: Drop Julia < 1.10 support, or keep compat range and let resolver handle it?
  Recommendation: Keep `julia = "1.6 - 1.12"` in Project.toml but only CI-test on 1.10+.

**Step 4.2: Update .github/workflows/Documentation.yml**

```yaml
# Changes:
# 1. actions/checkout@v2 -> actions/checkout@v4
# 2. julia-actions/cache@v1 -> julia-actions/cache@v2
# 3. Add setup-julia step (currently missing!)
```

Full target Documentation.yml:

```yaml
name: Documentation
on:
    push:
        branches:
            - main
        tags: '*'
    pull_request:
        branches:
            - main
jobs:
    build:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4
            - uses: julia-actions/setup-julia@latest
              with:
                  version: '1'
            - uses: julia-actions/cache@v2
            - uses: julia-actions/julia-buildpkg@latest
            - uses: julia-actions/julia-docdeploy@latest
              env:
                GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
                DOCUMENTER_KEY: ${{ secrets.DOCUMENTER_KEY }}
```

- **Risk**: LOW.
- **Note**: Added explicit `setup-julia` step which was missing in the original.

### Phase 5: Dead Code Cleanup (Optional, Low Risk)

**Step 5.1: Handle upsample.jl**

`src/upsample.jl` exists (76 lines) but is NOT included in the module (`src/TSFrames.jl`).
The function `upsample` is also NOT in the export list.

Options:
1. **Delete it** -- it is dead code, never loaded
2. **Include and export it** -- if the feature is desired
3. **Leave as-is** -- if future work is planned

- **Recommendation**: Flag for project maintainer decision. Do not delete without confirmation
  as it may be intentionally staged for a future release.

---

## 3. Risk Assessment Summary

| Step | Risk Level | Impact if Fails | Rollback |
|------|-----------|----------------|----------|
| 1.1 Julia compat | LOW | Package won't resolve on new Julia | Revert Project.toml |
| 1.2 DataFrames compat | MEDIUM | Test failures from API changes | Narrow compat back |
| 1.3 RollingFunctions compat | LOW | rollapply tests fail | Keep 0.6.2, 0.7 only |
| 1.4 RecipesBase compat | LOW | Plot recipes break | Narrow compat back |
| 1.6 Manifest regen | LOW | Resolution conflict | Delete Manifest, re-resolve |
| 2.1 Test suite | GATE | Blocks all further changes | Fix failures first |
| 3.1-3.2 Documenter update | MEDIUM-HIGH | Doc build fails | Revert docs/ changes |
| 4.1-4.2 CI updates | LOW | CI workflow fails | Revert workflow files |
| 5.1 Dead code | LOW | N/A | Restore file |

---

## 4. Files to Change

| File | Changes |
|------|---------|
| `Project.toml` | Julia compat, DataFrames compat, RollingFunctions compat, RecipesBase compat |
| `Manifest.toml` | Regenerated (auto) |
| `docs/Project.toml` | Documenter compat 0.27.15 -> 1 |
| `docs/make.jl` | Remove `repo` kwarg, replace `strict=false` with `warnonly=true` |
| `.github/workflows/CI.yml` | checkout@v4, cache@v2, codecov@v5, Julia version matrix |
| `.github/workflows/Documentation.yml` | checkout@v4, cache@v2, add setup-julia step |

---

## 5. Verification Commands

```bash
# After Phase 1: Resolution check
julia -e 'using Pkg; Pkg.activate("."); Pkg.resolve(); Pkg.instantiate(); Pkg.precompile()'

# After Phase 2: Full test suite
julia -e 'using Pkg; Pkg.activate("."); Pkg.test()'

# After Phase 3: Local doc build
julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate(); Pkg.update()'
julia --project=docs docs/make.jl

# After Phase 4: CI validation (push to branch, check GitHub Actions)
# Or validate YAML syntax locally:
# python -c "import yaml; yaml.safe_load(open('.github/workflows/CI.yml'))"
```

---

## 6. Pre-Implementation Checks

All checks completed (2026-04-01):

- [x] `grep -r "runmean\|runcov\|runvar\|runstd\|runsum" src/` -- **CLEAR**: No matches.
  TSFrames does NOT use any RollingFunctions API directly; only re-exports via `using`.
- [x] `grep -r "by(\|aggregate(" src/` -- **CLEAR**: No matches.
  TSFrames does not use removed DataFrames functions.
- [x] `grep -r "allowmissing\|disallowmissing" src/` -- **CLEAR**: No matches.
- [x] Confirm no docs/Manifest.toml exists -- **CONFIRMED**: clean state.
- [x] `rollapply.jl` reviewed: Uses only DataFrames `mapcols`, `rename!`, `vcat` + manual
  windowing. Safe for DataFrames 1.3-1.8 range.

---

## 7. Decision Points for Maintainer

1. **Julia minimum version**: Keep 1.6 in compat (broad) or raise to 1.10 (practical minimum)?
   - Recommendation: Keep `"1.6 - 1.12"` but CI-test only 1.10+
2. **RollingFunctions 0.8**: Safe to include (verified: TSFrames uses no RF API directly).
   - Recommendation: Add 0.8 to compat.
3. **upsample.jl**: Delete, include, or leave as dead code?
   - Recommendation: Ask maintainer. Not blocking for this update.
4. **Documenter warnonly**: Keep `warnonly=true` or fix all warnings and use strict default?
   - Recommendation: Start with `warnonly=true`, fix warnings in a follow-up PR.
