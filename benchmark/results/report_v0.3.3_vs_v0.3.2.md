# TSFrames.jl Benchmark Report

Generated: 2026-04-03 23:39:46

## Dataset Sizes

| Label | Rows | Notes |
|-------|------|-------|
| small | 1,000 | |
| medium | 25,000 | |
| large | 1,000,000 | rollapply uses 100,000 for large |

## apply

Period-based aggregation (last/first/mean/sum) over time series

| Benchmark | v0.3.2 | v0.3.3 |
|---|---|---|
| **── small ──** |  |  |
| monthly_first | 2.08 us | 2.04 us (~1.0x) |
| monthly_last | 2.21 us | 2.12 us (~1.0x) |
| monthly_mean | 2.62 us | **2.42 us (1.1x faster)** |
| monthly_sum | 2.5 us | 2.42 us (~1.0x) |
| weekly_last | 1.83 us | 1.79 us (~1.0x) |
| weekly_mean | 2.58 us | **2.42 us (1.1x faster)** |
| yearly_first | 1.54 us | **1.46 us (1.1x faster)** |
| **── medium ──** |  |  |
| monthly_first | 25.5 us | 24.92 us (~1.0x) |
| monthly_last | 25.79 us | 25.0 us (~1.0x) |
| monthly_mean | 35.42 us | 33.75 us (~1.0x) |
| monthly_sum | 32.5 us | 31.79 us (~1.0x) |
| weekly_last | 18.33 us | 17.96 us (~1.0x) |
| weekly_mean | 34.42 us | 33.08 us (~1.0x) |
| yearly_first | 10.42 us | 10.17 us (~1.0x) |
| **── large ──** |  |  |
| monthly_first | 972.29 us | 934.25 us (~1.0x) |
| monthly_last | 993.46 us | 946.67 us (~1.0x) |
| monthly_mean | 1.37 ms | **1.28 ms (1.1x faster)** |
| monthly_sum | 1.23 ms | 1.17 ms (~1.0x) |
| weekly_last | 656.88 us | 632.54 us (~1.0x) |
| weekly_mean | 1.34 ms | 1.29 ms (~1.0x) |
| yearly_first | 350.79 us | 343.46 us (~1.0x) |

## construction

TSFrame construction from various input types

| Benchmark | v0.3.2 | v0.3.3 |
|---|---|---|
| **── small ──** |  |  |
| from_dataframe_first_col | 7.92 us | **7.42 us (1.1x faster)** |
| from_dataframe_sorted_nocopy | 500.0 ns | **458.0 ns (1.1x faster)** |
| from_dataframe_with_index | 7.25 us | 7.08 us (~1.0x) |
| from_matrix_and_dates | 2.29 us | **2.04 us (1.1x faster)** |
| from_vector_and_dates | 1.5 us | **1.38 us (1.1x faster)** |
| **── medium ──** |  |  |
| from_dataframe_first_col | 58.21 us | **55.04 us (1.1x faster)** |
| from_dataframe_sorted_nocopy | 500.0 ns | **458.0 ns (1.1x faster)** |
| from_dataframe_with_index | 56.12 us | 54.88 us (~1.0x) |
| from_matrix_and_dates | 23.5 us | 23.04 us (~1.0x) |
| from_vector_and_dates | 16.33 us | 16.0 us (~1.0x) |
| **── large ──** |  |  |
| from_dataframe_first_col | 2.36 ms | **2.21 ms (1.1x faster)** |
| from_dataframe_sorted_nocopy | 500.0 ns | 500.0 ns (~1.0x) |
| from_dataframe_with_index | 2.36 ms | **2.21 ms (1.1x faster)** |
| from_matrix_and_dates | 928.54 us | 897.62 us (~1.0x) |
| from_vector_and_dates | 664.96 us | 649.12 us (~1.0x) |

## endpoints

Finding period endpoints (last date of each week/month/quarter/year)

| Benchmark | v0.3.2 | v0.3.3 |
|---|---|---|
| **── small ──** |  |  |
| monthly | 1.04 us | **916.0 ns (1.1x faster)** |
| quarterly | 708.0 ns | **625.0 ns (1.1x faster)** |
| symbol_months | 1.04 us | 1.0 us (~1.0x) |
| symbol_weeks | 541.0 ns | **500.0 ns (1.1x faster)** |
| weekly | 458.0 ns | **416.0 ns (1.1x faster)** |
| yearly | 458.0 ns | **375.0 ns (1.2x faster)** |
| **── medium ──** |  |  |
| monthly | 22.42 us | 21.75 us (~1.0x) |
| quarterly | 15.88 us | 15.29 us (~1.0x) |
| symbol_months | 22.42 us | 21.79 us (~1.0x) |
| symbol_weeks | 10.17 us | 9.75 us (~1.0x) |
| weekly | 9.96 us | 9.58 us (~1.0x) |
| yearly | 8.83 us | 8.67 us (~1.0x) |
| **── large ──** |  |  |
| monthly | 882.67 us | 855.17 us (~1.0x) |
| quarterly | 623.12 us | **590.25 us (1.1x faster)** |
| symbol_months | 862.08 us | 855.83 us (~1.0x) |
| symbol_weeks | 377.12 us | 373.38 us (~1.0x) |
| weekly | 395.62 us | **373.04 us (1.1x faster)** |
| yearly | 337.0 us | 336.33 us (~1.0x) |

