# test/upsample.jl
# Tests for upsample() — convert time series to higher frequency

using Dates, DataFrames, Test, TSFrames

# -- Test data setup -----------------------------------------------------------

_upsample_dates = collect(Date(2020, 1, 1):Day(1):Date(2020, 1, 5))
_upsample_vals = Float64.(1:5)
ts_up_basic = TSFrame(_upsample_vals, _upsample_dates)

# -- 1. Basic upsampling: daily to 12-hourly -----------------------------------

@testset "upsample daily to 12-hourly" begin
    # upsample requires DateTime-compatible index for sub-day periods.
    # Date index with Day period works: daily -> every-other-day won't add rows,
    # but we can test with a DateTime-indexed series.
    dt_dates = collect(DateTime(2020, 1, 1):Day(1):DateTime(2020, 1, 5))
    dt_ts = TSFrame(Float64.(1:5), dt_dates)
    result = upsample(dt_ts, Hour(12))

    # Expected: from Jan 1 00:00 to Jan 5 00:00, step 12h => 9 rows
    @test result isa TSFrame
    expected_index = collect(DateTime(2020, 1, 1):Hour(12):DateTime(2020, 1, 5))
    @test length(result) == length(expected_index)
    @test index(result) == expected_index

    # Original data points should be present (non-missing)
    @test result[1, :x1] == 1.0   # Jan 1 00:00
    @test result[3, :x1] == 2.0   # Jan 2 00:00
    @test result[5, :x1] == 3.0   # Jan 3 00:00

    # Intermediate rows should be missing
    @test ismissing(result[2, :x1])  # Jan 1 12:00
    @test ismissing(result[4, :x1])  # Jan 2 12:00
end

# -- 2. Upsampling hourly to minute-level --------------------------------------

@testset "upsample hourly to minutes" begin
    hr_dates = collect(DateTime(2020, 1, 1):Hour(1):DateTime(2020, 1, 1, 3))
    hr_ts = TSFrame(Float64.(10:13), hr_dates)
    result = upsample(hr_ts, Minute(30))

    expected_index = collect(DateTime(2020, 1, 1):Minute(30):DateTime(2020, 1, 1, 3))
    @test length(result) == length(expected_index)
    @test index(result) == expected_index

    # Original hourly values should be present
    @test result[1, :x1] == 10.0  # 00:00
    @test result[3, :x1] == 11.0  # 01:00
    @test result[5, :x1] == 12.0  # 02:00
    @test result[7, :x1] == 13.0  # 03:00

    # Half-hour marks should be missing
    @test ismissing(result[2, :x1])  # 00:30
    @test ismissing(result[4, :x1])  # 01:30
end

# -- 3. Single-row input -------------------------------------------------------

@testset "upsample single row" begin
    single_ts = TSFrame([42.0], [DateTime(2020, 6, 15)])
    result = upsample(single_ts, Hour(1))

    # Single row: range is zero-length, so output has just 1 row
    @test length(result) == 1
    @test result[1, :x1] == 42.0
end

# -- 4. Multi-column input -----------------------------------------------------

@testset "upsample multi-column" begin
    mc_dates = collect(DateTime(2020, 1, 1):Day(1):DateTime(2020, 1, 3))
    mc_ts = TSFrame([Float64.(1:3) Float64.(11:13)], mc_dates, colnames=[:a, :b])
    result = upsample(mc_ts, Hour(12))

    expected_len = length(collect(DateTime(2020, 1, 1):Hour(12):DateTime(2020, 1, 3)))
    @test length(result) == expected_len

    # Original values present for both columns
    @test result[1, :a] == 1.0
    @test result[1, :b] == 11.0
    @test result[expected_len, :a] == 3.0
    @test result[expected_len, :b] == 13.0

    # Intermediate rows missing for both columns
    @test ismissing(result[2, :a])
    @test ismissing(result[2, :b])
end

# -- 5. Already-at-target-frequency (period matches original step) -------------

@testset "upsample same frequency" begin
    same_dates = collect(DateTime(2020, 1, 1):Hour(1):DateTime(2020, 1, 1, 4))
    same_ts = TSFrame(Float64.(1:5), same_dates)
    result = upsample(same_ts, Hour(1))

    # No new rows should be added
    @test length(result) == 5
    @test index(result) == same_dates
    @test result[:, :x1] == Float64.(1:5)
end

# -- 6. Output length verification ---------------------------------------------

@testset "upsample output length" begin
    # 3 days of data upsampled to 6-hourly => 4 intervals per day * 2 gaps + 1 = 9
    len_dates = collect(DateTime(2020, 1, 1):Day(1):DateTime(2020, 1, 3))
    len_ts = TSFrame(Float64.(1:3), len_dates)
    result = upsample(len_ts, Hour(6))

    expected_index = collect(DateTime(2020, 1, 1):Hour(6):DateTime(2020, 1, 3))
    @test length(result) == length(expected_index)
end

# -- 7. Empty TSFrame guard ----------------------------------------------------

@testset "upsample empty guard" begin
    empty_ts = TSFrame(DataFrame(A=Float64[], Index=Date[]))
    @test TSFrames.nrow(upsample(empty_ts, Day(1))) == 0
end
