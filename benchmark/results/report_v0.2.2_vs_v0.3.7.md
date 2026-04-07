# TSFrames.jl Benchmark Report

Generated: 2026-04-07 11:26:15

## Dataset Sizes

| Label | Rows | Notes |
|-------|------|-------|
| small | 1,000 | |
| medium | 25,000 | |
| large | 1,000,000 | rollapply uses 100,000 for large |

## apply

Period-based aggregation (last/first/mean/sum) over time series

| Benchmark | v0.2.2 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| monthly_first | 70.25 us | **2.04 us (34.4x faster)** |
| monthly_last | 71.58 us | **2.12 us (33.7x faster)** |
| monthly_mean | 73.92 us | **2.54 us (29.1x faster)** |
| monthly_sum | 72.67 us | **2.38 us (30.6x faster)** |
| weekly_last | 71.29 us | **1.79 us (39.8x faster)** |
| weekly_mean | 73.62 us | **2.5 us (29.4x faster)** |
| yearly_first | 70.92 us | **1.5 us (47.3x faster)** |
| **── medium ──** |  |  |
| monthly_first | 224.92 us | **24.67 us (9.1x faster)** |
| monthly_last | 225.25 us | **25.0 us (9.0x faster)** |
| monthly_mean | 333.29 us | **34.04 us (9.8x faster)** |
| monthly_sum | 345.17 us | **31.58 us (10.9x faster)** |
| weekly_last | 220.62 us | **17.38 us (12.7x faster)** |
| weekly_mean | 373.92 us | **32.62 us (11.5x faster)** |
| yearly_first | 193.96 us | **11.12 us (17.4x faster)** |
| **── large ──** |  |  |
| monthly_first | 8.1 ms | **936.62 us (8.6x faster)** |
| monthly_last | 8.34 ms | **952.33 us (8.8x faster)** |
| monthly_mean | 11.11 ms | **1.31 ms (8.5x faster)** |
| monthly_sum | 11.82 ms | **1.2 ms (9.9x faster)** |
| weekly_last | 5.96 ms | **627.12 us (9.5x faster)** |
| weekly_mean | 11.47 ms | **1.29 ms (8.9x faster)** |
| yearly_first | 5.62 ms | **345.17 us (16.3x faster)** |

## construction

TSFrame construction from various input types

| Benchmark | v0.2.2 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| from_dataframe_first_col | 7.58 us | 7.71 us (~1.0x) |
| from_dataframe_sorted_nocopy | 459.0 ns | 459.0 ns (~1.0x) |
| from_dataframe_with_index | 7.25 us | 7.21 us (~1.0x) |
| from_matrix_and_dates | 2.29 us | **2.12 us (1.1x faster)** |
| from_vector_and_dates | 1.29 us | _2.25 us (1.7x slower)_ |
| **── medium ──** |  |  |
| from_dataframe_first_col | 56.46 us | 54.75 us (~1.0x) |
| from_dataframe_sorted_nocopy | 500.0 ns | **458.0 ns (1.1x faster)** |
| from_dataframe_with_index | 55.92 us | 53.33 us (~1.0x) |
| from_matrix_and_dates | 23.79 us | **21.83 us (1.1x faster)** |
| from_vector_and_dates | 16.58 us | **15.5 us (1.1x faster)** |
| **── large ──** |  |  |
| from_dataframe_first_col | 2.32 ms | **2.2 ms (1.1x faster)** |
| from_dataframe_sorted_nocopy | 500.0 ns | 500.0 ns (~1.0x) |
| from_dataframe_with_index | 2.34 ms | 2.23 ms (~1.0x) |
| from_matrix_and_dates | 963.04 us | **884.25 us (1.1x faster)** |
| from_vector_and_dates | 692.5 us | **645.62 us (1.1x faster)** |

## endpoints

Finding period endpoints (last date of each week/month/quarter/year)

