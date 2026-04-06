# TSFrames.jl Benchmark Report

Generated: 2026-04-06 14:47:39

## Dataset Sizes

| Label | Rows | Notes |
|-------|------|-------|
| small | 1,000 | |
| medium | 25,000 | |
| large | 1,000,000 | rollapply uses 100,000 for large |

## apply

Period-based aggregation (last/first/mean/sum) over time series

| Benchmark | v0.3.3 | v0.3.4 |
|---|---|---|
| **── small ──** |  |  |
| monthly_first | 2.04 us | 2.04 us (~1.0x) |
| monthly_last | 2.12 us | 2.08 us (~1.0x) |
| monthly_mean | 2.42 us | 2.46 us (~1.0x) |
| monthly_sum | 2.42 us | 2.33 us (~1.0x) |
| weekly_last | 1.79 us | 1.79 us (~1.0x) |
| weekly_mean | 2.42 us | 2.46 us (~1.0x) |
| yearly_first | 1.46 us | 1.46 us (~1.0x) |
| **── medium ──** |  |  |
| monthly_first | 24.92 us | 24.5 us (~1.0x) |
| monthly_last | 25.0 us | 24.83 us (~1.0x) |
| monthly_mean | 33.75 us | 33.71 us (~1.0x) |
| monthly_sum | 31.79 us | 31.42 us (~1.0x) |
| weekly_last | 17.96 us | 17.5 us (~1.0x) |
| weekly_mean | 33.08 us | 32.96 us (~1.0x) |
| yearly_first | 10.17 us | 9.96 us (~1.0x) |
| **── large ──** |  |  |
| monthly_first | 934.25 us | 933.58 us (~1.0x) |
| monthly_last | 946.67 us | 950.42 us (~1.0x) |
| monthly_mean | 1.28 ms | 1.29 ms (~1.0x) |
| monthly_sum | 1.17 ms | 1.17 ms (~1.0x) |
| weekly_last | 632.54 us | 626.12 us (~1.0x) |
| weekly_mean | 1.29 ms | 1.28 ms (~1.0x) |
| yearly_first | 343.46 us | 342.88 us (~1.0x) |

## construction

TSFrame construction from various input types

| Benchmark | v0.3.3 | v0.3.4 |
|---|---|---|
| **── small ──** |  |  |
| from_dataframe_first_col | 7.42 us | 7.21 us (~1.0x) |
| from_dataframe_sorted_nocopy | 458.0 ns | 458.0 ns (~1.0x) |
| from_dataframe_with_index | 7.08 us | 6.83 us (~1.0x) |
| from_matrix_and_dates | 2.04 us | _2.17 us (1.1x slower)_ |
| from_vector_and_dates | 1.38 us | 1.42 us (~1.0x) |
| **── medium ──** |  |  |
| from_dataframe_first_col | 55.04 us | 53.58 us (~1.0x) |
| from_dataframe_sorted_nocopy | 458.0 ns | 459.0 ns (~1.0x) |
| from_dataframe_with_index | 54.88 us | 53.71 us (~1.0x) |
| from_matrix_and_dates | 23.04 us | 21.96 us (~1.0x) |
| from_vector_and_dates | 16.0 us | 15.29 us (~1.0x) |
| **── large ──** |  |  |
| from_dataframe_first_col | 2.21 ms | 2.21 ms (~1.0x) |
| from_dataframe_sorted_nocopy | 500.0 ns | 500.0 ns (~1.0x) |
| from_dataframe_with_index | 2.21 ms | 2.22 ms (~1.0x) |
| from_matrix_and_dates | 897.62 us | 892.29 us (~1.0x) |
| from_vector_and_dates | 649.12 us | 640.62 us (~1.0x) |

## endpoints

Finding period endpoints (last date of each week/month/quarter/year)

| Benchmark | v0.3.3 | v0.3.4 |
|---|---|---|
| **── small ──** |  |  |
| monthly | 916.0 ns | 875.0 ns (~1.0x) |
| quarterly | 625.0 ns | _666.0 ns (1.1x slower)_ |
| symbol_months | 1.0 us | 1.0 us (~1.0x) |
| symbol_weeks | 500.0 ns | 500.0 ns (~1.0x) |
| weekly | 416.0 ns | 416.0 ns (~1.0x) |
| yearly | 375.0 ns | 375.0 ns (~1.0x) |
| **── medium ──** |  |  |
| monthly | 21.75 us | 21.58 us (~1.0x) |
| quarterly | 15.29 us | 15.54 us (~1.0x) |
| symbol_months | 21.79 us | 21.71 us (~1.0x) |
| symbol_weeks | 9.75 us | 9.54 us (~1.0x) |
| weekly | 9.58 us | 9.5 us (~1.0x) |
| yearly | 8.67 us | 8.46 us (~1.0x) |
| **── large ──** |  |  |
| monthly | 855.17 us | 856.17 us (~1.0x) |
| quarterly | 590.25 us | 592.25 us (~1.0x) |
| symbol_months | 855.83 us | 854.79 us (~1.0x) |
| symbol_weeks | 373.38 us | 372.33 us (~1.0x) |
| weekly | 373.04 us | 375.92 us (~1.0x) |
| yearly | 336.33 us | 336.21 us (~1.0x) |

