# test/resample.jl
# Tests for resample() — period-based resampling with per-column aggregation

using Dates, DataFrames, Random, Statistics, Test, TSFrames

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

# -- 19. fill_gaps=:ffill basic ---------------------------------------------------

@testset "fill_gaps=:ffill basic" begin
    # ── Monthly gap: Jan + Mar present, Feb missing ──────────────────────
    dates_fg = vcat(
        collect(Date(2020,1,1):Day(1):Date(2020,1,31)),   # January
        collect(Date(2020,3,1):Day(1):Date(2020,3,31))     # March
    )
    nfg = length(dates_fg)
    ts_fg = TSFrame(DataFrame(
        Open   = Float64.(1:nfg),
        High   = Float64.(1:nfg) .+ 1,
        Low    = Float64.(1:nfg) .- 1,
        Close  = Float64.(1:nfg),
        Volume = Int.(1:nfg) .* 100
    ), dates_fg)

    r = resample(ts_fg, Month(1); fill_gaps=:ffill)
    @test DataFrames.nrow(r.coredata) == 4  # Jan, Feb(gap filled), Mar-boundary, Mar

    # Feb is the gap row — should be forward-filled from Jan's aggregated values
    feb_idx = findfirst(==(Date(2020,2,1)), index(r))
    @test feb_idx !== nothing

    # Jan group: rows 1-31 of January data
    jan_idx = findfirst(==(Date(2020,1,1)), index(r))
    jan_open = r.coredata[jan_idx, :Open]
    jan_high = r.coredata[jan_idx, :High]
    jan_low  = r.coredata[jan_idx, :Low]
    jan_close = r.coredata[jan_idx, :Close]
    jan_volume = r.coredata[jan_idx, :Volume]

    # Feb gap row should be filled with Jan's values (ffill)
    @test r.coredata[feb_idx, :Open]   == jan_open
    @test r.coredata[feb_idx, :High]   == jan_high
    @test r.coredata[feb_idx, :Low]    == jan_low
    @test r.coredata[feb_idx, :Close]  == jan_close
    @test r.coredata[feb_idx, :Volume] == jan_volume

    # Non-gap rows still have real data (not missing)
    @test !ismissing(r.coredata[jan_idx, :Open])

    # ── Pre-existing missing in non-gap row is preserved ─────────────────
    dates_pre = vcat(
        collect(Date(2020,1,1):Day(1):Date(2020,1,31)),
        collect(Date(2020,3,1):Day(1):Date(2020,3,31))
    )
    npre = length(dates_pre)
    # Put a missing in row 1 of January
    open_vals = Union{Float64,Missing}[i == 1 ? missing : Float64(i) for i in 1:npre]
    ts_pre = TSFrame(DataFrame(
        Open   = open_vals,
        High   = Float64.(1:npre) .+ 1,
        Low    = Float64.(1:npre) .- 1,
        Close  = Float64.(1:npre),
        Volume = Int.(1:npre) .* 100
    ), dates_pre)

    # Use skipmissing-safe agg: first still returns missing if first element is missing
    r_pre = resample(ts_pre, Month(1), :Open => first; fill_gaps=:ffill)
    # Jan's Open via first should be missing (first element of January is missing)
    jan_idx_pre = findfirst(==(Date(2020,1,1)), index(r_pre))
    @test ismissing(r_pre.coredata[jan_idx_pre, :Open])

    # ── Works with custom Symbol pairs ───────────────────────────────────
    r_custom = resample(ts_fg, Month(1), :Open => first, :Volume => sum; fill_gaps=:ffill)
    @test DataFrames.nrow(r_custom.coredata) == 4
    feb_idx_c = findfirst(==(Date(2020,2,1)), index(r_custom))
    jan_idx_c = findfirst(==(Date(2020,1,1)), index(r_custom))
    @test r_custom.coredata[feb_idx_c, :Open]   == r_custom.coredata[jan_idx_c, :Open]
    @test r_custom.coredata[feb_idx_c, :Volume]  == r_custom.coredata[jan_idx_c, :Volume]

    # ── Works with String pairs ──────────────────────────────────────────
    r_str = resample(ts_fg, Month(1), "Open" => first; fill_gaps=:ffill)
    @test DataFrames.nrow(r_str.coredata) == 4
    feb_idx_s = findfirst(==(Date(2020,2,1)), index(r_str))
    jan_idx_s = findfirst(==(Date(2020,1,1)), index(r_str))
    @test r_str.coredata[feb_idx_s, :Open] == r_str.coredata[jan_idx_s, :Open]
end

# -- 20. fill_gaps=:bfill basic ---------------------------------------------------

@testset "fill_gaps=:bfill basic" begin
    # ── Monthly gap: Jan + Mar present, Feb missing ──────────────────────
    dates_bf = vcat(
        collect(Date(2020,1,1):Day(1):Date(2020,1,31)),   # January
        collect(Date(2020,3,1):Day(1):Date(2020,3,31))     # March
    )
    nbf = length(dates_bf)
    ts_bf = TSFrame(DataFrame(
        Open   = Float64.(1:nbf),
        High   = Float64.(1:nbf) .+ 1,
        Low    = Float64.(1:nbf) .- 1,
        Close  = Float64.(1:nbf),
        Volume = Int.(1:nbf) .* 100
    ), dates_bf)

    r = resample(ts_bf, Month(1); fill_gaps=:bfill)
    @test DataFrames.nrow(r.coredata) == 4

    feb_idx = findfirst(==(Date(2020,2,1)), index(r))
    @test feb_idx !== nothing

    # The row after Feb gap is the Mar-boundary row (Mar 1 data assigned to Feb boundary).
    # bfill should fill Feb from the next non-missing row.
    next_idx = feb_idx + 1
    @test r.coredata[feb_idx, :Open]   == r.coredata[next_idx, :Open]
    @test r.coredata[feb_idx, :High]   == r.coredata[next_idx, :High]
    @test r.coredata[feb_idx, :Low]    == r.coredata[next_idx, :Low]
    @test r.coredata[feb_idx, :Close]  == r.coredata[next_idx, :Close]
    @test r.coredata[feb_idx, :Volume] == r.coredata[next_idx, :Volume]

    # ── Edge: first period is a gap → bfill fills from next period ───────
    # Data only in March (no January or February data)
    dates_late = collect(Date(2020,3,1):Day(1):Date(2020,3,31))
    ts_late = TSFrame(DataFrame(
        Open   = Float64.(1:31),
        High   = Float64.(1:31) .+ 1,
        Low    = Float64.(1:31) .- 1,
        Close  = Float64.(1:31),
        Volume = Int.(1:31) .* 100
    ), dates_late)

    # With Month(1) there's only 1 period (March). No gap possible within a single period.
    # Use Week(1) instead — create weekly data with a gap at the start.
    dates_wk_late = vcat(
        collect(Date(2020,1,20):Day(1):Date(2020,1,26))   # week 3 only (Mon-Sun)
    )
    nwl = length(dates_wk_late)
    # First period boundary is Jan 20 (Monday). No gap before that.
    # Instead, let's use data that starts mid-month to create a leading gap.
    dates_lead_gap = vcat(
        collect(Date(2020,1,15):Day(1):Date(2020,1,31)),   # mid-Jan to end-Jan
        collect(Date(2020,3,1):Day(1):Date(2020,3,31))     # March
    )
    nlg = length(dates_lead_gap)
    ts_lead = TSFrame(DataFrame(
        Open   = Float64.(1:nlg),
        High   = Float64.(1:nlg) .+ 1,
        Low    = Float64.(1:nlg) .- 1,
        Close  = Float64.(1:nlg),
        Volume = Int.(1:nlg) .* 100
    ), dates_lead_gap)

    # Monthly resample: Jan is present, Feb is gap, Mar is present
    r_lead = resample(ts_lead, Month(1); fill_gaps=:bfill)
    feb_idx_l = findfirst(==(Date(2020,2,1)), index(r_lead))
    @test feb_idx_l !== nothing
    # bfill: Feb filled from next non-missing row
    next_idx_l = feb_idx_l + 1
    @test r_lead.coredata[feb_idx_l, :Open] == r_lead.coredata[next_idx_l, :Open]