| Benchmark | v0.2.2 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| monthly | 1.0 us | **916.0 ns (1.1x faster)** |
| quarterly | 666.0 ns | 667.0 ns (~1.0x) |
| symbol_months | 958.0 ns | 1.0 us (~1.0x) |
| symbol_weeks | 416.0 ns | _500.0 ns (1.2x slower)_ |
| weekly | 416.0 ns | 416.0 ns (~1.0x) |
| yearly | 458.0 ns | **416.0 ns (1.1x faster)** |
| **── medium ──** |  |  |
| monthly | 22.5 us | 21.67 us (~1.0x) |
| quarterly | 16.33 us | 15.71 us (~1.0x) |
| symbol_months | 22.38 us | 21.83 us (~1.0x) |
| symbol_weeks | 10.83 us | **9.5 us (1.1x faster)** |
| weekly | 11.04 us | **9.38 us (1.2x faster)** |
| yearly | 8.83 us | 8.5 us (~1.0x) |
| **── large ──** |  |  |
| monthly | 884.17 us | 860.33 us (~1.0x) |
| quarterly | 621.08 us | 596.38 us (~1.0x) |
| symbol_months | 883.04 us | 861.08 us (~1.0x) |
| symbol_weeks | 398.71 us | **372.0 us (1.1x faster)** |
| weekly | 385.17 us | 371.67 us (~1.0x) |
| yearly | 343.54 us | 335.71 us (~1.0x) |

## getindex_period

| Benchmark | v0.2.2 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| range_slice |  | 4.62 us |
| scalar_dt |  | 1.83 us |
| year |  | 8.46 us |
| year_month |  | 8.38 us |
| year_month_day |  | 8.46 us |
| **── medium ──** |  |  |
| range_slice |  | 34.42 us |
| scalar_dt |  | 1.83 us |
| year |  | 64.88 us |
| year_month |  | 64.79 us |
| year_month_day |  | 11.67 us |
| **── large ──** |  |  |
| range_slice |  | 1.28 ms |
| scalar_dt |  | 1.88 us |
| year |  | 1.34 ms |
| year_month |  | 111.67 us |
| year_month_day |  | 11.62 us |

## join

Time-series join operations (inner/outer/left)

| Benchmark | v0.2.2 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| 3way_outer |  | 66.0 us |
| inner | 15.29 us | **13.83 us (1.1x faster)** |
| left | 19.71 us | **18.58 us (1.1x faster)** |
| outer | 25.38 us | **23.96 us (1.1x faster)** |
| **── medium ──** |  |  |
| 3way_outer |  | 1.09 ms |
| inner | 99.29 us | 94.75 us (~1.0x) |
| left | 165.33 us | 159.17 us (~1.0x) |
| outer | 235.79 us | 226.96 us (~1.0x) |
| **── large ──** |  |  |
| 3way_outer |  | 81.91 ms |
| inner | 3.52 ms | 3.53 ms (~1.0x) |
| left | 6.52 ms | 6.35 ms (~1.0x) |
| outer | 9.51 ms | 9.47 ms (~1.0x) |

## lag_lead_diff

Lag, lead, diff, and pctchange operations

| Benchmark | v0.2.2 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| diff_1 | 29.62 us | **1.62 us (18.2x faster)** |
| diff_5 | 30.88 us | **1.62 us (19.0x faster)** |
| lag_1 | 11.21 us | **1.62 us (6.9x faster)** |
| lag_5 | 11.33 us | **1.67 us (6.8x faster)** |
| lag_neg3 |  | 1.5 us |
| lead_1 | 11.17 us | **1.5 us (7.4x faster)** |
| lead_5 | 11.25 us | **1.5 us (7.5x faster)** |
| pctchange_1 | 47.08 us | **10.46 us (4.5x faster)** |
| pctchange_5 | 46.5 us | **10.54 us (4.4x faster)** |
| **── medium ──** |  |  |
| diff_1 | 256.71 us | **15.58 us (16.5x faster)** |
| diff_5 | 255.33 us | **15.67 us (16.3x faster)** |
| lag_1 | 105.38 us | **14.46 us (7.3x faster)** |
| lag_5 | 105.79 us | **14.54 us (7.3x faster)** |
| lag_neg3 |  | 12.83 us |
| lead_1 | 104.67 us | **12.88 us (8.1x faster)** |
| lead_5 | 105.42 us | **12.92 us (8.2x faster)** |
| pctchange_1 | 401.21 us | **64.5 us (6.2x faster)** |
| pctchange_5 | 405.25 us | **64.54 us (6.3x faster)** |
| **── large ──** |  |  |
| diff_1 | 10.6 ms | **592.75 us (17.9x faster)** |
| diff_5 | 10.78 ms | **595.83 us (18.1x faster)** |
| lag_1 | 4.55 ms | **549.75 us (8.3x faster)** |
| lag_5 | 4.44 ms | **554.29 us (8.0x faster)** |
| lag_neg3 |  | 482.33 us |
| lead_1 | 4.45 ms | **485.71 us (9.2x faster)** |
| lead_5 | 4.44 ms | **484.96 us (9.2x faster)** |
| pctchange_1 | 17.46 ms | **2.63 ms (6.6x faster)** |
| pctchange_5 | 17.81 ms | **2.56 ms (7.0x faster)** |

