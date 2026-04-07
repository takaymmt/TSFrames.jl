# TSFrames.jl Benchmark Report

Generated: 2026-04-07 11:26:10

## Dataset Sizes

| Label | Rows | Notes |
|-------|------|-------|
| small | 1,000 | |
| medium | 25,000 | |
| large | 1,000,000 | rollapply uses 100,000 for large |

## apply

Period-based aggregation (last/first/mean/sum) over time series

| Benchmark | v0.3.5 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| monthly_first | 2.04 us | 2.04 us (~1.0x) |
| monthly_last | 2.04 us | 2.12 us (~1.0x) |
| monthly_mean | 2.46 us | 2.54 us (~1.0x) |
| monthly_sum | 2.38 us | 2.38 us (~1.0x) |
| weekly_last | 1.79 us | 1.79 us (~1.0x) |
| weekly_mean | 2.46 us | 2.5 us (~1.0x) |
| yearly_first | 1.46 us | 1.5 us (~1.0x) |
| **── medium ──** |  |  |
| monthly_first | 24.5 us | 24.67 us (~1.0x) |
| monthly_last | 24.79 us | 25.0 us (~1.0x) |
| monthly_mean | 33.58 us | 34.04 us (~1.0x) |
| monthly_sum | 31.29 us | 31.58 us (~1.0x) |
| weekly_last | 17.46 us | 17.38 us (~1.0x) |
| weekly_mean | 32.79 us | 32.62 us (~1.0x) |
| yearly_first | 9.75 us | _11.12 us (1.1x slower)_ |
| **── large ──** |  |  |
| monthly_first | 931.0 us | 936.62 us (~1.0x) |
| monthly_last | 946.54 us | 952.33 us (~1.0x) |
| monthly_mean | 1.28 ms | 1.31 ms (~1.0x) |
| monthly_sum | 1.18 ms | 1.2 ms (~1.0x) |
| weekly_last | 618.75 us | 627.12 us (~1.0x) |
| weekly_mean | 1.28 ms | 1.29 ms (~1.0x) |
| yearly_first | 332.17 us | 345.17 us (~1.0x) |

## construction

TSFrame construction from various input types

| Benchmark | v0.3.5 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| from_dataframe_first_col | 7.46 us | 7.71 us (~1.0x) |
| from_dataframe_sorted_nocopy | 458.0 ns | 459.0 ns (~1.0x) |
| from_dataframe_with_index | 7.08 us | 7.21 us (~1.0x) |
| from_matrix_and_dates | 2.0 us | _2.12 us (1.1x slower)_ |
| from_vector_and_dates | 1.33 us | _2.25 us (1.7x slower)_ |
| **── medium ──** |  |  |
| from_dataframe_first_col | 53.71 us | 54.75 us (~1.0x) |
| from_dataframe_sorted_nocopy | 458.0 ns | 458.0 ns (~1.0x) |
| from_dataframe_with_index | 53.21 us | 53.33 us (~1.0x) |
| from_matrix_and_dates | 21.92 us | 21.83 us (~1.0x) |
| from_vector_and_dates | 15.54 us | 15.5 us (~1.0x) |
| **── large ──** |  |  |
| from_dataframe_first_col | 2.18 ms | 2.2 ms (~1.0x) |
| from_dataframe_sorted_nocopy | 458.0 ns | _500.0 ns (1.1x slower)_ |
| from_dataframe_with_index | 2.18 ms | 2.23 ms (~1.0x) |
| from_matrix_and_dates | 883.42 us | 884.25 us (~1.0x) |
| from_vector_and_dates | 634.25 us | 645.62 us (~1.0x) |

## endpoints

Finding period endpoints (last date of each week/month/quarter/year)

| Benchmark | v0.3.5 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| monthly | 916.0 ns | 916.0 ns (~1.0x) |
| quarterly | 666.0 ns | 667.0 ns (~1.0x) |
| symbol_months | 958.0 ns | 1.0 us (~1.0x) |
| symbol_weeks | 500.0 ns | 500.0 ns (~1.0x) |
| weekly | 416.0 ns | 416.0 ns (~1.0x) |
| yearly | 416.0 ns | 416.0 ns (~1.0x) |
| **── medium ──** |  |  |
| monthly | 21.58 us | 21.67 us (~1.0x) |
| quarterly | 15.08 us | 15.71 us (~1.0x) |
| symbol_months | 21.62 us | 21.83 us (~1.0x) |
| symbol_weeks | 9.5 us | 9.5 us (~1.0x) |
| weekly | 9.38 us | 9.38 us (~1.0x) |
| yearly | 9.62 us | **8.5 us (1.1x faster)** |
| **── large ──** |  |  |
| monthly | 855.5 us | 860.33 us (~1.0x) |
| quarterly | 590.12 us | 596.38 us (~1.0x) |
| symbol_months | 855.29 us | 861.08 us (~1.0x) |
| symbol_weeks | 373.33 us | 372.0 us (~1.0x) |
| weekly | 371.71 us | 371.67 us (~1.0x) |
| yearly | 323.21 us | 335.71 us (~1.0x) |

