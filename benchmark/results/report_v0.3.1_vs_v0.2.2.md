# TSFrames.jl Benchmark Report

Generated: 2026-04-03 07:28:42

## apply

| Benchmark | v0.3.1 | xKDR v0.2.2 | Speedup vs v0.3.1 |
|---|---|---|---|
| large/monthly_first | 937.88 us | _7.53 ms (8.0x slower)_ | _8.0x slower_ |
| large/monthly_last | 954.96 us | _6.95 ms (7.3x slower)_ | _7.3x slower_ |
| large/monthly_mean | 1.3 ms | _10.47 ms (8.0x slower)_ | _8.0x slower_ |
| large/monthly_sum | 1.21 ms | _11.26 ms (9.3x slower)_ | _9.3x slower_ |
| large/weekly_last | 625.0 us | _5.41 ms (8.7x slower)_ | _8.7x slower_ |
| large/weekly_mean | 1.28 ms | _10.3 ms (8.0x slower)_ | _8.0x slower_ |
| large/yearly_first | 341.46 us | _5.27 ms (15.4x slower)_ | _15.4x slower_ |
| medium/monthly_first | 10.92 us | _112.54 us (10.3x slower)_ | _10.3x slower_ |
| medium/monthly_last | 11.29 us | _105.92 us (9.4x slower)_ | _9.4x slower_ |
| medium/monthly_mean | 15.04 us | _181.0 us (12.0x slower)_ | _12.0x slower_ |
| medium/monthly_sum | 14.38 us | _188.88 us (13.1x slower)_ | _13.1x slower_ |
| medium/weekly_last | 7.96 us | _121.04 us (15.2x slower)_ | _15.2x slower_ |
| medium/weekly_mean | 14.29 us | _194.04 us (13.6x slower)_ | _13.6x slower_ |
| medium/yearly_first | 5.0 us | _104.75 us (21.0x slower)_ | _21.0x slower_ |
| small/monthly_first | 1.17 us | _59.38 us (50.9x slower)_ | _50.9x slower_ |
| small/monthly_last | 1.17 us | _59.29 us (50.8x slower)_ | _50.8x slower_ |
| small/monthly_mean | 1.25 us | _59.58 us (47.7x slower)_ | _47.7x slower_ |
| small/monthly_sum | 1.25 us | _60.25 us (48.2x slower)_ | _48.2x slower_ |
| small/weekly_last | 1.12 us | _59.96 us (53.3x slower)_ | _53.3x slower_ |
| small/weekly_mean | 1.25 us | _60.25 us (48.2x slower)_ | _48.2x slower_ |
| small/yearly_first | 1.08 us | _58.58 us (54.1x slower)_ | _54.1x slower_ |

## construction

| Benchmark | v0.3.1 | xKDR v0.2.2 | Speedup vs v0.3.1 |
|---|---|---|---|
| large/from_dataframe_first_col | 2.21 ms | 2.15 ms | ~1.0x |
| large/from_dataframe_sorted_nocopy | 458.0 ns | 458.0 ns | ~1.0x |
| large/from_dataframe_with_index | 2.21 ms | 2.18 ms | ~1.0x |
| large/from_matrix_and_dates | 1.93 ms | **910.38 us (2.1x)** | **2.1x** |
| large/from_vector_and_dates | 1.43 ms | **655.83 us (2.2x)** | **2.2x** |
| medium/from_dataframe_first_col | 25.0 us | 24.88 us | ~1.0x |
| medium/from_dataframe_sorted_nocopy | 458.0 ns | 458.0 ns | ~1.0x |
| medium/from_dataframe_with_index | 24.42 us | 24.5 us | ~1.0x |
| medium/from_matrix_and_dates | 21.58 us | **10.71 us (2.0x)** | **2.0x** |
| medium/from_vector_and_dates | 16.12 us | **7.5 us (2.2x)** | **2.2x** |
| small/from_dataframe_first_col | 2.0 us | 2.04 us | ~1.0x |
| small/from_dataframe_sorted_nocopy | 500.0 ns | **458.0 ns (1.1x)** | **1.1x** |
| small/from_dataframe_with_index | 1.83 us | 1.83 us | ~1.0x |
| small/from_matrix_and_dates | 1.25 us | **1.0 us (1.2x)** | **1.2x** |
| small/from_vector_and_dates | 791.0 ns | **625.0 ns (1.3x)** | **1.3x** |

