# TSFrames.jl Benchmark Report

Generated: 2026-04-03 05:59:15

## apply

| Benchmark | v0.3.0 |
|---|---|
| large/monthly_first | 937.88 us |
| large/monthly_last | 954.96 us |
| large/monthly_mean | 1.3 ms |
| large/monthly_sum | 1.21 ms |
| large/weekly_last | 625.0 us |
| large/weekly_mean | 1.28 ms |
| large/yearly_first | 341.46 us |
| medium/monthly_first | 10.92 us |
| medium/monthly_last | 11.29 us |
| medium/monthly_mean | 15.04 us |
| medium/monthly_sum | 14.38 us |
| medium/weekly_last | 7.96 us |
| medium/weekly_mean | 14.29 us |
| medium/yearly_first | 5.0 us |
| small/monthly_first | 1.17 us |
| small/monthly_last | 1.17 us |
| small/monthly_mean | 1.25 us |
| small/monthly_sum | 1.25 us |
| small/weekly_last | 1.12 us |
| small/weekly_mean | 1.25 us |
| small/yearly_first | 1.08 us |

## construction

| Benchmark | v0.3.0 |
|---|---|
| large/from_dataframe_first_col | 2.21 ms |
| large/from_dataframe_sorted_nocopy | 458.0 ns |
| large/from_dataframe_with_index | 2.21 ms |
| large/from_matrix_and_dates | 1.93 ms |
| large/from_vector_and_dates | 1.43 ms |
| medium/from_dataframe_first_col | 25.0 us |
| medium/from_dataframe_sorted_nocopy | 458.0 ns |
| medium/from_dataframe_with_index | 24.42 us |
| medium/from_matrix_and_dates | 21.58 us |
| medium/from_vector_and_dates | 16.12 us |
| small/from_dataframe_first_col | 2.0 us |
| small/from_dataframe_sorted_nocopy | 500.0 ns |
| small/from_dataframe_with_index | 1.83 us |
| small/from_matrix_and_dates | 1.25 us |
| small/from_vector_and_dates | 791.0 ns |

## endpoints

| Benchmark | v0.3.0 |
|---|---|
| large/monthly | 868.58 us |
| large/quarterly | 605.96 us |
| large/symbol_months | 866.46 us |
| large/symbol_weeks | 373.79 us |
| large/weekly | 373.96 us |
| large/yearly | 335.83 us |
| medium/monthly | 8.83 us |
| medium/quarterly | 6.33 us |
| medium/symbol_months | 9.17 us |
| medium/symbol_weeks | 4.17 us |
| medium/weekly | 4.0 us |
| medium/yearly | 3.67 us |
| small/monthly | 125.0 ns |
| small/quarterly | 125.0 ns |
| small/symbol_months | 208.0 ns |
| small/symbol_weeks | 125.0 ns |
| small/weekly | 41.0 ns |
| small/yearly | 42.0 ns |

## join

| Benchmark | v0.3.0 |
|---|---|
| large/inner | 3.5 ms |
| large/left | 6.51 ms |
| large/outer | 9.36 ms |
| medium/inner | 62.12 us |
| medium/left | 72.58 us |
| medium/outer | 101.33 us |
| small/inner | 7.88 us |
| small/left | 8.33 us |
| small/outer | 9.17 us |

## lag_lead_diff

| Benchmark | v0.3.0 |
|---|---|
| large/diff_1 | 4.14 ms |
| large/diff_5 | 4.14 ms |
| large/lag_1 | 1.62 ms |
| large/lag_5 | 1.68 ms |
| large/lead_1 | 1.64 ms |
| large/lead_5 | 1.61 ms |
| large/pctchange_1 | 5.63 ms |
| large/pctchange_5 | 5.6 ms |
| medium/diff_1 | 47.92 us |
| medium/diff_5 | 47.88 us |
| medium/lag_1 | 18.04 us |
| medium/lag_5 | 18.04 us |
| medium/lead_1 | 18.0 us |
| medium/lead_5 | 18.04 us |
| medium/pctchange_1 | 61.42 us |
| medium/pctchange_5 | 61.54 us |
| small/diff_1 | 9.0 us |
| small/diff_5 | 9.04 us |
| small/lag_1 | 2.0 us |
| small/lag_5 | 2.04 us |
| small/lead_1 | 2.04 us |
| small/lead_5 | 2.08 us |
| small/pctchange_1 | 9.12 us |
| small/pctchange_5 | 9.17 us |

