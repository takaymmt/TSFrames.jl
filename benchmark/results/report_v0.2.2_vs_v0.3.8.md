# TSFrames.jl Benchmark Report

Generated: 2026-04-07 15:41:28

## Dataset Sizes

| Label | Rows | Notes |
|-------|------|-------|
| small | 1,000 | |
| medium | 25,000 | |
| large | 1,000,000 | rollapply uses 100,000 for large |

## apply

Period-based aggregation (last/first/mean/sum) over time series

| Benchmark | v0.2.2 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| monthly_first | 70.25 us | **2.04 us (34.4x faster)** |
| monthly_last | 71.58 us | **2.04 us (35.1x faster)** |
| monthly_mean | 73.92 us | **2.46 us (30.1x faster)** |
| monthly_sum | 72.67 us | **2.38 us (30.6x faster)** |
| weekly_last | 71.29 us | **1.79 us (39.8x faster)** |
| weekly_mean | 73.62 us | **2.46 us (30.0x faster)** |
| yearly_first | 70.92 us | **1.5 us (47.3x faster)** |
| **── medium ──** |  |  |
| monthly_first | 224.92 us | **24.67 us (9.1x faster)** |
| monthly_last | 225.25 us | **24.92 us (9.0x faster)** |
| monthly_mean | 333.29 us | **33.83 us (9.9x faster)** |
| monthly_sum | 345.17 us | **31.71 us (10.9x faster)** |
| weekly_last | 220.62 us | **17.5 us (12.6x faster)** |
| weekly_mean | 373.92 us | **32.79 us (11.4x faster)** |
| yearly_first | 193.96 us | **10.04 us (19.3x faster)** |
| **── large ──** |  |  |
| monthly_first | 8.1 ms | **938.0 us (8.6x faster)** |
| monthly_last | 8.34 ms | **957.21 us (8.7x faster)** |
| monthly_mean | 11.11 ms | **1.3 ms (8.6x faster)** |
| monthly_sum | 11.82 ms | **1.19 ms (9.9x faster)** |
| weekly_last | 5.96 ms | **632.04 us (9.4x faster)** |
| weekly_mean | 11.47 ms | **1.28 ms (8.9x faster)** |
| yearly_first | 5.62 ms | **343.21 us (16.4x faster)** |

## construction

TSFrame construction from various input types

| Benchmark | v0.2.2 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| from_dataframe_first_col | 7.58 us | 7.67 us (~1.0x) |
| from_dataframe_sorted_nocopy | 459.0 ns | 458.0 ns (~1.0x) |
| from_dataframe_with_index | 7.25 us | 7.25 us (~1.0x) |
| from_matrix_and_dates | 2.29 us | **2.08 us (1.1x faster)** |
| from_vector_and_dates | 1.29 us | _1.96 us (1.5x slower)_ |
| **── medium ──** |  |  |
| from_dataframe_first_col | 56.46 us | 54.0 us (~1.0x) |
| from_dataframe_sorted_nocopy | 500.0 ns | 500.0 ns (~1.0x) |
| from_dataframe_with_index | 55.92 us | **53.21 us (1.1x faster)** |
| from_matrix_and_dates | 23.79 us | **21.96 us (1.1x faster)** |
| from_vector_and_dates | 16.58 us | **15.62 us (1.1x faster)** |
| **── large ──** |  |  |
| from_dataframe_first_col | 2.32 ms | 2.21 ms (~1.0x) |
| from_dataframe_sorted_nocopy | 500.0 ns | **458.0 ns (1.1x faster)** |
| from_dataframe_with_index | 2.34 ms | 2.22 ms (~1.0x) |
| from_matrix_and_dates | 963.04 us | **890.75 us (1.1x faster)** |
| from_vector_and_dates | 692.5 us | **644.96 us (1.1x faster)** |

## endpoints

Finding period endpoints (last date of each week/month/quarter/year)

