# test/resample.jl
# Tests for resample() — period-based resampling with per-column aggregation

using Dates, DataFrames, Statistics, Test, TSFrames

# -- Test data setup -----------------------------------------------------------

# 28 days of daily OHLCV data (Jan 1–28, 2020)
# Jan 1, 2020 is a Wednesday. Weekly endpoints (floor to Monday) produce 5 groups:
#   Group 1: rows 1-5   (Jan 1-5,   Wed-Sun)   — partial first week
#   Group 2: rows 6-12  (Jan 6-12,  Mon-Sun)   — full week
#   Group 3: rows 13-19 (Jan 13-19, Mon-Sun)   — full week
#   Group 4: rows 20-26 (Jan 20-26, Mon-Sun)   — full week
#   Group 5: rows 27-28 (Jan 27-28, Mon-Tue)   — partial last week
_dates_28 = collect(Date(2020,1,1):Day(1):Date(2020,1,28))
_df_ohlcv = DataFrame(
    Open   = Float64.(1:28),
    High   = Float64.(2:29),
    Low    = Float64.(0:27),
    Close  = Float64.(1:28) .+ 0.5,
    Volume = Int.(100:127),
)
ts_ohlcv = TSFrame(_df_ohlcv, _dates_28)

# Single-column TSFrame for compatibility with apply()
_df_single = DataFrame(x1 = randn(MersenneTwister(42), 28))
ts_single = TSFrame(_df_single, _dates_28)

# -- 1. Default OHLCV resampling ----------------------------------------------

@testset "resample default OHLCV" begin
    weekly = resample(ts_ohlcv, Week(1))

    # 5 weekly groups (partial first + 3 full + partial last)
    @test DataFrames.nrow(weekly.coredata) == 5

    # Column names preserved (renamecols=false default)
    @test names(weekly) == ["Open", "High", "Low", "Close", "Volume"]

    # Open = first of each group
    # Group 1: rows 1-5 -> Open[1]=1.0
    # Group 2: rows 6-12 -> Open[6]=6.0
    # Group 3: rows 13-19 -> Open[13]=13.0
    # Group 4: rows 20-26 -> Open[20]=20.0
    # Group 5: rows 27-28 -> Open[27]=27.0
    @test weekly[:, :Open][1] ≈ 1.0
    @test weekly[:, :Open][2] ≈ 6.0
    @test weekly[:, :Open][3] ≈ 13.0
    @test weekly[:, :Open][4] ≈ 20.0
    @test weekly[:, :Open][5] ≈ 27.0

    # High = maximum of each group
    # Group 1: High rows 1-5 = 2..6, max=6
    # Group 2: High rows 6-12 = 7..13, max=13
    @test weekly[:, :High][1] ≈ maximum(Float64.(2:6))
    @test weekly[:, :High][2] ≈ maximum(Float64.(7:13))

    # Low = minimum of each group
    # Group 1: Low rows 1-5 = 0..4, min=0
    @test weekly[:, :Low][1] ≈ minimum(Float64.(0:4))

    # Close = last of each group
    # Group 1: Close[5] = 5.5
    # Group 5: Close[28] = 28.5
    @test weekly[:, :Close][1] ≈ 5.5
    @test weekly[:, :Close][5] ≈ 28.5

    # Volume = sum of each group
    # Group 1: Volume rows 1-5 = 100..104, sum=510
    @test weekly[:, :Volume][1] == sum(100:104)

    # Monthly
    monthly = resample(ts_ohlcv, Month(1))
    @test DataFrames.nrow(monthly.coredata) == 1  # all in January
    @test monthly[:, :Open][1] ≈ 1.0
    @test monthly[:, :High][1] ≈ maximum(Float64.(2:29))
    @test monthly[:, :Volume][1] == sum(100:127)
end

# -- 2. index_at parameter ----------------------------------------------------

@testset "resample index_at" begin
    weekly_first = resample(ts_ohlcv, Week(1); index_at=first)
    weekly_last  = resample(ts_ohlcv, Week(1); index_at=last)

    # first: index is first day of each group
    @test weekly_first.coredata[1, :Index] == Date(2020,1,1)

    # last: index is last day of each group (group 1 ends on Jan 5)
    @test weekly_last.coredata[1, :Index] == Date(2020,1,5)
end

# -- 3. Custom Symbol => Function pairs ----------------------------------------

