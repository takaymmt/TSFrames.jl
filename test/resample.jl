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

# -- 11. Single-row TSFrame -----------------------------------------------------

@testset "Single-row TSFrame" begin
    ts = TSFrame(DataFrame(Open=[1.0], High=[2.0], Low=[0.5], Close=[1.5], Volume=[100]), [Date(2020,1,1)])
    result = resample(ts, Week(1))
    @test DataFrames.nrow(result.coredata) == 1
    @test result[:, :Open][1] == 1.0
    @test result[:, :High][1] == 2.0
    @test result[:, :Low][1] == 0.5
    @test result[:, :Close][1] == 1.5
    @test result[:, :Volume][1] == 100
end

# -- 12. DateTime index ---------------------------------------------------------

@testset "DateTime index" begin
    dts = collect(DateTime(2020,1,1,0,0,0):Hour(1):DateTime(2020,1,7,23,0,0))  # hourly for 7 days
    n = length(dts)
    df = DataFrame(Open=rand(n), High=rand(n).+1.0, Low=rand(n).-1.0, Close=rand(n), Volume=rand(1:100, n))
    ts = TSFrame(df, dts)
    result = resample(ts, Day(1))
    @test DataFrames.nrow(result.coredata) == 7  # 7 days
    @test eltype(index(result)) == DateTime
end

# -- 13. Non-default element types (Float32, Int32) ------------------------------

@testset "Non-default element types" begin
    dates = collect(Date(2020,1,1):Day(1):Date(2020,1,14))
    df = DataFrame(
        price = Float32.(1.0:14.0),
        count = Int32.(1:14)
    )
    ts = TSFrame(df, dates)
    result = resample(ts, Week(1), :price => mean, :count => sum)
    @test eltype(result[:, :price]) <: AbstractFloat  # type may widen to Float64
    @test result[:, :count][1] == sum(Int32.(1:5))  # first week sum (Jan 1-5, Wed-Sun)
end

# -- 14. Missing values in columns -----------------------------------------------

@testset "Missing values in columns" begin
    # Jan 1-7, 2020: Jan 1 (Wed) through Jan 7 (Tue)
    # Weekly grouping (floor to Monday):
    #   Group 1: Jan 1-5 (Wed-Sun) → values [1.0, missing, 3.0, 4.0, missing]
    #   Group 2: Jan 6-7 (Mon-Tue) → values [6.0, 7.0]
    dates = collect(Date(2020,1,1):Day(1):Date(2020,1,7))
    df = DataFrame(
        val = Union{Float64,Missing}[1.0, missing, 3.0, 4.0, missing, 6.0, 7.0]
    )
    ts = TSFrame(df, dates)

    # sum over a column with Missing eltype propagates missing when any element is missing.
    result = resample(ts, Week(1), :val => sum)
    @test ismissing(result[:, :val][1])

    # Workaround: use skipmissing to avoid the issue
    result2 = resample(ts, Week(1), :val => (x -> sum(skipmissing(x))))
    @test !ismissing(result2[:, :val][1])
    @test result2[:, :val][1] ≈ 1.0 + 3.0 + 4.0  # Group 1 non-missing sum
    @test result2[:, :val][2] ≈ 6.0 + 7.0          # Group 2 sum

    # Column with all non-missing values in a Union{Missing,T} column works fine
    dates2 = collect(Date(2020,1,1):Day(1):Date(2020,1,5))
    df2 = DataFrame(val = Union{Float64,Missing}[1.0, 2.0, 3.0, 4.0, 5.0])
    ts2 = TSFrame(df2, dates2)
    result3 = resample(ts2, Week(1), :val => sum)
    @test result3[:, :val][1] ≈ 15.0
end

# -- 15. Missing values — comprehensive ------------------------------------------