## endpoints

| Benchmark | v0.3.1 | xKDR v0.2.2 | Speedup vs v0.3.1 |
|---|---|---|---|
| large/monthly | 868.58 us | 861.75 us | ~1.0x |
| large/quarterly | 605.96 us | 602.71 us | ~1.0x |
| large/symbol_months | 866.46 us | 862.0 us | ~1.0x |
| large/symbol_weeks | 373.79 us | 372.12 us | ~1.0x |
| large/weekly | 373.96 us | 372.75 us | ~1.0x |
| large/yearly | 335.83 us | 336.46 us | ~1.0x |
| medium/monthly | 8.83 us | 8.83 us | ~1.0x |
| medium/quarterly | 6.33 us | 6.29 us | ~1.0x |
| medium/symbol_months | 9.17 us | 8.83 us | ~1.0x |
| medium/symbol_weeks | 4.17 us | 4.08 us | ~1.0x |
| medium/weekly | 4.0 us | 4.12 us | ~1.0x |
| medium/yearly | 3.67 us | _4.04 us (1.1x slower)_ | _1.1x slower_ |
| small/monthly | 125.0 ns | 125.0 ns | ~1.0x |
| small/quarterly | 125.0 ns | **84.0 ns (1.5x)** | **1.5x** |
| small/symbol_months | 208.0 ns | **125.0 ns (1.7x)** | **1.7x** |
| small/symbol_weeks | 125.0 ns | **0.0 ns (125000.0x)** | **125000.0x** |
| small/weekly | 41.0 ns | 41.0 ns | ~1.0x |
| small/yearly | 42.0 ns | 42.0 ns | ~1.0x |

## join

| Benchmark | v0.3.1 | xKDR v0.2.2 | Speedup vs v0.3.1 |
|---|---|---|---|
| large/inner | 3.5 ms | 3.42 ms | ~1.0x |
| large/left | 6.51 ms | **6.18 ms (1.1x)** | **1.1x** |
| large/outer | 9.36 ms | 9.08 ms | ~1.0x |
| medium/inner | 62.12 us | 62.83 us | ~1.0x |
| medium/left | 72.58 us | 73.58 us | ~1.0x |
| medium/outer | 101.33 us | 101.75 us | ~1.0x |
| small/inner | 7.88 us | _8.62 us (1.1x slower)_ | _1.1x slower_ |
| small/left | 8.33 us | _9.08 us (1.1x slower)_ | _1.1x slower_ |
| small/outer | 9.17 us | _9.96 us (1.1x slower)_ | _1.1x slower_ |

## lag_lead_diff