## resample_vs_to_period

| Benchmark | v0.3.0 |
|---|---|
| large/resample_last/monthly_last | 956.42 us |
| large/resample_last/quarterly_last | 627.5 us |
| large/resample_last/weekly_last | 621.83 us |
| large/resample_last/yearly_last | 343.0 us |
| large/resample_mean/monthly_mean | 1.28 ms |
| large/resample_mean/weekly_mean | 1.24 ms |
| large/resample_ohlcv/monthly_default | 1.43 ms |
| large/resample_ohlcv/monthly_explicit | 1.43 ms |
| large/resample_ohlcv/weekly_default | 1.41 ms |
| large/to_period/monthly | 944.42 us |
| large/to_period/quarterly | 626.0 us |
| large/to_period/weekly | 651.0 us |
| large/to_period/yearly | 341.79 us |
| medium/resample_last/monthly_last | 10.79 us |
| medium/resample_last/quarterly_last | 7.46 us |
| medium/resample_last/weekly_last | 7.21 us |
| medium/resample_last/yearly_last | 4.58 us |
| medium/resample_mean/monthly_mean | 14.08 us |
| medium/resample_mean/weekly_mean | 13.38 us |
| medium/resample_ohlcv/monthly_default | 16.17 us |
| medium/resample_ohlcv/monthly_explicit | 16.42 us |
| medium/resample_ohlcv/weekly_default | 15.67 us |
| medium/to_period/monthly | 10.58 us |
| medium/to_period/quarterly | 7.33 us |
| medium/to_period/weekly | 7.25 us |
| medium/to_period/yearly | 4.54 us |
| small/resample_last/monthly_last | 833.0 ns |
| small/resample_last/quarterly_last | 833.0 ns |
| small/resample_last/weekly_last | 750.0 ns |
| small/resample_last/yearly_last | 750.0 ns |
| small/resample_mean/monthly_mean | 875.0 ns |
| small/resample_mean/weekly_mean | 833.0 ns |
| small/resample_ohlcv/monthly_default | 1.38 us |
| small/resample_ohlcv/monthly_explicit | 1.42 us |
| small/resample_ohlcv/weekly_default | 1.33 us |
| small/to_period/monthly | 875.0 ns |
| small/to_period/quarterly | 875.0 ns |
| small/to_period/weekly | 791.0 ns |
| small/to_period/yearly | 791.0 ns |

## rollapply

| Benchmark | v0.3.0 |
|---|---|
| large/mean_w5 | 763.14 ms |
| large/sum_w20 | 839.19 ms |
| medium/mean_w5 | 66.58 ms |
| medium/std_w10 | 66.64 ms |
| medium/sum_w20 | 66.84 ms |
| small/mean_w5 | 550.79 us |
| small/std_w10 | 521.38 us |
| small/sum_w20 | 467.42 us |

## vcat

| Benchmark | v0.3.0 |
|---|---|
| large/diff_cols_intersect | 2.92 ms |
| large/diff_cols_union | 6.74 ms |
| large/same_cols_union | 4.18 ms |
| medium/diff_cols_intersect | 32.88 us |
| medium/diff_cols_union | 80.38 us |
| medium/same_cols_union | 46.88 us |
| small/diff_cols_intersect | 5.0 us |
| small/diff_cols_union | 19.58 us |
| small/same_cols_union | 8.25 us |