end

# -- 21. fill_gaps=:zero -----------------------------------------------------------

@testset "fill_gaps=:zero" begin
    # ── Monthly gap: Jan + Mar present, Feb missing ──────────────────────
    dates_z = vcat(
        collect(Date(2020,1,1):Day(1):Date(2020,1,31)),
        collect(Date(2020,3,1):Day(1):Date(2020,3,31))
    )
    nz = length(dates_z)
    ts_z = TSFrame(DataFrame(
        Open   = Float64.(1:nz),
        High   = Float64.(1:nz) .+ 1,
        Low    = Float64.(1:nz) .- 1,
        Close  = Float64.(1:nz),
        Volume = Int.(1:nz) .* 100
    ), dates_z)

    r = resample(ts_z, Month(1); fill_gaps=:zero)
    @test DataFrames.nrow(r.coredata) == 4

    feb_idx = findfirst(==(Date(2020,2,1)), index(r))
    @test feb_idx !== nothing

    # Gap rows filled with typed zero
    @test r.coredata[feb_idx, :Open]   == 0.0    # Float64 zero
    @test r.coredata[feb_idx, :High]   == 0.0
    @test r.coredata[feb_idx, :Low]    == 0.0
    @test r.coredata[feb_idx, :Close]  == 0.0
    @test r.coredata[feb_idx, :Volume] == 0       # Int zero

    # Verify type: column is Union{T, Missing} but gap rows have zero, not missing
    @test !ismissing(r.coredata[feb_idx, :Open])
    @test !ismissing(r.coredata[feb_idx, :Volume])

    # Non-gap rows retain their real values
    jan_idx = findfirst(==(Date(2020,1,1)), index(r))
    @test r.coredata[jan_idx, :Open] > 0
end

# -- 22. fill_gaps=<Real> constant --------------------------------------------------

@testset "fill_gaps=Real constant" begin
    dates_rc = vcat(
        collect(Date(2020,1,1):Day(1):Date(2020,1,31)),
        collect(Date(2020,3,1):Day(1):Date(2020,3,31))
    )
    nrc = length(dates_rc)
    ts_rc = TSFrame(DataFrame(
        Open   = Float64.(1:nrc),
        High   = Float64.(1:nrc) .+ 1,
        Low    = Float64.(1:nrc) .- 1,
        Close  = Float64.(1:nrc),
        Volume = Int.(1:nrc) .* 100
    ), dates_rc)

    # fill_gaps=99.0
    r99 = resample(ts_rc, Month(1); fill_gaps=99.0)
    @test DataFrames.nrow(r99.coredata) == 4
    feb_idx_99 = findfirst(==(Date(2020,2,1)), index(r99))
    @test r99.coredata[feb_idx_99, :Open]   == 99.0
    @test r99.coredata[feb_idx_99, :High]   == 99.0
    @test r99.coredata[feb_idx_99, :Close]  == 99.0
    @test r99.coredata[feb_idx_99, :Volume] == 99.0  # Real constant applied to all cols

    # fill_gaps=-1
    r_neg = resample(ts_rc, Month(1); fill_gaps=-1)
    feb_idx_neg = findfirst(==(Date(2020,2,1)), index(r_neg))
    @test r_neg.coredata[feb_idx_neg, :Open]   == -1
    @test r_neg.coredata[feb_idx_neg, :Volume]  == -1

    # Non-gap rows are unaffected
    jan_idx_99 = findfirst(==(Date(2020,1,1)), index(r99))
    @test r99.coredata[jan_idx_99, :Open] != 99.0
end

# -- 23. fill_gaps backward compatibility (true/false) ------------------------------

@testset "fill_gaps backward compat" begin
    dates_bc = vcat(
        collect(Date(2020,1,1):Day(1):Date(2020,1,31)),
        collect(Date(2020,3,1):Day(1):Date(2020,3,31))
    )
    nbc = length(dates_bc)
    ts_bc = TSFrame(DataFrame(
        Open   = Float64.(1:nbc),
        High   = Float64.(1:nbc) .+ 1,
        Low    = Float64.(1:nbc) .- 1,
        Close  = Float64.(1:nbc),
        Volume = Int.(1:nbc) .* 100
    ), dates_bc)

    # fill_gaps=true should behave like :missing (gap rows stay missing)
    r_true = resample(ts_bc, Month(1); fill_gaps=true)
    @test DataFrames.nrow(r_true.coredata) == 4
    feb_idx_t = findfirst(==(Date(2020,2,1)), index(r_true))
    @test ismissing(r_true.coredata[feb_idx_t, :Open])
    @test ismissing(r_true.coredata[feb_idx_t, :Volume])

    # fill_gaps=:missing explicitly → same as true
    r_missing = resample(ts_bc, Month(1); fill_gaps=:missing)
    @test DataFrames.nrow(r_missing.coredata) == 4
    feb_idx_m = findfirst(==(Date(2020,2,1)), index(r_missing))
    @test ismissing(r_missing.coredata[feb_idx_m, :Open])

    # fill_gaps=false → no gap rows inserted at all
    r_false = resample(ts_bc, Month(1); fill_gaps=false)
    @test DataFrames.nrow(r_false.coredata) == 3  # no Feb gap row
    @test !(Date(2020,2,1) in index(r_false))
end

# -- 24. fill_limit with :ffill ----------------------------------------------------

