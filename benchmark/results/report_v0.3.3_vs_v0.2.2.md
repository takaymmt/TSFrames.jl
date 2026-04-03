# TSFrames.jl Benchmark Report

Generated: 2026-04-03 23:39:44

## Dataset Sizes

| Label | Rows | Notes |
|-------|------|-------|
| small | 1,000 | |
| medium | 25,000 | |
| large | 1,000,000 | rollapply uses 100,000 for large |

## apply

Period-based aggregation (last/first/mean/sum) over time series

| Benchmark | v0.2.2 | v0.3.3 |
|---|---|---|
| **── small ──** |  |  |
| monthly_first | 70.25 us | **2.04 us (34.4x faster)** |
| monthly_last | 71.58 us | **2.12 us (33.7x faster)** |
| monthly_mean | 73.92 us | **2.42 us (30.6x faster)** |
| monthly_sum | 72.67 us | **2.42 us (30.1x faster)** |
| weekly_last | 71.29 us | **1.79 us (39.8x faster)** |
| weekly_mean | 73.62 us | **2.42 us (30.5x faster)** |
| yearly_first | 70.92 us | **1.46 us (48.6x faster)** |
| **── medium ──** |  |  |
| monthly_first | 224.92 us | **24.92 us (9.0x faster)** |
| monthly_last | 225.25 us | **25.0 us (9.0x faster)** |
| monthly_mean | 333.29 us | **33.75 us (9.9x faster)** |
| monthly_sum | 345.17 us | **31.79 us (10.9x faster)** |
| weekly_last | 220.62 us | **17.96 us (12.3x faster)** |
| weekly_mean | 373.92 us | **33.08 us (11.3x faster)** |
| yearly_first | 193.96 us | **10.17 us (19.1x faster)** |
| **── large ──** |  |  |
| monthly_first | 8.1 ms | **934.25 us (8.7x faster)** |
| monthly_last | 8.34 ms | **946.67 us (8.8x faster)** |
| monthly_mean | 11.11 ms | **1.28 ms (8.7x faster)** |
| monthly_sum | 11.82 ms | **1.17 ms (10.1x faster)** |
| weekly_last | 5.96 ms | **632.54 us (9.4x faster)** |
| weekly_mean | 11.47 ms | **1.29 ms (8.9x faster)** |
| yearly_first | 5.62 ms | **343.46 us (16.4x faster)** |

## construction

TSFrame construction from various input types

| Benchmark | v0.2.2 | v0.3.3 |
|---|---|---|
| **── small ──** |  |  |
| from_dataframe_first_col | 7.58 us | 7.42 us (~1.0x) |
| from_dataframe_sorted_nocopy | 459.0 ns | 458.0 ns (~1.0x) |
| from_dataframe_with_index | 7.25 us | 7.08 us (~1.0x) |
| from_matrix_and_dates | 2.29 us | **2.04 us (1.1x faster)** |
| from_vector_and_dates | 1.29 us | _1.38 us (1.1x slower)_ |
| **── medium ──** |  |  |
| from_dataframe_first_col | 56.46 us | 55.04 us (~1.0x) |
| from_dataframe_sorted_nocopy | 500.0 ns | **458.0 ns (1.1x faster)** |
| from_dataframe_with_index | 55.92 us | 54.88 us (~1.0x) |
| from_matrix_and_dates | 23.79 us | 23.04 us (~1.0x) |
| from_vector_and_dates | 16.58 us | 16.0 us (~1.0x) |
| **── large ──** |  |  |
| from_dataframe_first_col | 2.32 ms | 2.21 ms (~1.0x) |
| from_dataframe_sorted_nocopy | 500.0 ns | 500.0 ns (~1.0x) |
| from_dataframe_with_index | 2.34 ms | **2.21 ms (1.1x faster)** |
| from_matrix_and_dates | 963.04 us | **897.62 us (1.1x faster)** |
| from_vector_and_dates | 692.5 us | **649.12 us (1.1x faster)** |

## endpoints

Finding period endpoints (last date of each week/month/quarter/year)

