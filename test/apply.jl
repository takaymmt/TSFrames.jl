DATA_SIZE_1 = 360
data_vector_1 = randn(DATA_SIZE_1)
index_timetype_1 = Date(2007, 1,1) + Day.(0:(DATA_SIZE_1 - 1))

df_timetype_index_1 = DataFrame(Index = index_timetype_1, data = data_vector_1)
ts_daily_1 = TSFrame(df_timetype_index_1, 1)
ts_daily_matrix_1 = TSFrame(DataFrames.innerjoin(df_timetype_index_1, df_timetype_index_1, on=:Index, makeunique=true))

DATA_SIZE_2 = 86400
data_vector_2 = randn(DATA_SIZE_2)
index_timetype_2 = DateTime(2000, 1, 1, 0, 0, 0) + Second.(0:(DATA_SIZE_2 - 1))

df_timetype_index_2 = DataFrame(Index = index_timetype_2, data = data_vector_2)
ts_intraday_2 = TSFrame(df_timetype_index_2)
ts_daily_matrix_2 = TSFrame(DataFrames.innerjoin(df_timetype_index_2, df_timetype_index_2, on=:Index, makeunique=true))


# function apply(ts::TSFrame, period::Union{T,Type{T}}, fun::V, index_at::Function=first) where {T<:Union{DatePeriod,TimePeriod}, V<:Function}

# Resampling

# Daily -> Monthly
ts_monthly = apply(ts_daily_1, Dates.Month(1), first)
@test typeof(ts_monthly) == TSFrames.TSFrame
@test typeof(ts_monthly.coredata) == DataFrame
@test DataFrames.nrow(ts_monthly.coredata) == 12 # 360 days

ts_monthly = apply(ts_daily_1, Dates.Month(1), last)
@test typeof(ts_monthly) == TSFrames.TSFrame
@test typeof(ts_monthly.coredata) == DataFrame
@test DataFrames.nrow(ts_monthly.coredata) == 12

ts_monthly = apply(ts_daily_1, Dates.Month(1), first)
@test typeof(ts_monthly) == TSFrames.TSFrame
@test typeof(ts_monthly.coredata) == DataFrame
@test DataFrames.nrow(ts_monthly.coredata) == 12

ts_monthly = apply(ts_daily_1, Dates.Month(2), first)
@test typeof(ts_monthly) == TSFrames.TSFrame
@test typeof(ts_monthly.coredata) == DataFrame
@test DataFrames.nrow(ts_monthly.coredata) == 6

ts_monthly = apply(ts_daily_1, Dates.Month(12), first)
@test typeof(ts_monthly) == TSFrames.TSFrame
@test typeof(ts_monthly.coredata) == DataFrame
@test DataFrames.nrow(ts_monthly.coredata) == 1

ts_monthly = apply(ts_daily_1, Dates.Month(100), first)
@test typeof(ts_monthly) == TSFrames.TSFrame
@test typeof(ts_monthly.coredata) == DataFrame
@test DataFrames.nrow(ts_monthly.coredata) == 1

ts_monthly = apply(ts_daily_1, Dates.Month(1), Statistics.mean)
t = ts_daily_1[:, "data"]
@test typeof(ts_monthly) == TSFrames.TSFrame
@test typeof(ts_monthly.coredata) == DataFrame
@test DataFrames.nrow(ts_monthly.coredata) == 12
@test typeof(ts_monthly[:, "data_mean"]) == Vector{Float64}
@test ts_monthly[1, "data_mean"] ≈ Statistics.mean(t[1:31])

ts_monthly = apply(ts_daily_1, Dates.Month(1), sum)
t = ts_daily_1[:, "data"]
@test typeof(ts_monthly) == TSFrames.TSFrame
@test typeof(ts_monthly.coredata) == DataFrame
@test DataFrames.nrow(ts_monthly.coredata) == 12
@test typeof(ts_monthly[:, "data_sum"]) == Vector{Float64}
@test ts_monthly[1, "data_sum"] ≈ sum(t[1:31])

ts_monthly = apply(ts_daily_1, Dates.Month(1), sum, last)
t = ts_daily_1[:, "data"]
@test typeof(ts_monthly) == TSFrames.TSFrame
@test typeof(ts_monthly.coredata) == DataFrame
@test DataFrames.nrow(ts_monthly.coredata) == 12
@test typeof(ts_monthly[:, "data_sum"]) == Vector{Float64}
@test ts_monthly["2007-01-31"][1,1] ≈ sum(t[1:31])