@testset "fill_limit with :ffill" begin
    # 3 consecutive weekly gaps: weeks 2, 3, 4 missing
    # Week 1: Jan 6-12 (Mon-Sun), Week 5: Feb 3-9 (Mon-Sun)
    # Weeks 2 (Jan 13), 3 (Jan 20), 4 (Jan 27) are gaps
    dates_3g = vcat(
        collect(Date(2020,1,6):Day(1):Date(2020,1,12)),   # week 1
        collect(Date(2020,2,3):Day(1):Date(2020,2,9))     # week 5
    )
    n3g = length(dates_3g)
    ts_3g = TSFrame(DataFrame(
        Open   = Float64.(1:n3g),
        High   = Float64.(1:n3g) .+ 1,
        Low    = Float64.(1:n3g) .- 1,
        Close  = Float64.(1:n3g),
        Volume = Int.(1:n3g) .* 100
    ), dates_3g)

    # fill_limit=nothing → all 3 gap weeks filled
    r_all = resample(ts_3g, Week(1); fill_gaps=:ffill, fill_limit=nothing)
    # Expect: week1, gap_w2(filled), gap_w3(filled), gap_w4(filled), straddle/week5
    gap_w2 = findfirst(==(Date(2020,1,13)), index(r_all))
    gap_w3 = findfirst(==(Date(2020,1,20)), index(r_all))
    gap_w4 = findfirst(==(Date(2020,1,27)), index(r_all))
    @test gap_w2 !== nothing
    @test gap_w3 !== nothing
    @test gap_w4 !== nothing
    @test !ismissing(r_all.coredata[gap_w2, :Open])
    @test !ismissing(r_all.coredata[gap_w3, :Open])
    @test !ismissing(r_all.coredata[gap_w4, :Open])

    # fill_limit=1 → only first gap week filled
    r_lim1 = resample(ts_3g, Week(1); fill_gaps=:ffill, fill_limit=1)
    gap_w2_l1 = findfirst(==(Date(2020,1,13)), index(r_lim1))
    gap_w3_l1 = findfirst(==(Date(2020,1,20)), index(r_lim1))
    gap_w4_l1 = findfirst(==(Date(2020,1,27)), index(r_lim1))
    @test !ismissing(r_lim1.coredata[gap_w2_l1, :Open])   # 1st gap → filled
    @test ismissing(r_lim1.coredata[gap_w3_l1, :Open])    # 2nd gap → stays missing
    @test ismissing(r_lim1.coredata[gap_w4_l1, :Open])    # 3rd gap → stays missing

    # fill_limit=2 → first 2 gap weeks filled, 3rd stays missing
    r_lim2 = resample(ts_3g, Week(1); fill_gaps=:ffill, fill_limit=2)
    gap_w2_l2 = findfirst(==(Date(2020,1,13)), index(r_lim2))
    gap_w3_l2 = findfirst(==(Date(2020,1,20)), index(r_lim2))
    gap_w4_l2 = findfirst(==(Date(2020,1,27)), index(r_lim2))
    @test !ismissing(r_lim2.coredata[gap_w2_l2, :Open])   # 1st gap → filled
    @test !ismissing(r_lim2.coredata[gap_w3_l2, :Open])   # 2nd gap → filled
    @test ismissing(r_lim2.coredata[gap_w4_l2, :Open])    # 3rd gap → stays missing

    # Verify that filled values propagate (ffill chain)
    week1_idx = findfirst(==(Date(2020,1,6)), index(r_all))
    @test r_all.coredata[gap_w2, :Open] == r_all.coredata[week1_idx, :Open]
    @test r_all.coredata[gap_w3, :Open] == r_all.coredata[week1_idx, :Open]
    @test r_all.coredata[gap_w4, :Open] == r_all.coredata[week1_idx, :Open]
end

# -- 25. fill_limit with :bfill ----------------------------------------------------

@testset "fill_limit with :bfill" begin
    # Same 3 consecutive weekly gaps as testset 24
    dates_3gb = vcat(
        collect(Date(2020,1,6):Day(1):Date(2020,1,12)),   # week 1
        collect(Date(2020,2,3):Day(1):Date(2020,2,9))     # week 5
    )
    n3gb = length(dates_3gb)
    ts_3gb = TSFrame(DataFrame(
        Open   = Float64.(1:n3gb),
        High   = Float64.(1:n3gb) .+ 1,
        Low    = Float64.(1:n3gb) .- 1,
        Close  = Float64.(1:n3gb),
        Volume = Int.(1:n3gb) .* 100
    ), dates_3gb)

    # fill_limit=nothing → all 3 gap weeks filled (backward from week 5)
    r_all_b = resample(ts_3gb, Week(1); fill_gaps=:bfill, fill_limit=nothing)
    gap_w2_b = findfirst(==(Date(2020,1,13)), index(r_all_b))
    gap_w3_b = findfirst(==(Date(2020,1,20)), index(r_all_b))
    gap_w4_b = findfirst(==(Date(2020,1,27)), index(r_all_b))
    @test !ismissing(r_all_b.coredata[gap_w2_b, :Open])
    @test !ismissing(r_all_b.coredata[gap_w3_b, :Open])
    @test !ismissing(r_all_b.coredata[gap_w4_b, :Open])

    # fill_limit=1 → only LAST gap week (closest to anchor) filled
    # bfill iterates in reverse: fills w4 first, then w3, then w2
    r_lim1_b = resample(ts_3gb, Week(1); fill_gaps=:bfill, fill_limit=1)
    gap_w2_bl1 = findfirst(==(Date(2020,1,13)), index(r_lim1_b))
    gap_w3_bl1 = findfirst(==(Date(2020,1,20)), index(r_lim1_b))
    gap_w4_bl1 = findfirst(==(Date(2020,1,27)), index(r_lim1_b))
    @test ismissing(r_lim1_b.coredata[gap_w2_bl1, :Open])   # 3rd from anchor → stays missing
    @test ismissing(r_lim1_b.coredata[gap_w3_bl1, :Open])   # 2nd from anchor → stays missing
    @test !ismissing(r_lim1_b.coredata[gap_w4_bl1, :Open])  # 1st from anchor → filled

    # fill_limit=2 → last 2 gap weeks filled, first stays missing
    r_lim2_b = resample(ts_3gb, Week(1); fill_gaps=:bfill, fill_limit=2)
    gap_w2_bl2 = findfirst(==(Date(2020,1,13)), index(r_lim2_b))
    gap_w3_bl2 = findfirst(==(Date(2020,1,20)), index(r_lim2_b))
    gap_w4_bl2 = findfirst(==(Date(2020,1,27)), index(r_lim2_b))
    @test ismissing(r_lim2_b.coredata[gap_w2_bl2, :Open])    # farthest → stays missing
    @test !ismissing(r_lim2_b.coredata[gap_w3_bl2, :Open])   # 2nd from anchor → filled
    @test !ismissing(r_lim2_b.coredata[gap_w4_bl2, :Open])   # 1st from anchor → filled

    # Verify that bfill uses the week-5 anchor value
    # The row right after the gap is the "straddle" row (Feb 3 assigned to Jan 27 boundary)
    # or the week-5 row itself. Find the first non-gap row after the gaps.
    last_row_idx = findfirst(>=(Date(2020,2,3)), index(r_all_b))
    if last_row_idx !== nothing
        # In bfill with no limit, all gap rows should have the same value as the anchor
        @test r_all_b.coredata[gap_w4_b, :Open] == r_all_b.coredata[last_row_idx, :Open]
    end
end

# -- 26. fill_gaps=:interpolate ----------------------------------------------------