| Benchmark | v0.2.2 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| monthly | 1.0 us | **916.0 ns (1.1x faster)** |
| quarterly | 666.0 ns | 666.0 ns (~1.0x) |
| symbol_months | 958.0 ns | 1.0 us (~1.0x) |
| symbol_weeks | 416.0 ns | _500.0 ns (1.2x slower)_ |
| weekly | 416.0 ns | 416.0 ns (~1.0x) |
| yearly | 458.0 ns | **417.0 ns (1.1x faster)** |
| **── medium ──** |  |  |
| monthly | 22.5 us | 21.67 us (~1.0x) |
| quarterly | 16.33 us | **15.04 us (1.1x faster)** |
| symbol_months | 22.38 us | 21.75 us (~1.0x) |
| symbol_weeks | 10.83 us | **9.62 us (1.1x faster)** |
| weekly | 11.04 us | **9.5 us (1.2x faster)** |
| yearly | 8.83 us | _9.67 us (1.1x slower)_ |
| **── large ──** |  |  |
| monthly | 884.17 us | 859.96 us (~1.0x) |
| quarterly | 621.08 us | 597.46 us (~1.0x) |
| symbol_months | 883.04 us | 859.04 us (~1.0x) |
| symbol_weeks | 398.71 us | **373.38 us (1.1x faster)** |
| weekly | 385.17 us | 373.92 us (~1.0x) |
| yearly | 343.54 us | 337.92 us (~1.0x) |

## getindex_period

| Benchmark | v0.2.2 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| range_slice |  | 4.75 us |
| scalar_dt |  | 1.88 us |
| year |  | 8.38 us |
| year_month |  | 8.25 us |
| year_month_day |  | 8.25 us |
| **── medium ──** |  |  |
| range_slice |  | 34.54 us |
| scalar_dt |  | 1.83 us |
| year |  | 64.88 us |
| year_month |  | 64.67 us |
| year_month_day |  | 11.42 us |
| **── large ──** |  |  |
| range_slice |  | 1.25 ms |
| scalar_dt |  | 1.88 us |
| year |  | 1.34 ms |
| year_month |  | 112.62 us |
| year_month_day |  | 11.5 us |

## join

Time-series join operations (inner/outer/left)

| Benchmark | v0.2.2 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| 3way_outer |  | 64.96 us |
| inner | 15.29 us | **13.79 us (1.1x faster)** |
| left | 19.71 us | **18.38 us (1.1x faster)** |
| outer | 25.38 us | 24.21 us (~1.0x) |
| **── medium ──** |  |  |
| 3way_outer |  | 1.1 ms |
| inner | 99.29 us | **94.21 us (1.1x faster)** |
| left | 165.33 us | 159.21 us (~1.0x) |
| outer | 235.79 us | 226.33 us (~1.0x) |
| **── large ──** |  |  |
| 3way_outer |  | 77.37 ms |
| inner | 3.52 ms | 3.43 ms (~1.0x) |
| left | 6.52 ms | **6.05 ms (1.1x faster)** |
| outer | 9.51 ms | **8.87 ms (1.1x faster)** |

## lag_lead_diff

Lag, lead, diff, and pctchange operations

| Benchmark | v0.2.2 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| diff_1 | 29.62 us | **1.62 us (18.2x faster)** |
| diff_5 | 30.88 us | **1.54 us (20.0x faster)** |
| lag_1 | 11.21 us | **1.58 us (7.1x faster)** |
| lag_5 | 11.33 us | **1.62 us (7.0x faster)** |
| lag_neg3 |  | 1.54 us |
| lead_1 | 11.17 us | **1.54 us (7.2x faster)** |
| lead_5 | 11.25 us | **1.5 us (7.5x faster)** |
| pctchange_1 | 47.08 us | **10.58 us (4.4x faster)** |
| pctchange_5 | 46.5 us | **10.79 us (4.3x faster)** |
| **── medium ──** |  |  |
| diff_1 | 256.71 us | **15.62 us (16.4x faster)** |
| diff_5 | 255.33 us | **15.67 us (16.3x faster)** |
| lag_1 | 105.38 us | **14.5 us (7.3x faster)** |
| lag_5 | 105.79 us | **14.54 us (7.3x faster)** |
| lag_neg3 |  | 12.88 us |
| lead_1 | 104.67 us | **12.88 us (8.1x faster)** |
| lead_5 | 105.42 us | **12.88 us (8.2x faster)** |
| pctchange_1 | 401.21 us | **80.5 us (5.0x faster)** |
| pctchange_5 | 405.25 us | **65.21 us (6.2x faster)** |
| **── large ──** |  |  |
| diff_1 | 10.6 ms | **597.92 us (17.7x faster)** |
| diff_5 | 10.78 ms | **600.38 us (18.0x faster)** |
| lag_1 | 4.55 ms | **554.75 us (8.2x faster)** |
| lag_5 | 4.44 ms | **556.29 us (8.0x faster)** |
| lag_neg3 |  | 497.33 us |
| lead_1 | 4.45 ms | **491.17 us (9.1x faster)** |
| lead_5 | 4.44 ms | **491.33 us (9.0x faster)** |
| pctchange_1 | 17.46 ms | **2.63 ms (6.6x faster)** |
| pctchange_5 | 17.81 ms | **2.6 ms (6.8x faster)** |

