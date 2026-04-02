# Test Review: Step 3

## Summary

All 23 test suites pass with 1,907 total tests and 0 failures. The Step 3 changes (apply() optimization, shared helpers, empty TSFrame guard, upsample export) are well-tested. The new test files are high quality and cover happy paths, edge cases, and boundary values.

## Test Execution Results

| Test Suite | Pass | Total |
|---|---|---|
| TSFrame() | 131 | 131 |
| getindex() | 167 | 167 |
| apply() | 343 | 343 |
| index() | 12 | 12 |
| utils | 145 | 145 |
| endpoints() | 152 | 152 |
| broadcasting | 320 | 320 |
| getproperty | 14 | 14 |
| diff | 54 | 54 |
| lag | 33 | 33 |
| lead | 36 | 36 |
| pctchange | 25 | 25 |
| subset | 38 | 38 |
| matrix | 46 | 46 |
| vcat | 36 | 36 |
| join | 131 | 131 |
| Tables.jl | 34 | 34 |
| rollapply() | 54 | 54 |
| to_period() | 24 | 24 |
| resample() | 48 | 48 |
| upsample() | 29 | 29 |
| DateTime/Time index | 40 | 40 |
| Irregular time series | 44 | 44 |
| **TOTAL** | **1,907** | **1,907** |

- Failed: 0

## to_period vs resample Equivalence

### Test Script Results

```
to_weekly rows: 14        | resample rows: 14
Index match: false        | Values match: true

to_monthly rows: 3        | resample monthly rows: 3
Monthly Index match: false | Monthly Values match: true

to_yearly rows: 5         | resample yearly rows: 5
Yearly Index match: false  | Yearly Values match: true
```

### Analysis

- **Row counts match** for weekly, monthly, and yearly periods.
- **Values match** perfectly in all cases when using `resample(ts, period, :col => last; renamecols=false)` vs `to_weekly/to_monthly/to_yearly`.
- **Indexes differ by design**: `to_weekly` uses the actual last date in each group (the endpoint date, e.g., 2020-01-05 for the first week), while `resample` uses the floor-based bucket start date (e.g., 2020-01-01). This is the expected and correct behavior:
  - `to_period` uses `apply()` with `index_at=last` (last timestamp in group)
  - `resample` uses `floor(first_date, period)` as bucket anchors
- **Verdict**: Semantically equivalent for data values. Index difference is by design and well-documented.

## Test Quality Assessment

### New testsets in test/apply.jl (lines 586-621)

Three new `@testset` blocks added at the end of the file:

1. **"apply multi-column correctness"** (lines 586-599)
   - Tests multi-column TSFrame with `mean` aggregation over monthly periods
   - Verifies per-column correctness against manually computed values
   - Uses seeded RNG (`MersenneTwister(42)`) for reproducibility
   - Good: Checks both columns A and B for months 1 and 2

2. **"apply renamecols=false"** (lines 601-614)
   - Tests the `renamecols` keyword argument for `apply()`
   - Verifies `renamecols=true` produces "val_sum" while `renamecols=false` keeps "val"
   - Verifies both produce the same values
   - Good: Clean test of the keyword parameter behavior

3. **"apply empty TSFrame"** (lines 616-621)
   - Tests `apply()` on an empty TSFrame (0 rows)
   - Verifies result has 0 rows and correct column names
   - Good: Critical edge case for the empty guard added in Step 3

**Assessment**: Good coverage of the Step 3 additions. All three test categories (multi-column, renamecols, empty) are relevant to the changes made.

### test/datetime_index.jl (168 lines, 40 tests)

Covers 9 distinct test areas:
1. DateTime index construction
2. Time index construction
3. endpoints() with hourly DateTime grouping
4. endpoints() with minute-level grouping
5. apply() with DateTime index
6. resample() with DateTime index (OHLCV-like data)
7. lag/lead with DateTime index
8. subset() with DateTime range (both bounded and open-ended)
9. rollapply with DateTime index
10. isregular() with regular and irregular DateTime series

