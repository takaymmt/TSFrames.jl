# TSFrames.jl Benchmark Report

Generated: 2026-04-06 16:47:18

## Dataset Sizes

| Label | Rows | Notes |
|-------|------|-------|
| small | 1,000 | |
| medium | 25,000 | |
| large | 1,000,000 | rollapply uses 100,000 for large |

## apply

Period-based aggregation (last/first/mean/sum) over time series

| Benchmark | v0.3.4 | v0.3.5 |
|---|---|---|
| **── small ──** |  |  |
| monthly_first | 2.04 us | 2.04 us (~1.0x) |
| monthly_last | 2.08 us | 2.08 us (~1.0x) |
| monthly_mean | 2.46 us | 2.5 us (~1.0x) |
| monthly_sum | 2.33 us | 2.38 us (~1.0x) |
| weekly_last | 1.79 us | 1.79 us (~1.0x) |
| weekly_mean | 2.46 us | 2.46 us (~1.0x) |
| yearly_first | 1.46 us | 1.5 us (~1.0x) |
| **── medium ──** |  |  |
| monthly_first | 24.5 us | 24.58 us (~1.0x) |
| monthly_last | 24.83 us | 24.79 us (~1.0x) |
| monthly_mean | 33.71 us | 33.67 us (~1.0x) |
| monthly_sum | 31.42 us | 31.42 us (~1.0x) |
| weekly_last | 17.5 us | 17.5 us (~1.0x) |
| weekly_mean | 32.96 us | 32.79 us (~1.0x) |
| yearly_first | 9.96 us | 9.62 us (~1.0x) |
| **── large ──** |  |  |
| monthly_first | 933.58 us | 932.21 us (~1.0x) |
| monthly_last | 950.42 us | 949.71 us (~1.0x) |
| monthly_mean | 1.29 ms | 1.28 ms (~1.0x) |
| monthly_sum | 1.17 ms | 1.19 ms (~1.0x) |
| weekly_last | 626.12 us | 627.0 us (~1.0x) |
| weekly_mean | 1.28 ms | 1.28 ms (~1.0x) |
| yearly_first | 342.88 us | 330.38 us (~1.0x) |

## construction

TSFrame construction from various input types

| Benchmark | v0.3.4 | v0.3.5 |
|---|---|---|
| **── small ──** |  |  |
| from_dataframe_first_col | 7.21 us | 7.42 us (~1.0x) |
| from_dataframe_sorted_nocopy | 458.0 ns | 458.0 ns (~1.0x) |
| from_dataframe_with_index | 6.83 us | 6.79 us (~1.0x) |
| from_matrix_and_dates | 2.17 us | **2.0 us (1.1x faster)** |
| from_vector_and_dates | 1.42 us | 1.38 us (~1.0x) |
| **── medium ──** |  |  |
| from_dataframe_first_col | 53.58 us | 54.25 us (~1.0x) |
| from_dataframe_sorted_nocopy | 459.0 ns | 458.0 ns (~1.0x) |
| from_dataframe_with_index | 53.71 us | 53.75 us (~1.0x) |
| from_matrix_and_dates | 21.96 us | 21.83 us (~1.0x) |
| from_vector_and_dates | 15.29 us | 15.5 us (~1.0x) |
| **── large ──** |  |  |
| from_dataframe_first_col | 2.21 ms | 2.21 ms (~1.0x) |
| from_dataframe_sorted_nocopy | 500.0 ns | **458.0 ns (1.1x faster)** |
| from_dataframe_with_index | 2.22 ms | 2.22 ms (~1.0x) |
| from_matrix_and_dates | 892.29 us | 888.29 us (~1.0x) |
| from_vector_and_dates | 640.62 us | 638.88 us (~1.0x) |

## endpoints

Finding period endpoints (last date of each week/month/quarter/year)

| Benchmark | v0.3.4 | v0.3.5 |
|---|---|---|
| **── small ──** |  |  |
| monthly | 875.0 ns | 916.0 ns (~1.0x) |
| quarterly | 666.0 ns | 666.0 ns (~1.0x) |
| symbol_months | 1.0 us | 1.0 us (~1.0x) |
| symbol_weeks | 500.0 ns | 500.0 ns (~1.0x) |
| weekly | 416.0 ns | 416.0 ns (~1.0x) |
| yearly | 375.0 ns | 375.0 ns (~1.0x) |
| **── medium ──** |  |  |
| monthly | 21.58 us | 21.62 us (~1.0x) |
| quarterly | 15.54 us | 15.12 us (~1.0x) |
| symbol_months | 21.71 us | 21.67 us (~1.0x) |
| symbol_weeks | 9.54 us | 9.62 us (~1.0x) |
| weekly | 9.5 us | 9.42 us (~1.0x) |
| yearly | 8.46 us | 8.21 us (~1.0x) |
| **── large ──** |  |  |
| monthly | 856.17 us | 855.62 us (~1.0x) |
| quarterly | 592.25 us | 590.54 us (~1.0x) |
| symbol_months | 854.79 us | 855.75 us (~1.0x) |
| symbol_weeks | 372.33 us | 372.62 us (~1.0x) |
| weekly | 375.92 us | 372.33 us (~1.0x) |
| yearly | 336.21 us | 324.0 us (~1.0x) |