## resample_fill_gaps

| Benchmark | v0.2.2 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| bfill |  | 3.29 us |
| ffill |  | 3.29 us |
| interpolate |  | 3.25 us |
| missing |  | 3.29 us |
| zero |  | 3.29 us |
| **── medium ──** |  |  |
| bfill |  | 63.17 us |
| ffill |  | 63.54 us |
| interpolate |  | 63.46 us |
| missing |  | 63.54 us |
| zero |  | 63.38 us |
| **── large ──** |  |  |
| bfill |  | 2.56 ms |
| ffill |  | 2.56 ms |
| interpolate |  | 2.56 ms |
| missing |  | 2.57 ms |
| zero |  | 2.55 ms |

## resample_vs_to_period

Comparison of resample() vs to_period() for period-based aggregation

<table>
<thead>
<tr><th rowspan="2">Benchmark</th><th colspan="2">v0.2.2</th><th colspan="2">v0.3.8</th></tr>
<tr><th>to_period</th><th>resample</th><th>to_period</th><th>resample</th></tr>
</thead>
<tbody>
<tr><td colspan="5"><strong>── small ──</strong></td></tr>
<tr><td>weekly</td><td>3.62 us</td><td></td><td><strong>1.38 us (2.6x faster)</strong></td><td>1.38 us</td></tr>
<tr><td>monthly</td><td>3.71 us</td><td></td><td><strong>1.75 us (2.1x faster)</strong></td><td>1.71 us</td></tr>
<tr><td>quarterly</td><td>3.33 us</td><td></td><td><strong>1.5 us (2.2x faster)</strong></td><td>1.42 us</td></tr>
<tr><td>yearly</td><td>2.83 us</td><td></td><td><strong>1.21 us (2.3x faster)</strong></td><td>1.17 us</td></tr>
<tr><td colspan="5"><strong>── medium ──</strong></td></tr>
<tr><td>weekly</td><td>40.71 us</td><td></td><td><strong>17.04 us (2.4x faster)</strong></td><td>16.88 us</td></tr>
<tr><td>monthly</td><td>31.25 us</td><td></td><td><strong>24.21 us (1.3x faster)</strong></td><td>24.25 us</td></tr>
<tr><td>quarterly</td><td>21.08 us</td><td></td><td><strong>16.62 us (1.3x faster)</strong></td><td>16.79 us</td></tr>
<tr><td>yearly</td><td>11.96 us</td><td></td><td><strong>9.58 us (1.2x faster)</strong></td><td>10.67 us</td></tr>
<tr><td colspan="5"><strong>── large ──</strong></td></tr>
<tr><td>weekly</td><td>1.0 ms</td><td></td><td><strong>653.96 us (1.5x faster)</strong></td><td>629.21 us</td></tr>
<tr><td>monthly</td><td>1.06 ms</td><td></td><td><strong>943.21 us (1.1x faster)</strong></td><td>955.33 us</td></tr>
<tr><td>quarterly</td><td>675.33 us</td><td></td><td><strong>618.58 us (1.1x faster)</strong></td><td>620.71 us</td></tr>
<tr><td>yearly</td><td>368.79 us</td><td></td><td><strong>344.12 us (1.1x faster)</strong></td><td>389.62 us</td></tr>
</tbody>
</table>