**Strengths**:
- Comprehensive coverage of operations with DateTime indexes
- Tests Time type (not just DateTime)
- Sub-day granularity tested (hourly, minutely, secondly)
- Open-ended subset tested (`:` for start/end)
- Good: isregular() tested for both true and false cases with different frequencies

**Minor gaps**:
- No error case tests (e.g., mixed Date/DateTime operations)
- No test for empty DateTime TSFrame

### test/irregular_timeseries.jl (180 lines, 44 tests)

Covers 9 distinct test areas:
1. Construction with weekday-only data
2. isregular() returns false
3. endpoints() weekly and monthly on irregular data
4. apply() weekly and monthly on irregular data
5. resample() with OHLCV pairs on irregular data
6. lag/lead on irregular data
7. subset() on irregular data
8. rollapply on irregular data
9. Mixed gap sizes (arbitrary irregular timestamps)

**Strengths**:
- Realistic weekday-only date generation helper
- Tests that gaps don't affect position-based operations (lag/lead)
- Verifies weekend dates don't appear in subset results
- Tests OHLCV aggregation correctness for irregular data
- Mixed gap sizes test with arbitrary timestamps
- Good: endpoint Friday verification for weekday data

**Minor gaps**:
- No test for very short irregular series (1-2 rows)
- No test for duplicate timestamps

### test/upsample.jl (116 lines, 29 tests)

Covers 6 distinct test areas:
1. Daily to 12-hourly upsampling
2. Hourly to 30-minute upsampling
3. Single-row input
4. Multi-column input
5. Same-frequency (no-op) upsampling
6. Output length verification

**Strengths**:
- Tests both original values preservation and missing interpolation
- Single-row edge case covered
- Multi-column correctly tested (both columns checked for missing)
- Same-frequency identity test (no new rows added)
- Output length mathematically verified

**Minor gaps**:
- No error case tests (e.g., upsampling Date index to sub-day period?)
- No test for Date index (only DateTime tested)
- No empty TSFrame test

### Expanded tests in test/lag.jl (new: lines 29-108)

7 new `@testset` blocks:
1. Multi-column lag
2. DateTime index lag
3. Single-row edge case
4. Default argument test
5. Lag/lead symmetry roundtrip
6. Out-of-bounds lag (all missing)
7. Negative lag equals lead

**Assessment**: Excellent coverage. The symmetry and negative-lag tests are particularly valuable.

### Expanded tests in test/lead.jl (new: lines 28-98)

6 new `@testset` blocks:
1. Multi-column lead
2. DateTime index lead
3. Single-row edge case
4. Out-of-bounds lead
5. Default argument test
6. Negative lead equals lag

**Assessment**: Good mirror of lag tests. Covers the same patterns.

### Expanded tests in test/rollapply.jl (new: lines 36-104)

5 new `@testset` blocks:
1. DateTime index rollapply
2. Custom function (range)
3. Window equals nrow (single output)
4. Window size 1 (identity)
5. Multi-column with custom function

**Assessment**: Good coverage of edge cases and custom functions. Window boundary tests are valuable.

## Coverage Gaps

### Minor gaps (low priority)
1. **Empty TSFrame**: Not tested for upsample(), datetime_index, or irregular_timeseries operations
2. **Error cases**: No tests for invalid inputs (e.g., negative window size for upsample, mixed index types)
3. **Duplicate timestamps**: Irregular timeseries doesn't test duplicate index values
4. **Date index with upsample**: Only DateTime tested; behavior with Date index not verified
5. **Very large datasets**: No stress test for the optimized apply() path (though benchmark exists separately)

### Not gaps (correctly excluded)
- Performance/benchmark tests: Handled separately in benchmark/
- Internal helper functions (_build_index_out, _alloc_and_fill_col): Tested indirectly through apply() and resample()

## Verdict

**Approve** - All 1,907 tests pass. The new test files are well-structured, follow the project's existing style, and cover happy paths, edge cases, and boundary values adequately. The to_period vs resample equivalence holds for values (index difference is by design). The minor coverage gaps identified are low priority and do not block approval.
