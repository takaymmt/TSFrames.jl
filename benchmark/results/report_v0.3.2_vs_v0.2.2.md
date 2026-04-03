# TSFrames.jl Benchmark Report

Generated: 2026-04-03 14:07:33

## Dataset Sizes

| Label | Rows | Notes |
|-------|------|-------|
| small | 1,000 | |
| medium | 25,000 | |
| large | 1,000,000 | rollapply uses 100,000 for large |

## apply

Period-based aggregation (last/first/mean/sum) over time series

| Benchmark | v0.2.2 | v0.3.2 |
|---|---|---|
| **── small ──** |  |  |
| monthly_first | 70.25 us | **2.08 us (33.7x faster)** |
| monthly_last | 71.58 us | **2.21 us (32.4x faster)** |
| monthly_mean | 73.92 us | **2.62 us (28.2x faster)** |
| monthly_sum | 72.67 us | **2.5 us (29.1x faster)** |
| weekly_last | 71.29 us | **1.83 us (38.9x faster)** |
| weekly_mean | 73.62 us | **2.58 us (28.5x faster)** |
| yearly_first | 70.92 us | **1.54 us (46.0x faster)** |
| **── medium ──** |  |  |
| monthly_first | 224.92 us | **25.5 us (8.8x faster)** |
| monthly_last | 225.25 us | **25.79 us (8.7x faster)** |
| monthly_mean | 333.29 us | **35.42 us (9.4x faster)** |
| monthly_sum | 345.17 us | **32.5 us (10.6x faster)** |
| weekly_last | 220.62 us | **18.33 us (12.0x faster)** |
| weekly_mean | 373.92 us | **34.42 us (10.9x faster)** |
| yearly_first | 193.96 us | **10.42 us (18.6x faster)** |
| **── large ──** |  |  |
| monthly_first | 8.1 ms | **972.29 us (8.3x faster)** |
| monthly_last | 8.34 ms | **993.46 us (8.4x faster)** |
| monthly_mean | 11.11 ms | **1.37 ms (8.1x faster)** |
| monthly_sum | 11.82 ms | **1.23 ms (9.6x faster)** |
| weekly_last | 5.96 ms | **656.88 us (9.1x faster)** |
| weekly_mean | 11.47 ms | **1.34 ms (8.6x faster)** |
| yearly_first | 5.62 ms | **350.79 us (16.0x faster)** |

## construction

TSFrame construction from various input types

| Benchmark | v0.2.2 | v0.3.2 |
|---|---|---|
| **── small ──** |  |  |
| from_dataframe_first_col | 7.58 us | 7.92 us (~1.0x) |
| from_dataframe_sorted_nocopy | 459.0 ns | _500.0 ns (1.1x slower)_ |
| from_dataframe_with_index | 7.25 us | 7.25 us (~1.0x) |
| from_matrix_and_dates | 2.29 us | 2.29 us (~1.0x) |
| from_vector_and_dates | 1.29 us | _1.5 us (1.2x slower)_ |
| **── medium ──** |  |  |
| from_dataframe_first_col | 56.46 us | 58.21 us (~1.0x) |
| from_dataframe_sorted_nocopy | 500.0 ns | 500.0 ns (~1.0x) |
| from_dataframe_with_index | 55.92 us | 56.12 us (~1.0x) |
| from_matrix_and_dates | 23.79 us | 23.5 us (~1.0x) |
| from_vector_and_dates | 16.58 us | 16.33 us (~1.0x) |
| **── large ──** |  |  |
| from_dataframe_first_col | 2.32 ms | 2.36 ms (~1.0x) |
| from_dataframe_sorted_nocopy | 500.0 ns | 500.0 ns (~1.0x) |
| from_dataframe_with_index | 2.34 ms | 2.36 ms (~1.0x) |
| from_matrix_and_dates | 963.04 us | 928.54 us (~1.0x) |
| from_vector_and_dates | 692.5 us | 664.96 us (~1.0x) |

## endpoints

Finding period endpoints (last date of each week/month/quarter/year)