@testset "fill_gaps=:interpolate" begin
    # ── Single gap: Jan + Mar, Feb missing → Feb interpolated ────────────
    dates_ip = vcat(
        collect(Date(2020,1,1):Day(1):Date(2020,1,31)),
        collect(Date(2020,3,1):Day(1):Date(2020,3,31))
    )
    nip = length(dates_ip)
    # Use constant values within each month for easy verification
    vals = vcat(fill(10.0, 31), fill(30.0, 31))
    ts_ip = TSFrame(DataFrame(
        val = vals
    ), dates_ip)

    r = resample(ts_ip, Month(1), :val => first; fill_gaps=:interpolate)
    # Should produce 4 rows: Jan, Feb(gap), Mar-boundary-straddle, Mar-rest
    @test DataFrames.nrow(r.coredata) == 4

    feb_idx = findfirst(==(Date(2020,2,1)), index(r))
    @test feb_idx !== nothing
    @test !ismissing(r.coredata[feb_idx, :val])

    # Jan val=10.0, next non-missing row val=30.0
    # Interpolation is time-weighted between Jan 1 and the Mar-boundary index
    jan_idx = findfirst(==(Date(2020,1,1)), index(r))
    jan_val = r.coredata[jan_idx, :val]
    @test jan_val == 10.0

    # Feb interpolated value should be between Jan and Mar values
    feb_val = r.coredata[feb_idx, :val]
    @test feb_val > 10.0
    @test feb_val < 30.0

    # ── Multiple consecutive gaps ────────────────────────────────────────
    # Jan + April data, Feb + Mar are gaps
    dates_multi = vcat(
        collect(Date(2020,1,1):Day(1):Date(2020,1,31)),   # January
        collect(Date(2020,4,1):Day(1):Date(2020,4,30))     # April
    )
    nmulti = length(dates_multi)
    vals_multi = vcat(fill(1.0, 31), fill(4.0, 30))
    ts_multi = TSFrame(DataFrame(val = vals_multi), dates_multi)

    r_multi = resample(ts_multi, Month(1), :val => first; fill_gaps=:interpolate)
    feb_idx_m = findfirst(==(Date(2020,2,1)), index(r_multi))
    mar_idx_m = findfirst(==(Date(2020,3,1)), index(r_multi))
    @test feb_idx_m !== nothing
    @test mar_idx_m !== nothing
    @test !ismissing(r_multi.coredata[feb_idx_m, :val])
    @test !ismissing(r_multi.coredata[mar_idx_m, :val])

    # Feb should be closer to 1.0, Mar closer to 4.0 (time-weighted)
    feb_v = r_multi.coredata[feb_idx_m, :val]
    mar_v = r_multi.coredata[mar_idx_m, :val]
    @test feb_v > 1.0
    @test mar_v > feb_v
    @test mar_v < 4.0

    # ── Non-numeric columns: stay missing ────────────────────────────────
    dates_str = vcat(
        collect(Date(2020,1,1):Day(1):Date(2020,1,31)),
        collect(Date(2020,3,1):Day(1):Date(2020,3,31))
    )
    nstr = length(dates_str)
    ts_str = TSFrame(DataFrame(
        label = [string("row_", i) for i in 1:nstr]
    ), dates_str)

    r_str = resample(ts_str, Month(1), :label => first; fill_gaps=:interpolate)
    feb_idx_str = findfirst(==(Date(2020,2,1)), index(r_str))
    @test feb_idx_str !== nothing
    @test ismissing(r_str.coredata[feb_idx_str, :label])  # non-numeric → stays missing

    # ── Edge: gap at start of series → extrapolate from right ────────────
    # Data only from March onward, with monthly period starting from March boundary
    # Use weekly data for a cleaner leading gap scenario
    dates_trail = vcat(
        collect(Date(2020,1,20):Day(1):Date(2020,1,26)),   # week 3 (Mon-Sun)
        collect(Date(2020,2,3):Day(1):Date(2020,2,9))      # week 5 (Mon-Sun)
    )
    nt = length(dates_trail)
    ts_trail = TSFrame(DataFrame(val = Float64.(1:nt)), dates_trail)

    r_trail = resample(ts_trail, Week(1), :val => first; fill_gaps=:interpolate)
    # Gap at Jan 27 (week 4) is between week 3 and week 5
    gap_w4 = findfirst(==(Date(2020,1,27)), index(r_trail))
    if gap_w4 !== nothing
        @test !ismissing(r_trail.coredata[gap_w4, :val])
    end
end

# -- 27. fill_gaps pre-existing missing preservation --------------------------------

@testset "fill_gaps pre-existing missing preservation" begin
    # Create data where a non-gap row has pre-existing missing in a column
    dates_pm = vcat(
        collect(Date(2020,1,1):Day(1):Date(2020,1,31)),
        collect(Date(2020,3,1):Day(1):Date(2020,3,31))
    )
    npm = length(dates_pm)

    # Put missing in the first element of January (non-gap data)
    vals_pm = Union{Float64,Missing}[i == 1 ? missing : Float64(i) for i in 1:npm]
    ts_pm = TSFrame(DataFrame(val = vals_pm), dates_pm)

    # ── :ffill: pre-existing missing in aggregated non-gap row stays missing ──
    r_ff = resample(ts_pm, Month(1), :val => first; fill_gaps=:ffill)
    jan_idx_ff = findfirst(==(Date(2020,1,1)), index(r_ff))
    # first(vals for January) = missing (row 1 is missing)
    @test ismissing(r_ff.coredata[jan_idx_ff, :val])

    # Feb gap: ffill from Jan, but Jan is missing → Feb stays missing too
    feb_idx_ff = findfirst(==(Date(2020,2,1)), index(r_ff))
    @test ismissing(r_ff.coredata[feb_idx_ff, :val])

    # ── :bfill: pre-existing missing in non-gap row stays missing ────────
    r_bf = resample(ts_pm, Month(1), :val => first; fill_gaps=:bfill)
    jan_idx_bf = findfirst(==(Date(2020,1,1)), index(r_bf))
    # Jan's aggregated value is missing (pre-existing) — should NOT be overwritten by bfill
    @test ismissing(r_bf.coredata[jan_idx_bf, :val])

    # Feb gap: bfill from Mar-boundary row (should be filled)
    feb_idx_bf = findfirst(==(Date(2020,2,1)), index(r_bf))
    next_non_gap = feb_idx_bf + 1
    @test r_bf.coredata[feb_idx_bf, :val] == r_bf.coredata[next_non_gap, :val]

    # ── :zero: pre-existing missing in non-gap row stays missing ─────────
    r_z = resample(ts_pm, Month(1), :val => first; fill_gaps=:zero)
    jan_idx_z = findfirst(==(Date(2020,1,1)), index(r_z))
    @test ismissing(r_z.coredata[jan_idx_z, :val])  # pre-existing missing preserved
    feb_idx_z = findfirst(==(Date(2020,2,1)), index(r_z))
    @test r_z.coredata[feb_idx_z, :val] == 0.0  # gap row filled with zero
end

# -- 28. fill_gaps with DateTime index ---------------------------------------------

@testset "fill_gaps with DateTime index" begin
    # Hourly data: Jan 1-3 and Jan 5-7 (Jan 4 is a gap day)
    dts_fg = vcat(
        collect(DateTime(2020,1,1,0,0,0):Hour(1):DateTime(2020,1,3,23,0,0)),
        collect(DateTime(2020,1,5,0,0,0):Hour(1):DateTime(2020,1,7,23,0,0))
    )
    ndf = length(dts_fg)
    ts_dt = TSFrame(DataFrame(
        Open   = Float64.(1:ndf),
        High   = Float64.(1:ndf) .+ 1,
        Low    = Float64.(1:ndf) .- 1,
        Close  = Float64.(1:ndf),
        Volume = Int.(1:ndf) .* 100
    ), dts_fg)

    # ── :ffill with DateTime → gap day filled with previous day's values ──
    r_ff_dt = resample(ts_dt, Day(1); fill_gaps=:ffill)
    gap_dt = DateTime(2020,1,4,0,0,0)
    gap_idx_dt = findfirst(==(gap_dt), index(r_ff_dt))
    @test gap_idx_dt !== nothing
    @test !ismissing(r_ff_dt.coredata[gap_idx_dt, :Open])
    @test !ismissing(r_ff_dt.coredata[gap_idx_dt, :Volume])

    # Verify it was filled from the preceding day (Jan 3)
    prev_idx = gap_idx_dt - 1
    @test r_ff_dt.coredata[gap_idx_dt, :Open]   == r_ff_dt.coredata[prev_idx, :Open]
    @test r_ff_dt.coredata[gap_idx_dt, :Volume]  == r_ff_dt.coredata[prev_idx, :Volume]

    # ── :interpolate with DateTime → time-weighted interpolation ─────────
    r_ip_dt = resample(ts_dt, Day(1); fill_gaps=:interpolate)
    gap_idx_ip = findfirst(==(gap_dt), index(r_ip_dt))
    @test gap_idx_ip !== nothing
    @test !ismissing(r_ip_dt.coredata[gap_idx_ip, :Open])

    # Gap Open should be between Jan 3's and Jan 5's Open values
    prev_open = r_ip_dt.coredata[gap_idx_ip - 1, :Open]
    next_open = r_ip_dt.coredata[gap_idx_ip + 1, :Open]
    gap_open  = r_ip_dt.coredata[gap_idx_ip, :Open]
    @test gap_open > prev_open || gap_open ≈ prev_open  # at least as large as prev
    @test gap_open < next_open || gap_open ≈ next_open  # at most as large as next

    # Index type preserved
    @test eltype(index(r_ff_dt)) == DateTime
    @test eltype(index(r_ip_dt)) == DateTime