### Additional resample benchmarks

| Benchmark | v0.2.2 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| resample_mean/monthly_mean |  | 2.12 us |
| resample_mean/weekly_mean |  | 2.12 us |
| resample_ohlcv/monthly_default |  | 2.67 us |
| resample_ohlcv/monthly_explicit |  | 2.71 us |
| resample_ohlcv/weekly_default |  | 2.62 us |
| **── medium ──** |  |  |
| resample_mean/monthly_mean |  | 33.0 us |
| resample_mean/weekly_mean |  | 32.42 us |
| resample_ohlcv/monthly_default |  | 35.71 us |
| resample_ohlcv/monthly_explicit |  | 35.88 us |
| resample_ohlcv/weekly_default |  | 36.33 us |
| **── large ──** |  |  |
| resample_mean/monthly_mean |  | 1.3 ms |
| resample_mean/weekly_mean |  | 1.32 ms |
| resample_ohlcv/monthly_default |  | 1.43 ms |
| resample_ohlcv/monthly_explicit |  | 1.42 ms |
| resample_ohlcv/weekly_default |  | 1.42 ms |

## rollapply

Rolling window operations (mean/sum/std)

| Benchmark | v0.2.2 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| bycolumn_false_w5 |  | 1.82 ms |
| mean_w5 | 6.96 ms | **15.67 us (444.0x faster)** |
| std_w10 | 6.95 ms | **19.71 us (352.5x faster)** |
| sum_w20 | 6.88 ms | **17.04 us (403.6x faster)** |
| **── medium ──** |  |  |
| bycolumn_false_w5 |  | 49.21 ms |
| mean_w5 | 253.0 ms | **331.33 us (763.6x faster)** |
| std_w10 | 252.72 ms | **429.42 us (588.5x faster)** |
| sum_w20 | 256.43 ms | **377.25 us (679.7x faster)** |
| **── large ──** |  |  |
| bycolumn_false_w5 |  | 210.32 ms |
| mean_w5 | 2.04 s | **1.35 ms (1510.0x faster)** |
| sum_w20 | 2.04 s | **1.59 ms (1285.8x faster)** |

## subset

| Benchmark | v0.2.2 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| date_both |  | 750.0 ns |
| date_left |  | 833.0 ns |
| date_right |  | 791.0 ns |
| int_both |  | 709.0 ns |
| **── medium ──** |  |  |
| date_both |  | 3.0 us |
| date_left |  | 4.17 us |
| date_right |  | 4.0 us |
| int_both |  | 3.04 us |
| **── large ──** |  |  |
| date_both |  | 87.79 us |
| date_left |  | 132.58 us |
| date_right |  | 130.25 us |
| int_both |  | 89.12 us |

## upsample

| Benchmark | v0.2.2 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| hour12 |  | 500.0 ns |
| hour6 |  | 792.0 ns |
| min30 |  | 5.79 us |
| **── medium ──** |  |  |
| hour12 |  | 1.75 us |
| hour6 |  | 2.5 us |
| min30 |  | 23.71 us |
| **── large ──** |  |  |
| hour12 |  | 4.46 us |
| hour6 |  | 7.92 us |

## vcat

Vertical concatenation of TSFrame objects

| Benchmark | v0.2.2 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| diff_cols_intersect |  | 14.33 us |
| diff_cols_union | 33.25 us | 32.79 us (~1.0x) |
| same_cols_union | 19.75 us | 19.04 us (~1.0x) |
| **── medium ──** |  |  |
| diff_cols_intersect |  | 70.71 us |
| diff_cols_union | 173.42 us | **165.0 us (1.1x faster)** |
| same_cols_union | 104.33 us | 99.92 us (~1.0x) |
| **── large ──** |  |  |
| diff_cols_intersect |  | 2.91 ms |
| diff_cols_union | 6.85 ms | 6.59 ms (~1.0x) |
| same_cols_union | 4.37 ms | **4.12 ms (1.1x faster)** |