@testset "resample Symbol pairs" begin
    result = resample(ts_ohlcv, Week(1), :Open => first, :Close => last)

    # Only specified columns returned
    @test sort(names(result)) == sort(["Open", "Close"])
    @test DataFrames.nrow(result.coredata) == 5

    # Values correct (group 1: rows 1-5)
    @test result[:, :Open][1] ≈ 1.0
    @test result[:, :Close][1] ≈ 5.5

    # Single column
    result2 = resample(ts_ohlcv, Month(1), :Volume => sum)
    @test DataFrames.nrow(result2.coredata) == 1
    @test result2[:, :Volume][1] == sum(100:127)

    # Custom function (group 1: Open rows 1-5 = 1..5, mean=3.0)
    result3 = resample(ts_ohlcv, Week(1), :Open => mean)
    @test result3[:, :Open][1] ≈ mean(Float64.(1:5))
end

# -- 4. String => Function pairs -----------------------------------------------

@testset "resample String pairs" begin
    result = resample(ts_ohlcv, Week(1), "Open" => first, "Volume" => sum)
    @test sort(names(result)) == sort(["Open", "Volume"])
    @test result[:, :Open][1] ≈ 1.0
    # Group 1: Volume rows 1-5 = 100..104, sum=510
    @test result[:, :Volume][1] == sum(100:104)
end

# -- 5. renamecols parameter ---------------------------------------------------

@testset "resample renamecols" begin
    # renamecols=false (default): original names preserved
    r_false = resample(ts_ohlcv, Week(1), :Open => first; renamecols=false)
    @test "Open" in names(r_false)

    # renamecols=true: DataFrames auto-naming
    r_true = resample(ts_ohlcv, Week(1), :Open => first; renamecols=true)
    @test "Open_first" in names(r_true)
end

# -- 6. Error cases ------------------------------------------------------------

@testset "resample errors" begin
    # Non-existent column
    @test_throws ArgumentError resample(ts_ohlcv, Week(1), :NonExistent => first)
    @test_throws ArgumentError resample(ts_ohlcv, Week(1), "BadCol" => sum)

    # No OHLCV columns in default mode
    ts_no_ohlcv = TSFrame(DataFrame(foo=randn(28), bar=randn(28)), _dates_28)
    @test_throws ArgumentError resample(ts_no_ohlcv, Week(1))
end

# -- 7. Partial OHLCV columns (default mode) -----------------------------------

@testset "resample partial OHLCV" begin
    # Only Open and Close (no High/Low/Volume)
    ts_partial = TSFrame(DataFrame(Open=Float64.(1:28), Close=Float64.(1:28).+0.5), _dates_28)
    result = resample(ts_partial, Week(1))

    # Only present columns returned
    @test sort(names(result)) == sort(["Open", "Close"])
    @test result[:, :Open][1] ≈ 1.0
    # Group 1: Close rows 1-5, last = 5.5
    @test result[:, :Close][1] ≈ 5.5
end

# -- 8. Consistency with apply() -----------------------------------------------

@testset "resample consistency with apply" begin
    # resample with single column should match apply() result values
    apply_result   = apply(ts_single, Week(1), first; renamecols=false)
    resample_result = resample(ts_single, Week(1), :x1 => first)

    @test DataFrames.nrow(apply_result.coredata) == DataFrames.nrow(resample_result.coredata)
    @test apply_result[:, :x1] ≈ resample_result[:, :x1]
    @test apply_result.coredata[:, :Index] == resample_result.coredata[:, :Index]
end

# -- 9. TSFrame index type -----------------------------------------------------

@testset "resample output is TSFrame" begin
    result = resample(ts_ohlcv, Week(1))
    @test result isa TSFrame
    @test eltype(result.coredata[:, :Index]) <: Dates.Date
end

# -- 10. Empty TSFrame ---------------------------------------------------------

@testset "resample empty TSFrame" begin
    ts_empty = TSFrame(DataFrame(Open=Float64[], Close=Float64[]), Date[])

    # Default OHLCV mode: no rows, correct columns
    result = resample(ts_empty, Week(1))
    @test result isa TSFrame
    @test DataFrames.nrow(result.coredata) == 0
    @test "Open" in names(result)
    @test "Close" in names(result)

    # Explicit pairs mode
    result2 = resample(ts_empty, Month(1), :Open => first, :Close => last)
    @test DataFrames.nrow(result2.coredata) == 0
    @test sort(names(result2)) == sort(["Open", "Close"])
end
