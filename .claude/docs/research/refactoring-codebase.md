# TSFrames.jl Codebase Refactoring Analysis

Date: 2026-04-01

## 1. Directory Structure and Organization

```
TSFrames.jl/
  Project.toml          # Package manifest (v0.2.2)
  Manifest.toml         # Lock file
  src/
    TSFrames.jl         # Module definition, imports, exports (102 lines)
    TSFrame.jl          # Core struct + constructors (445 lines)
    getindex.jl         # Indexing overloads (498 lines)
    utils.jl            # Utility functions: show, size, index, names, head/tail, rename!, isregular, iterate, equality (689 lines)
    apply.jl            # apply() function (163 lines)
    diff.jl             # diff() function (84 lines)
    endpoints.jl        # endpoints() function (388 lines)
    getproperty.jl      # Property access delegation (4 lines)
    join.jl             # Join operations + cbind alias (305 lines)
    lag.jl              # lag() function (78 lines)
    lead.jl             # lead() function (86 lines)
    matrix.jl           # Matrix conversion (47 lines)
    pctchange.jl        # Percentage change (88 lines)
    plot.jl             # Plotting recipes (75 lines)
    rollapply.jl        # Rolling window functions (94 lines)
    subset.jl           # Subsetting operations (152 lines)
    to_period.jl        # Period conversion convenience methods (71 lines)
    upsample.jl         # Upsampling (75 lines)
    vcat.jl             # Vertical concatenation + rbind alias (158 lines)
    broadcasting.jl     # Broadcasting support (22 lines)
    tables.jl           # Tables.jl interface (17 lines)
  test/
    runtests.jl         # Test runner (86 lines)
    dataobjects.jl      # Shared test fixtures (23 lines)
    TSFrame.jl          # Constructor tests (305 lines)
    getindex.jl         # Indexing tests (452 lines)
    ... (one test file per module, mostly)
  docs/
    make.jl             # Documenter.jl setup
    src/                # Documentation source
```

### Source Statistics
- Total source lines: ~3,450 (across 20 files in src/)
- Total test lines: ~3,323 (across 21 files in test/)
- Largest files: utils.jl (689), getindex.jl (498), TSFrame.jl (445)

## 2. Key Modules and Responsibilities

### Core Type (TSFrame.jl)
- Single struct `TSFrame` wrapping a `DataFrame` with an `:Index` column
- Two inner constructors: DataFrame+column-selector, DataFrame+external-vector
- 8 outer constructors covering DataFrames, Vectors, Arrays, Tables.jl, empty frames
- `issorted` and `copycols` options for performance

### Indexing (getindex.jl)
- **46 method overloads** for `Base.getindex`
- Supports: Int, UnitRange, AbstractVector{Int}, TimeType, AbstractVector{TimeType}, Year/Month/Day/Hour/Minute/Second/Millisecond combinations, String timestamps, Colon
- Column selectors: Int, Symbol, String, vectors of these, UnitRange

### Utilities (utils.jl)
- Size functions: nrow, ncol, size, length, lastindex
- Display: show, summary, describe
- Data access: index, names, first, head, tail
- Mutation: rename! (6 overloads)
- Validation: _check_consistency, isregular
- Iteration: iterate, ndims
- Equality: ==, isequal

### Time Series Operations
- **lag.jl / lead.jl**: Shift operations via ShiftedArrays
- **diff.jl**: Discrete differencing (depends on lag)
- **pctchange.jl**: Percentage change (depends on lag)
- **rollapply.jl**: Rolling window application
- **apply.jl**: Period-based aggregation
- **endpoints.jl**: Period boundary detection
- **to_period.jl**: Convenience wrappers for downsampling
- **upsample.jl**: Upsampling via outer join
- **subset.jl**: Range-based filtering

### Integration
- **join.jl**: Column-binding (4 join types via DataFrames)
- **vcat.jl**: Row-binding
- **broadcasting.jl**: Broadcast support
- **tables.jl**: Tables.jl interface
- **plot.jl**: RecipesBase plotting
- **matrix.jl**: Matrix conversion

## 3. Existing Patterns and Conventions

### Good Patterns
- Consistent docstring style with examples (jldoctest format)
- Clear separation of concerns (one file per feature)
- Wrapper pattern: delegates to DataFrames where possible
- Test file per source file (with a few exceptions)
- `issorted`/`copycols` constructor options for performance