# Daily -> Yearly
ts_yearly = apply(ts_daily_1, Dates.Year(1), first)
@test typeof(ts_yearly) == TSFrames.TSFrame
@test typeof(ts_yearly.coredata) == DataFrame
@test DataFrames.nrow(ts_yearly.coredata) == 1

ts_yearly = apply(ts_daily_1, Dates.Year(1), last)
@test typeof(ts_yearly) == TSFrames.TSFrame
@test typeof(ts_yearly.coredata) == DataFrame
@test DataFrames.nrow(ts_yearly.coredata) == 1

ts_yearly = apply(ts_daily_1, Dates.Year(1), first)
@test typeof(ts_yearly) == TSFrames.TSFrame
@test typeof(ts_yearly.coredata) == DataFrame
@test DataFrames.nrow(ts_yearly.coredata) == 1

ts_yearly = apply(ts_daily_1, Dates.Year(2), first)
@test typeof(ts_yearly) == TSFrames.TSFrame
@test typeof(ts_yearly.coredata) == DataFrame
@test DataFrames.nrow(ts_yearly.coredata) == 1

ts_yearly = apply(ts_daily_1, Dates.Year(100), first)
@test typeof(ts_yearly) == TSFrames.TSFrame
@test typeof(ts_yearly.coredata) == DataFrame
@test DataFrames.nrow(ts_yearly.coredata) == 1

ts_yearly = apply(ts_daily_1, Dates.Year(1), Statistics.mean)
t = ts_daily_1[:, "data"]
@test typeof(ts_yearly) == TSFrames.TSFrame
@test typeof(ts_yearly.coredata) == DataFrame
@test DataFrames.nrow(ts_yearly.coredata) == 1
@test typeof(ts_yearly[:, "data_mean"]) == Vector{Float64}
@test ts_yearly[1, "data_mean"] ≈ Statistics.mean(t)

ts_yearly = apply(ts_daily_1, Dates.Year(1), sum)
t = ts_daily_1[:, "data"]
@test typeof(ts_yearly) == TSFrames.TSFrame
@test typeof(ts_yearly.coredata) == DataFrame
@test DataFrames.nrow(ts_yearly.coredata) == 1
@test typeof(ts_yearly[:, "data_sum"]) == Vector{Float64}
@test ts_yearly[1, "data_sum"] ≈ sum(t)

ts_yearly = apply(ts_daily_1, Dates.Year(1), sum, last)
t = ts_daily_1[:, "data"]
@test typeof(ts_yearly) == TSFrames.TSFrame
@test typeof(ts_yearly.coredata) == DataFrame
@test DataFrames.nrow(ts_yearly.coredata) == 1
@test typeof(ts_yearly[:, "data_sum"]) == Vector{Float64}
@test ts_yearly[1, "data_sum"] ≈ sum(t)
@test ts_yearly["2007-12-26"][1,1] ≈ sum(t)

# Daily -> Weekly
ts_weekly = apply(ts_daily_1, Dates.Week(1), first)
@test typeof(ts_weekly) == TSFrames.TSFrame
@test typeof(ts_weekly.coredata) == DataFrame
@test DataFrames.nrow(ts_weekly.coredata) == 52

ts_weekly = apply(ts_daily_1, Dates.Week(1), last)
@test typeof(ts_weekly) == TSFrames.TSFrame
@test typeof(ts_weekly.coredata) == DataFrame
@test DataFrames.nrow(ts_weekly.coredata) == 52

ts_weekly = apply(ts_daily_1, Dates.Week(1), first)
@test typeof(ts_weekly) == TSFrames.TSFrame
@test typeof(ts_weekly.coredata) == DataFrame
@test DataFrames.nrow(ts_weekly.coredata) == 52

ts_weekly = apply(ts_daily_1, Dates.Week(2), first)
@test typeof(ts_weekly) == TSFrames.TSFrame
@test typeof(ts_weekly.coredata) == DataFrame
@test DataFrames.nrow(ts_weekly.coredata) == 26

ts_weekly = apply(ts_daily_1, Dates.Week(52), first)
@test typeof(ts_weekly) == TSFrames.TSFrame
@test typeof(ts_weekly.coredata) == DataFrame
@test DataFrames.nrow(ts_weekly.coredata) == 1

