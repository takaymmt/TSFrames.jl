# TSFrames.jl Benchmark Report

Generated: 2026-04-07 15:56:15

## Dataset Sizes

| Label | Rows | Notes |
|-------|------|-------|
| small | 1,000 | |
| medium | 25,000 | |
| large | 1,000,000 | rollapply uses 100,000 for large |

## apply

Period-based aggregation (last/first/mean/sum) over time series

| Benchmark | v0.3.5 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| monthly_first | 2.04 us | 2.04 us (~1.0x) |
| monthly_last | 2.04 us | 2.04 us (~1.0x) |
| monthly_mean | 2.46 us | 2.46 us (~1.0x) |
| monthly_sum | 2.38 us | 2.38 us (~1.0x) |
| weekly_last | 1.79 us | 1.79 us (~1.0x) |
| weekly_mean | 2.46 us | 2.46 us (~1.0x) |
| yearly_first | 1.46 us | 1.5 us (~1.0x) |
| **── medium ──** |  |  |
| monthly_first | 24.5 us | 24.67 us (~1.0x) |
| monthly_last | 24.79 us | 24.92 us (~1.0x) |
| monthly_mean | 33.58 us | 33.83 us (~1.0x) |
| monthly_sum | 31.29 us | 31.71 us (~1.0x) |
| weekly_last | 17.46 us | 17.5 us (~1.0x) |
| weekly_mean | 32.79 us | 32.79 us (~1.0x) |
| yearly_first | 9.75 us | 10.04 us (~1.0x) |
| **── large ──** |  |  |
| monthly_first | 931.0 us | 938.0 us (~1.0x) |
| monthly_last | 946.54 us | 957.21 us (~1.0x) |
| monthly_mean | 1.28 ms | 1.3 ms (~1.0x) |
| monthly_sum | 1.18 ms | 1.19 ms (~1.0x) |
| weekly_last | 618.75 us | 632.04 us (~1.0x) |
| weekly_mean | 1.28 ms | 1.28 ms (~1.0x) |
| yearly_first | 332.17 us | 343.21 us (~1.0x) |

## construction

TSFrame construction from various input types

| Benchmark | v0.3.5 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| from_dataframe_first_col | 7.46 us | 7.67 us (~1.0x) |
| from_dataframe_sorted_nocopy | 458.0 ns | 458.0 ns (~1.0x) |
| from_dataframe_with_index | 7.08 us | 7.25 us (~1.0x) |
| from_matrix_and_dates | 2.0 us | 2.08 us (~1.0x) |
| from_vector_and_dates | 1.33 us | _1.96 us (1.5x slower)_ |
| **── medium ──** |  |  |
| from_dataframe_first_col | 53.71 us | 54.0 us (~1.0x) |
| from_dataframe_sorted_nocopy | 458.0 ns | _500.0 ns (1.1x slower)_ |
| from_dataframe_with_index | 53.21 us | 53.21 us (~1.0x) |
| from_matrix_and_dates | 21.92 us | 21.96 us (~1.0x) |
| from_vector_and_dates | 15.54 us | 15.62 us (~1.0x) |
| **── large ──** |  |  |
| from_dataframe_first_col | 2.18 ms | 2.21 ms (~1.0x) |
| from_dataframe_sorted_nocopy | 458.0 ns | 458.0 ns (~1.0x) |
| from_dataframe_with_index | 2.18 ms | 2.22 ms (~1.0x) |
| from_matrix_and_dates | 883.42 us | 890.75 us (~1.0x) |
| from_vector_and_dates | 634.25 us | 644.96 us (~1.0x) |

## endpoints

Finding period endpoints (last date of each week/month/quarter/year)

| Benchmark | v0.3.5 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| monthly | 916.0 ns | 916.0 ns (~1.0x) |
| quarterly | 666.0 ns | 666.0 ns (~1.0x) |
| symbol_months | 958.0 ns | 1.0 us (~1.0x) |
| symbol_weeks | 500.0 ns | 500.0 ns (~1.0x) |
| weekly | 416.0 ns | 416.0 ns (~1.0x) |
| yearly | 416.0 ns | 417.0 ns (~1.0x) |
| **── medium ──** |  |  |
| monthly | 21.58 us | 21.67 us (~1.0x) |
| quarterly | 15.08 us | 15.04 us (~1.0x) |
| symbol_months | 21.62 us | 21.75 us (~1.0x) |
| symbol_weeks | 9.5 us | 9.62 us (~1.0x) |
| weekly | 9.38 us | 9.5 us (~1.0x) |
| yearly | 9.62 us | 9.67 us (~1.0x) |
| **── large ──** |  |  |
| monthly | 855.5 us | 859.96 us (~1.0x) |
| quarterly | 590.12 us | 597.46 us (~1.0x) |
| symbol_months | 855.29 us | 859.04 us (~1.0x) |
| symbol_weeks | 373.33 us | 373.38 us (~1.0x) |
| weekly | 371.71 us | 373.92 us (~1.0x) |
| yearly | 323.21 us | 337.92 us (~1.0x) |