## join

Time-series join operations (inner/outer/left)

| Benchmark | v0.3.2 | v0.3.3 |
|---|---|---|
| **── small ──** |  |  |
| inner | 14.5 us | 14.08 us (~1.0x) |
| left | 18.71 us | 18.42 us (~1.0x) |
| outer | 24.33 us | 23.88 us (~1.0x) |
| **── medium ──** |  |  |
| inner | 98.42 us | 96.29 us (~1.0x) |
| left | 164.62 us | 161.08 us (~1.0x) |
| outer | 234.71 us | 229.5 us (~1.0x) |
| **── large ──** |  |  |
| inner | 3.52 ms | 3.42 ms (~1.0x) |
| left | 6.39 ms | 6.23 ms (~1.0x) |
| outer | 9.78 ms | 9.46 ms (~1.0x) |

## lag_lead_diff

Lag, lead, diff, and pctchange operations

| Benchmark | v0.3.2 | v0.3.3 |
|---|---|---|
| **── small ──** |  |  |
| diff_1 | 16.04 us | 15.5 us (~1.0x) |
| diff_5 | 15.75 us | 15.71 us (~1.0x) |
| lag_1 | 3.92 us | 3.83 us (~1.0x) |
| lag_5 | 4.04 us | **3.83 us (1.1x faster)** |
| lead_1 | 3.92 us | 3.79 us (~1.0x) |
| lead_5 | 3.92 us | 3.88 us (~1.0x) |
| pctchange_1 | 16.96 us | 16.54 us (~1.0x) |
| pctchange_5 | 17.04 us | 16.62 us (~1.0x) |
| **── medium ──** |  |  |
| diff_1 | 112.17 us | **102.71 us (1.1x faster)** |
| diff_5 | 108.75 us | **102.21 us (1.1x faster)** |
| lag_1 | 41.38 us | 40.38 us (~1.0x) |
| lag_5 | 41.42 us | 40.38 us (~1.0x) |
| lead_1 | 41.33 us | 40.25 us (~1.0x) |
| lead_5 | 41.21 us | 40.21 us (~1.0x) |
| pctchange_1 | 135.0 us | 135.29 us (~1.0x) |
| pctchange_5 | 139.42 us | 135.92 us (~1.0x) |
| **── large ──** |  |  |
| diff_1 | 4.92 ms | **4.58 ms (1.1x faster)** |
| diff_5 | 4.67 ms | **4.13 ms (1.1x faster)** |
| lag_1 | 1.74 ms | **1.6 ms (1.1x faster)** |
| lag_5 | 1.72 ms | **1.62 ms (1.1x faster)** |
| lead_1 | 1.68 ms | 1.66 ms (~1.0x) |
| lead_5 | 1.69 ms | 1.63 ms (~1.0x) |
| pctchange_1 | 5.84 ms | 5.62 ms (~1.0x) |
| pctchange_5 | 5.79 ms | 5.66 ms (~1.0x) |

## resample_vs_to_period

Comparison of resample() vs to_period() for period-based aggregation

<table>
<thead>
<tr><th rowspan="2">Benchmark</th><th colspan="2">v0.3.2</th><th colspan="2">v0.3.3</th></tr>
<tr><th>to_period</th><th>resample</th><th>to_period</th><th>resample</th></tr>
</thead>
<tbody>
<tr><td colspan="5"><strong>── small ──</strong></td></tr>
<tr><td>weekly</td><td>1.38 us</td><td>1.42 us</td><td>1.38 us (~1.0x)</td><td><strong>1.33 us (1.1x faster)</strong></td></tr>
<tr><td>monthly</td><td>1.75 us</td><td>1.75 us</td><td>1.71 us (~1.0x)</td><td>1.71 us (~1.0x)</td></tr>
<tr><td>quarterly</td><td>1.5 us</td><td>1.5 us</td><td><strong>1.42 us (1.1x faster)</strong></td><td>1.46 us (~1.0x)</td></tr>
<tr><td>yearly</td><td>1.17 us</td><td>1.12 us</td><td>1.12 us (~1.0x)</td><td>1.12 us (~1.0x)</td></tr>
<tr><td colspan="5"><strong>── medium ──</strong></td></tr>
<tr><td>weekly</td><td>18.04 us</td><td>17.71 us</td><td><strong>17.17 us (1.1x faster)</strong></td><td>16.88 us (~1.0x)</td></tr>
<tr><td>monthly</td><td>25.0 us</td><td>25.17 us</td><td>24.21 us (~1.0x)</td><td>24.33 us (~1.0x)</td></tr>
<tr><td>quarterly</td><td>17.29 us</td><td>17.46 us</td><td>16.71 us (~1.0x)</td><td>16.79 us (~1.0x)</td></tr>
<tr><td>yearly</td><td>9.88 us</td><td>9.92 us</td><td>9.62 us (~1.0x)</td><td>9.71 us (~1.0x)</td></tr>
<tr><td colspan="5"><strong>── large ──</strong></td></tr>
<tr><td>weekly</td><td>694.33 us</td><td>668.46 us</td><td><strong>649.92 us (1.1x faster)</strong></td><td><strong>635.71 us (1.1x faster)</strong></td></tr>
<tr><td>monthly</td><td>982.12 us</td><td>988.88 us</td><td>938.46 us (~1.0x)</td><td>949.0 us (~1.0x)</td></tr>
<tr><td>quarterly</td><td>646.5 us</td><td>643.33 us</td><td>619.5 us (~1.0x)</td><td>616.12 us (~1.0x)</td></tr>
<tr><td>yearly</td><td>350.67 us</td><td>350.83 us</td><td>344.54 us (~1.0x)</td><td>344.46 us (~1.0x)</td></tr>
</tbody>
</table>