### Conventions
- Index stored in `:Index` column of `coredata` DataFrame
- Column indexing offsets by +1 to account for hidden Index column
- Functions return new TSFrame objects (immutable pattern)
- Heavy use of Julia's multiple dispatch for method overloading
- Aliases defined via assignment: `nr = TSFrames.nrow`, `cbind = join`, `rbind = vcat`

## 4. Dependencies and Tech Stack

### Direct Dependencies (Project.toml)
| Package | Version | Purpose |
|---------|---------|---------|
| DataFrames | 1.8 | Core data structure |
| Dates | stdlib | Time types |
| Random | stdlib | Random number generation |
| RecipesBase | 1.3 | Plotting recipes |
| RollingFunctions | 0.8 | Rolling window operations |
| ShiftedArrays | 2 | Lag/lead operations |
| Statistics | stdlib | Statistical functions |
| StatsBase | 0.34 | Statistical utilities |
| Tables | 1 | Tables.jl interface |
| Artifacts | stdlib | Artifact management |

### Observations
- `Random` is imported but only used in docstring examples, not in core logic
- `Statistics` is imported in TSFrames.jl but NOT actually used in any src/ file
- `StatsBase` is listed as a dependency but NOT imported in TSFrames.jl module (only used in tests)
- `RollingFunctions` is imported but NOT used anywhere in src/
- `Artifacts` is listed as a dependency but not used
- Julia compat: 1.12+

## 5. Test Structure

### Coverage Analysis
- **Files WITH tests**: TSFrame, getindex, apply, endpoints, broadcasting, getproperty, diff, lag, lead, pctchange, subset, matrix, vcat, join, tables, rollapply, to_period, utils, index
- **Files WITHOUT tests**: `plot.jl`, `upsample.jl`
- **Not included in test runner**: upsample (no test file exists), plot (no test file exists)
- Test fixtures in `dataobjects.jl`: shared constants and DataFrames

### Test Quality
- Tests use `@testset` blocks
- Constructor tests in TSFrame.jl include edge cases: empty, single-row, missing values, duplicates, unsorted
- Good regression test for data misalignment bug (recently added)
- No performance/benchmark tests in test suite

## 6. Code Quality Issues

### 6.1 Duplicated Code Patterns

**A. Linear search via `findfirst` in getindex.jl (CRITICAL)**
- Lines 264, 269, 284, 289, 310, 318, 336, 344, 462
- The pattern `findfirst(x -> x == dt, index(ts))` and `map(d -> findfirst(x -> x == d, index(ts)), dt)` appears **9 times**
- Since the index is always sorted, these could use `searchsortedfirst`/`searchsortedlast` for O(log n) instead of O(n)

**B. Duplicated lag computation in pctchange.jl (line 85)**
```julia
ddf = (ts.coredata[:, Not(:Index)] .- TSFrames.lag(ts, periods).coredata[:, Not(:Index)]) ./ abs.(TSFrames.lag(ts, periods).coredata[:, Not(:Index)])
```
- `TSFrames.lag(ts, periods)` is computed **twice** in a single expression
- Should be computed once and cached

**C. Repeated period-indexing pattern in getindex.jl (lines 411-457)**
- 8 nearly identical methods for Year, Year+Quarter, Year+Month, ..., Year+Month+Day+Hour+Minute+Second+Millisecond
- Each constructs a tuple of period extractors and compares -- could be a single generic method

**D. Repeated `insertcols!` + TSFrame pattern in lag.jl, lead.jl, diff.jl, pctchange.jl**
- All four files follow the exact same pattern:
  1. Extract columns excluding Index
  2. Apply transformation
  3. `insertcols!(result, 1, :Index => ts.coredata[!, :Index])`
  4. `TSFrame(result, :Index)`

**E. to_period.jl boilerplate (lines 29-71)**
- 11 nearly identical functions (`to_yearly`, `to_quarterly`, ... `to_nanoseconds`)
- Each is `tsf[endpoints(tsf, PeriodType(n))]` with different PeriodType
- Could use a macro or Dict-based dispatch

**F. endpoints Symbol dispatch (endpoints.jl lines 358-383)**
- 11-branch if-elseif chain mapping Symbols to Period types
- Should be a Dict lookup

### 6.2 Inconsistent Patterns