## getindex_period

| Benchmark | v0.3.5 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| range_slice | 4.67 us | 4.75 us (~1.0x) |
| scalar_dt | 1.83 us | 1.88 us (~1.0x) |
| year | 8.62 us | 8.38 us (~1.0x) |
| year_month | 8.46 us | 8.25 us (~1.0x) |
| year_month_day | 8.62 us | 8.25 us (~1.0x) |
| **── medium ──** |  |  |
| range_slice | 34.21 us | 34.54 us (~1.0x) |
| scalar_dt | 1.88 us | 1.83 us (~1.0x) |
| year | 64.21 us | 64.88 us (~1.0x) |
| year_month | 64.38 us | 64.67 us (~1.0x) |
| year_month_day | 11.46 us | 11.42 us (~1.0x) |
| **── large ──** |  |  |
| range_slice | 1.26 ms | 1.25 ms (~1.0x) |
| scalar_dt | 1.83 us | 1.88 us (~1.0x) |
| year | 1.33 ms | 1.34 ms (~1.0x) |
| year_month | 111.08 us | 112.62 us (~1.0x) |
| year_month_day | 11.42 us | 11.5 us (~1.0x) |

## join

Time-series join operations (inner/outer/left)

| Benchmark | v0.3.5 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| 3way_outer | 64.92 us | 64.96 us (~1.0x) |
| inner | 13.54 us | 13.79 us (~1.0x) |
| left | 18.29 us | 18.38 us (~1.0x) |
| outer | 23.71 us | 24.21 us (~1.0x) |
| **── medium ──** |  |  |
| 3way_outer | 1.08 ms | 1.1 ms (~1.0x) |
| inner | 94.75 us | 94.21 us (~1.0x) |
| left | 158.29 us | 159.21 us (~1.0x) |
| outer | 226.29 us | 226.33 us (~1.0x) |
| **── large ──** |  |  |
| 3way_outer | 79.92 ms | 77.37 ms (~1.0x) |
| inner | 3.48 ms | 3.43 ms (~1.0x) |
| left | 6.28 ms | 6.05 ms (~1.0x) |
| outer | 9.42 ms | **8.87 ms (1.1x faster)** |

## lag_lead_diff

Lag, lead, diff, and pctchange operations

| Benchmark | v0.3.5 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| diff_1 | 15.38 us | **1.62 us (9.5x faster)** |
| diff_5 | 15.17 us | **1.54 us (9.8x faster)** |
| lag_1 | 3.79 us | **1.58 us (2.4x faster)** |
| lag_5 | 4.17 us | **1.62 us (2.6x faster)** |
| lag_neg3 | 3.75 us | **1.54 us (2.4x faster)** |
| lead_1 | 3.83 us | **1.54 us (2.5x faster)** |
| lead_5 | 3.79 us | **1.5 us (2.5x faster)** |
| pctchange_1 | 10.62 us | 10.58 us (~1.0x) |
| pctchange_5 | 10.54 us | 10.79 us (~1.0x) |
| **── medium ──** |  |  |
| diff_1 | 99.25 us | **15.62 us (6.4x faster)** |
| diff_5 | 99.21 us | **15.67 us (6.3x faster)** |
| lag_1 | 39.71 us | **14.5 us (2.7x faster)** |
| lag_5 | 39.83 us | **14.54 us (2.7x faster)** |
| lag_neg3 | 39.75 us | **12.88 us (3.1x faster)** |
| lead_1 | 39.75 us | **12.88 us (3.1x faster)** |
| lead_5 | 39.75 us | **12.88 us (3.1x faster)** |
| pctchange_1 | 59.96 us | _80.5 us (1.3x slower)_ |
| pctchange_5 | 59.92 us | _65.21 us (1.1x slower)_ |
| **── large ──** |  |  |
| diff_1 | 4.68 ms | **597.92 us (7.8x faster)** |
| diff_5 | 4.74 ms | **600.38 us (7.9x faster)** |
| lag_1 | 1.61 ms | **554.75 us (2.9x faster)** |
| lag_5 | 1.68 ms | **556.29 us (3.0x faster)** |
| lag_neg3 | 1.62 ms | **497.33 us (3.3x faster)** |
| lead_1 | 1.68 ms | **491.17 us (3.4x faster)** |
| lead_5 | 1.59 ms | **491.33 us (3.2x faster)** |
| pctchange_1 | 2.33 ms | _2.63 ms (1.1x slower)_ |
| pctchange_5 | 2.31 ms | _2.6 ms (1.1x slower)_ |