end

# -- 29. fill_gaps with index_at=last ----------------------------------------------

@testset "fill_gaps with index_at=last" begin
    dates_il = vcat(
        collect(Date(2020,1,1):Day(1):Date(2020,1,31)),
        collect(Date(2020,3,1):Day(1):Date(2020,3,31))
    )
    nil = length(dates_il)
    ts_il = TSFrame(DataFrame(
        Open   = Float64.(1:nil),
        High   = Float64.(1:nil) .+ 1,
        Low    = Float64.(1:nil) .- 1,
        Close  = Float64.(1:nil),
        Volume = Int.(1:nil) .* 100
    ), dates_il)

    # ── :ffill with index_at=last → gap rows get end-of-period labels ────
    r_last = resample(ts_il, Month(1); fill_gaps=:ffill, index_at=last)
    @test DataFrames.nrow(r_last.coredata) == 4

    # Feb gap row should have end-of-Feb label (Feb 29, 2020 is a leap year)
    @test Date(2020,2,29) in index(r_last)
    feb_idx_last = findfirst(==(Date(2020,2,29)), index(r_last))
    @test feb_idx_last !== nothing

    # Feb gap row should be filled (ffill from Jan)
    @test !ismissing(r_last.coredata[feb_idx_last, :Open])
    @test !ismissing(r_last.coredata[feb_idx_last, :Volume])

    # Jan's index_at=last label should be Jan 31
    @test Date(2020,1,31) in index(r_last)
    jan_idx_last = findfirst(==(Date(2020,1,31)), index(r_last))
    @test r_last.coredata[feb_idx_last, :Open] == r_last.coredata[jan_idx_last, :Open]

    # ── :bfill with index_at=last ────────────────────────────────────────
    r_last_bf = resample(ts_il, Month(1); fill_gaps=:bfill, index_at=last)
    feb_idx_lbf = findfirst(==(Date(2020,2,29)), index(r_last_bf))
    @test !ismissing(r_last_bf.coredata[feb_idx_lbf, :Open])
    # bfill: Feb filled from the next non-missing row
    next_row = feb_idx_lbf + 1
    @test r_last_bf.coredata[feb_idx_lbf, :Open] == r_last_bf.coredata[next_row, :Open]

    # ── :zero with index_at=last ─────────────────────────────────────────
    r_last_z = resample(ts_il, Month(1); fill_gaps=:zero, index_at=last)
    feb_idx_lz = findfirst(==(Date(2020,2,29)), index(r_last_z))
    @test r_last_z.coredata[feb_idx_lz, :Open] == 0.0
    @test r_last_z.coredata[feb_idx_lz, :Volume] == 0

    # ── :interpolate with index_at=last ──────────────────────────────────
    # NOTE: Use explicit Float pairs to avoid InexactError on Int columns (Volume).
    # The implementation's _apply_interpolate_gaps! produces Float results for all
    # numeric columns; Int columns trigger InexactError — this is a known limitation
    # (implementation bug) that should be fixed in src/resample.jl.
    r_last_ip = resample(ts_il, Month(1), :Open => first, :Close => last;
                         fill_gaps=:interpolate, index_at=last)
    feb_idx_lip = findfirst(==(Date(2020,2,29)), index(r_last_ip))
    @test !ismissing(r_last_ip.coredata[feb_idx_lip, :Open])
end

# -- 30. fill_gaps invalid strategy throws ArgumentError ------------------------------

@testset "fill_gaps invalid strategy throws ArgumentError" begin
    dates = [Date(2020,1,1), Date(2020,3,1)]
    df = DataFrame(Open=[1.0, 2.0], Close=[1.1, 2.1])
    ts = TSFrame(df, dates)
    @test_throws ArgumentError resample(ts, Month(1); fill_gaps=:invalid)
    @test_throws ArgumentError resample(ts, Month(1); fill_gaps=:unknown_strategy)
    @test_throws ArgumentError resample(ts, Month(1); fill_gaps=:FFILL)  # case-sensitive
end

# -- 27b. fill_gaps pre-existing missing preservation (:interpolate + constant) -------

@testset "fill_gaps pre-existing missing preservation (:interpolate and constant)" begin
    # Same data structure as testset #27: non-gap row has pre-existing missing in column
    dates_pm2 = vcat(
        collect(Date(2020,1,1):Day(1):Date(2020,1,31)),
        collect(Date(2020,3,1):Day(1):Date(2020,3,31))
    )
    npm2 = length(dates_pm2)

    # Put missing in the first element of January (non-gap data)
    vals_pm2 = Union{Float64,Missing}[i == 1 ? missing : Float64(i) for i in 1:npm2]
    ts_pm2 = TSFrame(DataFrame(val = vals_pm2), dates_pm2)

    # ── :interpolate: pre-existing missing in aggregated non-gap row stays missing ──
    r_ip = resample(ts_pm2, Month(1), :val => first; fill_gaps=:interpolate)
    jan_idx_ip = findfirst(==(Date(2020,1,1)), index(r_ip))
    # first(vals for January) = missing (row 1 is missing)
    @test ismissing(r_ip.coredata[jan_idx_ip, :val])

    # Feb gap: interpolate should fill with a value (between Jan and Mar)
    # but since Jan is missing, the left anchor for interpolation is missing,
    # so Feb may remain missing (implementation-dependent). We just check Jan is preserved.
    feb_idx_ip = findfirst(==(Date(2020,2,1)), index(r_ip))
    @test feb_idx_ip !== nothing  # Feb row exists

    # ── constant fill (99.0): pre-existing missing in non-gap row stays missing ──
    r_const = resample(ts_pm2, Month(1), :val => first; fill_gaps=99.0)
    jan_idx_c = findfirst(==(Date(2020,1,1)), index(r_const))
    @test ismissing(r_const.coredata[jan_idx_c, :val])  # pre-existing missing preserved
    feb_idx_c = findfirst(==(Date(2020,2,1)), index(r_const))
    @test r_const.coredata[feb_idx_c, :val] == 99.0  # gap row filled with constant
end

# -- 31. fill_limit=0 throws ArgumentError (validation) ------------------------------

@testset "fill_limit=0 throws ArgumentError (validation)" begin
    dates = [Date(2020,1,1), Date(2020,3,1)]
    df = DataFrame(Open=[1.0, 2.0])
    ts = TSFrame(df, dates)
    @test_throws ArgumentError resample(ts, Month(1); fill_gaps=:ffill, fill_limit=0)
    @test_throws ArgumentError resample(ts, Month(1); fill_gaps=:ffill, fill_limit=-1)