## join

Time-series join operations (inner/outer/left)

| Benchmark | v0.3.4 | v0.3.5 |
|---|---|---|
| **── small ──** |  |  |
| inner | 13.71 us | 13.83 us (~1.0x) |
| left | 18.29 us | 18.46 us (~1.0x) |
| outer | 23.75 us | 23.79 us (~1.0x) |
| **── medium ──** |  |  |
| inner | 94.0 us | 94.0 us (~1.0x) |
| left | 157.46 us | 158.08 us (~1.0x) |
| outer | 226.17 us | 226.54 us (~1.0x) |
| **── large ──** |  |  |
| inner | 3.42 ms | 3.44 ms (~1.0x) |
| left | 6.09 ms | 6.22 ms (~1.0x) |
| outer | 9.3 ms | 9.3 ms (~1.0x) |

## lag_lead_diff

Lag, lead, diff, and pctchange operations

| Benchmark | v0.3.4 | v0.3.5 |
|---|---|---|
| **── small ──** |  |  |
| diff_1 | 14.83 us | 15.17 us (~1.0x) |
| diff_5 | 15.04 us | 15.25 us (~1.0x) |
| lag_1 | 3.79 us | 3.79 us (~1.0x) |
| lag_5 | 3.79 us | 3.83 us (~1.0x) |
| lead_1 | 3.83 us | 3.71 us (~1.0x) |
| lead_5 | 3.79 us | 3.79 us (~1.0x) |
| pctchange_1 | 16.04 us | **10.33 us (1.6x faster)** |
| pctchange_5 | 15.71 us | **10.38 us (1.5x faster)** |
| **── medium ──** |  |  |
| diff_1 | 99.29 us | 99.54 us (~1.0x) |
| diff_5 | 99.17 us | 99.75 us (~1.0x) |
| lag_1 | 39.75 us | 39.75 us (~1.0x) |
| lag_5 | 39.75 us | 39.79 us (~1.0x) |
| lead_1 | 39.79 us | 39.79 us (~1.0x) |
| lead_5 | 39.71 us | 39.79 us (~1.0x) |
| pctchange_1 | 133.04 us | **63.04 us (2.1x faster)** |
| pctchange_5 | 132.0 us | **59.54 us (2.2x faster)** |
| **── large ──** |  |  |
| diff_1 | 4.53 ms | **4.31 ms (1.1x faster)** |
| diff_5 | 4.25 ms | 4.29 ms (~1.0x) |
| lag_1 | 1.69 ms | **1.57 ms (1.1x faster)** |
| lag_5 | 1.65 ms | 1.66 ms (~1.0x) |
| lead_1 | 1.53 ms | _1.66 ms (1.1x slower)_ |
| lead_5 | 1.5 ms | _1.61 ms (1.1x slower)_ |
| pctchange_1 | 5.64 ms | **2.28 ms (2.5x faster)** |
| pctchange_5 | 5.68 ms | **2.28 ms (2.5x faster)** |

## resample_fill_gaps

| Benchmark | v0.3.4 | v0.3.5 |
|---|---|---|
| **── small ──** |  |  |
| bfill |  | 3.29 us |
| ffill |  | 3.25 us |
| interpolate |  | 3.21 us |
| missing |  | 3.29 us |
| zero |  | 3.25 us |
| **── medium ──** |  |  |
| bfill |  | 62.21 us |
| ffill |  | 62.25 us |
| interpolate |  | 62.12 us |
| missing |  | 63.5 us |
| zero |  | 62.08 us |
| **── large ──** |  |  |
| bfill |  | 2.56 ms |
| ffill |  | 2.57 ms |
| interpolate |  | 2.56 ms |
| missing |  | 2.55 ms |
| zero |  | 2.55 ms |

## resample_vs_to_period

Comparison of resample() vs to_period() for period-based aggregation