## resample_fill_gaps

| Benchmark | v0.3.5 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| bfill | 3.25 us | 3.29 us (~1.0x) |
| ffill | 3.21 us | 3.29 us (~1.0x) |
| interpolate | 3.25 us | 3.25 us (~1.0x) |
| missing | 3.25 us | 3.29 us (~1.0x) |
| zero | 3.25 us | 3.29 us (~1.0x) |
| **── medium ──** |  |  |
| bfill | 63.25 us | 63.17 us (~1.0x) |
| ffill | 61.75 us | 63.54 us (~1.0x) |
| interpolate | 63.29 us | 63.46 us (~1.0x) |
| missing | 63.17 us | 63.54 us (~1.0x) |
| zero | 63.25 us | 63.38 us (~1.0x) |
| **── large ──** |  |  |
| bfill | 2.55 ms | 2.56 ms (~1.0x) |
| ffill | 2.54 ms | 2.56 ms (~1.0x) |
| interpolate | 2.55 ms | 2.56 ms (~1.0x) |
| missing | 2.55 ms | 2.57 ms (~1.0x) |
| zero | 2.55 ms | 2.55 ms (~1.0x) |

## resample_vs_to_period

Comparison of resample() vs to_period() for period-based aggregation

<table>
<thead>
<tr><th rowspan="2">Benchmark</th><th colspan="2">v0.3.5</th><th colspan="2">v0.3.8</th></tr>
<tr><th>to_period</th><th>resample</th><th>to_period</th><th>resample</th></tr>
</thead>
<tbody>
<tr><td colspan="5"><strong>── small ──</strong></td></tr>
<tr><td>weekly</td><td>1.38 us</td><td>1.38 us</td><td>1.38 us (~1.0x)</td><td>1.38 us (~1.0x)</td></tr>
<tr><td>monthly</td><td>1.71 us</td><td>1.71 us</td><td>1.75 us (~1.0x)</td><td>1.71 us (~1.0x)</td></tr>
<tr><td>quarterly</td><td>1.42 us</td><td>1.38 us</td><td><em>1.5 us (1.1x slower)</em></td><td>1.42 us (~1.0x)</td></tr>
<tr><td>yearly</td><td>1.12 us</td><td>1.08 us</td><td><em>1.21 us (1.1x slower)</em></td><td><em>1.17 us (1.1x slower)</em></td></tr>
<tr><td colspan="5"><strong>── medium ──</strong></td></tr>
<tr><td>weekly</td><td>16.92 us</td><td>16.62 us</td><td>17.04 us (~1.0x)</td><td>16.88 us (~1.0x)</td></tr>
<tr><td>monthly</td><td>24.08 us</td><td>24.12 us</td><td>24.21 us (~1.0x)</td><td>24.25 us (~1.0x)</td></tr>
<tr><td>quarterly</td><td>16.62 us</td><td>16.54 us</td><td>16.62 us (~1.0x)</td><td>16.79 us (~1.0x)</td></tr>
<tr><td>yearly</td><td>9.17 us</td><td>9.29 us</td><td>9.58 us (~1.0x)</td><td><em>10.67 us (1.1x slower)</em></td></tr>
<tr><td colspan="5"><strong>── large ──</strong></td></tr>
<tr><td>weekly</td><td>654.17 us</td><td>621.46 us</td><td>653.96 us (~1.0x)</td><td>629.21 us (~1.0x)</td></tr>
<tr><td>monthly</td><td>937.38 us</td><td>949.08 us</td><td>943.21 us (~1.0x)</td><td>955.33 us (~1.0x)</td></tr>
<tr><td>quarterly</td><td>621.29 us</td><td>618.67 us</td><td>618.58 us (~1.0x)</td><td>620.71 us (~1.0x)</td></tr>
<tr><td>yearly</td><td>330.96 us</td><td>332.0 us</td><td>344.12 us (~1.0x)</td><td><em>389.62 us (1.2x slower)</em></td></tr>
</tbody>
</table>

### Additional resample benchmarks

