# TSFrames.jl Benchmark Report

Generated: 2026-04-07 15:41:26

## Dataset Sizes

| Label | Rows | Notes |
|-------|------|-------|
| small | 1,000 | |
| medium | 25,000 | |
| large | 1,000,000 | rollapply uses 100,000 for large |

## apply

Period-based aggregation (last/first/mean/sum) over time series

| Benchmark | v0.3.7 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| monthly_first | 2.04 us | 2.04 us (~1.0x) |
| monthly_last | 2.12 us | 2.04 us (~1.0x) |
| monthly_mean | 2.54 us | 2.46 us (~1.0x) |
| monthly_sum | 2.38 us | 2.38 us (~1.0x) |
| weekly_last | 1.79 us | 1.79 us (~1.0x) |
| weekly_mean | 2.5 us | 2.46 us (~1.0x) |
| yearly_first | 1.5 us | 1.5 us (~1.0x) |
| **── medium ──** |  |  |
| monthly_first | 24.67 us | 24.67 us (~1.0x) |
| monthly_last | 25.0 us | 24.92 us (~1.0x) |
| monthly_mean | 34.04 us | 33.83 us (~1.0x) |
| monthly_sum | 31.58 us | 31.71 us (~1.0x) |
| weekly_last | 17.38 us | 17.5 us (~1.0x) |
| weekly_mean | 32.62 us | 32.79 us (~1.0x) |
| yearly_first | 11.12 us | **10.04 us (1.1x faster)** |
| **── large ──** |  |  |
| monthly_first | 936.62 us | 938.0 us (~1.0x) |
| monthly_last | 952.33 us | 957.21 us (~1.0x) |
| monthly_mean | 1.31 ms | 1.3 ms (~1.0x) |
| monthly_sum | 1.2 ms | 1.19 ms (~1.0x) |
| weekly_last | 627.12 us | 632.04 us (~1.0x) |
| weekly_mean | 1.29 ms | 1.28 ms (~1.0x) |
| yearly_first | 345.17 us | 343.21 us (~1.0x) |

## construction

TSFrame construction from various input types

| Benchmark | v0.3.7 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| from_dataframe_first_col | 7.71 us | 7.67 us (~1.0x) |
| from_dataframe_sorted_nocopy | 459.0 ns | 458.0 ns (~1.0x) |
| from_dataframe_with_index | 7.21 us | 7.25 us (~1.0x) |
| from_matrix_and_dates | 2.12 us | 2.08 us (~1.0x) |
| from_vector_and_dates | 2.25 us | **1.96 us (1.1x faster)** |
| **── medium ──** |  |  |
| from_dataframe_first_col | 54.75 us | 54.0 us (~1.0x) |
| from_dataframe_sorted_nocopy | 458.0 ns | _500.0 ns (1.1x slower)_ |
| from_dataframe_with_index | 53.33 us | 53.21 us (~1.0x) |
| from_matrix_and_dates | 21.83 us | 21.96 us (~1.0x) |
| from_vector_and_dates | 15.5 us | 15.62 us (~1.0x) |
| **── large ──** |  |  |
| from_dataframe_first_col | 2.2 ms | 2.21 ms (~1.0x) |
| from_dataframe_sorted_nocopy | 500.0 ns | **458.0 ns (1.1x faster)** |
| from_dataframe_with_index | 2.23 ms | 2.22 ms (~1.0x) |
| from_matrix_and_dates | 884.25 us | 890.75 us (~1.0x) |
| from_vector_and_dates | 645.62 us | 644.96 us (~1.0x) |

## endpoints

Finding period endpoints (last date of each week/month/quarter/year)

| Benchmark | v0.3.7 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| monthly | 916.0 ns | 916.0 ns (~1.0x) |
| quarterly | 667.0 ns | 666.0 ns (~1.0x) |
| symbol_months | 1.0 us | 1.0 us (~1.0x) |
| symbol_weeks | 500.0 ns | 500.0 ns (~1.0x) |
| weekly | 416.0 ns | 416.0 ns (~1.0x) |
| yearly | 416.0 ns | 417.0 ns (~1.0x) |
| **── medium ──** |  |  |
| monthly | 21.67 us | 21.67 us (~1.0x) |
| quarterly | 15.71 us | 15.04 us (~1.0x) |
| symbol_months | 21.83 us | 21.75 us (~1.0x) |
| symbol_weeks | 9.5 us | 9.62 us (~1.0x) |
| weekly | 9.38 us | 9.5 us (~1.0x) |
| yearly | 8.5 us | _9.67 us (1.1x slower)_ |
| **── large ──** |  |  |
| monthly | 860.33 us | 859.96 us (~1.0x) |
| quarterly | 596.38 us | 597.46 us (~1.0x) |
| symbol_months | 861.08 us | 859.04 us (~1.0x) |
| symbol_weeks | 372.0 us | 373.38 us (~1.0x) |
| weekly | 371.67 us | 373.92 us (~1.0x) |
| yearly | 335.71 us | 337.92 us (~1.0x) |

