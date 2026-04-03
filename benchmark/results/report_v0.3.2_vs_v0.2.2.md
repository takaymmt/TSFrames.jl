# TSFrames.jl Benchmark Report

Generated: 2026-04-03 12:08:41

## apply

| Benchmark | v0.2.2 | v0.3.1 | v0.3.2 |
|---|---|---|---|
| large/monthly_first | 7.53 ms | **937.88 us (8.0x faster)** | **936.88 us (8.0x faster)** |
| large/monthly_last | 6.95 ms | **954.96 us (7.3x faster)** | **951.58 us (7.3x faster)** |
| large/monthly_mean | 10.47 ms | **1.3 ms (8.0x faster)** | **1.3 ms (8.0x faster)** |
| large/monthly_sum | 11.26 ms | **1.21 ms (9.3x faster)** | **1.18 ms (9.5x faster)** |
| large/weekly_last | 5.41 ms | **625.0 us (8.7x faster)** | **627.67 us (8.6x faster)** |
| large/weekly_mean | 10.3 ms | **1.28 ms (8.0x faster)** | **1.28 ms (8.0x faster)** |
| large/yearly_first | 5.27 ms | **341.46 us (15.4x faster)** | **341.96 us (15.4x faster)** |
| medium/monthly_first | 112.54 us | **10.92 us (10.3x faster)** | **10.83 us (10.4x faster)** |
| medium/monthly_last | 105.92 us | **11.29 us (9.4x faster)** | **11.0 us (9.6x faster)** |
| medium/monthly_mean | 181.0 us | **15.04 us (12.0x faster)** | **14.75 us (12.3x faster)** |
| medium/monthly_sum | 188.88 us | **14.38 us (13.1x faster)** | **14.25 us (13.3x faster)** |
| medium/weekly_last | 121.04 us | **7.96 us (15.2x faster)** | **8.0 us (15.1x faster)** |
| medium/weekly_mean | 194.04 us | **14.29 us (13.6x faster)** | **14.38 us (13.5x faster)** |
| medium/yearly_first | 104.75 us | **5.0 us (21.0x faster)** | **4.96 us (21.1x faster)** |
| small/monthly_first | 59.38 us | **1.17 us (50.9x faster)** | **1.12 us (52.8x faster)** |
| small/monthly_last | 59.29 us | **1.17 us (50.8x faster)** | **1.17 us (50.8x faster)** |
| small/monthly_mean | 59.58 us | **1.25 us (47.7x faster)** | **1.21 us (49.3x faster)** |
| small/monthly_sum | 60.25 us | **1.25 us (48.2x faster)** | **1.21 us (49.9x faster)** |
| small/weekly_last | 59.96 us | **1.12 us (53.3x faster)** | **1.12 us (53.3x faster)** |
| small/weekly_mean | 60.25 us | **1.25 us (48.2x faster)** | **1.21 us (49.9x faster)** |
| small/yearly_first | 58.58 us | **1.08 us (54.1x faster)** | **1.12 us (52.1x faster)** |

## construction

| Benchmark | v0.2.2 | v0.3.1 | v0.3.2 |
|---|---|---|---|
| large/from_dataframe_first_col | 2.15 ms | 2.21 ms (~1.0x) | 2.16 ms (~1.0x) |
| large/from_dataframe_sorted_nocopy | 458.0 ns | 458.0 ns (~1.0x) | 458.0 ns (~1.0x) |
| large/from_dataframe_with_index | 2.18 ms | 2.21 ms (~1.0x) | 2.15 ms (~1.0x) |
| large/from_matrix_and_dates | 910.38 us | _1.93 ms (2.1x slower)_ | 889.12 us (~1.0x) |
| large/from_vector_and_dates | 655.83 us | _1.43 ms (2.2x slower)_ | 639.04 us (~1.0x) |
| medium/from_dataframe_first_col | 24.88 us | 25.0 us (~1.0x) | 24.96 us (~1.0x) |
| medium/from_dataframe_sorted_nocopy | 458.0 ns | 458.0 ns (~1.0x) | 459.0 ns (~1.0x) |
| medium/from_dataframe_with_index | 24.5 us | 24.42 us (~1.0x) | 24.58 us (~1.0x) |
| medium/from_matrix_and_dates | 10.71 us | _21.58 us (2.0x slower)_ | 10.5 us (~1.0x) |
| medium/from_vector_and_dates | 7.5 us | _16.12 us (2.2x slower)_ | 7.38 us (~1.0x) |
| small/from_dataframe_first_col | 2.04 us | 2.0 us (~1.0x) | 2.0 us (~1.0x) |
| small/from_dataframe_sorted_nocopy | 458.0 ns | _500.0 ns (1.1x slower)_ | 458.0 ns (~1.0x) |
| small/from_dataframe_with_index | 1.83 us | 1.83 us (~1.0x) | 1.79 us (~1.0x) |
| small/from_matrix_and_dates | 1.0 us | _1.25 us (1.2x slower)_ | 958.0 ns (~1.0x) |
| small/from_vector_and_dates | 625.0 ns | _791.0 ns (1.3x slower)_ | 625.0 ns (~1.0x) |