| Benchmark | v0.3.5 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| resample_mean/monthly_mean | 2.08 us | 2.12 us (~1.0x) |
| resample_mean/weekly_mean | 2.08 us | 2.12 us (~1.0x) |
| resample_ohlcv/monthly_default | 2.62 us | 2.67 us (~1.0x) |
| resample_ohlcv/monthly_explicit | 2.67 us | 2.71 us (~1.0x) |
| resample_ohlcv/weekly_default | 2.58 us | 2.62 us (~1.0x) |
| **── medium ──** |  |  |
| resample_mean/monthly_mean | 32.92 us | 33.0 us (~1.0x) |
| resample_mean/weekly_mean | 32.04 us | 32.42 us (~1.0x) |
| resample_ohlcv/monthly_default | 35.58 us | 35.71 us (~1.0x) |
| resample_ohlcv/monthly_explicit | 35.88 us | 35.88 us (~1.0x) |
| resample_ohlcv/weekly_default | 36.67 us | 36.33 us (~1.0x) |
| **── large ──** |  |  |
| resample_mean/monthly_mean | 1.28 ms | 1.3 ms (~1.0x) |
| resample_mean/weekly_mean | 1.29 ms | 1.32 ms (~1.0x) |
| resample_ohlcv/monthly_default | 1.4 ms | 1.43 ms (~1.0x) |
| resample_ohlcv/monthly_explicit | 1.4 ms | 1.42 ms (~1.0x) |
| resample_ohlcv/weekly_default | 1.42 ms | 1.42 ms (~1.0x) |

## rollapply

Rolling window operations (mean/sum/std)

| Benchmark | v0.3.5 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| bycolumn_false_w5 | 1.81 ms | 1.82 ms (~1.0x) |
| mean_w5 | 6.08 ms | **15.67 us (388.0x faster)** |
| std_w10 | 5.97 ms | **19.71 us (303.0x faster)** |
| sum_w20 | 5.97 ms | **17.04 us (350.4x faster)** |
| **── medium ──** |  |  |
| bycolumn_false_w5 | 50.28 ms | 49.21 ms (~1.0x) |
| mean_w5 | 172.67 ms | **331.33 us (521.1x faster)** |
| std_w10 | 175.55 ms | **429.42 us (408.8x faster)** |
| sum_w20 | 173.33 ms | **377.25 us (459.5x faster)** |
| **── large ──** |  |  |
| bycolumn_false_w5 | 207.63 ms | 210.32 ms (~1.0x) |
| mean_w5 | 799.3 ms | **1.35 ms (590.8x faster)** |
| sum_w20 | 793.24 ms | **1.59 ms (499.7x faster)** |

## subset

| Benchmark | v0.3.5 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| date_both | 11.29 us | **750.0 ns (15.1x faster)** |
| date_left | 12.58 us | **833.0 ns (15.1x faster)** |
| date_right | 12.38 us | **791.0 ns (15.6x faster)** |
| int_both | 10.67 us | **709.0 ns (15.0x faster)** |
| **── medium ──** |  |  |
| date_both | 46.12 us | **3.0 us (15.4x faster)** |
| date_left | 56.08 us | **4.17 us (13.5x faster)** |
| date_right | 55.88 us | **4.0 us (14.0x faster)** |
| int_both | 45.79 us | **3.04 us (15.1x faster)** |
| **── large ──** |  |  |
| date_both | 1.53 ms | **87.79 us (17.4x faster)** |
| date_left | 1.98 ms | **132.58 us (15.0x faster)** |
| date_right | 1.98 ms | **130.25 us (15.2x faster)** |
| int_both | 1.51 ms | **89.12 us (17.0x faster)** |

## upsample

| Benchmark | v0.3.5 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| hour12 | 11.33 us | **500.0 ns (22.7x faster)** |
| hour6 | 14.79 us | **792.0 ns (18.7x faster)** |
| min30 | 73.0 us | **5.79 us (12.6x faster)** |
| **── medium ──** |  |  |
| hour12 | 25.25 us | **1.75 us (14.4x faster)** |
| hour6 | 36.92 us | **2.5 us (14.8x faster)** |
| min30 | 170.46 us | **23.71 us (7.2x faster)** |
| **── large ──** |  |  |
| hour12 | 70.62 us | **4.46 us (15.8x faster)** |
| hour6 | 127.67 us | **7.92 us (16.1x faster)** |

## vcat

Vertical concatenation of TSFrame objects

| Benchmark | v0.3.5 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| diff_cols_intersect | 14.33 us | 14.33 us (~1.0x) |
| diff_cols_union | 32.58 us | 32.79 us (~1.0x) |
| same_cols_union | 19.04 us | 19.04 us (~1.0x) |
| **── medium ──** |  |  |
| diff_cols_intersect | 71.12 us | 70.71 us (~1.0x) |
| diff_cols_union | 164.25 us | 165.0 us (~1.0x) |
| same_cols_union | 99.83 us | 99.92 us (~1.0x) |
| **── large ──** |  |  |
| diff_cols_intersect | 2.9 ms | 2.91 ms (~1.0x) |
| diff_cols_union | 6.4 ms | 6.59 ms (~1.0x) |
| same_cols_union | 4.06 ms | 4.12 ms (~1.0x) |