@testset "Missing values — comprehensive" begin
    dates = collect(Date(2020,1,1):Day(1):Date(2020,1,14))  # 2 weeks
    # Week grouping (floor to Monday):
    #   Group 1: Jan 1-5   (Wed-Sun, 5 days)  — indices 1-5
    #   Group 2: Jan 6-12  (Mon-Sun, 7 days)  — indices 6-12
    #   Group 3: Jan 13-14 (Mon-Tue, 2 days)  — indices 13-14

    # Case 1: missing in first group only → output must be Union{Missing, Float64}
    col1 = Union{Float64,Missing}[missing, missing, 1.0, 2.0, 3.0, 4.0, 5.0,
                                   6.0,    7.0,    8.0, 9.0, 10.0, 11.0, 12.0]
    ts1 = TSFrame(DataFrame(val=col1), dates)
    r1 = resample(ts1, Week(1), :val => sum)
    @test ismissing(r1[:, :val][1])         # first group has missing → sum=missing
    @test r1[:, :val][2] ≈ 4.0+5.0+6.0+7.0+8.0+9.0+10.0  # group 2: indices 6-12
    @test r1[:, :val][3] ≈ 11.0+12.0                        # group 3: indices 13-14

    # Case 2: missing in second group only → first group returns Float64, second missing
    col2 = Union{Float64,Missing}[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, missing,
                                   8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0]
    ts2 = TSFrame(DataFrame(val=col2), dates)
    r2 = resample(ts2, Week(1), :val => sum)
    @test r2[:, :val][1] ≈ 1.0+2.0+3.0+4.0+5.0             # group 1: no missing
    @test ismissing(r2[:, :val][2])                           # group 2: has missing
    @test r2[:, :val][3] ≈ 13.0+14.0                         # group 3: no missing

    # Case 3: skipmissing wrapper → no missing in output
    ts3 = TSFrame(DataFrame(val=col1), dates)
    r3 = resample(ts3, Week(1), :val => (x -> sum(skipmissing(x))))
    @test !ismissing(r3[:, :val][1])
    @test r3[:, :val][1] ≈ 1.0+2.0+3.0  # skips the 2 missings in group 1

    # Case 4: all-missing group
    col4 = Union{Float64,Missing}[missing, missing, missing, missing, missing,
                                   1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0,
                                   8.0, 9.0]
    ts4 = TSFrame(DataFrame(val=col4), dates)
    r4 = resample(ts4, Week(1), :val => sum)
    @test ismissing(r4[:, :val][1])
    @test r4[:, :val][2] ≈ 1.0+2.0+3.0+4.0+5.0+6.0+7.0
    @test r4[:, :val][3] ≈ 8.0+9.0

    # Case 5: default OHLCV with Missing in Volume
    vol = Union{Int,Missing}[100, missing, 200, 300, 400, 500, 600,
                              700, 800, 900, missing, 1100, 1200, 1300]
    ohlc_df = DataFrame(
        Open   = rand(14),
        High   = rand(14) .+ 1,
        Low    = rand(14) .- 1,
        Close  = rand(14),
        Volume = vol
    )
    ts5 = TSFrame(ohlc_df, dates)
    r5 = resample(ts5, Week(1))
    @test ismissing(r5[:, :Volume][1])   # Group 1 has missing in Volume
    @test ismissing(r5[:, :Volume][2])   # Group 2 has missing in Volume
    @test !ismissing(r5[:, :Volume][3])  # Group 3 (indices 13-14): no missing
    @test !ismissing(r5[:, :Open][1])    # Open (Float64, no missing) → not missing
end

# -- 16. index_at=last with Month period -----------------------------------------

@testset "index_at=last with Month period" begin
    dates = collect(Date(2020,1,1):Day(1):Date(2020,3,31))
    n = length(dates)
    df = DataFrame(Open=rand(n), High=rand(n).+1, Low=rand(n).-1, Close=rand(n), Volume=rand(1:1000,n))
    ts = TSFrame(df, dates)

    result_first = resample(ts, Month(1); index_at=first)
    result_last  = resample(ts, Month(1); index_at=last)

    @test DataFrames.nrow(result_first.coredata) == DataFrames.nrow(result_last.coredata)
    # index_at=first: index is first day of each month
    @test index(result_first)[1] == Date(2020,1,1)
    # index_at=last: index is last day of each month
    @test index(result_last)[1] == Date(2020,1,31)
    # Data values should be identical regardless of index_at
    @test result_first[:, :Open] == result_last[:, :Open]
    @test result_first[:, :Volume] == result_last[:, :Volume]
end

# -- 17. fill_gaps=true ------------------------------------------------------------