ts_weekly = apply(ts_daily_1, Dates.Week(100), first)
@test typeof(ts_weekly) == TSFrames.TSFrame
@test typeof(ts_weekly.coredata) == DataFrame
@test DataFrames.nrow(ts_weekly.coredata) == 1

# Daily -> Quarterly
ts_quarterly = apply(ts_daily_1, Dates.Quarter(1), first)
@test typeof(ts_quarterly) == TSFrames.TSFrame
@test typeof(ts_quarterly.coredata) == DataFrame
@test DataFrames.nrow(ts_quarterly.coredata) == 4

ts_quarterly = apply(ts_daily_1, Dates.Quarter(1), last)
@test typeof(ts_quarterly) == TSFrames.TSFrame
@test typeof(ts_quarterly.coredata) == DataFrame
@test DataFrames.nrow(ts_quarterly.coredata) == 4

ts_quarterly = apply(ts_daily_1, Dates.Quarter(1), first)
@test typeof(ts_quarterly) == TSFrames.TSFrame
@test typeof(ts_quarterly.coredata) == DataFrame
@test DataFrames.nrow(ts_quarterly.coredata) == 4

ts_quarterly = apply(ts_daily_1, Dates.Quarter(2), first)
@test typeof(ts_quarterly) == TSFrames.TSFrame
@test typeof(ts_quarterly.coredata) == DataFrame
@test DataFrames.nrow(ts_quarterly.coredata) == 2

ts_quarterly = apply(ts_daily_1, Dates.Quarter(4), first)
@test typeof(ts_quarterly) == TSFrames.TSFrame
@test typeof(ts_quarterly.coredata) == DataFrame
@test DataFrames.nrow(ts_quarterly.coredata) == 1

ts_quarterly = apply(ts_daily_1, Dates.Quarter(100), first)
@test typeof(ts_quarterly) == TSFrames.TSFrame
@test typeof(ts_quarterly.coredata) == DataFrame
@test DataFrames.nrow(ts_quarterly.coredata) == 1

ts_quarterly = apply(ts_daily_1, Dates.Quarter(1), Statistics.mean)
t = ts_daily_1[:, "data"]
@test typeof(ts_quarterly) == TSFrames.TSFrame
@test typeof(ts_quarterly.coredata) == DataFrame
@test DataFrames.nrow(ts_quarterly.coredata) == 4
@test typeof(ts_quarterly[:, "data_mean"]) == Vector{Float64}
@test ts_quarterly[1, "data_mean"] ≈ Statistics.mean(t[1:90])

ts_quarterly = apply(ts_daily_1, Dates.Quarter(1), sum)
t = ts_daily_1[:, "data"]
@test typeof(ts_quarterly) == TSFrames.TSFrame
@test typeof(ts_quarterly.coredata) == DataFrame
@test DataFrames.nrow(ts_quarterly.coredata) == 4
@test typeof(ts_quarterly[:, "data_sum"]) == Vector{Float64}
@test ts_quarterly[1, "data_sum"] ≈ sum(t[1:90])

ts_quarterly = apply(ts_daily_1, Dates.Quarter(1), sum, last)
t = ts_daily_1[:, "data"]
@test typeof(ts_quarterly) == TSFrames.TSFrame
@test typeof(ts_quarterly.coredata) == DataFrame
@test DataFrames.nrow(ts_quarterly.coredata) == 4
@test typeof(ts_quarterly[:, "data_sum"]) == Vector{Float64}
@test ts_quarterly[1, "data_sum"] ≈ sum(t[1:90])
@test ts_quarterly["2007-03-31"][1,1] ≈ sum(t[1:90])


# Daily -> Daily
ts_test_daily = apply(ts_daily_1, Dates.Day(1), first)
@test typeof(ts_test_daily) == TSFrames.TSFrame
@test typeof(ts_test_daily.coredata) == DataFrame
@test DataFrames.nrow(ts_test_daily.coredata) == 360

ts_test_daily = apply(ts_daily_1, Dates.Day(1), last)
@test typeof(ts_test_daily) == TSFrames.TSFrame
@test typeof(ts_test_daily.coredata) == DataFrame
@test DataFrames.nrow(ts_test_daily.coredata) == 360

ts_test_daily = apply(ts_daily_1, Dates.Day(1), first)
@test typeof(ts_test_daily) == TSFrames.TSFrame
@test typeof(ts_test_daily.coredata) == DataFrame
@test DataFrames.nrow(ts_test_daily.coredata) == 360