| Benchmark | v0.2.2 | v0.3.3 |
|---|---|---|
| **── small ──** |  |  |
| monthly | 1.0 us | **916.0 ns (1.1x faster)** |
| quarterly | 666.0 ns | **625.0 ns (1.1x faster)** |
| symbol_months | 958.0 ns | 1.0 us (~1.0x) |
| symbol_weeks | 416.0 ns | _500.0 ns (1.2x slower)_ |
| weekly | 416.0 ns | 416.0 ns (~1.0x) |
| yearly | 458.0 ns | **375.0 ns (1.2x faster)** |
| **── medium ──** |  |  |
| monthly | 22.5 us | 21.75 us (~1.0x) |
| quarterly | 16.33 us | **15.29 us (1.1x faster)** |
| symbol_months | 22.38 us | 21.79 us (~1.0x) |
| symbol_weeks | 10.83 us | **9.75 us (1.1x faster)** |
| weekly | 11.04 us | **9.58 us (1.2x faster)** |
| yearly | 8.83 us | 8.67 us (~1.0x) |
| **── large ──** |  |  |
| monthly | 884.17 us | 855.17 us (~1.0x) |
| quarterly | 621.08 us | **590.25 us (1.1x faster)** |
| symbol_months | 883.04 us | 855.83 us (~1.0x) |
| symbol_weeks | 398.71 us | **373.38 us (1.1x faster)** |
| weekly | 385.17 us | 373.04 us (~1.0x) |
| yearly | 343.54 us | 336.33 us (~1.0x) |

## join

Time-series join operations (inner/outer/left)

| Benchmark | v0.2.2 | v0.3.3 |
|---|---|---|
| **── small ──** |  |  |
| inner | 15.29 us | **14.08 us (1.1x faster)** |
| left | 19.71 us | **18.42 us (1.1x faster)** |
| outer | 25.38 us | **23.88 us (1.1x faster)** |
| **── medium ──** |  |  |
| inner | 99.29 us | 96.29 us (~1.0x) |
| left | 165.33 us | 161.08 us (~1.0x) |
| outer | 235.79 us | 229.5 us (~1.0x) |
| **── large ──** |  |  |
| inner | 3.52 ms | 3.42 ms (~1.0x) |
| left | 6.52 ms | 6.23 ms (~1.0x) |
| outer | 9.51 ms | 9.46 ms (~1.0x) |

## lag_lead_diff

Lag, lead, diff, and pctchange operations

| Benchmark | v0.2.2 | v0.3.3 |
|---|---|---|
| **── small ──** |  |  |
| diff_1 | 29.62 us | **15.5 us (1.9x faster)** |
| diff_5 | 30.88 us | **15.71 us (2.0x faster)** |
| lag_1 | 11.21 us | **3.83 us (2.9x faster)** |
| lag_5 | 11.33 us | **3.83 us (3.0x faster)** |
| lead_1 | 11.17 us | **3.79 us (2.9x faster)** |
| lead_5 | 11.25 us | **3.88 us (2.9x faster)** |
| pctchange_1 | 47.08 us | **16.54 us (2.8x faster)** |
| pctchange_5 | 46.5 us | **16.62 us (2.8x faster)** |
| **── medium ──** |  |  |
| diff_1 | 256.71 us | **102.71 us (2.5x faster)** |
| diff_5 | 255.33 us | **102.21 us (2.5x faster)** |
| lag_1 | 105.38 us | **40.38 us (2.6x faster)** |
| lag_5 | 105.79 us | **40.38 us (2.6x faster)** |
| lead_1 | 104.67 us | **40.25 us (2.6x faster)** |
| lead_5 | 105.42 us | **40.21 us (2.6x faster)** |
| pctchange_1 | 401.21 us | **135.29 us (3.0x faster)** |
| pctchange_5 | 405.25 us | **135.92 us (3.0x faster)** |
| **── large ──** |  |  |
| diff_1 | 10.6 ms | **4.58 ms (2.3x faster)** |
| diff_5 | 10.78 ms | **4.13 ms (2.6x faster)** |
| lag_1 | 4.55 ms | **1.6 ms (2.8x faster)** |
| lag_5 | 4.44 ms | **1.62 ms (2.7x faster)** |
| lead_1 | 4.45 ms | **1.66 ms (2.7x faster)** |
| lead_5 | 4.44 ms | **1.63 ms (2.7x faster)** |
| pctchange_1 | 17.46 ms | **5.62 ms (3.1x faster)** |
| pctchange_5 | 17.81 ms | **5.66 ms (3.1x faster)** |

## resample_vs_to_period

Comparison of resample() vs to_period() for period-based aggregation

