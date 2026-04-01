# TSFrames.jl Test Improvement Codebase Analysis

## 1. Directory Structure and Organization

```
TSFrames.jl/
  src/                      # 21 Julia source files
    TSFrames.jl             # Main module (exports, imports, includes)
    TSFrame.jl              # Core struct + constructors (~440 lines)
    utils.jl                # Utility functions (describe, show, size, index, names, etc.)
    apply.jl                # Period-based aggregation
    broadcasting.jl         # Broadcasting support for TSFrame
    diff.jl                 # Differencing
    endpoints.jl            # Period endpoint computation
    getindex.jl             # Comprehensive indexing (~499 lines)
    getproperty.jl          # Property access delegation
    join.jl                 # Column-wise joins (inner/outer/left/right)
    lag.jl                  # Lag operation
    lead.jl                 # Lead operation
    matrix.jl               # TSFrame to Matrix conversion
    pctchange.jl            # Percentage change
    plot.jl                 # RecipesBase plotting
    rollapply.jl            # Rolling window functions
    subset.jl               # Index-based subsetting
    tables.jl               # Tables.jl interface implementation
    to_period.jl            # Frequency conversion convenience methods
    upsample.jl             # Upsampling (NOT included in main module!)
    vcat.jl                 # Row concatenation
  test/                     # 21 test files
    runtests.jl             # Test runner (19 testsets)
    dataobjects.jl          # Shared test data/fixtures
    ... (individual test files)
  .github/workflows/
    ci.yml                  # CI: Julia 1.12 + latest, 3 OS, x64
    documentation.yml       # Docs deployment
    CompatHelper.yml        # Compatibility helper
    TagBot.yml              # Release tagging
  Project.toml              # Package metadata
```

## 2. Key Modules and Responsibilities

### Core Type (TSFrame.jl)
- `struct TSFrame` with single field `coredata::DataFrame`
- 10+ constructor methods (DataFrame, Vector, Array, UnitRange, empty, Tables.jl)
- Supports `issorted` and `copycols` kwargs for performance
- Index column must be `Int` or `TimeType`

### Utility Functions (utils.jl) -- LARGEST file
- `describe()` -- summary statistics
- `show()`, `print()`, `summary()` -- display
- `nrow()/nr()`, `ncol()/nc()`, `size()` -- dimensions
- `index()` -- return index vector
- `names()` -- column names (excluding index)
- `first()`, `head()`, `tail()` -- row selection
- `rename!()` -- column renaming (6+ method signatures)
- `_check_consistency()` -- verify index is sorted
- `isregular()` -- check regularity of time series
- `iterate()` -- row-based iteration
- `ndims()` -- always returns 2
- `==`, `isequal` -- equality comparison

### Data Operations
| File | Function | Description |
|------|----------|-------------|
| apply.jl | `apply()` | Period-based aggregation with function |
| diff.jl | `diff()` | Discrete differencing |
| endpoints.jl | `endpoints()` | Compute period endpoints (many overloads) |
| getindex.jl | `getindex()` | ~40 method signatures for indexing |
| getproperty.jl | `getproperty()` | Delegates to coredata |
| join.jl | `join()` | Inner/outer/left/right joins, `cbind` alias |
| lag.jl | `lag()` | Shift data backward |
| lead.jl | `lead()` | Shift data forward |
| matrix.jl | `Matrix()` | Convert to Matrix |
| pctchange.jl | `pctchange()` | Percentage change |
| plot.jl | `@recipe` | Plots.jl integration |
| rollapply.jl | `rollapply()` | Rolling window function |
| subset.jl | `subset()` | Range-based subsetting |
| tables.jl | Tables.jl interface | istable, rows, columns, schema, etc. |
| to_period.jl | `to_period()` + 11 convenience methods | Frequency conversion |
| upsample.jl | `upsample()` | **NOT included in module!** |
| vcat.jl | `vcat()` | Row concatenation, `rbind` alias |
| broadcasting.jl | `broadcasted()` | Element-wise operations |

## 3. Existing Test Structure

### Test Runner (runtests.jl)
- Uses `Test.jl` standard library
- 19 `@testset` blocks, each including a separate file
- Shared data fixtures in `dataobjects.jl`

### Test File Inventory