## getindex_period

| Benchmark | v0.3.7 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| range_slice | 4.62 us | 4.75 us (~1.0x) |
| scalar_dt | 1.83 us | 1.88 us (~1.0x) |
| year | 8.46 us | 8.38 us (~1.0x) |
| year_month | 8.38 us | 8.25 us (~1.0x) |
| year_month_day | 8.46 us | 8.25 us (~1.0x) |
| **── medium ──** |  |  |
| range_slice | 34.42 us | 34.54 us (~1.0x) |
| scalar_dt | 1.83 us | 1.83 us (~1.0x) |
| year | 64.88 us | 64.88 us (~1.0x) |
| year_month | 64.79 us | 64.67 us (~1.0x) |
| year_month_day | 11.67 us | 11.42 us (~1.0x) |
| **── large ──** |  |  |
| range_slice | 1.28 ms | 1.25 ms (~1.0x) |
| scalar_dt | 1.88 us | 1.88 us (~1.0x) |
| year | 1.34 ms | 1.34 ms (~1.0x) |
| year_month | 111.67 us | 112.62 us (~1.0x) |
| year_month_day | 11.62 us | 11.5 us (~1.0x) |

## join

Time-series join operations (inner/outer/left)

| Benchmark | v0.3.7 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| 3way_outer | 66.0 us | 64.96 us (~1.0x) |
| inner | 13.83 us | 13.79 us (~1.0x) |
| left | 18.58 us | 18.38 us (~1.0x) |
| outer | 23.96 us | 24.21 us (~1.0x) |
| **── medium ──** |  |  |
| 3way_outer | 1.09 ms | 1.1 ms (~1.0x) |
| inner | 94.75 us | 94.21 us (~1.0x) |
| left | 159.17 us | 159.21 us (~1.0x) |
| outer | 226.96 us | 226.33 us (~1.0x) |
| **── large ──** |  |  |
| 3way_outer | 81.91 ms | **77.37 ms (1.1x faster)** |
| inner | 3.53 ms | 3.43 ms (~1.0x) |
| left | 6.35 ms | **6.05 ms (1.1x faster)** |
| outer | 9.47 ms | **8.87 ms (1.1x faster)** |

## lag_lead_diff

Lag, lead, diff, and pctchange operations

| Benchmark | v0.3.7 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| diff_1 | 1.62 us | 1.62 us (~1.0x) |
| diff_5 | 1.62 us | **1.54 us (1.1x faster)** |
| lag_1 | 1.62 us | 1.58 us (~1.0x) |
| lag_5 | 1.67 us | 1.62 us (~1.0x) |
| lag_neg3 | 1.5 us | 1.54 us (~1.0x) |
| lead_1 | 1.5 us | 1.54 us (~1.0x) |
| lead_5 | 1.5 us | 1.5 us (~1.0x) |
| pctchange_1 | 10.46 us | 10.58 us (~1.0x) |
| pctchange_5 | 10.54 us | 10.79 us (~1.0x) |
| **── medium ──** |  |  |
| diff_1 | 15.58 us | 15.62 us (~1.0x) |
| diff_5 | 15.67 us | 15.67 us (~1.0x) |
| lag_1 | 14.46 us | 14.5 us (~1.0x) |
| lag_5 | 14.54 us | 14.54 us (~1.0x) |
| lag_neg3 | 12.83 us | 12.88 us (~1.0x) |
| lead_1 | 12.88 us | 12.88 us (~1.0x) |
| lead_5 | 12.92 us | 12.88 us (~1.0x) |
| pctchange_1 | 64.5 us | _80.5 us (1.2x slower)_ |
| pctchange_5 | 64.54 us | 65.21 us (~1.0x) |
| **── large ──** |  |  |
| diff_1 | 592.75 us | 597.92 us (~1.0x) |
| diff_5 | 595.83 us | 600.38 us (~1.0x) |
| lag_1 | 549.75 us | 554.75 us (~1.0x) |
| lag_5 | 554.29 us | 556.29 us (~1.0x) |
| lag_neg3 | 482.33 us | 497.33 us (~1.0x) |
| lead_1 | 485.71 us | 491.17 us (~1.0x) |
| lead_5 | 484.96 us | 491.33 us (~1.0x) |
| pctchange_1 | 2.63 ms | 2.63 ms (~1.0x) |
| pctchange_5 | 2.56 ms | 2.6 ms (~1.0x) |