ts_test_daily = apply(ts_daily_1, Dates.Day(2), first)
@test typeof(ts_test_daily) == TSFrames.TSFrame
@test typeof(ts_test_daily.coredata) == DataFrame
@test DataFrames.nrow(ts_test_daily.coredata) == 180

ts_test_daily = apply(ts_daily_1, Dates.Day(3), first)
@test typeof(ts_test_daily) == TSFrames.TSFrame
@test typeof(ts_test_daily.coredata) == DataFrame
@test DataFrames.nrow(ts_test_daily.coredata) == 120

ts_test_daily = apply(ts_daily_1, Dates.Day(180), first)
@test typeof(ts_test_daily) == TSFrames.TSFrame
@test typeof(ts_test_daily.coredata) == DataFrame
@test DataFrames.nrow(ts_test_daily.coredata) == 2

ts_test_daily = apply(ts_daily_1, Dates.Day(360), first)
@test typeof(ts_test_daily) == TSFrames.TSFrame
@test typeof(ts_test_daily.coredata) == DataFrame
@test DataFrames.nrow(ts_test_daily.coredata) == 1

ts_test_daily = apply(ts_daily_1, Dates.Day(1000), first)
@test typeof(ts_test_daily) == TSFrames.TSFrame
@test typeof(ts_test_daily.coredata) == DataFrame
@test DataFrames.nrow(ts_test_daily.coredata) == 1


# Secondly -> Yearly
ts_yearly = apply(ts_intraday_2, Dates.Year(1), first)
@test typeof(ts_yearly) == TSFrames.TSFrame
@test typeof(ts_yearly.coredata) == DataFrame
@test DataFrames.nrow(ts_yearly.coredata) == 1

ts_yearly = apply(ts_intraday_2, Dates.Year(1), last)
@test typeof(ts_yearly) == TSFrames.TSFrame
@test typeof(ts_yearly.coredata) == DataFrame
@test DataFrames.nrow(ts_yearly.coredata) == 1

ts_yearly = apply(ts_intraday_2, Dates.Year(1), first)
@test typeof(ts_yearly) == TSFrames.TSFrame
@test typeof(ts_yearly.coredata) == DataFrame
@test DataFrames.nrow(ts_yearly.coredata) == 1

ts_yearly = apply(ts_intraday_2, Dates.Year(100), first)
@test typeof(ts_yearly) == TSFrames.TSFrame
@test typeof(ts_yearly.coredata) == DataFrame
@test DataFrames.nrow(ts_yearly.coredata) == 1


# Secondly -> Monthly
ts_monthly = apply(ts_intraday_2, Dates.Month(1), first)
@test typeof(ts_monthly) == TSFrames.TSFrame
@test typeof(ts_monthly.coredata) == DataFrame
@test DataFrames.nrow(ts_monthly.coredata) == 1

ts_monthly = apply(ts_intraday_2, Dates.Month(1), last)
@test typeof(ts_monthly) == TSFrames.TSFrame
@test typeof(ts_monthly.coredata) == DataFrame
@test DataFrames.nrow(ts_monthly.coredata) == 1

ts_monthly = apply(ts_intraday_2, Dates.Month(1), first)
@test typeof(ts_monthly) == TSFrames.TSFrame
@test typeof(ts_monthly.coredata) == DataFrame
@test DataFrames.nrow(ts_monthly.coredata) == 1

ts_monthly = apply(ts_intraday_2, Dates.Month(100), first)
@test typeof(ts_monthly) == TSFrames.TSFrame
@test typeof(ts_monthly.coredata) == DataFrame
@test DataFrames.nrow(ts_monthly.coredata) == 1


# Secondly -> Weekly
ts_weekly = apply(ts_intraday_2, Dates.Week(1), first)
@test typeof(ts_weekly) == TSFrames.TSFrame
@test typeof(ts_weekly.coredata) == DataFrame
@test DataFrames.nrow(ts_weekly.coredata) == 1

ts_weekly = apply(ts_intraday_2, Dates.Week(1), last)
@test typeof(ts_weekly) == TSFrames.TSFrame
@test typeof(ts_weekly.coredata) == DataFrame
@test DataFrames.nrow(ts_weekly.coredata) == 1