<table>
<thead>
<tr><th rowspan="2">Benchmark</th><th colspan="2">v0.3.4</th><th colspan="2">v0.3.5</th></tr>
<tr><th>to_period</th><th>resample</th><th>to_period</th><th>resample</th></tr>
</thead>
<tbody>
<tr><td colspan="5"><strong>── small ──</strong></td></tr>
<tr><td>weekly</td><td>1.38 us</td><td>1.33 us</td><td>1.38 us (~1.0x)</td><td>1.38 us (~1.0x)</td></tr>
<tr><td>monthly</td><td>1.67 us</td><td>1.71 us</td><td>1.71 us (~1.0x)</td><td>1.71 us (~1.0x)</td></tr>
<tr><td>quarterly</td><td>1.42 us</td><td>1.38 us</td><td>1.42 us (~1.0x)</td><td>1.42 us (~1.0x)</td></tr>
<tr><td>yearly</td><td>1.12 us</td><td>1.12 us</td><td>1.12 us (~1.0x)</td><td>1.17 us (~1.0x)</td></tr>
<tr><td colspan="5"><strong>── medium ──</strong></td></tr>
<tr><td>weekly</td><td>17.12 us</td><td>16.58 us</td><td>16.96 us (~1.0x)</td><td>16.58 us (~1.0x)</td></tr>
<tr><td>monthly</td><td>24.04 us</td><td>24.17 us</td><td>24.04 us (~1.0x)</td><td>24.12 us (~1.0x)</td></tr>
<tr><td>quarterly</td><td>16.46 us</td><td>16.67 us</td><td>16.58 us (~1.0x)</td><td>16.67 us (~1.0x)</td></tr>
<tr><td>yearly</td><td>9.42 us</td><td>9.54 us</td><td>9.17 us (~1.0x)</td><td>9.29 us (~1.0x)</td></tr>
<tr><td colspan="5"><strong>── large ──</strong></td></tr>
<tr><td>weekly</td><td>651.62 us</td><td>627.67 us</td><td>654.62 us (~1.0x)</td><td>625.21 us (~1.0x)</td></tr>
<tr><td>monthly</td><td>941.67 us</td><td>952.33 us</td><td>941.58 us (~1.0x)</td><td>948.67 us (~1.0x)</td></tr>
<tr><td>quarterly</td><td>615.75 us</td><td>616.08 us</td><td>614.96 us (~1.0x)</td><td>617.79 us (~1.0x)</td></tr>
<tr><td>yearly</td><td>343.12 us</td><td>343.08 us</td><td>330.46 us (~1.0x)</td><td>331.67 us (~1.0x)</td></tr>
</tbody>
</table>

### Additional resample benchmarks

| Benchmark | v0.3.4 | v0.3.5 |
|---|---|---|
| **── small ──** |  |  |
| resample_mean/monthly_mean | 2.08 us | 2.12 us (~1.0x) |
| resample_mean/weekly_mean | 2.04 us | 2.04 us (~1.0x) |
| resample_ohlcv/monthly_default | 2.54 us | 2.62 us (~1.0x) |
| resample_ohlcv/monthly_explicit | 2.67 us | 2.75 us (~1.0x) |
| resample_ohlcv/weekly_default | 2.67 us | 2.62 us (~1.0x) |
| **── medium ──** |  |  |
| resample_mean/monthly_mean | 32.96 us | 32.83 us (~1.0x) |
| resample_mean/weekly_mean | 31.96 us | 32.04 us (~1.0x) |
| resample_ohlcv/monthly_default | 35.62 us | 35.83 us (~1.0x) |
| resample_ohlcv/monthly_explicit | 35.5 us | 35.96 us (~1.0x) |
| resample_ohlcv/weekly_default | 36.25 us | 36.33 us (~1.0x) |
| **── large ──** |  |  |
| resample_mean/monthly_mean | 1.29 ms | 1.28 ms (~1.0x) |
| resample_mean/weekly_mean | 1.26 ms | 1.27 ms (~1.0x) |
| resample_ohlcv/monthly_default | 1.42 ms | 1.44 ms (~1.0x) |
| resample_ohlcv/monthly_explicit | 1.43 ms | 1.45 ms (~1.0x) |
| resample_ohlcv/weekly_default | 1.41 ms | 1.44 ms (~1.0x) |

## rollapply

Rolling window operations (mean/sum/std)

| Benchmark | v0.3.4 | v0.3.5 |
|---|---|---|
| **── small ──** |  |  |
| mean_w5 | 6.1 ms | 6.16 ms (~1.0x) |
| std_w10 | 6.16 ms | 6.11 ms (~1.0x) |
| sum_w20 | 6.03 ms | 6.09 ms (~1.0x) |
| **── medium ──** |  |  |
| mean_w5 | 168.39 ms | 173.07 ms (~1.0x) |
| std_w10 | 173.85 ms | 172.15 ms (~1.0x) |
| sum_w20 | 178.17 ms | 174.1 ms (~1.0x) |
| **── large ──** |  |  |
| mean_w5 | 762.79 ms | 760.48 ms (~1.0x) |
| sum_w20 | 828.01 ms | 830.06 ms (~1.0x) |

## vcat

Vertical concatenation of TSFrame objects

| Benchmark | v0.3.4 | v0.3.5 |
|---|---|---|
| **── small ──** |  |  |
| diff_cols_intersect | 14.42 us | 14.33 us (~1.0x) |
| diff_cols_union | 32.12 us | 32.58 us (~1.0x) |
| same_cols_union | 19.46 us | 19.71 us (~1.0x) |
| **── medium ──** |  |  |
| diff_cols_intersect | 70.42 us | 71.58 us (~1.0x) |
| diff_cols_union | 163.62 us | 164.38 us (~1.0x) |
| same_cols_union | 99.08 us | 99.62 us (~1.0x) |
| **── large ──** |  |  |
| diff_cols_intersect | 2.95 ms | 2.97 ms (~1.0x) |
| diff_cols_union | 6.57 ms | 6.73 ms (~1.0x) |
| same_cols_union | 4.13 ms | 4.19 ms (~1.0x) |