## endpoints

| Benchmark | v0.2.2 | v0.3.1 | v0.3.2 |
|---|---|---|---|
| large/monthly | 861.75 us | 868.58 us (~1.0x) | 859.71 us (~1.0x) |
| large/quarterly | 602.71 us | 605.96 us (~1.0x) | 602.25 us (~1.0x) |
| large/symbol_months | 862.0 us | 866.46 us (~1.0x) | 859.88 us (~1.0x) |
| large/symbol_weeks | 372.12 us | 373.79 us (~1.0x) | 373.33 us (~1.0x) |
| large/weekly | 372.75 us | 373.96 us (~1.0x) | 372.88 us (~1.0x) |
| large/yearly | 336.46 us | 335.83 us (~1.0x) | 334.92 us (~1.0x) |
| medium/monthly | 8.83 us | 8.83 us (~1.0x) | 8.83 us (~1.0x) |
| medium/quarterly | 6.29 us | 6.33 us (~1.0x) | 6.33 us (~1.0x) |
| medium/symbol_months | 8.83 us | 9.17 us (~1.0x) | 8.92 us (~1.0x) |
| medium/symbol_weeks | 4.08 us | 4.17 us (~1.0x) | 4.08 us (~1.0x) |
| medium/weekly | 4.12 us | 4.0 us (~1.0x) | 4.0 us (~1.0x) |
| medium/yearly | 4.04 us | **3.67 us (1.1x faster)** | 4.08 us (~1.0x) |
| small/monthly | 125.0 ns | 125.0 ns (~1.0x) | **83.0 ns (1.5x faster)** |
| small/quarterly | 84.0 ns | _125.0 ns (1.5x slower)_ | 83.0 ns (~1.0x) |
| small/symbol_months | 125.0 ns | _208.0 ns (1.7x slower)_ | _167.0 ns (1.3x slower)_ |
| small/symbol_weeks | 0.0 ns | _125.0 ns (125000.0x slower)_ | _125.0 ns (125000.0x slower)_ |
| small/weekly | 41.0 ns | 41.0 ns (~1.0x) | 41.0 ns (~1.0x) |
| small/yearly | 42.0 ns | 42.0 ns (~1.0x) | 42.0 ns (~1.0x) |

## join

| Benchmark | v0.2.2 | v0.3.1 | v0.3.2 |
|---|---|---|---|
| large/inner | 3.42 ms | 3.5 ms (~1.0x) | 3.4 ms (~1.0x) |
| large/left | 6.18 ms | _6.51 ms (1.1x slower)_ | 6.04 ms (~1.0x) |
| large/outer | 9.08 ms | 9.36 ms (~1.0x) | 9.09 ms (~1.0x) |
| medium/inner | 62.83 us | 62.12 us (~1.0x) | 61.79 us (~1.0x) |
| medium/left | 73.58 us | 72.58 us (~1.0x) | 72.33 us (~1.0x) |
| medium/outer | 101.75 us | 101.33 us (~1.0x) | 100.71 us (~1.0x) |
| small/inner | 8.62 us | **7.88 us (1.1x faster)** | **7.71 us (1.1x faster)** |
| small/left | 9.08 us | **8.33 us (1.1x faster)** | **8.21 us (1.1x faster)** |
| small/outer | 9.96 us | **9.17 us (1.1x faster)** | **9.0 us (1.1x faster)** |

## lag_lead_diff

| Benchmark | v0.2.2 | v0.3.1 | v0.3.2 |
|---|---|---|---|
| large/diff_1 | 10.41 ms | **4.14 ms (2.5x faster)** | **4.72 ms (2.2x faster)** |
| large/diff_5 | 10.2 ms | **4.14 ms (2.5x faster)** | **4.72 ms (2.2x faster)** |
| large/lag_1 | 4.26 ms | **1.62 ms (2.6x faster)** | **1.68 ms (2.5x faster)** |
| large/lag_5 | 4.38 ms | **1.68 ms (2.6x faster)** | **1.66 ms (2.6x faster)** |
| large/lead_1 | 4.33 ms | **1.64 ms (2.6x faster)** | **1.66 ms (2.6x faster)** |
| large/lead_5 | 4.42 ms | **1.61 ms (2.7x faster)** | **1.67 ms (2.6x faster)** |
| large/pctchange_1 | 17.16 ms | **5.63 ms (3.0x faster)** | **5.62 ms (3.1x faster)** |
| large/pctchange_5 | 17.07 ms | **5.6 ms (3.1x faster)** | **5.59 ms (3.1x faster)** |
| medium/diff_1 | 106.21 us | **47.92 us (2.2x faster)** | **48.42 us (2.2x faster)** |
| medium/diff_5 | 105.29 us | **47.88 us (2.2x faster)** | **48.58 us (2.2x faster)** |
| medium/lag_1 | 44.62 us | **18.04 us (2.5x faster)** | **17.96 us (2.5x faster)** |
| medium/lag_5 | 44.71 us | **18.04 us (2.5x faster)** | **18.04 us (2.5x faster)** |
| medium/lead_1 | 44.67 us | **18.0 us (2.5x faster)** | **17.96 us (2.5x faster)** |
| medium/lead_5 | 44.71 us | **18.04 us (2.5x faster)** | **17.96 us (2.5x faster)** |
| medium/pctchange_1 | 168.38 us | **61.42 us (2.7x faster)** | **61.88 us (2.7x faster)** |
| medium/pctchange_5 | 168.29 us | **61.54 us (2.7x faster)** | **61.62 us (2.7x faster)** |
| small/diff_1 | 13.21 us | **9.0 us (1.5x faster)** | **9.62 us (1.4x faster)** |
| small/diff_5 | 13.04 us | **9.04 us (1.4x faster)** | **9.62 us (1.4x faster)** |
| small/lag_1 | 3.88 us | **2.0 us (1.9x faster)** | **2.04 us (1.9x faster)** |
| small/lag_5 | 3.83 us | **2.04 us (1.9x faster)** | **2.08 us (1.8x faster)** |
| small/lead_1 | 3.75 us | **2.04 us (1.8x faster)** | **2.04 us (1.8x faster)** |
| small/lead_5 | 3.88 us | **2.08 us (1.9x faster)** | **2.0 us (1.9x faster)** |
| small/pctchange_1 | 18.46 us | **9.12 us (2.0x faster)** | **9.79 us (1.9x faster)** |
| small/pctchange_5 | 18.42 us | **9.17 us (2.0x faster)** | **9.88 us (1.9x faster)** |