@testset "fill_gaps=true" begin
    # ── Monthly gap: Jan + Mar present, Feb missing ──────────────────────
    # endpoints() assigns the first obs after a gap to the crossed boundary's group,
    # so Mar 1 ends up as a single-row "Feb boundary" group.  _resample_core thus
    # produces 3 rows; _fill_period_gaps detects Feb as having no *source* data
    # and inserts a gap row, giving 4 rows total.
    dates_month_gap = vcat(
        collect(Date(2020,1,1):Day(1):Date(2020,1,31)),   # January
        collect(Date(2020,3,1):Day(1):Date(2020,3,31))    # March
    )
    nm = length(dates_month_gap)
    ts_month_gap = TSFrame(DataFrame(
        Open   = Float64.(1:nm),
        High   = Float64.(1:nm) .+ 1,
        Low    = Float64.(1:nm) .- 1,
        Close  = Float64.(1:nm),
        Volume = Int.(1:nm) .* 100
    ), dates_month_gap)

    # fill_gaps=false: 3 rows (Jan, Mar-1-straddle, Mar-rest)
    r_no_fill = resample(ts_month_gap, Month(1))
    @test DataFrames.nrow(r_no_fill.coredata) == 3

    # fill_gaps=true: 4 rows (adds Feb 1 gap row)
    r_fill = resample(ts_month_gap, Month(1); fill_gaps=true)
    @test DataFrames.nrow(r_fill.coredata) == 4

    # Gap row (February) data is all missing
    gap_row_idx = findfirst(==(Date(2020,2,1)), index(r_fill))
    @test gap_row_idx !== nothing
    @test ismissing(r_fill.coredata[gap_row_idx, :Open])
    @test ismissing(r_fill.coredata[gap_row_idx, :Volume])

    # Non-gap rows have normal data
    @test !ismissing(r_fill.coredata[1, :Open])

    # fill_gaps=true works with custom pairs
    r_custom = resample(ts_month_gap, Month(1), :Open => first, :Volume => sum; fill_gaps=true)
    @test DataFrames.nrow(r_custom.coredata) == 4
    @test ismissing(r_custom.coredata[findfirst(==(Date(2020,2,1)), index(r_custom)), :Open])

    # index_at=last also works
    r_last = resample(ts_month_gap, Month(1); fill_gaps=true, index_at=last)
    @test DataFrames.nrow(r_last.coredata) == 4
    # Feb gap row gets last-of-period label: Feb 29 (2020 is a leap year)
    @test Date(2020,2,29) in index(r_last)
    feb_idx = findfirst(==(Date(2020,2,29)), index(r_last))
    @test ismissing(r_last.coredata[feb_idx, :Open])

    # No-gap data: fill_gaps=true produces same row count (no extra rows)
    dates_no_gap = collect(Date(2020,1,1):Day(1):Date(2020,3,31))
    ts_no_gap = TSFrame(DataFrame(Open=rand(91), High=rand(91).+1, Low=rand(91).-1, Close=rand(91), Volume=rand(1:100,91)), dates_no_gap)
    r_nogap_fill   = resample(ts_no_gap, Month(1); fill_gaps=true)
    r_nogap_nofill = resample(ts_no_gap, Month(1))
    @test DataFrames.nrow(r_nogap_fill.coredata) == DataFrames.nrow(r_nogap_nofill.coredata)

    # ── Weekly gap: week 1 + week 3, week 2 missing ─────────────────────
    # endpoints() assigns Jan 20 (first obs after gap) to the "Jan 13 week" group,
    # so without fill_gaps we get 3 rows; with fill_gaps we get 4 (Jan 13 gap added).
    dates_weekly_gap = vcat(
        collect(Date(2020,1,6):Day(1):Date(2020,1,12)),   # week 1: Mon-Sun
        collect(Date(2020,1,20):Day(1):Date(2020,1,26))   # week 3: Mon-Sun
    )
    nw = length(dates_weekly_gap)
    ts_weekly_gap = TSFrame(DataFrame(
        Open   = Float64.(1:nw),
        High   = Float64.(1:nw) .+ 1,
        Low    = Float64.(1:nw) .- 1,
        Close  = Float64.(1:nw),
        Volume = Int.(1:nw) .* 100
    ), dates_weekly_gap)

    r_weekly_no_fill = resample(ts_weekly_gap, Week(1))
    r_weekly_fill    = resample(ts_weekly_gap, Week(1); fill_gaps=true)
    # Without fill: 3 groups (Jan 6 week, Jan 20 straddle, Jan 20 week)
    @test DataFrames.nrow(r_weekly_no_fill.coredata) == 3
    # With fill: adds Jan 13 gap row → 4 rows
    @test DataFrames.nrow(r_weekly_fill.coredata) == 4
    @test Date(2020,1,13) in index(r_weekly_fill)
    gap_idx = findfirst(==(Date(2020,1,13)), index(r_weekly_fill))
    @test ismissing(r_weekly_fill.coredata[gap_idx, :Open])

    # String pairs also forward fill_gaps correctly
    r_str = resample(ts_month_gap, Month(1), "Open" => first; fill_gaps=true)
    @test DataFrames.nrow(r_str.coredata) == 4
    @test ismissing(r_str.coredata[findfirst(==(Date(2020,2,1)), index(r_str)), :Open])

    # fill_gaps=true on empty TSFrame: should return empty result unchanged
    ts_empty = TSFrame(DataFrame(Open=Float64[], High=Float64[], Low=Float64[], Close=Float64[], Volume=Int[]), Date[])
    r_empty = resample(ts_empty, Month(1); fill_gaps=true)
    @test DataFrames.nrow(r_empty.coredata) == 0

    # fill_gaps=true on single-row TSFrame: no gaps possible, identity result
    ts_single = TSFrame(DataFrame(Open=[1.0], High=[2.0], Low=[0.5], Close=[1.5], Volume=[100]), [Date(2020,1,15)])
    r_single = resample(ts_single, Month(1); fill_gaps=true)
    @test DataFrames.nrow(r_single.coredata) == 1