| Benchmark | v0.3.1 | xKDR v0.2.2 | Speedup vs v0.3.1 |
|---|---|---|---|
| large/diff_1 | 4.14 ms | _10.41 ms (2.5x slower)_ | _2.5x slower_ |
| large/diff_5 | 4.14 ms | _10.2 ms (2.5x slower)_ | _2.5x slower_ |
| large/lag_1 | 1.62 ms | _4.26 ms (2.6x slower)_ | _2.6x slower_ |
| large/lag_5 | 1.68 ms | _4.38 ms (2.6x slower)_ | _2.6x slower_ |
| large/lead_1 | 1.64 ms | _4.33 ms (2.6x slower)_ | _2.6x slower_ |
| large/lead_5 | 1.61 ms | _4.42 ms (2.7x slower)_ | _2.7x slower_ |
| large/pctchange_1 | 5.63 ms | _17.16 ms (3.0x slower)_ | _3.0x slower_ |
| large/pctchange_5 | 5.6 ms | _17.07 ms (3.1x slower)_ | _3.1x slower_ |
| medium/diff_1 | 47.92 us | _106.21 us (2.2x slower)_ | _2.2x slower_ |
| medium/diff_5 | 47.88 us | _105.29 us (2.2x slower)_ | _2.2x slower_ |
| medium/lag_1 | 18.04 us | _44.62 us (2.5x slower)_ | _2.5x slower_ |
| medium/lag_5 | 18.04 us | _44.71 us (2.5x slower)_ | _2.5x slower_ |
| medium/lead_1 | 18.0 us | _44.67 us (2.5x slower)_ | _2.5x slower_ |
| medium/lead_5 | 18.04 us | _44.71 us (2.5x slower)_ | _2.5x slower_ |
| medium/pctchange_1 | 61.42 us | _168.38 us (2.7x slower)_ | _2.7x slower_ |
| medium/pctchange_5 | 61.54 us | _168.29 us (2.7x slower)_ | _2.7x slower_ |
| small/diff_1 | 9.0 us | _13.21 us (1.5x slower)_ | _1.5x slower_ |
| small/diff_5 | 9.04 us | _13.04 us (1.4x slower)_ | _1.4x slower_ |
| small/lag_1 | 2.0 us | _3.88 us (1.9x slower)_ | _1.9x slower_ |
| small/lag_5 | 2.04 us | _3.83 us (1.9x slower)_ | _1.9x slower_ |
| small/lead_1 | 2.04 us | _3.75 us (1.8x slower)_ | _1.8x slower_ |
| small/lead_5 | 2.08 us | _3.88 us (1.9x slower)_ | _1.9x slower_ |
| small/pctchange_1 | 9.12 us | _18.46 us (2.0x slower)_ | _2.0x slower_ |
| small/pctchange_5 | 9.17 us | _18.42 us (2.0x slower)_ | _2.0x slower_ |

## resample_vs_to_period