## resample_fill_gaps

| Benchmark | v0.2.2 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| bfill |  | 3.29 us |
| ffill |  | 3.29 us |
| interpolate |  | 3.29 us |
| missing |  | 3.29 us |
| zero |  | 3.25 us |
| **── medium ──** |  |  |
| bfill |  | 62.21 us |
| ffill |  | 62.08 us |
| interpolate |  | 62.17 us |
| missing |  | 62.25 us |
| zero |  | 61.92 us |
| **── large ──** |  |  |
| bfill |  | 2.51 ms |
| ffill |  | 2.51 ms |
| interpolate |  | 2.5 ms |
| missing |  | 2.53 ms |
| zero |  | 2.49 ms |

## resample_vs_to_period

Comparison of resample() vs to_period() for period-based aggregation

<table>
<thead>
<tr><th rowspan="2">Benchmark</th><th colspan="2">v0.2.2</th><th colspan="2">v0.3.7</th></tr>
<tr><th>to_period</th><th>resample</th><th>to_period</th><th>resample</th></tr>
</thead>
<tbody>
<tr><td colspan="5"><strong>── small ──</strong></td></tr>
<tr><td>weekly</td><td>3.62 us</td><td></td><td><strong>1.33 us (2.7x faster)</strong></td><td>1.38 us</td></tr>
<tr><td>monthly</td><td>3.71 us</td><td></td><td><strong>1.71 us (2.2x faster)</strong></td><td>1.67 us</td></tr>
<tr><td>quarterly</td><td>3.33 us</td><td></td><td><strong>1.42 us (2.4x faster)</strong></td><td>1.42 us</td></tr>
<tr><td>yearly</td><td>2.83 us</td><td></td><td><strong>1.21 us (2.3x faster)</strong></td><td>1.17 us</td></tr>
<tr><td colspan="5"><strong>── medium ──</strong></td></tr>
<tr><td>weekly</td><td>40.71 us</td><td></td><td><strong>17.0 us (2.4x faster)</strong></td><td>16.67 us</td></tr>
<tr><td>monthly</td><td>31.25 us</td><td></td><td><strong>24.21 us (1.3x faster)</strong></td><td>24.29 us</td></tr>
<tr><td>quarterly</td><td>21.08 us</td><td></td><td><strong>17.12 us (1.2x faster)</strong></td><td>16.71 us</td></tr>
<tr><td>yearly</td><td>11.96 us</td><td></td><td><strong>9.5 us (1.3x faster)</strong></td><td>10.75 us</td></tr>
<tr><td colspan="5"><strong>── large ──</strong></td></tr>
<tr><td>weekly</td><td>1.0 ms</td><td></td><td><strong>649.12 us (1.5x faster)</strong></td><td>628.08 us</td></tr>
<tr><td>monthly</td><td>1.06 ms</td><td></td><td><strong>946.62 us (1.1x faster)</strong></td><td>959.54 us</td></tr>
<tr><td>quarterly</td><td>675.33 us</td><td></td><td><strong>619.79 us (1.1x faster)</strong></td><td>621.75 us</td></tr>
<tr><td>yearly</td><td>368.79 us</td><td></td><td><strong>343.71 us (1.1x faster)</strong></td><td>344.12 us</td></tr>
</tbody>
</table>