end

# -- 18. fill_gaps=true with DateTime index ----------------------------------------

@testset "fill_gaps=true with DateTime index" begin
    # Hourly data: Jan 1-3 and Jan 5-7 (Jan 4 is a gap day)
    dts_with_gap = vcat(
        collect(DateTime(2020,1,1,0,0,0):Hour(1):DateTime(2020,1,3,23,0,0)),  # Jan 1-3
        collect(DateTime(2020,1,5,0,0,0):Hour(1):DateTime(2020,1,7,23,0,0))   # Jan 5-7
    )
    nd = length(dts_with_gap)
    ts_dt_gap = TSFrame(DataFrame(
        Open   = Float64.(1:nd),
        High   = Float64.(1:nd) .+ 1,
        Low    = Float64.(1:nd) .- 1,
        Close  = Float64.(1:nd),
        Volume = Int.(1:nd) .* 10
    ), dts_with_gap)

    # Without fill: endpoints() assigns Jan 5 data to the Jan 4 boundary group,
    # so we get fewer rows than calendar days
    r_no_fill = resample(ts_dt_gap, Day(1))
    # With fill: Jan 4 gap row is inserted
    r_fill = resample(ts_dt_gap, Day(1); fill_gaps=true)
    @test DataFrames.nrow(r_fill.coredata) > DataFrames.nrow(r_no_fill.coredata)
    @test DateTime(2020,1,4,0,0,0) in index(r_fill)
    gap_idx = findfirst(==(DateTime(2020,1,4,0,0,0)), index(r_fill))
    @test ismissing(r_fill.coredata[gap_idx, :Open])
    @test eltype(index(r_fill)) == DateTime

    # index_at=last with DateTime: gap label = hi - Millisecond(1)
    # hi for Jan 4 boundary = DateTime(2020,1,5,0,0,0), so label = DateTime(2020,1,4,23,59,59,999)
    r_fill_last = resample(ts_dt_gap, Day(1); fill_gaps=true, index_at=last)
    expected_gap_label = DateTime(2020,1,5,0,0,0) - Millisecond(1)
    @test expected_gap_label in index(r_fill_last)
    gap_idx_last = findfirst(==(expected_gap_label), index(r_fill_last))
    @test ismissing(r_fill_last.coredata[gap_idx_last, :Open])
    @test ismissing(r_fill_last.coredata[gap_idx_last, :Volume])
end