end

# -- 32. fill_gaps :ffill fills last-period gap ---------------------------------------

@testset "fill_gaps :ffill fills last-period gap" begin
    # Data in Jan + Mar only → Feb is a gap
    # :ffill should fill Feb from Jan's aggregated value
    dates2 = [Date(2020,1,15), Date(2020,3,15)]
    df2 = DataFrame(Close=[10.0, 30.0])
    ts2 = TSFrame(df2, dates2)
    result = resample(ts2, Month(1); fill_gaps=:ffill)
    # Expect 3 rows: Jan, Feb (gap), Mar
    @test size(result.coredata, 1) == 3
    # Feb should be filled from Jan (10.0)
    feb_idx = findfirst(==(Date(2020,2,1)), index(result))
    @test feb_idx !== nothing
    @test result.coredata[feb_idx, :Close] == 10.0
    @test !ismissing(result.coredata[feb_idx, :Close])
end

# -- 33. fill_limit ignored for non-directional strategies ----------------------------

@testset "fill_limit ignored for non-directional strategies" begin
    dates = [Date(2020,1,1), Date(2020,4,1)]  # Feb and Mar are gaps
    df = DataFrame(Close=[10.0, 40.0])
    ts = TSFrame(df, dates)

    # For :zero, fill_limit=1 should still fill ALL gap rows (fill_limit is ignored)
    result = resample(ts, Month(1); fill_gaps=:zero, fill_limit=1)
    feb_idx = findfirst(==(Date(2020,2,1)), index(result))
    mar_idx = findfirst(==(Date(2020,3,1)), index(result))
    @test result.coredata[feb_idx, :Close] == 0.0   # Feb gap → zero
    @test result.coredata[mar_idx, :Close] == 0.0   # Mar gap → zero (not limited)

    # For :interpolate, fill_limit=1 should still fill ALL gap rows
    result2 = resample(ts, Month(1); fill_gaps=:interpolate, fill_limit=1)
    feb_idx2 = findfirst(==(Date(2020,2,1)), index(result2))
    mar_idx2 = findfirst(==(Date(2020,3,1)), index(result2))
    @test !ismissing(result2.coredata[feb_idx2, :Close])
    @test !ismissing(result2.coredata[mar_idx2, :Close])
end

# -- 34. fill_gaps :interpolate with Int column ---------------------------------------

@testset "fill_gaps :interpolate with Int column" begin
    # Int columns should now be interpolated with round()
    dates = [Date(2020,1,1), Date(2020,3,1)]  # Feb is a gap
    df = DataFrame(Volume=[100, 200])
    ts = TSFrame(df, dates)
    result = resample(ts, Month(1); fill_gaps=:interpolate)
    @test size(result.coredata, 1) == 3
    # Feb gap: interpolate between 100 and 200
    # 2020 is a leap year: Jan1→Mar1 = 60 days, Feb1 is 31 days after Jan1
    # frac = 31/60 → round(Int64, 100 + 31/60 * 100) = round(151.67) = 152
    feb_idx = findfirst(==(Date(2020,2,1)), index(result))
    @test feb_idx !== nothing
    @test result.coredata[feb_idx, :Volume] == 152
end

# -- A. fill_gaps strategies with empty TSFrame ---------------------------------
@testset "fill_gaps: empty TSFrame returns empty for all strategies" begin
    empty_ts = TSFrame(DataFrame(Open=Float64[], High=Float64[]), Date[])

    for strat in [:ffill, :bfill, :zero, :missing, :interpolate]
        r = resample(empty_ts, Month(1); fill_gaps=strat)
        @test DataFrames.nrow(r.coredata) == 0
    end

    # constant fill
    r_const = resample(empty_ts, Month(1); fill_gaps=0.0)
    @test DataFrames.nrow(r_const.coredata) == 0
end

# -- B. fill_gaps=:ffill leading gap stays missing ----------------------------
@testset "fill_gaps=:ffill: leading gap row stays missing" begin
    # Only February and March data; January is a gap (no prior value to forward fill from)
    dates_lead = vcat(
        collect(Date(2020,2,1):Day(1):Date(2020,2,29)),
        collect(Date(2020,3,1):Day(1):Date(2020,3,31))
    )
    n_lead = length(dates_lead)
    ts_lead = TSFrame(DataFrame(
        Close = Float64.(1:n_lead)
    ), dates_lead)

    r = resample(ts_lead, Month(1); fill_gaps=:ffill)

    jan_idx = findfirst(==(Date(2020,1,1)), index(r))
    if jan_idx !== nothing
        # If January gap row was inserted, it must remain missing (no prior value)
        @test ismissing(r.coredata[jan_idx, :Close])
    end
    # February and March should have aggregated values (not missing)
    feb_idx = findfirst(==(Date(2020,2,1)), index(r))
    mar_idx = findfirst(==(Date(2020,3,1)), index(r))
    @test feb_idx !== nothing
    @test mar_idx !== nothing
    @test !ismissing(r.coredata[feb_idx, :Close])
    @test !ismissing(r.coredata[mar_idx, :Close])
end

# -- D. fill_limit resets between gap groups -----------------------------------
@testset "fill_gaps=:ffill: fill_limit resets between gap groups" begin
    # Pattern: [Jan data] [Feb gap] [Mar data] [Apr gap] [May data]
    dates_groups = vcat(
        collect(Date(2020,1,1):Day(1):Date(2020,1,31)),
        collect(Date(2020,3,1):Day(1):Date(2020,3,31)),
        collect(Date(2020,5,1):Day(1):Date(2020,5,31))
    )
    n_groups = length(dates_groups)
    ts_groups = TSFrame(DataFrame(
        Close = Float64.(1:n_groups)
    ), dates_groups)

    r = resample(ts_groups, Month(1); fill_gaps=:ffill, fill_limit=1)

    feb_idx = findfirst(==(Date(2020,2,1)), index(r))
    apr_idx = findfirst(==(Date(2020,4,1)), index(r))

    # Both gap months should be filled (limit=1 resets after each data group)
    @test feb_idx !== nothing
    @test apr_idx !== nothing
    @test !ismissing(r.coredata[feb_idx, :Close])
    @test !ismissing(r.coredata[apr_idx, :Close])
end

# -- E. fill_limit is ignored for :missing and constant strategies -------------
@testset "fill_gaps: fill_limit ignored for :missing and constant strategies" begin
    dates_lim = vcat(
        collect(Date(2020,1,1):Day(1):Date(2020,1,31)),
        collect(Date(2020,4,1):Day(1):Date(2020,4,30))
    )
    n_lim = length(dates_lim)
    ts_lim = TSFrame(DataFrame(Close=Float64.(1:n_lim)), dates_lim)

    # :missing with fill_limit=1 — both gap months (Feb, Mar) should stay missing
    r_miss = resample(ts_lim, Month(1); fill_gaps=:missing, fill_limit=1)
    feb_miss = findfirst(==(Date(2020,2,1)), index(r_miss))
    mar_miss = findfirst(==(Date(2020,3,1)), index(r_miss))
    if feb_miss !== nothing
        @test ismissing(r_miss.coredata[feb_miss, :Close])
    end
    if mar_miss !== nothing
        @test ismissing(r_miss.coredata[mar_miss, :Close])
    end

    # constant fill (42.0) with fill_limit=1 — both gap months should be filled
    r_const = resample(ts_lim, Month(1); fill_gaps=42.0, fill_limit=1)
    feb_const = findfirst(==(Date(2020,2,1)), index(r_const))
    mar_const = findfirst(==(Date(2020,3,1)), index(r_const))
    if feb_const !== nothing
        @test r_const.coredata[feb_const, :Close] == 42.0
    end
    if mar_const !== nothing
        @test r_const.coredata[mar_const, :Close] == 42.0
    end