## resample_vs_to_period

| Benchmark | v0.2.2 | v0.3.1 | v0.3.2 |
|---|---|---|---|
| large/to_period/monthly | 1.02 ms | **944.42 us (1.1x faster)** | **944.08 us (1.1x faster)** |
| large/to_period/quarterly | 657.25 us | 626.0 us (~1.0x) | 626.12 us (~1.0x) |
| large/to_period/weekly | 968.67 us | **651.0 us (1.5x faster)** | **650.75 us (1.5x faster)** |
| large/to_period/yearly | 359.62 us | **341.79 us (1.1x faster)** | **341.21 us (1.1x faster)** |
| medium/to_period/monthly | 14.04 us | **10.58 us (1.3x faster)** | **10.33 us (1.4x faster)** |
| medium/to_period/quarterly | 9.46 us | **7.33 us (1.3x faster)** | **7.38 us (1.3x faster)** |
| medium/to_period/weekly | 17.29 us | **7.25 us (2.4x faster)** | **7.25 us (2.4x faster)** |
| medium/to_period/yearly | 6.33 us | **4.54 us (1.4x faster)** | **4.5 us (1.4x faster)** |
| small/to_period/monthly | 2.46 us | **875.0 ns (2.8x faster)** | **833.0 ns (3.0x faster)** |
| small/to_period/quarterly | 2.54 us | **875.0 ns (2.9x faster)** | **875.0 ns (2.9x faster)** |
| small/to_period/weekly | 2.46 us | **791.0 ns (3.1x faster)** | **750.0 ns (3.3x faster)** |
| small/to_period/yearly | 2.42 us | **791.0 ns (3.1x faster)** | **833.0 ns (2.9x faster)** |

## rollapply

| Benchmark | v0.2.2 | v0.3.1 | v0.3.2 |
|---|---|---|---|
| large/mean_w5 | 1.93 s | **763.14 ms (2.5x faster)** | **757.74 ms (2.5x faster)** |
| large/sum_w20 | 1.93 s | **839.19 ms (2.3x faster)** | **797.67 ms (2.4x faster)** |
| medium/mean_w5 | 80.04 ms | **66.58 ms (1.2x faster)** | **64.76 ms (1.2x faster)** |
| medium/std_w10 | 82.32 ms | **66.64 ms (1.2x faster)** | **63.84 ms (1.3x faster)** |
| medium/sum_w20 | 83.57 ms | **66.84 ms (1.3x faster)** | **65.33 ms (1.3x faster)** |
| small/mean_w5 | 577.96 us | 550.79 us (~1.0x) | 550.92 us (~1.0x) |
| small/std_w10 | 547.04 us | 521.38 us (~1.0x) | 523.71 us (~1.0x) |
| small/sum_w20 | 489.33 us | 467.42 us (~1.0x) | 468.5 us (~1.0x) |

## vcat

| Benchmark | v0.2.2 | v0.3.1 | v0.3.2 |
|---|---|---|---|
| large/diff_cols_union | 6.63 ms | 6.74 ms (~1.0x) | 6.54 ms (~1.0x) |
| large/same_cols_union | 4.06 ms | 4.18 ms (~1.0x) | 4.01 ms (~1.0x) |
| medium/diff_cols_union | 80.67 us | 80.38 us (~1.0x) | 80.83 us (~1.0x) |
| medium/same_cols_union | 47.25 us | 46.88 us (~1.0x) | 46.83 us (~1.0x) |
| small/diff_cols_union | 19.21 us | 19.58 us (~1.0x) | 20.0 us (~1.0x) |
| small/same_cols_union | 8.33 us | 8.25 us (~1.0x) | 8.33 us (~1.0x) |