## join

Time-series join operations (inner/outer/left)

| Benchmark | v0.3.3 | v0.3.4 |
|---|---|---|
| **── small ──** |  |  |
| inner | 14.08 us | 13.71 us (~1.0x) |
| left | 18.42 us | 18.29 us (~1.0x) |
| outer | 23.88 us | 23.75 us (~1.0x) |
| **── medium ──** |  |  |
| inner | 96.29 us | 94.0 us (~1.0x) |
| left | 161.08 us | 157.46 us (~1.0x) |
| outer | 229.5 us | 226.17 us (~1.0x) |
| **── large ──** |  |  |
| inner | 3.42 ms | 3.42 ms (~1.0x) |
| left | 6.23 ms | 6.09 ms (~1.0x) |
| outer | 9.46 ms | 9.3 ms (~1.0x) |

## lag_lead_diff

Lag, lead, diff, and pctchange operations

| Benchmark | v0.3.3 | v0.3.4 |
|---|---|---|
| **── small ──** |  |  |
| diff_1 | 15.5 us | 14.83 us (~1.0x) |
| diff_5 | 15.71 us | 15.04 us (~1.0x) |
| lag_1 | 3.83 us | 3.79 us (~1.0x) |
| lag_5 | 3.83 us | 3.79 us (~1.0x) |
| lead_1 | 3.79 us | 3.83 us (~1.0x) |
| lead_5 | 3.88 us | 3.79 us (~1.0x) |
| pctchange_1 | 16.54 us | 16.04 us (~1.0x) |
| pctchange_5 | 16.62 us | **15.71 us (1.1x faster)** |
| **── medium ──** |  |  |
| diff_1 | 102.71 us | 99.29 us (~1.0x) |
| diff_5 | 102.21 us | 99.17 us (~1.0x) |
| lag_1 | 40.38 us | 39.75 us (~1.0x) |
| lag_5 | 40.38 us | 39.75 us (~1.0x) |
| lead_1 | 40.25 us | 39.79 us (~1.0x) |
| lead_5 | 40.21 us | 39.71 us (~1.0x) |
| pctchange_1 | 135.29 us | 133.04 us (~1.0x) |
| pctchange_5 | 135.92 us | 132.0 us (~1.0x) |
| **── large ──** |  |  |
| diff_1 | 4.58 ms | 4.53 ms (~1.0x) |
| diff_5 | 4.13 ms | 4.25 ms (~1.0x) |
| lag_1 | 1.6 ms | _1.69 ms (1.1x slower)_ |
| lag_5 | 1.62 ms | 1.65 ms (~1.0x) |
| lead_1 | 1.66 ms | **1.53 ms (1.1x faster)** |
| lead_5 | 1.63 ms | **1.5 ms (1.1x faster)** |
| pctchange_1 | 5.62 ms | 5.64 ms (~1.0x) |
| pctchange_5 | 5.66 ms | 5.68 ms (~1.0x) |

## resample_vs_to_period

Comparison of resample() vs to_period() for period-based aggregation

<table>
<thead>
<tr><th rowspan="2">Benchmark</th><th colspan="2">v0.3.3</th><th colspan="2">v0.3.4</th></tr>
<tr><th>to_period</th><th>resample</th><th>to_period</th><th>resample</th></tr>
</thead>
<tbody>
<tr><td colspan="5"><strong>── small ──</strong></td></tr>
<tr><td>weekly</td><td>1.38 us</td><td>1.33 us</td><td>1.38 us (~1.0x)</td><td>1.33 us (~1.0x)</td></tr>
<tr><td>monthly</td><td>1.71 us</td><td>1.71 us</td><td>1.67 us (~1.0x)</td><td>1.71 us (~1.0x)</td></tr>
<tr><td>quarterly</td><td>1.42 us</td><td>1.46 us</td><td>1.42 us (~1.0x)</td><td><strong>1.38 us (1.1x faster)</strong></td></tr>
<tr><td>yearly</td><td>1.12 us</td><td>1.12 us</td><td>1.12 us (~1.0x)</td><td>1.12 us (~1.0x)</td></tr>
<tr><td colspan="5"><strong>── medium ──</strong></td></tr>
<tr><td>weekly</td><td>17.17 us</td><td>16.88 us</td><td>17.12 us (~1.0x)</td><td>16.58 us (~1.0x)</td></tr>
<tr><td>monthly</td><td>24.21 us</td><td>24.33 us</td><td>24.04 us (~1.0x)</td><td>24.17 us (~1.0x)</td></tr>
<tr><td>quarterly</td><td>16.71 us</td><td>16.79 us</td><td>16.46 us (~1.0x)</td><td>16.67 us (~1.0x)</td></tr>
<tr><td>yearly</td><td>9.62 us</td><td>9.71 us</td><td>9.42 us (~1.0x)</td><td>9.54 us (~1.0x)</td></tr>
<tr><td colspan="5"><strong>── large ──</strong></td></tr>
<tr><td>weekly</td><td>649.92 us</td><td>635.71 us</td><td>651.62 us (~1.0x)</td><td>627.67 us (~1.0x)</td></tr>
<tr><td>monthly</td><td>938.46 us</td><td>949.0 us</td><td>941.67 us (~1.0x)</td><td>952.33 us (~1.0x)</td></tr>
<tr><td>quarterly</td><td>619.5 us</td><td>616.12 us</td><td>615.75 us (~1.0x)</td><td>616.08 us (~1.0x)</td></tr>
<tr><td>yearly</td><td>344.54 us</td><td>344.46 us</td><td>343.12 us (~1.0x)</td><td>343.08 us (~1.0x)</td></tr>
</tbody>
</table>