ts_weekly = apply(ts_intraday_2, Dates.Week(1), first)
@test typeof(ts_weekly) == TSFrames.TSFrame
@test typeof(ts_weekly.coredata) == DataFrame
@test DataFrames.nrow(ts_weekly.coredata) == 1

ts_weekly = apply(ts_intraday_2, Dates.Week(100), first)
@test typeof(ts_weekly) == TSFrames.TSFrame
@test typeof(ts_weekly.coredata) == DataFrame
@test DataFrames.nrow(ts_weekly.coredata) == 1


# Secondly -> Quarterly
ts_quarterly = apply(ts_intraday_2, Dates.Quarter(1), first)
@test typeof(ts_quarterly) == TSFrames.TSFrame
@test typeof(ts_quarterly.coredata) == DataFrame
@test DataFrames.nrow(ts_quarterly.coredata) == 1

ts_quarterly = apply(ts_intraday_2, Dates.Quarter(1), last)
@test typeof(ts_quarterly) == TSFrames.TSFrame
@test typeof(ts_quarterly.coredata) == DataFrame
@test DataFrames.nrow(ts_quarterly.coredata) == 1

ts_quarterly = apply(ts_intraday_2, Dates.Quarter(1), first)
@test typeof(ts_quarterly) == TSFrames.TSFrame
@test typeof(ts_quarterly.coredata) == DataFrame
@test DataFrames.nrow(ts_quarterly.coredata) == 1

ts_quarterly = apply(ts_intraday_2, Dates.Quarter(100), first)
@test typeof(ts_quarterly) == TSFrames.TSFrame
@test typeof(ts_quarterly.coredata) == DataFrame
@test DataFrames.nrow(ts_quarterly.coredata) == 1


# Secondly -> Daily
ts_test_daily = apply(ts_intraday_2, Dates.Day(1), first)
@test typeof(ts_test_daily) == TSFrames.TSFrame
@test typeof(ts_test_daily.coredata) == DataFrame
@test DataFrames.nrow(ts_test_daily.coredata) == 1

ts_test_daily = apply(ts_intraday_2, Dates.Day(1), last)
@test typeof(ts_test_daily) == TSFrames.TSFrame
@test typeof(ts_test_daily.coredata) == DataFrame
@test DataFrames.nrow(ts_test_daily.coredata) == 1

ts_test_daily = apply(ts_intraday_2, Dates.Day(1), first)
@test typeof(ts_test_daily) == TSFrames.TSFrame
@test typeof(ts_test_daily.coredata) == DataFrame
@test DataFrames.nrow(ts_test_daily.coredata) == 1

ts_test_daily = apply(ts_intraday_2, Dates.Day(100), first)
@test typeof(ts_test_daily) == TSFrames.TSFrame
@test typeof(ts_test_daily.coredata) == DataFrame
@test DataFrames.nrow(ts_test_daily.coredata) == 1


# Secondly -> Hourly
ts_hourly = apply(ts_intraday_2, Dates.Hour(1), first)
@test typeof(ts_hourly) == TSFrames.TSFrame
@test typeof(ts_hourly.coredata) == DataFrame
@test DataFrames.nrow(ts_hourly.coredata) == 24

ts_hourly = apply(ts_intraday_2, Dates.Hour(1), last)
@test typeof(ts_hourly) == TSFrames.TSFrame
@test typeof(ts_hourly.coredata) == DataFrame
@test DataFrames.nrow(ts_hourly.coredata) == 24

ts_hourly = apply(ts_intraday_2, Dates.Hour(1), first)
@test typeof(ts_hourly) == TSFrames.TSFrame
@test typeof(ts_hourly.coredata) == DataFrame
@test DataFrames.nrow(ts_hourly.coredata) == 24

ts_hourly = apply(ts_intraday_2, Dates.Hour(2), first)
@test typeof(ts_hourly) == TSFrames.TSFrame
@test typeof(ts_hourly.coredata) == DataFrame
@test DataFrames.nrow(ts_hourly.coredata) == 12

ts_hourly = apply(ts_intraday_2, Dates.Hour(3), first)
@test typeof(ts_hourly) == TSFrames.TSFrame
@test typeof(ts_hourly.coredata) == DataFrame
@test DataFrames.nrow(ts_hourly.coredata) == 8

ts_hourly = apply(ts_intraday_2, Dates.Hour(12), first)
@test typeof(ts_hourly) == TSFrames.TSFrame
@test typeof(ts_hourly.coredata) == DataFrame
@test DataFrames.nrow(ts_hourly.coredata) == 2