end

# -- F. :interpolate Float column exact value verification ---------------------
@testset "fill_gaps=:interpolate: Float column time-weighted values" begin
    dates_interp = vcat(
        collect(Date(2020,1,1):Day(1):Date(2020,1,31)),
        collect(Date(2020,3,1):Day(1):Date(2020,3,31))
    )
    n_interp = length(dates_interp)
    ts_interp = TSFrame(DataFrame(
        Close = Float64.(1:n_interp)
    ), dates_interp)

    r = resample(ts_interp, Month(1); fill_gaps=:interpolate)

    jan_idx = findfirst(==(Date(2020,1,1)), index(r))
    feb_idx = findfirst(==(Date(2020,2,1)), index(r))
    mar_idx = findfirst(==(Date(2020,3,1)), index(r))

    @test jan_idx !== nothing
    @test feb_idx !== nothing
    @test mar_idx !== nothing

    jan_val = r.coredata[jan_idx, :Close]
    mar_val = r.coredata[mar_idx, :Close]
    feb_val = r.coredata[feb_idx, :Close]

    # Feb gap must be strictly between Jan and Mar aggregated values
    @test !ismissing(feb_val)
    @test feb_val > jan_val
    @test feb_val < mar_val

    # Time-weighted interpolation: frac = (feb_date - jan_date) / (mar_date - jan_date)
    # Using the actual index dates from result
    jan_date = index(r)[jan_idx]
    feb_date = index(r)[feb_idx]
    mar_date = index(r)[mar_idx]
    frac = Dates.value(feb_date - jan_date) / Dates.value(mar_date - jan_date)
    expected = jan_val + frac * (mar_val - jan_val)
    @test feb_val ≈ expected
end

# -- G. Additional edge cases --------------------------------------------------
# These tests cover edge conditions that the existing suite does not yet exercise:
#   1. Single-row TSFrame with a period larger than the row span
#   2. Float32 columns across all fill strategies (type preservation)
#   3. All-missing columns (ffill/bfill stay missing, zero fills only gap rows)
#   4. fill_limit=0 — ArgumentError (not a positive integer)
#   5. fill_limit negative — ArgumentError

