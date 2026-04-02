# test/irregular_timeseries.jl
# Tests for irregular (non-uniform) time series operations

using Dates, DataFrames, Statistics, Test, TSFrames

# -- Helper: generate weekday-only dates ---------------------------------------

function weekday_dates(start::Date, n::Int)
    dates = Date[]
    d = start
    while length(dates) < n
        if dayofweek(d) <= 5  # Mon-Fri
            push!(dates, d)
        end
        d += Day(1)
    end
    return dates
end

# -- Test data setup -----------------------------------------------------------

# 20 weekday-only dates starting from 2020-01-06 (Monday)
_irreg_dates = weekday_dates(Date(2020, 1, 6), 20)
_irreg_vals = Float64.(1:20)
ts_irreg = TSFrame(_irreg_vals, _irreg_dates)

# -- 1. Construction with weekday-only data ------------------------------------

@testset "irregular construction" begin
    @test ts_irreg isa TSFrame
    @test length(ts_irreg) == 20

    # Verify there are gaps (weekends missing)
    diffs = diff(index(ts_irreg))
    @test any(d -> d > Day(1), diffs)  # some gaps > 1 day (weekends)
end

# -- 2. isregular() returns false for irregular data ---------------------------

@testset "isregular false for weekday data" begin
    @test !isregular(ts_irreg)
    @test !isregular(ts_irreg, Day(1))
end

# -- 3. endpoints() on weekday-only data to weekly -----------------------------

@testset "endpoints irregular weekly" begin
    ep = endpoints(ts_irreg, Week(1))
    @test length(ep) >= 1

    # Each endpoint should be the last trading day of the week (Friday)
    for i in 1:length(ep)-1
        ep_date = index(ts_irreg)[ep[i]]
        @test dayofweek(ep_date) == 5  # Friday
    end

    # Last endpoint is always the last row
    @test ep[end] == length(ts_irreg)
end

@testset "endpoints irregular monthly" begin
    # Use longer series for monthly endpoints
    long_dates = weekday_dates(Date(2020, 1, 1), 60)
    long_ts = TSFrame(Float64.(1:60), long_dates)
    ep = endpoints(long_ts, Month(1))

    @test length(ep) >= 2

    # Last endpoint should be the last row
    @test ep[end] == length(long_ts)
end

# -- 4. apply() on irregular data ----------------------------------------------

@testset "apply irregular weekly" begin
    result = apply(ts_irreg, Week(1), mean)
    @test result isa TSFrame
    @test length(result) >= 1

    # First week: Mon-Fri = 5 weekdays, mean(1:5) = 3.0
    @test result[1, :x1_mean] ≈ mean(1.0:5.0)
end

@testset "apply irregular monthly" begin
    long_dates = weekday_dates(Date(2020, 1, 1), 60)
    long_ts = TSFrame(Float64.(1:60), long_dates)
    result = apply(long_ts, Month(1), sum)

    @test result isa TSFrame
    @test length(result) >= 2
end

# -- 5. resample() on irregular data -------------------------------------------

@testset "resample irregular with pairs" begin
    # Create irregular OHLCV-like data
    irreg_ohlcv_dates = weekday_dates(Date(2020, 1, 6), 15)
    df_irreg = DataFrame(
        Open   = Float64.(1:15),
        High   = Float64.(2:16),
        Low    = Float64.(0:14),
        Close  = Float64.(1:15) .+ 0.5,
        Volume = collect(100:114),
    )
    ts_irreg_ohlcv = TSFrame(df_irreg, irreg_ohlcv_dates)

    result = resample(ts_irreg_ohlcv, Week(1))
    @test result isa TSFrame
    @test length(result) >= 1

    # First week has 5 trading days
    @test result[:, :Open][1] ≈ 1.0  # first of week
    @test result[:, :High][1] ≈ maximum(Float64.(2:6))  # max High of week
    @test result[:, :Low][1] ≈ minimum(Float64.(0:4))    # min Low of week
    @test result[:, :Close][1] ≈ 5.5  # last Close of week
    @test result[:, :Volume][1] == sum(100:104)  # sum Volume of week
end

# -- 6. lag/lead on irregular data ---------------------------------------------

@testset "lag irregular" begin
    lagged = lag(ts_irreg, 1)
    @test length(lagged) == length(ts_irreg)
    @test isequal(lagged[:, :Index], ts_irreg[:, :Index])
    @test ismissing(lagged[1, :x1])
    @test lagged[2, :x1] == 1.0  # previous value regardless of gap size
end

@testset "lead irregular" begin
    led = lead(ts_irreg, 1)
    @test length(led) == length(ts_irreg)
    @test isequal(led[:, :Index], ts_irreg[:, :Index])
    @test ismissing(led[length(ts_irreg), :x1])
    @test led[1, :x1] == 2.0  # next value regardless of gap size
end

# -- 7. subset() on irregular data ---------------------------------------------

@testset "subset irregular" begin
    sub = TSFrames.subset(ts_irreg, Date(2020, 1, 10), Date(2020, 1, 20))
    @test length(sub) >= 1
    @test all(d -> Date(2020, 1, 10) <= d <= Date(2020, 1, 20), index(sub))

    # Weekend dates should not appear
    @test all(d -> dayofweek(d) <= 5, index(sub))
end

# -- 8. rollapply on irregular data --------------------------------------------

@testset "rollapply irregular" begin
    result = rollapply(ts_irreg, mean, 5)
    @test result isa TSFrame
    @test length(result) == length(ts_irreg) - 5 + 1

    # First window: mean(1,2,3,4,5) = 3.0
    @test result[1, :rolling_x1_mean] ≈ mean(1.0:5.0)
end

# -- 9. Mixed gap sizes --------------------------------------------------------

@testset "irregular mixed gaps" begin
    # Arbitrary irregular timestamps (not just weekday gaps)
    mixed_dates = [Date(2020, 1, 1), Date(2020, 1, 3), Date(2020, 1, 10),
                   Date(2020, 1, 11), Date(2020, 2, 1)]
    mixed_ts = TSFrame(Float64.(1:5), mixed_dates)

    @test !isregular(mixed_ts)
    @test length(mixed_ts) == 5

    # lag still works position-based
    lagged = lag(mixed_ts, 1)
    @test ismissing(lagged[1, :x1])
    @test lagged[2, :x1] == 1.0

    # endpoints works even with large gaps
    ep = endpoints(mixed_ts, Month(1))
    @test length(ep) >= 1
    @test ep[end] == 5
end