## resample_fill_gaps

| Benchmark | v0.3.7 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| bfill | 3.29 us | 3.29 us (~1.0x) |
| ffill | 3.29 us | 3.29 us (~1.0x) |
| interpolate | 3.29 us | 3.25 us (~1.0x) |
| missing | 3.29 us | 3.29 us (~1.0x) |
| zero | 3.25 us | 3.29 us (~1.0x) |
| **── medium ──** |  |  |
| bfill | 62.21 us | 63.17 us (~1.0x) |
| ffill | 62.08 us | 63.54 us (~1.0x) |
| interpolate | 62.17 us | 63.46 us (~1.0x) |
| missing | 62.25 us | 63.54 us (~1.0x) |
| zero | 61.92 us | 63.38 us (~1.0x) |
| **── large ──** |  |  |
| bfill | 2.51 ms | 2.56 ms (~1.0x) |
| ffill | 2.51 ms | 2.56 ms (~1.0x) |
| interpolate | 2.5 ms | 2.56 ms (~1.0x) |
| missing | 2.53 ms | 2.57 ms (~1.0x) |
| zero | 2.49 ms | 2.55 ms (~1.0x) |

## resample_vs_to_period

Comparison of resample() vs to_period() for period-based aggregation

<table>
<thead>
<tr><th rowspan="2">Benchmark</th><th colspan="2">v0.3.7</th><th colspan="2">v0.3.8</th></tr>
<tr><th>to_period</th><th>resample</th><th>to_period</th><th>resample</th></tr>
</thead>
<tbody>
<tr><td colspan="5"><strong>── small ──</strong></td></tr>
<tr><td>weekly</td><td>1.33 us</td><td>1.38 us</td><td>1.38 us (~1.0x)</td><td>1.38 us (~1.0x)</td></tr>
<tr><td>monthly</td><td>1.71 us</td><td>1.67 us</td><td>1.75 us (~1.0x)</td><td>1.71 us (~1.0x)</td></tr>
<tr><td>quarterly</td><td>1.42 us</td><td>1.42 us</td><td><em>1.5 us (1.1x slower)</em></td><td>1.42 us (~1.0x)</td></tr>
<tr><td>yearly</td><td>1.21 us</td><td>1.17 us</td><td>1.21 us (~1.0x)</td><td>1.17 us (~1.0x)</td></tr>
<tr><td colspan="5"><strong>── medium ──</strong></td></tr>
<tr><td>weekly</td><td>17.0 us</td><td>16.67 us</td><td>17.04 us (~1.0x)</td><td>16.88 us (~1.0x)</td></tr>
<tr><td>monthly</td><td>24.21 us</td><td>24.29 us</td><td>24.21 us (~1.0x)</td><td>24.25 us (~1.0x)</td></tr>
<tr><td>quarterly</td><td>17.12 us</td><td>16.71 us</td><td>16.62 us (~1.0x)</td><td>16.79 us (~1.0x)</td></tr>
<tr><td>yearly</td><td>9.5 us</td><td>10.75 us</td><td>9.58 us (~1.0x)</td><td>10.67 us (~1.0x)</td></tr>
<tr><td colspan="5"><strong>── large ──</strong></td></tr>
<tr><td>weekly</td><td>649.12 us</td><td>628.08 us</td><td>653.96 us (~1.0x)</td><td>629.21 us (~1.0x)</td></tr>
<tr><td>monthly</td><td>946.62 us</td><td>959.54 us</td><td>943.21 us (~1.0x)</td><td>955.33 us (~1.0x)</td></tr>
<tr><td>quarterly</td><td>619.79 us</td><td>621.75 us</td><td>618.58 us (~1.0x)</td><td>620.71 us (~1.0x)</td></tr>
<tr><td>yearly</td><td>343.71 us</td><td>344.12 us</td><td>344.12 us (~1.0x)</td><td><em>389.62 us (1.1x slower)</em></td></tr>
</tbody>
</table>

### Additional resample benchmarks