### Additional resample benchmarks

| Benchmark | v0.3.3 | v0.3.4 |
|---|---|---|
| **── small ──** |  |  |
| resample_mean/monthly_mean | 2.04 us | 2.08 us (~1.0x) |
| resample_mean/weekly_mean | 2.04 us | 2.04 us (~1.0x) |
| resample_ohlcv/monthly_default | 2.58 us | 2.54 us (~1.0x) |
| resample_ohlcv/monthly_explicit | 2.79 us | 2.67 us (~1.0x) |
| resample_ohlcv/weekly_default | 2.71 us | 2.67 us (~1.0x) |
| **── medium ──** |  |  |
| resample_mean/monthly_mean | 33.04 us | 32.96 us (~1.0x) |
| resample_mean/weekly_mean | 32.12 us | 31.96 us (~1.0x) |
| resample_ohlcv/monthly_default | 36.0 us | 35.62 us (~1.0x) |
| resample_ohlcv/monthly_explicit | 35.79 us | 35.5 us (~1.0x) |
| resample_ohlcv/weekly_default | 37.0 us | 36.25 us (~1.0x) |
| **── large ──** |  |  |
| resample_mean/monthly_mean | 1.28 ms | 1.29 ms (~1.0x) |
| resample_mean/weekly_mean | 1.26 ms | 1.26 ms (~1.0x) |
| resample_ohlcv/monthly_default | 1.42 ms | 1.42 ms (~1.0x) |
| resample_ohlcv/monthly_explicit | 1.41 ms | 1.43 ms (~1.0x) |
| resample_ohlcv/weekly_default | 1.43 ms | 1.41 ms (~1.0x) |

## rollapply

Rolling window operations (mean/sum/std)

| Benchmark | v0.3.3 | v0.3.4 |
|---|---|---|
| **── small ──** |  |  |
| mean_w5 | 6.13 ms | 6.1 ms (~1.0x) |
| std_w10 | 6.14 ms | 6.16 ms (~1.0x) |
| sum_w20 | 6.09 ms | 6.03 ms (~1.0x) |
| **── medium ──** |  |  |
| mean_w5 | 170.15 ms | 168.39 ms (~1.0x) |
| std_w10 | 172.57 ms | 173.85 ms (~1.0x) |
| sum_w20 | 175.89 ms | 178.17 ms (~1.0x) |
| **── large ──** |  |  |
| mean_w5 | 763.8 ms | 762.79 ms (~1.0x) |
| sum_w20 | 839.24 ms | 828.01 ms (~1.0x) |

## vcat

Vertical concatenation of TSFrame objects

| Benchmark | v0.3.3 | v0.3.4 |
|---|---|---|
| **── small ──** |  |  |
| diff_cols_intersect | 14.38 us | 14.42 us (~1.0x) |
| diff_cols_union | 33.08 us | 32.12 us (~1.0x) |
| same_cols_union | 19.88 us | 19.46 us (~1.0x) |
| **── medium ──** |  |  |
| diff_cols_intersect | 71.54 us | 70.42 us (~1.0x) |
| diff_cols_union | 167.5 us | 163.62 us (~1.0x) |
| same_cols_union | 101.58 us | 99.08 us (~1.0x) |
| **── large ──** |  |  |
| diff_cols_intersect | 2.96 ms | 2.95 ms (~1.0x) |
| diff_cols_union | 6.79 ms | 6.57 ms (~1.0x) |
| same_cols_union | 4.18 ms | 4.13 ms (~1.0x) |