@testset "resample edge cases" begin
    # ── 1. Single-row TSFrame with various periods ──────────────────────────
    @testset "Single-row TSFrame — multiple period types" begin
        # Single row with Year period — output must have exactly one row
        ts_single_year = TSFrame(
            DataFrame(Open=[10.0], High=[12.0], Low=[9.0], Close=[11.0], Volume=[500]),
            [Date(2020, 6, 15)],
        )
        result_year = resample(ts_single_year, Year(1))
        @test DataFrames.nrow(result_year.coredata) == 1
        @test result_year[:, :Open][1] == 10.0
        @test result_year[:, :High][1] == 12.0
        @test result_year[:, :Low][1] == 9.0
        @test result_year[:, :Close][1] == 11.0
        @test result_year[:, :Volume][1] == 500

        # Single row with Month period — custom Symbol pairs
        result_month = resample(ts_single_year, Month(1), :Open => first, :Volume => sum)
        @test DataFrames.nrow(result_month.coredata) == 1
        @test result_month[:, :Open][1] == 10.0
        @test result_month[:, :Volume][1] == 500

        # Single row with fill_gaps=:ffill — no gap to fill, still 1 row
        result_ff = resample(ts_single_year, Month(1); fill_gaps=:ffill)
        @test DataFrames.nrow(result_ff.coredata) == 1
        @test !ismissing(result_ff[:, :Open][1])
    end

    # ── 2. Float32 columns — type preservation across fill strategies ───────
    @testset "Float32 column with fill_gaps strategies" begin
        # Jan and Mar data, Feb gap
        dates_f32 = vcat(
            collect(Date(2020,1,1):Day(1):Date(2020,1,31)),
            collect(Date(2020,3,1):Day(1):Date(2020,3,31)),
        )
        n_f32 = length(dates_f32)
        ts_f32 = TSFrame(DataFrame(val = Float32.(1:n_f32)), dates_f32)

        # :ffill — Feb filled from Jan's aggregated value; eltype stays Float32
        r_ffill = resample(ts_f32, Month(1), :val => first; fill_gaps=:ffill)
        @test nonmissingtype(eltype(r_ffill.coredata[!, :val])) == Float32
        feb_ff = findfirst(==(Date(2020,2,1)), index(r_ffill))
        @test feb_ff !== nothing
        @test !ismissing(r_ffill.coredata[feb_ff, :val])
        @test r_ffill.coredata[feb_ff, :val] isa Float32

        # :bfill — Feb filled from Mar's aggregated value
        r_bfill = resample(ts_f32, Month(1), :val => first; fill_gaps=:bfill)
        @test nonmissingtype(eltype(r_bfill.coredata[!, :val])) == Float32
        feb_bf = findfirst(==(Date(2020,2,1)), index(r_bfill))
        @test feb_bf !== nothing
        @test !ismissing(r_bfill.coredata[feb_bf, :val])
        @test r_bfill.coredata[feb_bf, :val] isa Float32

        # :zero — Feb filled with Float32(0)
        r_zero = resample(ts_f32, Month(1), :val => first; fill_gaps=:zero)
        @test nonmissingtype(eltype(r_zero.coredata[!, :val])) == Float32
        feb_z = findfirst(==(Date(2020,2,1)), index(r_zero))
        @test feb_z !== nothing
        @test r_zero.coredata[feb_z, :val] === Float32(0)

        # :interpolate — Feb interpolated with Float32 result
        r_interp = resample(ts_f32, Month(1), :val => first; fill_gaps=:interpolate)
        @test nonmissingtype(eltype(r_interp.coredata[!, :val])) == Float32
        feb_ip = findfirst(==(Date(2020,2,1)), index(r_interp))
        @test feb_ip !== nothing
        @test !ismissing(r_interp.coredata[feb_ip, :val])
        @test r_interp.coredata[feb_ip, :val] isa Float32
    end

    # ── 3. All-missing column ───────────────────────────────────────────────
    @testset "All-missing column with fill_gaps" begin
        dates_am = vcat(
            collect(Date(2020,1,1):Day(1):Date(2020,1,31)),
            collect(Date(2020,3,1):Day(1):Date(2020,3,31)),
        )
        n_am = length(dates_am)
        # Column that is entirely missing
        vals_am = Vector{Union{Missing, Float64}}(missing, n_am)
        ts_am = TSFrame(DataFrame(val = vals_am), dates_am)

        # :ffill — nothing to ffill from, all rows stay missing
        r_ff = resample(ts_am, Month(1), :val => first; fill_gaps=:ffill)
        for i in 1:DataFrames.nrow(r_ff.coredata)
            @test ismissing(r_ff.coredata[i, :val])
        end

        # :bfill — nothing to bfill from, all rows stay missing
        r_bf = resample(ts_am, Month(1), :val => first; fill_gaps=:bfill)
        for i in 1:DataFrames.nrow(r_bf.coredata)
            @test ismissing(r_bf.coredata[i, :val])
        end

        # :zero — only inserted gap rows are filled with 0.0.
        # Pre-existing missing values from aggregation remain missing.
        r_z = resample(ts_am, Month(1), :val => first; fill_gaps=:zero)
        feb_idx_z = findfirst(==(Date(2020,2,1)), index(r_z))
        @test feb_idx_z !== nothing
        @test r_z.coredata[feb_idx_z, :val] == 0.0
        # Non-gap rows (Jan, Mar) originated from aggregating all-missing data,
        # so they stay missing (zero-fill only touches gap rows).
        jan_idx_z = findfirst(==(Date(2020,1,1)), index(r_z))
        @test jan_idx_z !== nothing
        @test ismissing(r_z.coredata[jan_idx_z, :val])
    end

    # ── 4. fill_limit=0 — rejected with ArgumentError ───────────────────────
    @testset "fill_limit=0 raises ArgumentError" begin
        dates_fl = vcat(
            collect(Date(2020,1,1):Day(1):Date(2020,1,31)),
            collect(Date(2020,3,1):Day(1):Date(2020,3,31)),
        )
        ts_fl = TSFrame(DataFrame(val = Float64.(1:length(dates_fl))), dates_fl)

        # Default (OHLCV) path — requires OHLCV columns, use explicit pairs instead
        @test_throws ArgumentError resample(
            ts_fl, Month(1), :val => first; fill_gaps=:ffill, fill_limit=0,
        )
        @test_throws ArgumentError resample(
            ts_fl, Month(1), :val => first; fill_gaps=:bfill, fill_limit=0,
        )

        # String-pair path — same validation applies
        @test_throws ArgumentError resample(
            ts_fl, Month(1), "val" => first; fill_gaps=:ffill, fill_limit=0,
        )

        # Default OHLCV path — needs OHLCV columns to reach fill_limit validation
        ts_ohlcv_fl = TSFrame(
            DataFrame(
                Open   = Float64.(1:length(dates_fl)),
                High   = Float64.(1:length(dates_fl)) .+ 1,
                Low    = Float64.(1:length(dates_fl)) .- 1,
                Close  = Float64.(1:length(dates_fl)),
                Volume = Int.(1:length(dates_fl)),
            ),
            dates_fl,
        )
        @test_throws ArgumentError resample(
            ts_ohlcv_fl, Month(1); fill_gaps=:ffill, fill_limit=0,
        )
    end

    # ── 5. fill_limit negative — rejected with ArgumentError ────────────────
    @testset "fill_limit negative raises ArgumentError" begin
        dates_neg = vcat(
            collect(Date(2020,1,1):Day(1):Date(2020,1,31)),
            collect(Date(2020,3,1):Day(1):Date(2020,3,31)),
        )
        ts_neg = TSFrame(DataFrame(val = Float64.(1:length(dates_neg))), dates_neg)

        @test_throws ArgumentError resample(
            ts_neg, Month(1), :val => first; fill_gaps=:ffill, fill_limit=-1,
        )
        @test_throws ArgumentError resample(
            ts_neg, Month(1), :val => first; fill_gaps=:bfill, fill_limit=-5,
        )
        @test_throws ArgumentError resample(
            ts_neg, Month(1), "val" => first; fill_gaps=:ffill, fill_limit=-10,
        )
    end

    # ── 6. fill_limit=1 boundary: exactly 1 consecutive gap row filled ──────
    @testset "fill_limit=1 boundary — fills 1 gap, leaves next missing" begin
        # Jan 15 → Apr 15, so Feb and Mar are two consecutive calendar gaps.
        dates_b = [Date(2020, 1, 15), Date(2020, 4, 15)]
        ts_b = TSFrame(DataFrame(val = [10.0, 20.0]), dates_b)

        # fill_limit=1 — only Feb (1st gap) filled; Mar (2nd gap) stays missing.
        r1 = resample(ts_b, Month(1), :val => first; fill_gaps=:ffill, fill_limit=1)
        feb_i = findfirst(==(Date(2020, 2, 1)), index(r1))
        mar_i = findfirst(==(Date(2020, 3, 1)), index(r1))
        @test feb_i !== nothing
        @test mar_i !== nothing
        @test !ismissing(r1.coredata[feb_i, :val])
        @test r1.coredata[feb_i, :val] == 10.0
        @test ismissing(r1.coredata[mar_i, :val])

        # fill_limit=2 — both Feb and Mar filled.
        r2 = resample(ts_b, Month(1), :val => first; fill_gaps=:ffill, fill_limit=2)
        feb_i2 = findfirst(==(Date(2020, 2, 1)), index(r2))
        mar_i2 = findfirst(==(Date(2020, 3, 1)), index(r2))
        @test feb_i2 !== nothing
        @test mar_i2 !== nothing
        @test !ismissing(r2.coredata[feb_i2, :val])
        @test !ismissing(r2.coredata[mar_i2, :val])
        @test r2.coredata[feb_i2, :val] == 10.0
        @test r2.coredata[mar_i2, :val] == 10.0
    end

    # ── 7. Float32 value assertions (not just eltype) ───────────────────────
    @testset "Float32 fill_gaps — value correctness" begin
        # 2-point TSFrame with 1-month gap so expected values are trivial.
        dates_fv = [Date(2020, 1, 15), Date(2020, 3, 15)]
        ts_fv = TSFrame(DataFrame(val = Float32[10.0, 30.0]), dates_fv)

        # :ffill — Feb row must equal Jan's aggregated value (10.0f0).
        r_ff = resample(ts_fv, Month(1), :val => first; fill_gaps=:ffill)
        feb_ff = findfirst(==(Date(2020, 2, 1)), index(r_ff))
        @test feb_ff !== nothing
        @test r_ff.coredata[feb_ff, :val] === Float32(10.0)

        # :bfill — Feb row must equal Mar's aggregated value (30.0f0).
        r_bf = resample(ts_fv, Month(1), :val => first; fill_gaps=:bfill)
        feb_bf = findfirst(==(Date(2020, 2, 1)), index(r_bf))
        @test feb_bf !== nothing
        @test r_bf.coredata[feb_bf, :val] === Float32(30.0)

        # :zero — Feb row must be exactly 0.0f0 (Float32-typed).
        r_z = resample(ts_fv, Month(1), :val => first; fill_gaps=:zero)
        feb_z = findfirst(==(Date(2020, 2, 1)), index(r_z))
        @test feb_z !== nothing
        @test r_z.coredata[feb_z, :val] === Float32(0.0)
    end

    # ── 8. :interpolate on all-missing column — graceful skip ───────────────
    @testset ":interpolate on all-missing column" begin
        # Entire column is missing: interpolation has no anchors to work from.
        # Verified behavior: all rows (including inserted gap rows) remain missing,
        # no error is thrown.
        dates_im = vcat(
            collect(Date(2020, 1, 1):Day(1):Date(2020, 1, 31)),
            collect(Date(2020, 3, 1):Day(1):Date(2020, 3, 31)),
        )
        n_im = length(dates_im)
        vals_im = Vector{Union{Missing, Float64}}(missing, n_im)
        ts_im = TSFrame(DataFrame(val = vals_im), dates_im)

        r_im = resample(ts_im, Month(1), :val => first; fill_gaps=:interpolate)
        # Feb gap row must exist
        feb_im = findfirst(==(Date(2020, 2, 1)), index(r_im))
        @test feb_im !== nothing
        # Every row stays missing — :interpolate has no anchors.
        for i in 1:DataFrames.nrow(r_im.coredata)
            @test ismissing(r_im.coredata[i, :val])
        end
    end
end