<table>
<thead>
<tr><th rowspan="2">Benchmark</th><th colspan="2">v0.2.2</th><th colspan="2">v0.3.3</th></tr>
<tr><th>to_period</th><th>resample</th><th>to_period</th><th>resample</th></tr>
</thead>
<tbody>
<tr><td colspan="5"><strong>── small ──</strong></td></tr>
<tr><td>weekly</td><td>3.62 us</td><td></td><td><strong>1.38 us (2.6x faster)</strong></td><td>1.33 us</td></tr>
<tr><td>monthly</td><td>3.71 us</td><td></td><td><strong>1.71 us (2.2x faster)</strong></td><td>1.71 us</td></tr>
<tr><td>quarterly</td><td>3.33 us</td><td></td><td><strong>1.42 us (2.4x faster)</strong></td><td>1.46 us</td></tr>
<tr><td>yearly</td><td>2.83 us</td><td></td><td><strong>1.12 us (2.5x faster)</strong></td><td>1.12 us</td></tr>
<tr><td colspan="5"><strong>── medium ──</strong></td></tr>
<tr><td>weekly</td><td>40.71 us</td><td></td><td><strong>17.17 us (2.4x faster)</strong></td><td>16.88 us</td></tr>
<tr><td>monthly</td><td>31.25 us</td><td></td><td><strong>24.21 us (1.3x faster)</strong></td><td>24.33 us</td></tr>
<tr><td>quarterly</td><td>21.08 us</td><td></td><td><strong>16.71 us (1.3x faster)</strong></td><td>16.79 us</td></tr>
<tr><td>yearly</td><td>11.96 us</td><td></td><td><strong>9.62 us (1.2x faster)</strong></td><td>9.71 us</td></tr>
<tr><td colspan="5"><strong>── large ──</strong></td></tr>
<tr><td>weekly</td><td>1.0 ms</td><td></td><td><strong>649.92 us (1.5x faster)</strong></td><td>635.71 us</td></tr>
<tr><td>monthly</td><td>1.06 ms</td><td></td><td><strong>938.46 us (1.1x faster)</strong></td><td>949.0 us</td></tr>
<tr><td>quarterly</td><td>675.33 us</td><td></td><td><strong>619.5 us (1.1x faster)</strong></td><td>616.12 us</td></tr>
<tr><td>yearly</td><td>368.79 us</td><td></td><td><strong>344.54 us (1.1x faster)</strong></td><td>344.46 us</td></tr>
</tbody>
</table>

### Additional resample benchmarks

| Benchmark | v0.2.2 | v0.3.3 |
|---|---|---|
| **── small ──** |  |  |
| resample_mean/monthly_mean | N/A | 2.04 us |
| resample_mean/weekly_mean | N/A | 2.04 us |
| resample_ohlcv/monthly_default | N/A | 2.58 us |
| resample_ohlcv/monthly_explicit | N/A | 2.79 us |
| resample_ohlcv/weekly_default | N/A | 2.71 us |
| **── medium ──** |  |  |
| resample_mean/monthly_mean | N/A | 33.04 us |
| resample_mean/weekly_mean | N/A | 32.12 us |
| resample_ohlcv/monthly_default | N/A | 36.0 us |
| resample_ohlcv/monthly_explicit | N/A | 35.79 us |
| resample_ohlcv/weekly_default | N/A | 37.0 us |
| **── large ──** |  |  |
| resample_mean/monthly_mean | N/A | 1.28 ms |
| resample_mean/weekly_mean | N/A | 1.26 ms |
| resample_ohlcv/monthly_default | N/A | 1.42 ms |
| resample_ohlcv/monthly_explicit | N/A | 1.41 ms |
| resample_ohlcv/weekly_default | N/A | 1.43 ms |

## rollapply

Rolling window operations (mean/sum/std)

| Benchmark | v0.2.2 | v0.3.3 |
|---|---|---|
| **── small ──** |  |  |
| mean_w5 | 6.96 ms | **6.13 ms (1.1x faster)** |
| std_w10 | 6.95 ms | **6.14 ms (1.1x faster)** |
| sum_w20 | 6.88 ms | **6.09 ms (1.1x faster)** |
| **── medium ──** |  |  |
| mean_w5 | 253.0 ms | **170.15 ms (1.5x faster)** |
| std_w10 | 252.72 ms | **172.57 ms (1.5x faster)** |
| sum_w20 | 256.43 ms | **175.89 ms (1.5x faster)** |
| **── large ──** |  |  |
| mean_w5 | 2.04 s | **763.8 ms (2.7x faster)** |
| sum_w20 | 2.04 s | **839.24 ms (2.4x faster)** |

## vcat

Vertical concatenation of TSFrame objects

| Benchmark | v0.2.2 | v0.3.3 |
|---|---|---|
| **── small ──** |  |  |
| diff_cols_intersect | N/A | 14.38 us |
| diff_cols_union | 33.25 us | 33.08 us (~1.0x) |
| same_cols_union | 19.75 us | 19.88 us (~1.0x) |
| **── medium ──** |  |  |
| diff_cols_intersect | N/A | 71.54 us |
| diff_cols_union | 173.42 us | 167.5 us (~1.0x) |
| same_cols_union | 104.33 us | 101.58 us (~1.0x) |
| **── large ──** |  |  |
| diff_cols_intersect | N/A | 2.96 ms |
| diff_cols_union | 6.85 ms | 6.79 ms (~1.0x) |
| same_cols_union | 4.37 ms | 4.18 ms (~1.0x) |