| Benchmark | v0.2.2 | v0.3.2 |
|---|---|---|
| **── small ──** |  |  |
| monthly | 1.0 us | 1.04 us (~1.0x) |
| quarterly | 666.0 ns | _708.0 ns (1.1x slower)_ |
| symbol_months | 958.0 ns | _1.04 us (1.1x slower)_ |
| symbol_weeks | 416.0 ns | _541.0 ns (1.3x slower)_ |
| weekly | 416.0 ns | _458.0 ns (1.1x slower)_ |
| yearly | 458.0 ns | 458.0 ns (~1.0x) |
| **── medium ──** |  |  |
| monthly | 22.5 us | 22.42 us (~1.0x) |
| quarterly | 16.33 us | 15.88 us (~1.0x) |
| symbol_months | 22.38 us | 22.42 us (~1.0x) |
| symbol_weeks | 10.83 us | **10.17 us (1.1x faster)** |
| weekly | 11.04 us | **9.96 us (1.1x faster)** |
| yearly | 8.83 us | 8.83 us (~1.0x) |
| **── large ──** |  |  |
| monthly | 884.17 us | 882.67 us (~1.0x) |
| quarterly | 621.08 us | 623.12 us (~1.0x) |
| symbol_months | 883.04 us | 862.08 us (~1.0x) |
| symbol_weeks | 398.71 us | **377.12 us (1.1x faster)** |
| weekly | 385.17 us | 395.62 us (~1.0x) |
| yearly | 343.54 us | 337.0 us (~1.0x) |

## join

Time-series join operations (inner/outer/left)

| Benchmark | v0.2.2 | v0.3.2 |
|---|---|---|
| **── small ──** |  |  |
| inner | 15.29 us | **14.5 us (1.1x faster)** |
| left | 19.71 us | **18.71 us (1.1x faster)** |
| outer | 25.38 us | 24.33 us (~1.0x) |
| **── medium ──** |  |  |
| inner | 99.29 us | 98.42 us (~1.0x) |
| left | 165.33 us | 164.62 us (~1.0x) |
| outer | 235.79 us | 234.71 us (~1.0x) |
| **── large ──** |  |  |
| inner | 3.52 ms | 3.52 ms (~1.0x) |
| left | 6.52 ms | 6.39 ms (~1.0x) |
| outer | 9.51 ms | 9.78 ms (~1.0x) |

## lag_lead_diff

Lag, lead, diff, and pctchange operations

| Benchmark | v0.2.2 | v0.3.2 |
|---|---|---|
| **── small ──** |  |  |
| diff_1 | 29.62 us | **16.04 us (1.8x faster)** |
| diff_5 | 30.88 us | **15.75 us (2.0x faster)** |
| lag_1 | 11.21 us | **3.92 us (2.9x faster)** |
| lag_5 | 11.33 us | **4.04 us (2.8x faster)** |
| lead_1 | 11.17 us | **3.92 us (2.9x faster)** |
| lead_5 | 11.25 us | **3.92 us (2.9x faster)** |
| pctchange_1 | 47.08 us | **16.96 us (2.8x faster)** |
| pctchange_5 | 46.5 us | **17.04 us (2.7x faster)** |
| **── medium ──** |  |  |
| diff_1 | 256.71 us | **112.17 us (2.3x faster)** |
| diff_5 | 255.33 us | **108.75 us (2.3x faster)** |
| lag_1 | 105.38 us | **41.38 us (2.5x faster)** |
| lag_5 | 105.79 us | **41.42 us (2.6x faster)** |
| lead_1 | 104.67 us | **41.33 us (2.5x faster)** |
| lead_5 | 105.42 us | **41.21 us (2.6x faster)** |
| pctchange_1 | 401.21 us | **135.0 us (3.0x faster)** |
| pctchange_5 | 405.25 us | **139.42 us (2.9x faster)** |
| **── large ──** |  |  |
| diff_1 | 10.6 ms | **4.92 ms (2.2x faster)** |
| diff_5 | 10.78 ms | **4.67 ms (2.3x faster)** |
| lag_1 | 4.55 ms | **1.74 ms (2.6x faster)** |
| lag_5 | 4.44 ms | **1.72 ms (2.6x faster)** |
| lead_1 | 4.45 ms | **1.68 ms (2.6x faster)** |
| lead_5 | 4.44 ms | **1.69 ms (2.6x faster)** |
| pctchange_1 | 17.46 ms | **5.84 ms (3.0x faster)** |
| pctchange_5 | 17.81 ms | **5.79 ms (3.1x faster)** |

## resample_vs_to_period

Comparison of resample() vs to_period() for period-based aggregation