| Test File | Covers | Lines | Quality |
|-----------|--------|-------|---------|
| TSFrame.jl | Constructors, issorted, colnames | ~175 | Good - covers multiple constructors |
| getindex.jl | ~40 getindex methods | ~453 | Excellent - very thorough |
| apply.jl | apply() with various periods | ~587 | Excellent - extensive coverage |
| index.jl | index() function | ~3 | **Minimal** - single assertion |
| utils.jl | describe, size, names, head, tail, first, isregular, rename! | ~317 | Good for covered functions |
| endpoints.jl | endpoints() all variants | ~349 | Excellent - thorough |
| broadcasting.jl | sin., log., scalar broadcast | ~23 | Adequate - basic coverage |
| getproperty.jl | Property access | ~2 | **Minimal** - single assertion |
| diff.jl | diff() | ~21 | Adequate - covers key cases |
| lag.jl | lag() | ~27 | Good - including negative lag |
| lead.jl | lead() | ~26 | Good - including negative lead |
| pctchange.jl | pctchange() | ~31 | Adequate |
| subset.jl | subset() with Int and Date | ~79 | Good - both index types, edge cases |
| matrix.jl | Matrix() conversion | ~5 | **Minimal** |
| vcat.jl | vcat() with 4 merge strategies | ~60 | Good |
| join.jl | join() all types, multi-join | ~152 | Excellent - comprehensive |
| tables.jl | Tables.jl interface | ~49 | Good - covers all interface methods |
| rollapply.jl | rollapply() by-column and whole | ~34 | Adequate |
| to_period.jl | to_period(), to_yearly(), etc. | ~44 | Good |

### Shared Test Data (dataobjects.jl)
- `DATA_SIZE = 400`, `COLUMN_NO = 100`
- Pre-built vectors, arrays, DataFrames
- Both integer and Date/TimeType indexes
- Used by most test files via include

## 4. Julia Testing Patterns Used

### Patterns
1. **@testset blocks** in runtests.jl with per-file granularity
2. **@test** for value assertions
3. **@test_throws** for error cases (ArgumentError, DomainError, MethodError)
4. **isequal()** for missing-aware comparisons
5. **Shared fixtures** via dataobjects.jl (global test data)
6. **Helper functions** in some test files (e.g., `test_types()`, `test_isregular()`)
7. **Loop-based parametric testing** (e.g., lag/lead/diff iterate over multiple period values)

### Missing Patterns
- No `@testset` nesting within individual test files (flat structure)
- No `@test_broken` for known issues
- No `@test_logs` for warning/logging tests
- No benchmarking or performance regression tests
- No property-based/fuzz testing

## 5. Test Coverage Gaps

### CRITICAL: Source Files With NO Tests
1. **`upsample.jl`** -- Not even included in the main module (`src/TSFrames.jl` does not include it), so it is dead code. No test file exists.
2. **`plot.jl`** -- No test file. 3 @recipe methods completely untested.

### Functions/Features With NO or Minimal Tests
1. **`show()`/`print()`/`summary()`** -- No tests for display output
2. **`Base.convert`** -- Imported but no custom method defined; no tests
3. **`Base.filter`** -- Imported but no custom method defined; used internally by getindex. No direct tests.
4. **`iterate()`** -- Defined in utils.jl but never tested
5. **`ndims()`** -- Defined in utils.jl but never tested
6. **`==` and `isequal` for TSFrame** -- Defined but only used indirectly in tests; no dedicated tests
7. **`cbind` alias** -- Never tested (only `join` is tested)
8. **`rbind` alias** -- Never tested (only `vcat` is tested)
9. **`describe()` with IO argument** -- Only stdout variant tested
10. **`nrow()`/`ncol()`/`nr()`/`nc()`** -- Tested only indirectly via other tests
11. **`length()`** -- Only tested once indirectly in utils.jl
12. **`lastindex()`** -- Only tested once indirectly in utils.jl

### Weak Test Coverage Areas
1. **index.jl** -- Only 3 lines, 1 assertion. Needs tests for different index types.
2. **getproperty.jl** -- Only 2 lines, 1 assertion. Needs edge cases.
3. **matrix.jl** -- Only 5 lines, 2 assertions. Needs multi-type, empty TSFrame tests.
4. **broadcasting.jl** -- Only basic function tests. Missing: arithmetic operators, multi-arg, edge cases.
5. **Constructor edge cases** -- No tests for Tables.jl compatible input types.
6. **Error handling** -- Many functions lack negative/error case tests:
   - `diff()` with periods=0 or negative (only positive tested; error msg has typo "postive")
   - `rollapply()` with single-row TSFrame
   - `subset()` with swapped from/to
   - `apply()` with invalid period or empty TSFrame