ts_hourly = apply(ts_intraday_2, Dates.Hour(24), first)
@test typeof(ts_hourly) == TSFrames.TSFrame
@test typeof(ts_hourly.coredata) == DataFrame
@test DataFrames.nrow(ts_hourly.coredata) == 1

ts_hourly = apply(ts_intraday_2, Dates.Hour(100), first)
@test typeof(ts_hourly) == TSFrames.TSFrame
@test typeof(ts_hourly.coredata) == DataFrame
@test DataFrames.nrow(ts_hourly.coredata) == 1

ts_hourly = apply(ts_intraday_2, Dates.Hour(1), Statistics.mean)
t = ts_intraday_2[:, "data"]
@test typeof(ts_hourly) == TSFrames.TSFrame
@test typeof(ts_hourly.coredata) == DataFrame
@test DataFrames.nrow(ts_hourly.coredata) == 24
@test typeof(ts_hourly[:, "data_mean"]) == Vector{Float64}
@test ts_hourly[1, "data_mean"] ≈ Statistics.mean(t[1:3600])

ts_hourly = apply(ts_intraday_2, Dates.Hour(1), sum)
t = ts_intraday_2[:, "data"]
@test typeof(ts_hourly) == TSFrames.TSFrame
@test typeof(ts_hourly.coredata) == DataFrame
@test DataFrames.nrow(ts_hourly.coredata) == 24
@test typeof(ts_hourly[:, "data_sum"]) == Vector{Float64}
@test ts_hourly[1, "data_sum"] ≈ sum(t[1:3600])

ts_hourly = apply(ts_intraday_2, Dates.Hour(1), sum, last)
t = ts_intraday_2[:, "data"]
@test typeof(ts_hourly) == TSFrames.TSFrame
@test typeof(ts_hourly.coredata) == DataFrame
@test DataFrames.nrow(ts_hourly.coredata) == 24
@test typeof(ts_hourly[:, "data_sum"]) == Vector{Float64}
@test ts_hourly[1, "data_sum"] ≈ sum(t[1:3600])
@test ts_hourly[DateTime(2000, 1, 1, 0, 59, 59)][1,1] ≈ sum(t[1:3600])

ts_hourly = apply(ts_intraday_2, Dates.Hour(2), sum, last)
t = ts_intraday_2[:, "data"]
@test typeof(ts_hourly) == TSFrames.TSFrame
@test typeof(ts_hourly.coredata) == DataFrame
@test DataFrames.nrow(ts_hourly.coredata) == 12
@test typeof(ts_hourly[:, "data_sum"]) == Vector{Float64}
@test ts_hourly[1, "data_sum"] ≈ sum(t[1:7200])
@test ts_hourly[DateTime(2000, 1, 1, 1, 59, 59)][1,1] ≈ sum(t[1:7200])

# Secondly -> Minutely
ts_minutely = apply(ts_intraday_2, Dates.Minute(1), first)
@test typeof(ts_minutely) == TSFrames.TSFrame
@test typeof(ts_minutely.coredata) == DataFrame
@test DataFrames.nrow(ts_minutely.coredata) == 1440

ts_minutely = apply(ts_intraday_2, Dates.Minute(1), last)
@test typeof(ts_minutely) == TSFrames.TSFrame
@test typeof(ts_minutely.coredata) == DataFrame
@test DataFrames.nrow(ts_minutely.coredata) == 1440

ts_minutely = apply(ts_intraday_2, Dates.Minute(1), first)
@test typeof(ts_minutely) == TSFrames.TSFrame
@test typeof(ts_minutely.coredata) == DataFrame
@test DataFrames.nrow(ts_minutely.coredata) == 1440

ts_minutely = apply(ts_intraday_2, Dates.Minute(2), first)
@test typeof(ts_minutely) == TSFrames.TSFrame
@test typeof(ts_minutely.coredata) == DataFrame
@test DataFrames.nrow(ts_minutely.coredata) == 720

ts_minutely = apply(ts_intraday_2, Dates.Minute(720), first)
@test typeof(ts_minutely) == TSFrames.TSFrame
@test typeof(ts_minutely.coredata) == DataFrame
@test DataFrames.nrow(ts_minutely.coredata) == 2