## getindex_period

| Benchmark | v0.3.5 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| range_slice | 4.67 us | 4.62 us (~1.0x) |
| scalar_dt | 1.83 us | 1.83 us (~1.0x) |
| year | 8.62 us | 8.46 us (~1.0x) |
| year_month | 8.46 us | 8.38 us (~1.0x) |
| year_month_day | 8.62 us | 8.46 us (~1.0x) |
| **── medium ──** |  |  |
| range_slice | 34.21 us | 34.42 us (~1.0x) |
| scalar_dt | 1.88 us | 1.83 us (~1.0x) |
| year | 64.21 us | 64.88 us (~1.0x) |
| year_month | 64.38 us | 64.79 us (~1.0x) |
| year_month_day | 11.46 us | 11.67 us (~1.0x) |
| **── large ──** |  |  |
| range_slice | 1.26 ms | 1.28 ms (~1.0x) |
| scalar_dt | 1.83 us | 1.88 us (~1.0x) |
| year | 1.33 ms | 1.34 ms (~1.0x) |
| year_month | 111.08 us | 111.67 us (~1.0x) |
| year_month_day | 11.42 us | 11.62 us (~1.0x) |

## join

Time-series join operations (inner/outer/left)

| Benchmark | v0.3.5 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| 3way_outer | 64.92 us | 66.0 us (~1.0x) |
| inner | 13.54 us | 13.83 us (~1.0x) |
| left | 18.29 us | 18.58 us (~1.0x) |
| outer | 23.71 us | 23.96 us (~1.0x) |
| **── medium ──** |  |  |
| 3way_outer | 1.08 ms | 1.09 ms (~1.0x) |
| inner | 94.75 us | 94.75 us (~1.0x) |
| left | 158.29 us | 159.17 us (~1.0x) |
| outer | 226.29 us | 226.96 us (~1.0x) |
| **── large ──** |  |  |
| 3way_outer | 79.92 ms | 81.91 ms (~1.0x) |
| inner | 3.48 ms | 3.53 ms (~1.0x) |
| left | 6.28 ms | 6.35 ms (~1.0x) |
| outer | 9.42 ms | 9.47 ms (~1.0x) |

## lag_lead_diff

Lag, lead, diff, and pctchange operations

| Benchmark | v0.3.5 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| diff_1 | 15.38 us | **1.62 us (9.5x faster)** |
| diff_5 | 15.17 us | **1.62 us (9.3x faster)** |
| lag_1 | 3.79 us | **1.62 us (2.3x faster)** |
| lag_5 | 4.17 us | **1.67 us (2.5x faster)** |
| lag_neg3 | 3.75 us | **1.5 us (2.5x faster)** |
| lead_1 | 3.83 us | **1.5 us (2.6x faster)** |
| lead_5 | 3.79 us | **1.5 us (2.5x faster)** |
| pctchange_1 | 10.62 us | 10.46 us (~1.0x) |
| pctchange_5 | 10.54 us | 10.54 us (~1.0x) |
| **── medium ──** |  |  |
| diff_1 | 99.25 us | **15.58 us (6.4x faster)** |
| diff_5 | 99.21 us | **15.67 us (6.3x faster)** |
| lag_1 | 39.71 us | **14.46 us (2.7x faster)** |
| lag_5 | 39.83 us | **14.54 us (2.7x faster)** |
| lag_neg3 | 39.75 us | **12.83 us (3.1x faster)** |
| lead_1 | 39.75 us | **12.88 us (3.1x faster)** |
| lead_5 | 39.75 us | **12.92 us (3.1x faster)** |
| pctchange_1 | 59.96 us | _64.5 us (1.1x slower)_ |
| pctchange_5 | 59.92 us | _64.54 us (1.1x slower)_ |
| **── large ──** |  |  |
| diff_1 | 4.68 ms | **592.75 us (7.9x faster)** |
| diff_5 | 4.74 ms | **595.83 us (8.0x faster)** |
| lag_1 | 1.61 ms | **549.75 us (2.9x faster)** |
| lag_5 | 1.68 ms | **554.29 us (3.0x faster)** |
| lag_neg3 | 1.62 ms | **482.33 us (3.4x faster)** |
| lead_1 | 1.68 ms | **485.71 us (3.5x faster)** |
| lead_5 | 1.59 ms | **484.96 us (3.3x faster)** |
| pctchange_1 | 2.33 ms | _2.63 ms (1.1x slower)_ |
| pctchange_5 | 2.31 ms | _2.56 ms (1.1x slower)_ |