### Missing Edge Case Categories
1. **Empty TSFrame operations** -- Most functions untested with 0-row TSFrame
2. **Single-row TSFrame** -- Edge behavior untested for most operations
3. **Multi-column operations** -- Most tests use single-column TSFrame (diff, lag, lead, pctchange)
4. **Mixed types** -- Minimal testing with non-Float64 columns
5. **DateTime/Time index** -- Most tests focus on Date, fewer DateTime/Time tests
6. **Integer index** -- Many functions only tested with TimeType index
7. **Missing values** -- Behavior with missing data in columns largely untested
8. **Large dataset edge cases** -- No stress testing beyond DATA_SIZE=400

## 6. Dependencies and Tech Stack

### Project.toml
```
name = "TSFrames"
version = "0.2.2"
julia = "1.12"

[deps]
DataFrames = "a93c6f00..."       # Core data structure
Dates                            # stdlib - time types
Random                           # stdlib - used in tests
RecipesBase = "3cdcf5f2..."      # Plots.jl recipe support
RollingFunctions = "b0e4dd01..." # Rolling window calculations
ShiftedArrays = "1277b4bf..."    # Lag/lead operations
Statistics                       # stdlib - statistical functions
StatsBase = "2913bbd2..."        # Extended statistics
Tables = "bd369af6..."           # Tables.jl interface
Artifacts                        # stdlib

[extras]
Test                             # stdlib - testing

[compat]
DataFrames = "1.8"
RecipesBase = "1.3"
RollingFunctions = "0.8"
ShiftedArrays = "2"
StatsBase = "0.34"
Tables = "1"
```

### Test Dependencies (in runtests.jl)
```julia
using Dates, DataFrames, Random, StatsBase, Statistics, Test, Tables, TSFrames
```

## 7. CI Configuration

### ci.yml
- Triggers: push/PR to all branches
- Matrix: Julia 1.12 + latest, ubuntu/windows/macos, x64
- Steps: checkout, setup-julia, cache, buildpkg, runtest
- Code coverage via codecov (separate job, ubuntu only, latest Julia)
- Uses standard `julia-actions/*` GitHub Actions

### Other Workflows
- `documentation.yml` -- Documenter.jl deployment
- `CompatHelper.yml` -- Dependency compatibility
- `TagBot.yml` -- Release management

## 8. Notable Code Issues Found

1. **Dead code**: `upsample.jl` exists in `src/` but is NOT included in `src/TSFrames.jl` module file. It is also not exported. This function is completely inaccessible.

2. **Typo in diff.jl**: Error message says "postive" instead of "positive" (line 79).

3. **`Base.filter` imported but never extended**: `import Base.filter` in TSFrames.jl but no `function filter(...)` for TSFrame. It is used as `filter(:Index => ...)` which calls DataFrames.filter on DataFrame, not a custom method.

4. **`Base.convert` imported but never extended**: Same pattern - imported but no custom method.

5. **`copycols` docstring error**: The docstring says "When `copycols` is `true`, the inputs are not copied" -- this describes `false` behavior, not `true`.

## 9. Recommendations for Test Improvement

### Priority 1: Add Missing Test Files
1. Create `test/upsample.jl` (after deciding whether to include module in TSFrames.jl)
2. Create tests for `show()`/`print()`/`summary()` output
3. Create tests for `iterate()`, `ndims()`, `==`/`isequal`

### Priority 2: Expand Minimal Tests
1. Expand `test/index.jl` (currently 3 lines)
2. Expand `test/getproperty.jl` (currently 2 lines)
3. Expand `test/matrix.jl` (currently 5 lines)
4. Expand `test/broadcasting.jl` (currently 23 lines)

### Priority 3: Add Edge Cases
1. Empty TSFrame behavior for all operations
2. Single-row TSFrame
3. Multi-column TSFrame for diff/lag/lead/pctchange
4. Missing values in data columns
5. Integer index for all operations (currently biased toward Date)

### Priority 4: Error Case Tests
1. Invalid inputs for all public functions
2. Boundary conditions
3. Type mismatch scenarios

### Priority 5: Code Quality
1. Fix dead code (upsample.jl)
2. Fix typo in diff.jl error message
3. Fix docstring error in TSFrame.jl
4. Remove unused imports (filter, convert)