| Benchmark | v0.3.7 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| resample_mean/monthly_mean | 2.12 us | 2.12 us (~1.0x) |
| resample_mean/weekly_mean | 2.04 us | 2.12 us (~1.0x) |
| resample_ohlcv/monthly_default | 2.71 us | 2.67 us (~1.0x) |
| resample_ohlcv/monthly_explicit | 2.92 us | **2.71 us (1.1x faster)** |
| resample_ohlcv/weekly_default | 2.75 us | 2.62 us (~1.0x) |
| **── medium ──** |  |  |
| resample_mean/monthly_mean | 33.12 us | 33.0 us (~1.0x) |
| resample_mean/weekly_mean | 32.33 us | 32.42 us (~1.0x) |
| resample_ohlcv/monthly_default | 36.33 us | 35.71 us (~1.0x) |
| resample_ohlcv/monthly_explicit | 36.54 us | 35.88 us (~1.0x) |
| resample_ohlcv/weekly_default | 36.71 us | 36.33 us (~1.0x) |
| **── large ──** |  |  |
| resample_mean/monthly_mean | 1.31 ms | 1.3 ms (~1.0x) |
| resample_mean/weekly_mean | 1.31 ms | 1.32 ms (~1.0x) |
| resample_ohlcv/monthly_default | 1.47 ms | 1.43 ms (~1.0x) |
| resample_ohlcv/monthly_explicit | 1.44 ms | 1.42 ms (~1.0x) |
| resample_ohlcv/weekly_default | 1.43 ms | 1.42 ms (~1.0x) |

## rollapply

Rolling window operations (mean/sum/std)

| Benchmark | v0.3.7 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| bycolumn_false_w5 | 1.82 ms | 1.82 ms (~1.0x) |
| mean_w5 | 16.0 us | 15.67 us (~1.0x) |
| std_w10 | 19.58 us | 19.71 us (~1.0x) |
| sum_w20 | 17.38 us | 17.04 us (~1.0x) |
| **── medium ──** |  |  |
| bycolumn_false_w5 | 49.79 ms | 49.21 ms (~1.0x) |
| mean_w5 | 335.12 us | 331.33 us (~1.0x) |
| std_w10 | 434.12 us | 429.42 us (~1.0x) |
| sum_w20 | 378.92 us | 377.25 us (~1.0x) |
| **── large ──** |  |  |
| bycolumn_false_w5 | 209.91 ms | 210.32 ms (~1.0x) |
| mean_w5 | 1.38 ms | 1.35 ms (~1.0x) |
| sum_w20 | 1.53 ms | 1.59 ms (~1.0x) |

## subset

| Benchmark | v0.3.7 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| date_both | 708.0 ns | _750.0 ns (1.1x slower)_ |
| date_left | 833.0 ns | 833.0 ns (~1.0x) |
| date_right | 791.0 ns | 791.0 ns (~1.0x) |
| int_both | 750.0 ns | **709.0 ns (1.1x faster)** |
| **── medium ──** |  |  |
| date_both | 3.0 us | 3.0 us (~1.0x) |
| date_left | 4.08 us | 4.17 us (~1.0x) |
| date_right | 4.0 us | 4.0 us (~1.0x) |
| int_both | 3.0 us | 3.04 us (~1.0x) |
| **── large ──** |  |  |
| date_both | 87.38 us | 87.79 us (~1.0x) |
| date_left | 132.96 us | 132.58 us (~1.0x) |
| date_right | 129.08 us | 130.25 us (~1.0x) |
| int_both | 88.0 us | 89.12 us (~1.0x) |

## upsample

| Benchmark | v0.3.7 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| hour12 | 541.0 ns | **500.0 ns (1.1x faster)** |
| hour6 | 1.12 us | **792.0 ns (1.4x faster)** |
| min30 | 5.54 us | 5.79 us (~1.0x) |
| **── medium ──** |  |  |
| hour12 | 1.62 us | _1.75 us (1.1x slower)_ |
| hour6 | 2.46 us | 2.5 us (~1.0x) |
| min30 | 23.62 us | 23.71 us (~1.0x) |
| **── large ──** |  |  |
| hour12 | 4.71 us | **4.46 us (1.1x faster)** |
| hour6 | 7.96 us | 7.92 us (~1.0x) |

## vcat

Vertical concatenation of TSFrame objects

| Benchmark | v0.3.7 | v0.3.8 |
|---|---|---|
| **── small ──** |  |  |
| diff_cols_intersect | 14.33 us | 14.33 us (~1.0x) |
| diff_cols_union | 32.88 us | 32.79 us (~1.0x) |
| same_cols_union | 19.62 us | 19.04 us (~1.0x) |
| **── medium ──** |  |  |
| diff_cols_intersect | 70.62 us | 70.71 us (~1.0x) |
| diff_cols_union | 163.75 us | 165.0 us (~1.0x) |
| same_cols_union | 99.21 us | 99.92 us (~1.0x) |
| **── large ──** |  |  |
| diff_cols_intersect | 2.91 ms | 2.91 ms (~1.0x) |
| diff_cols_union | 6.38 ms | 6.59 ms (~1.0x) |
| same_cols_union | 4.09 ms | 4.12 ms (~1.0x) |