| Benchmark | v0.3.1 | xKDR v0.2.2 | Speedup vs v0.3.1 |
|---|---|---|---|
| large/resample_last/monthly_last | 956.42 us | N/A | N/A |
| large/resample_last/quarterly_last | 627.5 us | N/A | N/A |
| large/resample_last/weekly_last | 621.83 us | N/A | N/A |
| large/resample_last/yearly_last | 343.0 us | N/A | N/A |
| large/resample_mean/monthly_mean | 1.28 ms | N/A | N/A |
| large/resample_mean/weekly_mean | 1.24 ms | N/A | N/A |
| large/resample_ohlcv/monthly_default | 1.43 ms | N/A | N/A |
| large/resample_ohlcv/monthly_explicit | 1.43 ms | N/A | N/A |
| large/resample_ohlcv/weekly_default | 1.41 ms | N/A | N/A |
| large/to_period/monthly | 944.42 us | _1.02 ms (1.1x slower)_ | _1.1x slower_ |
| large/to_period/quarterly | 626.0 us | 657.25 us | ~1.0x |
| large/to_period/weekly | 651.0 us | _968.67 us (1.5x slower)_ | _1.5x slower_ |
| large/to_period/yearly | 341.79 us | _359.62 us (1.1x slower)_ | _1.1x slower_ |
| medium/resample_last/monthly_last | 10.79 us | N/A | N/A |
| medium/resample_last/quarterly_last | 7.46 us | N/A | N/A |
| medium/resample_last/weekly_last | 7.21 us | N/A | N/A |
| medium/resample_last/yearly_last | 4.58 us | N/A | N/A |
| medium/resample_mean/monthly_mean | 14.08 us | N/A | N/A |
| medium/resample_mean/weekly_mean | 13.38 us | N/A | N/A |
| medium/resample_ohlcv/monthly_default | 16.17 us | N/A | N/A |
| medium/resample_ohlcv/monthly_explicit | 16.42 us | N/A | N/A |
| medium/resample_ohlcv/weekly_default | 15.67 us | N/A | N/A |
| medium/to_period/monthly | 10.58 us | _14.04 us (1.3x slower)_ | _1.3x slower_ |
| medium/to_period/quarterly | 7.33 us | _9.46 us (1.3x slower)_ | _1.3x slower_ |
| medium/to_period/weekly | 7.25 us | _17.29 us (2.4x slower)_ | _2.4x slower_ |
| medium/to_period/yearly | 4.54 us | _6.33 us (1.4x slower)_ | _1.4x slower_ |
| small/resample_last/monthly_last | 833.0 ns | N/A | N/A |
| small/resample_last/quarterly_last | 833.0 ns | N/A | N/A |
| small/resample_last/weekly_last | 750.0 ns | N/A | N/A |
| small/resample_last/yearly_last | 750.0 ns | N/A | N/A |
| small/resample_mean/monthly_mean | 875.0 ns | N/A | N/A |
| small/resample_mean/weekly_mean | 833.0 ns | N/A | N/A |
| small/resample_ohlcv/monthly_default | 1.38 us | N/A | N/A |
| small/resample_ohlcv/monthly_explicit | 1.42 us | N/A | N/A |
| small/resample_ohlcv/weekly_default | 1.33 us | N/A | N/A |
| small/to_period/monthly | 875.0 ns | _2.46 us (2.8x slower)_ | _2.8x slower_ |
| small/to_period/quarterly | 875.0 ns | _2.54 us (2.9x slower)_ | _2.9x slower_ |
| small/to_period/weekly | 791.0 ns | _2.46 us (3.1x slower)_ | _3.1x slower_ |
| small/to_period/yearly | 791.0 ns | _2.42 us (3.1x slower)_ | _3.1x slower_ |

## rollapply

| Benchmark | v0.3.1 | xKDR v0.2.2 | Speedup vs v0.3.1 |
|---|---|---|---|
| large/mean_w5 | 763.14 ms | _1.93 s (2.5x slower)_ | _2.5x slower_ |
| large/sum_w20 | 839.19 ms | _1.93 s (2.3x slower)_ | _2.3x slower_ |
| medium/mean_w5 | 66.58 ms | _80.04 ms (1.2x slower)_ | _1.2x slower_ |
| medium/std_w10 | 66.64 ms | _82.32 ms (1.2x slower)_ | _1.2x slower_ |
| medium/sum_w20 | 66.84 ms | _83.57 ms (1.3x slower)_ | _1.3x slower_ |
| small/mean_w5 | 550.79 us | 577.96 us | ~1.0x |
| small/std_w10 | 521.38 us | 547.04 us | ~1.0x |
| small/sum_w20 | 467.42 us | 489.33 us | ~1.0x |

## vcat

| Benchmark | v0.3.1 | xKDR v0.2.2 | Speedup vs v0.3.1 |
|---|---|---|---|
| large/diff_cols_intersect | 2.92 ms | N/A | N/A |
| large/diff_cols_union | 6.74 ms | 6.63 ms | ~1.0x |
| large/same_cols_union | 4.18 ms | 4.06 ms | ~1.0x |
| medium/diff_cols_intersect | 32.88 us | N/A | N/A |
| medium/diff_cols_union | 80.38 us | 80.67 us | ~1.0x |
| medium/same_cols_union | 46.88 us | 47.25 us | ~1.0x |
| small/diff_cols_intersect | 5.0 us | N/A | N/A |
| small/diff_cols_union | 19.58 us | 19.21 us | ~1.0x |
| small/same_cols_union | 8.25 us | 8.33 us | ~1.0x |