**A. Module prefix inconsistency**
- `TSFrames.nrow(ts)` vs `DataFrames.size(ts.coredata)[1]` (utils.jl:105)
- `DataFrames.size(...)` should just use `nrow(ts.coredata)`

**B. Docstring formatting inconsistency**
- Some docstrings use `"""` with markdown headers, others use plain text
- `first()` docstring example output is wrong (shows 10x1 instead of 1x1)

**C. `copycols` parameter semantics inverted in docstring**
- TSFrame.jl line 61-63: "When `copycols` is `true`, the inputs are not copied" -- this is the OPPOSITE of the actual behavior. The docstring is wrong.

**D. Unused imports in TSFrames.jl**
- `import Base.convert` -- no convert methods defined
- `import Base.filter` -- filter is used via DataFrames.filter, not Base.filter
- `import Base.print` -- no print methods defined (only show)

**E. Duplicate exports**
- `first` exported twice (lines 38 and 49)
- `head` exported twice (lines 40 and 50)
- `tail` exported twice (lines 51 and 64)

### 6.3 Potential Bugs

**A. TSFrame constructor early-return issue (TSFrame.jl lines 346-348)**
```julia
if (DataFrames.ncol(coredata) == 1)
    TSFrame(coredata, collect(Base.OneTo(DataFrames.nrow(coredata))); ...)
end
```
- This does NOT actually return. The result of the recursive call is discarded, and execution continues. Should have `return` keyword.

**B. `eval()` usage in endpoints.jl (line 287)**
```julia
ex = Expr(:call, on, values)
keys = eval(ex)
```
- Using `eval()` at runtime is a serious performance and correctness concern
- `eval()` runs in module scope, not local scope
- Should simply be `keys = on(values)`

**C. `isregular` uses `ts.Index` instead of `index(ts)` (utils.jl lines 660, 664)**
- This accesses via `getproperty` which happens to work because getproperty delegates to coredata
- Should use `index(ts)` for consistency and clarity

## 7. Algorithm Improvement Opportunities

### 7.1 O(n) to O(log n): Index Lookup (HIGH IMPACT)

**Files**: src/getindex.jl (lines 264, 269, 284, 289, 310, 318, 336, 344, 462)

The TSFrame index is always sorted (enforced by constructor). All TimeType lookups use `findfirst(x -> x == dt, index(ts))` which is O(n) linear scan.

**Recommendation**: Use `searchsortedfirst(index(ts), dt)` for O(log n) binary search. For vector lookups (`map(d -> findfirst(...), dt)`), use a single sorted merge or `searchsortedfirst` per element.

**Estimated improvement**: For a 1M-row TSFrame, lookup goes from ~500us to ~20 comparisons.

### 7.2 Double Computation in pctchange (MEDIUM IMPACT)

**File**: src/pctchange.jl (line 85)

`TSFrames.lag(ts, periods)` is called twice: once for the numerator difference and once for the denominator. Each call creates a new DataFrame with shifted arrays.

**Recommendation**: Cache the lag result: `lagged = TSFrames.lag(ts, periods).coredata[:, Not(:Index)]`

### 7.3 rollapply O(n*w) Allocation (MEDIUM IMPACT)

**File**: src/rollapply.jl (lines 66-94)

The rolling apply function uses a loop with `vcat` in each iteration, creating O(n) intermediate DataFrames. Each iteration:
1. Creates a TSFrame slice (allocation)
2. Applies function
3. vcats to result (growing allocation)

**Recommendation**: Pre-allocate result matrix/vectors and fill in-place. Or use `RollingFunctions.jl` which is already a dependency but unused.

### 7.4 endpoints eval() Call (LOW IMPACT but correctness issue)

**File**: src/endpoints.jl (lines 286-287)

```julia
ex = Expr(:call, on, values)
keys = eval(ex)
```

`eval()` compiles code at runtime in module scope. This is slow (invokes the compiler) and semantically incorrect (captures module globals instead of local variables).

**Fix**: Replace with `keys = on(values)` -- a direct function call.

### 7.5 Unnecessary Copy in subset (LOW IMPACT)

**File**: src/subset.jl (lines 141-152)

Uses `DataFrames.subset` which creates a copy. For sorted indices, a range-based approach using `searchsortedfirst`/`searchsortedlast` would avoid the full-DataFrame filter.

### 7.6 Unused Dependencies Increase Load Time