ts_minutely = apply(ts_intraday_2, Dates.Minute(1440), first)
@test typeof(ts_minutely) == TSFrames.TSFrame
@test typeof(ts_minutely.coredata) == DataFrame
@test DataFrames.nrow(ts_minutely.coredata) == 1

ts_minutely = apply(ts_intraday_2, Dates.Minute(100000), first)
@test typeof(ts_minutely) == TSFrames.TSFrame
@test typeof(ts_minutely.coredata) == DataFrame
@test DataFrames.nrow(ts_minutely.coredata) == 1

ts_minutely = apply(ts_intraday_2, Dates.Minute(1), Statistics.mean)
t = ts_intraday_2[:, "data"]
@test typeof(ts_minutely) == TSFrames.TSFrame
@test typeof(ts_minutely.coredata) == DataFrame
@test DataFrames.nrow(ts_minutely.coredata) == 1440
@test typeof(ts_minutely[:, "data_mean"]) == Vector{Float64}
@test ts_minutely[1, "data_mean"] ≈ Statistics.mean(t[1:60])

ts_minutely = apply(ts_intraday_2, Dates.Minute(1), sum)
t = ts_intraday_2[:, "data"]
@test typeof(ts_minutely) == TSFrames.TSFrame
@test typeof(ts_minutely.coredata) == DataFrame
@test DataFrames.nrow(ts_minutely.coredata) == 1440
@test typeof(ts_minutely[:, "data_sum"]) == Vector{Float64}
@test ts_minutely[1, "data_sum"] ≈ sum(t[1:60])

ts_minutely = apply(ts_intraday_2, Dates.Minute(1), sum, last)
t = ts_intraday_2[:, "data"]
@test typeof(ts_minutely) == TSFrames.TSFrame
@test typeof(ts_minutely.coredata) == DataFrame
@test DataFrames.nrow(ts_minutely.coredata) == 1440
@test typeof(ts_minutely[:, "data_sum"]) == Vector{Float64}
@test ts_minutely[1, "data_sum"] ≈ sum(t[1:60])
@test ts_minutely[DateTime(2000, 1, 1, 0, 0, 59)][1,1] ≈ sum(t[1:60])

ts_minutely = apply(ts_intraday_2, Dates.Minute(2), sum, last)
t = ts_intraday_2[:, "data"]
@test typeof(ts_minutely) == TSFrames.TSFrame
@test typeof(ts_minutely.coredata) == DataFrame
@test DataFrames.nrow(ts_minutely.coredata) == 720
@test typeof(ts_minutely[:, "data_sum"]) == Vector{Float64}
@test ts_minutely[1, "data_sum"] ≈ sum(t[1:120])
@test ts_minutely[DateTime(2000, 1, 1, 0, 1, 59)][1,1] ≈ sum(t[1:120])


# Secondly -> Secondly
ts_secondly = apply(ts_intraday_2, Dates.Second(1), first)
@test typeof(ts_secondly) == TSFrames.TSFrame
@test typeof(ts_secondly.coredata) == DataFrame
@test DataFrames.nrow(ts_secondly.coredata) == 86400

ts_secondly = apply(ts_intraday_2, Dates.Second(1), last)
@test typeof(ts_secondly) == TSFrames.TSFrame
@test typeof(ts_secondly.coredata) == DataFrame
@test DataFrames.nrow(ts_secondly.coredata) == 86400

ts_secondly = apply(ts_intraday_2, Dates.Second(1), first)
@test typeof(ts_secondly) == TSFrames.TSFrame
@test typeof(ts_secondly.coredata) == DataFrame
@test DataFrames.nrow(ts_secondly.coredata) == 86400
@test ts_secondly[:, "data_first"] == ts_intraday_2[:, "data"]

ts_secondly = apply(ts_intraday_2, Dates.Second(2), first)
@test typeof(ts_secondly) == TSFrames.TSFrame
@test typeof(ts_secondly.coredata) == DataFrame
@test DataFrames.nrow(ts_secondly.coredata) == 43200

ts_secondly = apply(ts_intraday_2, Dates.Second(43200), first)
@test typeof(ts_secondly) == TSFrames.TSFrame
@test typeof(ts_secondly.coredata) == DataFrame
@test DataFrames.nrow(ts_secondly.coredata) == 2

ts_secondly = apply(ts_intraday_2, Dates.Second(86400), first)
@test typeof(ts_secondly) == TSFrames.TSFrame
@test typeof(ts_secondly.coredata) == DataFrame
@test DataFrames.nrow(ts_secondly.coredata) == 1