<table>
<thead>
<tr><th rowspan="2">Benchmark</th><th colspan="2">v0.2.2</th><th colspan="2">v0.3.2</th></tr>
<tr><th>to_period</th><th>resample</th><th>to_period</th><th>resample</th></tr>
</thead>
<tbody>
<tr><td colspan="5"><strong>── small ──</strong></td></tr>
<tr><td>weekly</td><td>3.62 us</td><td></td><td><strong>1.38 us (2.6x faster)</strong></td><td>1.42 us</td></tr>
<tr><td>monthly</td><td>3.71 us</td><td></td><td><strong>1.75 us (2.1x faster)</strong></td><td>1.75 us</td></tr>
<tr><td>quarterly</td><td>3.33 us</td><td></td><td><strong>1.5 us (2.2x faster)</strong></td><td>1.5 us</td></tr>
<tr><td>yearly</td><td>2.83 us</td><td></td><td><strong>1.17 us (2.4x faster)</strong></td><td>1.12 us</td></tr>
<tr><td colspan="5"><strong>── medium ──</strong></td></tr>
<tr><td>weekly</td><td>40.71 us</td><td></td><td><strong>18.04 us (2.3x faster)</strong></td><td>17.71 us</td></tr>
<tr><td>monthly</td><td>31.25 us</td><td></td><td><strong>25.0 us (1.2x faster)</strong></td><td>25.17 us</td></tr>
<tr><td>quarterly</td><td>21.08 us</td><td></td><td><strong>17.29 us (1.2x faster)</strong></td><td>17.46 us</td></tr>
<tr><td>yearly</td><td>11.96 us</td><td></td><td><strong>9.88 us (1.2x faster)</strong></td><td>9.92 us</td></tr>
<tr><td colspan="5"><strong>── large ──</strong></td></tr>
<tr><td>weekly</td><td>1.0 ms</td><td></td><td><strong>694.33 us (1.4x faster)</strong></td><td>668.46 us</td></tr>
<tr><td>monthly</td><td>1.06 ms</td><td></td><td><strong>982.12 us (1.1x faster)</strong></td><td>988.88 us</td></tr>
<tr><td>quarterly</td><td>675.33 us</td><td></td><td>646.5 us (~1.0x)</td><td>643.33 us</td></tr>
<tr><td>yearly</td><td>368.79 us</td><td></td><td><strong>350.67 us (1.1x faster)</strong></td><td>350.83 us</td></tr>
</tbody>
</table>

### Additional resample benchmarks

| Benchmark | v0.2.2 | v0.3.2 |
|---|---|---|
| **── small ──** |  |  |
| resample_mean/monthly_mean | N/A | 2.38 us |
| resample_mean/weekly_mean | N/A | 2.12 us |
| resample_ohlcv/monthly_default | N/A | 2.71 us |
| resample_ohlcv/monthly_explicit | N/A | 2.79 us |
| resample_ohlcv/weekly_default | N/A | 2.75 us |
| **── medium ──** |  |  |
| resample_mean/monthly_mean | N/A | 34.17 us |
| resample_mean/weekly_mean | N/A | 33.75 us |
| resample_ohlcv/monthly_default | N/A | 37.33 us |
| resample_ohlcv/monthly_explicit | N/A | 37.54 us |
| resample_ohlcv/weekly_default | N/A | 37.92 us |
| **── large ──** |  |  |
| resample_mean/monthly_mean | N/A | 1.35 ms |
| resample_mean/weekly_mean | N/A | 1.35 ms |
| resample_ohlcv/monthly_default | N/A | 1.53 ms |
| resample_ohlcv/monthly_explicit | N/A | 1.51 ms |
| resample_ohlcv/weekly_default | N/A | 1.5 ms |

## rollapply

Rolling window operations (mean/sum/std)

| Benchmark | v0.2.2 | v0.3.2 |
|---|---|---|
| **── small ──** |  |  |
| mean_w5 | 6.96 ms | 6.68 ms (~1.0x) |
| std_w10 | 6.95 ms | **6.57 ms (1.1x faster)** |
| sum_w20 | 6.88 ms | **6.48 ms (1.1x faster)** |
| **── medium ──** |  |  |
| mean_w5 | 253.0 ms | **177.76 ms (1.4x faster)** |
| std_w10 | 252.72 ms | **177.74 ms (1.4x faster)** |
| sum_w20 | 256.43 ms | **183.3 ms (1.4x faster)** |
| **── large ──** |  |  |
| mean_w5 | 2.04 s | **845.66 ms (2.4x faster)** |
| sum_w20 | 2.04 s | **879.52 ms (2.3x faster)** |

## vcat

Vertical concatenation of TSFrame objects

| Benchmark | v0.2.2 | v0.3.2 |
|---|---|---|
| **── small ──** |  |  |
| diff_cols_intersect | N/A | 14.88 us |
| diff_cols_union | 33.25 us | _35.12 us (1.1x slower)_ |
| same_cols_union | 19.75 us | 20.38 us (~1.0x) |
| **── medium ──** |  |  |
| diff_cols_intersect | N/A | 74.79 us |
| diff_cols_union | 173.42 us | 172.88 us (~1.0x) |
| same_cols_union | 104.33 us | 104.58 us (~1.0x) |
| **── large ──** |  |  |
| diff_cols_intersect | N/A | 3.12 ms |
| diff_cols_union | 6.85 ms | 6.87 ms (~1.0x) |
| same_cols_union | 4.37 ms | 4.37 ms (~1.0x) |