**Dependencies imported but unused in source**:
- `RollingFunctions` -- imported in module but never called
- `Statistics` -- imported but not used in src/
- `StatsBase` -- listed in deps but not imported
- `Random` -- listed in deps but not used in runtime code
- `Artifacts` -- listed in deps but not used

Removing unused dependencies reduces precompilation and load time.

## 8. Refactoring Candidates

### Priority 1: Critical Issues

| # | Issue | File | Lines | Effort |
|---|-------|------|-------|--------|
| 1 | Missing `return` in constructor | src/TSFrame.jl | 346-348 | Small |
| 2 | `eval()` in endpoints | src/endpoints.jl | 286-287 | Small |
| 3 | Unused Base imports (convert, filter, print) | src/TSFrames.jl | 5,7,15 | Small |
| 4 | Duplicate exports (first, head, tail) | src/TSFrames.jl | 38-64 | Small |
| 5 | Wrong `copycols` docstring | src/TSFrame.jl | 61-63 | Small |

### Priority 2: Performance

| # | Issue | File | Lines | Effort |
|---|-------|------|-------|--------|
| 6 | Linear search -> binary search for index | src/getindex.jl | 264-462 | Medium |
| 7 | Double lag computation in pctchange | src/pctchange.jl | 85 | Small |
| 8 | rollapply vcat-in-loop | src/rollapply.jl | 76-83 | Medium |
| 9 | Remove unused dependencies | Project.toml | - | Small |

### Priority 3: Code Deduplication

| # | Issue | File | Lines | Effort |
|---|-------|------|-------|--------|
| 10 | Period-based getindex repetition (8 methods) | src/getindex.jl | 411-457 | Medium |
| 11 | to_period boilerplate (11 functions) | src/to_period.jl | 29-71 | Medium |
| 12 | endpoints Symbol dispatch if-elseif | src/endpoints.jl | 358-383 | Small |
| 13 | lag/lead/diff/pctchange shared pattern | src/lag.jl, lead.jl, diff.jl, pctchange.jl | all | Medium |

### Priority 4: Missing Tests & Code Quality

| # | Issue | File | Lines | Effort |
|---|-------|------|-------|--------|
| 14 | No tests for upsample.jl | test/ | - | Medium |
| 15 | No tests for plot.jl | test/ | - | Medium |
| 16 | utils.jl is too large (689 lines) | src/utils.jl | all | Medium |
| 17 | Wrong docstring example for first() | src/utils.jl | 259-266 | Small |

### Priority 5: Architecture

| # | Issue | File | Lines | Effort |
|---|-------|------|-------|--------|
| 18 | TSFrame is not parametric on index type | src/TSFrame.jl | 336 | Large |
| 19 | No type stability for getindex with TimeType | src/getindex.jl | - | Large |
| 20 | Consider dedicated Index type instead of DataFrame column | src/TSFrame.jl | - | Large |

## 9. Summary of Top Findings

### Architecture
- TSFrame is a simple wrapper around DataFrame with an Index column convention
- The design is clean but has scaling concerns (linear index lookups, no parametric typing)
- 20 source files, well-separated by concern, total ~3,450 LOC

### Top 5 Refactoring Candidates
1. **Missing `return` in constructor** (src/TSFrame.jl:346-348) -- potential silent bug
2. **`eval()` at runtime** (src/endpoints.jl:286-287) -- performance and correctness
3. **Linear O(n) index lookups** (src/getindex.jl:264-462, 9 occurrences) -- should be O(log n)
4. **Double lag computation** (src/pctchange.jl:85) -- wasteful double allocation
5. **Period-based getindex duplication** (src/getindex.jl:411-457) -- 8 near-identical methods

### Top 3 Algorithm Improvements
1. **Binary search for sorted index** (getindex.jl) -- O(n) -> O(log n), affects all TimeType lookups
2. **rollapply pre-allocation** (rollapply.jl) -- avoid O(n) intermediate DataFrame vcats
3. **Remove `eval()` in endpoints** (endpoints.jl:287) -- replace with direct function call

### Convention Violations
- Unused imports: `Base.convert`, `Base.filter`, `Base.print`
- Duplicate exports: `first`, `head`, `tail` each appear twice in export list
- Unused dependencies: `RollingFunctions`, `Statistics`, `Random`, `StatsBase`, `Artifacts` either not imported or not used in source
- Inconsistent property access: `ts.Index` vs `index(ts)` in isregular
- `copycols` docstring describes behavior inversely