### Additional resample benchmarks

| Benchmark | v0.2.2 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| resample_mean/monthly_mean |  | 2.12 us |
| resample_mean/weekly_mean |  | 2.04 us |
| resample_ohlcv/monthly_default |  | 2.71 us |
| resample_ohlcv/monthly_explicit |  | 2.92 us |
| resample_ohlcv/weekly_default |  | 2.75 us |
| **── medium ──** |  |  |
| resample_mean/monthly_mean |  | 33.12 us |
| resample_mean/weekly_mean |  | 32.33 us |
| resample_ohlcv/monthly_default |  | 36.33 us |
| resample_ohlcv/monthly_explicit |  | 36.54 us |
| resample_ohlcv/weekly_default |  | 36.71 us |
| **── large ──** |  |  |
| resample_mean/monthly_mean |  | 1.31 ms |
| resample_mean/weekly_mean |  | 1.31 ms |
| resample_ohlcv/monthly_default |  | 1.47 ms |
| resample_ohlcv/monthly_explicit |  | 1.44 ms |
| resample_ohlcv/weekly_default |  | 1.43 ms |

## rollapply

Rolling window operations (mean/sum/std)

| Benchmark | v0.2.2 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| bycolumn_false_w5 |  | 1.82 ms |
| mean_w5 | 6.96 ms | **16.0 us (434.7x faster)** |
| std_w10 | 6.95 ms | **19.58 us (354.8x faster)** |
| sum_w20 | 6.88 ms | **17.38 us (395.9x faster)** |
| **── medium ──** |  |  |
| bycolumn_false_w5 |  | 49.79 ms |
| mean_w5 | 253.0 ms | **335.12 us (754.9x faster)** |
| std_w10 | 252.72 ms | **434.12 us (582.1x faster)** |
| sum_w20 | 256.43 ms | **378.92 us (676.7x faster)** |
| **── large ──** |  |  |
| bycolumn_false_w5 |  | 209.91 ms |
| mean_w5 | 2.04 s | **1.38 ms (1480.5x faster)** |
| sum_w20 | 2.04 s | **1.53 ms (1329.8x faster)** |

## subset

| Benchmark | v0.2.2 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| date_both |  | 708.0 ns |
| date_left |  | 833.0 ns |
| date_right |  | 791.0 ns |
| int_both |  | 750.0 ns |
| **── medium ──** |  |  |
| date_both |  | 3.0 us |
| date_left |  | 4.08 us |
| date_right |  | 4.0 us |
| int_both |  | 3.0 us |
| **── large ──** |  |  |
| date_both |  | 87.38 us |
| date_left |  | 132.96 us |
| date_right |  | 129.08 us |
| int_both |  | 88.0 us |

## upsample

| Benchmark | v0.2.2 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| hour12 |  | 541.0 ns |
| hour6 |  | 1.12 us |
| min30 |  | 5.54 us |
| **── medium ──** |  |  |
| hour12 |  | 1.62 us |
| hour6 |  | 2.46 us |
| min30 |  | 23.62 us |
| **── large ──** |  |  |
| hour12 |  | 4.71 us |
| hour6 |  | 7.96 us |

## vcat

Vertical concatenation of TSFrame objects

| Benchmark | v0.2.2 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| diff_cols_intersect |  | 14.33 us |
| diff_cols_union | 33.25 us | 32.88 us (~1.0x) |
| same_cols_union | 19.75 us | 19.62 us (~1.0x) |
| **── medium ──** |  |  |
| diff_cols_intersect |  | 70.62 us |
| diff_cols_union | 173.42 us | **163.75 us (1.1x faster)** |
| same_cols_union | 104.33 us | **99.21 us (1.1x faster)** |
| **── large ──** |  |  |
| diff_cols_intersect |  | 2.91 ms |
| diff_cols_union | 6.85 ms | **6.38 ms (1.1x faster)** |
| same_cols_union | 4.37 ms | **4.09 ms (1.1x faster)** |