### Additional resample benchmarks

| Benchmark | v0.3.2 | v0.3.3 |
|---|---|---|
| **── small ──** |  |  |
| resample_mean/monthly_mean | 2.38 us | **2.04 us (1.2x faster)** |
| resample_mean/weekly_mean | 2.12 us | 2.04 us (~1.0x) |
| resample_ohlcv/monthly_default | 2.71 us | 2.58 us (~1.0x) |
| resample_ohlcv/monthly_explicit | 2.79 us | 2.79 us (~1.0x) |
| resample_ohlcv/weekly_default | 2.75 us | 2.71 us (~1.0x) |
| **── medium ──** |  |  |
| resample_mean/monthly_mean | 34.17 us | 33.04 us (~1.0x) |
| resample_mean/weekly_mean | 33.75 us | **32.12 us (1.1x faster)** |
| resample_ohlcv/monthly_default | 37.33 us | 36.0 us (~1.0x) |
| resample_ohlcv/monthly_explicit | 37.54 us | 35.79 us (~1.0x) |
| resample_ohlcv/weekly_default | 37.92 us | 37.0 us (~1.0x) |
| **── large ──** |  |  |
| resample_mean/monthly_mean | 1.35 ms | **1.28 ms (1.1x faster)** |
| resample_mean/weekly_mean | 1.35 ms | **1.26 ms (1.1x faster)** |
| resample_ohlcv/monthly_default | 1.53 ms | **1.42 ms (1.1x faster)** |
| resample_ohlcv/monthly_explicit | 1.51 ms | **1.41 ms (1.1x faster)** |
| resample_ohlcv/weekly_default | 1.5 ms | **1.43 ms (1.1x faster)** |

## rollapply

Rolling window operations (mean/sum/std)

| Benchmark | v0.3.2 | v0.3.3 |
|---|---|---|
| **── small ──** |  |  |
| mean_w5 | 6.68 ms | **6.13 ms (1.1x faster)** |
| std_w10 | 6.57 ms | **6.14 ms (1.1x faster)** |
| sum_w20 | 6.48 ms | **6.09 ms (1.1x faster)** |
| **── medium ──** |  |  |
| mean_w5 | 177.76 ms | 170.15 ms (~1.0x) |
| std_w10 | 177.74 ms | 172.57 ms (~1.0x) |
| sum_w20 | 183.3 ms | 175.89 ms (~1.0x) |
| **── large ──** |  |  |
| mean_w5 | 845.66 ms | **763.8 ms (1.1x faster)** |
| sum_w20 | 879.52 ms | 839.24 ms (~1.0x) |

## vcat

Vertical concatenation of TSFrame objects

| Benchmark | v0.3.2 | v0.3.3 |
|---|---|---|
| **── small ──** |  |  |
| diff_cols_intersect | 14.88 us | 14.38 us (~1.0x) |
| diff_cols_union | 35.12 us | **33.08 us (1.1x faster)** |
| same_cols_union | 20.38 us | 19.88 us (~1.0x) |
| **── medium ──** |  |  |
| diff_cols_intersect | 74.79 us | 71.54 us (~1.0x) |
| diff_cols_union | 172.88 us | 167.5 us (~1.0x) |
| same_cols_union | 104.58 us | 101.58 us (~1.0x) |
| **── large ──** |  |  |
| diff_cols_intersect | 3.12 ms | **2.96 ms (1.1x faster)** |
| diff_cols_union | 6.87 ms | 6.79 ms (~1.0x) |
| same_cols_union | 4.37 ms | 4.18 ms (~1.0x) |