## resample_fill_gaps

| Benchmark | v0.3.5 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| bfill | 3.25 us | 3.29 us (~1.0x) |
| ffill | 3.21 us | 3.29 us (~1.0x) |
| interpolate | 3.25 us | 3.29 us (~1.0x) |
| missing | 3.25 us | 3.29 us (~1.0x) |
| zero | 3.25 us | 3.25 us (~1.0x) |
| **── medium ──** |  |  |
| bfill | 63.25 us | 62.21 us (~1.0x) |
| ffill | 61.75 us | 62.08 us (~1.0x) |
| interpolate | 63.29 us | 62.17 us (~1.0x) |
| missing | 63.17 us | 62.25 us (~1.0x) |
| zero | 63.25 us | 61.92 us (~1.0x) |
| **── large ──** |  |  |
| bfill | 2.55 ms | 2.51 ms (~1.0x) |
| ffill | 2.54 ms | 2.51 ms (~1.0x) |
| interpolate | 2.55 ms | 2.5 ms (~1.0x) |
| missing | 2.55 ms | 2.53 ms (~1.0x) |
| zero | 2.55 ms | 2.49 ms (~1.0x) |

## resample_vs_to_period

Comparison of resample() vs to_period() for period-based aggregation

<table>
<thead>
<tr><th rowspan="2">Benchmark</th><th colspan="2">v0.3.5</th><th colspan="2">v0.3.7</th></tr>
<tr><th>to_period</th><th>resample</th><th>to_period</th><th>resample</th></tr>
</thead>
<tbody>
<tr><td colspan="5"><strong>── small ──</strong></td></tr>
<tr><td>weekly</td><td>1.38 us</td><td>1.38 us</td><td>1.33 us (~1.0x)</td><td>1.38 us (~1.0x)</td></tr>
<tr><td>monthly</td><td>1.71 us</td><td>1.71 us</td><td>1.71 us (~1.0x)</td><td>1.67 us (~1.0x)</td></tr>
<tr><td>quarterly</td><td>1.42 us</td><td>1.38 us</td><td>1.42 us (~1.0x)</td><td>1.42 us (~1.0x)</td></tr>
<tr><td>yearly</td><td>1.12 us</td><td>1.08 us</td><td><em>1.21 us (1.1x slower)</em></td><td><em>1.17 us (1.1x slower)</em></td></tr>
<tr><td colspan="5"><strong>── medium ──</strong></td></tr>
<tr><td>weekly</td><td>16.92 us</td><td>16.62 us</td><td>17.0 us (~1.0x)</td><td>16.67 us (~1.0x)</td></tr>
<tr><td>monthly</td><td>24.08 us</td><td>24.12 us</td><td>24.21 us (~1.0x)</td><td>24.29 us (~1.0x)</td></tr>
<tr><td>quarterly</td><td>16.62 us</td><td>16.54 us</td><td>17.12 us (~1.0x)</td><td>16.71 us (~1.0x)</td></tr>
<tr><td>yearly</td><td>9.17 us</td><td>9.29 us</td><td>9.5 us (~1.0x)</td><td><em>10.75 us (1.2x slower)</em></td></tr>
<tr><td colspan="5"><strong>── large ──</strong></td></tr>
<tr><td>weekly</td><td>654.17 us</td><td>621.46 us</td><td>649.12 us (~1.0x)</td><td>628.08 us (~1.0x)</td></tr>
<tr><td>monthly</td><td>937.38 us</td><td>949.08 us</td><td>946.62 us (~1.0x)</td><td>959.54 us (~1.0x)</td></tr>
<tr><td>quarterly</td><td>621.29 us</td><td>618.67 us</td><td>619.79 us (~1.0x)</td><td>621.75 us (~1.0x)</td></tr>
<tr><td>yearly</td><td>330.96 us</td><td>332.0 us</td><td>343.71 us (~1.0x)</td><td>344.12 us (~1.0x)</td></tr>
</tbody>
</table>

### Additional resample benchmarks