ts_secondly = apply(ts_intraday_2, Dates.Second(100000), first)
@test typeof(ts_secondly) == TSFrames.TSFrame
@test typeof(ts_secondly.coredata) == DataFrame
@test DataFrames.nrow(ts_secondly.coredata) == 1

ts_secondly = apply(ts_intraday_2, Dates.Second(1), Statistics.mean)
t = ts_intraday_2[:, "data"]
@test typeof(ts_secondly) == TSFrames.TSFrame
@test typeof(ts_secondly.coredata) == DataFrame
@test DataFrames.nrow(ts_secondly.coredata) == 86400
@test typeof(ts_secondly[:, "data_mean"]) == Vector{Float64}
@test ts_secondly[1, "data_mean"] ≈ Statistics.mean(t[1])

ts_secondly = apply(ts_intraday_2, Dates.Second(1), sum)
t = ts_intraday_2[:, "data"]
@test typeof(ts_secondly) == TSFrames.TSFrame
@test typeof(ts_secondly.coredata) == DataFrame
@test DataFrames.nrow(ts_secondly.coredata) == 86400
@test typeof(ts_secondly[:, "data_sum"]) == Vector{Float64}
@test ts_secondly[1, "data_sum"] ≈ sum(t[1])

ts_secondly = apply(ts_intraday_2, Dates.Second(1), sum, last)
t = ts_intraday_2[:, "data"]
@test typeof(ts_secondly) == TSFrames.TSFrame
@test typeof(ts_secondly.coredata) == DataFrame
@test DataFrames.nrow(ts_secondly.coredata) == 86400
@test typeof(ts_secondly[:, "data_sum"]) == Vector{Float64}
@test ts_secondly[1, "data_sum"] ≈ sum(t[1])
@test ts_secondly[DateTime(2000, 1, 1, 0, 0, 0)][1,1] ≈ sum(t[1])

ts_secondly = apply(ts_intraday_2, Dates.Second(2), sum, last)
t = ts_intraday_2[:, "data"]
@test typeof(ts_secondly) == TSFrames.TSFrame
@test typeof(ts_secondly.coredata) == DataFrame
@test DataFrames.nrow(ts_secondly.coredata) == 43200
@test typeof(ts_secondly[:, "data_sum"]) == Vector{Float64}
@test ts_secondly[1, "data_sum"] ≈ sum(t[1:2])
@test ts_secondly[DateTime(2000, 1, 1, 0, 0, 1)][1,1] ≈ sum(t[1:2])

# Multi-column TSFrame value correctness
@testset "apply multi-column correctness" begin
    using Statistics
    dates = collect(Date(2020,1,1):Day(1):Date(2020,3,31))  # 91 days
    rng = MersenneTwister(42)
    df_mc = DataFrame(A=rand(rng, 91), B=rand(rng, 91))
    ts_mc = TSFrame(df_mc, dates)

    result = apply(ts_mc, Month(1), mean)
    @test DataFrames.nrow(result.coredata) == 3   # Jan, Feb, Mar
    @test result[1, "A_mean"] ≈ mean(df_mc.A[1:31])
    @test result[1, "B_mean"] ≈ mean(df_mc.B[1:31])
    @test result[2, "A_mean"] ≈ mean(df_mc.A[32:60])   # Feb: days 32-60
    @test result[2, "B_mean"] ≈ mean(df_mc.B[32:60])
end

@testset "apply renamecols=false" begin
    dates = collect(Date(2020,1,1):Day(1):Date(2020,1,31))
    ts_rc = TSFrame(DataFrame(val=randn(MersenneTwister(1), 31)), dates)

    result_true  = apply(ts_rc, Month(1), sum; renamecols=true)
    result_false = apply(ts_rc, Month(1), sum; renamecols=false)

    # renamecols=true: column named "val_sum"
    @test "val_sum" in names(result_true.coredata)
    # renamecols=false: column keeps original name "val"
    @test "val" in names(result_false.coredata)
    # Values should be equal
    @test result_true[1, "val_sum"] ≈ result_false[1, "val"]
end

@testset "apply empty TSFrame" begin
    empty_ts = TSFrame(DataFrame(Index=Date[], x=Float64[]))
    result = apply(empty_ts, Month(1), sum)
    @test DataFrames.nrow(result.coredata) == 0
    @test "x_sum" in names(result.coredata)
end