| Benchmark | v0.3.5 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| resample_mean/monthly_mean | 2.08 us | 2.12 us (~1.0x) |
| resample_mean/weekly_mean | 2.08 us | 2.04 us (~1.0x) |
| resample_ohlcv/monthly_default | 2.62 us | 2.71 us (~1.0x) |
| resample_ohlcv/monthly_explicit | 2.67 us | _2.92 us (1.1x slower)_ |
| resample_ohlcv/weekly_default | 2.58 us | _2.75 us (1.1x slower)_ |
| **── medium ──** |  |  |
| resample_mean/monthly_mean | 32.92 us | 33.12 us (~1.0x) |
| resample_mean/weekly_mean | 32.04 us | 32.33 us (~1.0x) |
| resample_ohlcv/monthly_default | 35.58 us | 36.33 us (~1.0x) |
| resample_ohlcv/monthly_explicit | 35.88 us | 36.54 us (~1.0x) |
| resample_ohlcv/weekly_default | 36.67 us | 36.71 us (~1.0x) |
| **── large ──** |  |  |
| resample_mean/monthly_mean | 1.28 ms | 1.31 ms (~1.0x) |
| resample_mean/weekly_mean | 1.29 ms | 1.31 ms (~1.0x) |
| resample_ohlcv/monthly_default | 1.4 ms | 1.47 ms (~1.0x) |
| resample_ohlcv/monthly_explicit | 1.4 ms | 1.44 ms (~1.0x) |
| resample_ohlcv/weekly_default | 1.42 ms | 1.43 ms (~1.0x) |

## rollapply

Rolling window operations (mean/sum/std)

| Benchmark | v0.3.5 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| bycolumn_false_w5 | 1.81 ms | 1.82 ms (~1.0x) |
| mean_w5 | 6.08 ms | **16.0 us (379.9x faster)** |
| std_w10 | 5.97 ms | **19.58 us (305.0x faster)** |
| sum_w20 | 5.97 ms | **17.38 us (343.6x faster)** |
| **── medium ──** |  |  |
| bycolumn_false_w5 | 50.28 ms | 49.79 ms (~1.0x) |
| mean_w5 | 172.67 ms | **335.12 us (515.3x faster)** |
| std_w10 | 175.55 ms | **434.12 us (404.4x faster)** |
| sum_w20 | 173.33 ms | **378.92 us (457.4x faster)** |
| **── large ──** |  |  |
| bycolumn_false_w5 | 207.63 ms | 209.91 ms (~1.0x) |
| mean_w5 | 799.3 ms | **1.38 ms (579.3x faster)** |
| sum_w20 | 793.24 ms | **1.53 ms (516.8x faster)** |

## subset

| Benchmark | v0.3.5 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| date_both | 11.29 us | **708.0 ns (15.9x faster)** |
| date_left | 12.58 us | **833.0 ns (15.1x faster)** |
| date_right | 12.38 us | **791.0 ns (15.6x faster)** |
| int_both | 10.67 us | **750.0 ns (14.2x faster)** |
| **── medium ──** |  |  |
| date_both | 46.12 us | **3.0 us (15.4x faster)** |
| date_left | 56.08 us | **4.08 us (13.7x faster)** |
| date_right | 55.88 us | **4.0 us (14.0x faster)** |
| int_both | 45.79 us | **3.0 us (15.3x faster)** |
| **── large ──** |  |  |
| date_both | 1.53 ms | **87.38 us (17.5x faster)** |
| date_left | 1.98 ms | **132.96 us (14.9x faster)** |
| date_right | 1.98 ms | **129.08 us (15.4x faster)** |
| int_both | 1.51 ms | **88.0 us (17.2x faster)** |

## upsample

| Benchmark | v0.3.5 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| hour12 | 11.33 us | **541.0 ns (20.9x faster)** |
| hour6 | 14.79 us | **1.12 us (13.1x faster)** |
| min30 | 73.0 us | **5.54 us (13.2x faster)** |
| **── medium ──** |  |  |
| hour12 | 25.25 us | **1.62 us (15.5x faster)** |
| hour6 | 36.92 us | **2.46 us (15.0x faster)** |
| min30 | 170.46 us | **23.62 us (7.2x faster)** |
| **── large ──** |  |  |
| hour12 | 70.62 us | **4.71 us (15.0x faster)** |
| hour6 | 127.67 us | **7.96 us (16.0x faster)** |

## vcat

Vertical concatenation of TSFrame objects

| Benchmark | v0.3.5 | v0.3.7 |
|---|---|---|
| **── small ──** |  |  |
| diff_cols_intersect | 14.33 us | 14.33 us (~1.0x) |
| diff_cols_union | 32.58 us | 32.88 us (~1.0x) |
| same_cols_union | 19.04 us | 19.62 us (~1.0x) |
| **── medium ──** |  |  |
| diff_cols_intersect | 71.12 us | 70.62 us (~1.0x) |
| diff_cols_union | 164.25 us | 163.75 us (~1.0x) |
| same_cols_union | 99.83 us | 99.21 us (~1.0x) |
| **── large ──** |  |  |
| diff_cols_intersect | 2.9 ms | 2.91 ms (~1.0x) |
| diff_cols_union | 6.4 ms | 6.38 ms (~1.0x) |
| same_cols_union | 4.06 ms | 4.09 ms (~1.0x) |

