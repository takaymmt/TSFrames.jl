# test/datetime_index.jl
# Tests for TSFrame operations with DateTime and Time index types

using Dates, DataFrames, Statistics, Test, TSFrames

# -- 1. TSFrame construction with DateTime index --------------------------------

@testset "construct with DateTime index" begin
    dt_index = collect(DateTime(2020, 1, 1):Hour(1):DateTime(2020, 1, 1, 9))
    ts = TSFrame(collect(1:10), dt_index)

    @test ts isa TSFrame
    @test eltype(index(ts)) == DateTime
    @test length(ts) == 10
    @test index(ts) == dt_index
end

# -- 2. TSFrame construction with Time index ------------------------------------

@testset "construct with Time index" begin
    t_index = collect(Time(9, 0):Minute(15):Time(11, 0))
    ts = TSFrame(collect(1:length(t_index)), t_index)

    @test ts isa TSFrame
    @test eltype(index(ts)) == Time
    @test length(ts) == length(t_index)
    @test index(ts) == t_index
end

# -- 3. endpoints() with DateTime index (hourly grouping) ----------------------

@testset "endpoints DateTime hourly" begin
    # 4 hours of minute-level data
    dt_index = collect(DateTime(2020, 3, 1, 9, 0):Minute(1):DateTime(2020, 3, 1, 12, 59))
    ts = TSFrame(randn(length(dt_index)), dt_index)

    ep = endpoints(ts, Hour(1))
    @test length(ep) == 4  # 09:xx, 10:xx, 11:xx, 12:xx

    # Each endpoint should be the last row in its hour-group
    @test hour(index(ts)[ep[1]]) == 9
    @test minute(index(ts)[ep[1]]) == 59
    @test hour(index(ts)[ep[end]]) == 12
    @test minute(index(ts)[ep[end]]) == 59
end

@testset "endpoints DateTime minute grouping" begin
    # 30 seconds of data, grouped by minute
    dt_index = collect(DateTime(2020, 1, 1, 10, 0, 0):Second(1):DateTime(2020, 1, 1, 10, 2, 30))
    ts = TSFrame(randn(length(dt_index)), dt_index)

    ep = endpoints(ts, Minute(1))
    # 10:00:xx, 10:01:xx, 10:02:xx => 3 groups
    @test length(ep) == 3
end

# -- 4. apply() with DateTime index --------------------------------------------

@testset "apply DateTime index" begin
    # 4 hours of minute data, aggregate to hourly mean
    dt_index = collect(DateTime(2020, 6, 1, 9, 0):Minute(1):DateTime(2020, 6, 1, 12, 59))
    vals = Float64.(1:length(dt_index))
    ts = TSFrame(vals, dt_index)

    result = apply(ts, Hour(1), mean)
    @test result isa TSFrame
    @test length(result) == 4
    @test eltype(index(result)) == DateTime
end

# -- 5. resample() with DateTime index -----------------------------------------

@testset "resample DateTime index" begin
    dt_index = collect(DateTime(2020, 1, 1):Hour(1):DateTime(2020, 1, 3, 23))
    n = length(dt_index)
    df = DataFrame(
        Open   = Float64.(1:n),
        High   = Float64.(2:n+1),
        Low    = Float64.(0:n-1),
        Close  = Float64.(1:n) .+ 0.5,
        Volume = collect(100:100+n-1),
    )
    ts = TSFrame(df, dt_index)

    daily = resample(ts, Day(1))
    @test daily isa TSFrame
    @test DataFrames.nrow(daily.coredata) == 3  # Jan 1, Jan 2, Jan 3
    @test eltype(index(daily)) == DateTime
end

# -- 6. lag/lead with DateTime index -------------------------------------------

@testset "lag with DateTime index" begin
    dt_index = collect(DateTime(2020, 1, 1):Minute(30):DateTime(2020, 1, 1, 4, 30))
    ts = TSFrame(Float64.(1:length(dt_index)), dt_index)

    lagged = lag(ts, 2)
    @test isequal(lagged[:, :Index], ts[:, :Index])
    @test ismissing(lagged[1, :x1])
    @test ismissing(lagged[2, :x1])
    @test lagged[3, :x1] == 1.0
end

@testset "lead with DateTime index" begin
    dt_index = collect(DateTime(2020, 1, 1):Minute(30):DateTime(2020, 1, 1, 4, 30))
    ts = TSFrame(Float64.(1:length(dt_index)), dt_index)

    led = lead(ts, 2)
    n = length(ts)
    @test isequal(led[:, :Index], ts[:, :Index])
    @test ismissing(led[n, :x1])
    @test ismissing(led[n-1, :x1])
    @test led[1, :x1] == 3.0
end

# -- 7. subset() with DateTime index range -------------------------------------

@testset "subset DateTime range" begin
    dt_index = collect(DateTime(2020, 1, 1):Hour(1):DateTime(2020, 1, 2))
    ts = TSFrame(Float64.(1:length(dt_index)), dt_index)

    sub = TSFrames.subset(ts, DateTime(2020, 1, 1, 6), DateTime(2020, 1, 1, 12))
    @test length(sub) == 7  # hours 6,7,8,9,10,11,12
    @test index(sub)[1] == DateTime(2020, 1, 1, 6)
    @test index(sub)[end] == DateTime(2020, 1, 1, 12)
end

@testset "subset DateTime open-ended" begin
    dt_index = collect(DateTime(2020, 1, 1):Hour(1):DateTime(2020, 1, 1, 10))
    ts = TSFrame(Float64.(1:11), dt_index)

    # from beginning to a specific time
    sub_to = TSFrames.subset(ts, :, DateTime(2020, 1, 1, 3))
    @test length(sub_to) == 4  # hours 0,1,2,3

    # from a specific time to end
    sub_from = TSFrames.subset(ts, DateTime(2020, 1, 1, 8), :)
    @test length(sub_from) == 3  # hours 8,9,10
end

# -- 8. rollapply with DateTime index ------------------------------------------

@testset "rollapply DateTime index" begin
    dt_index = collect(DateTime(2020, 1, 1):Hour(1):DateTime(2020, 1, 1, 7))
    ts = TSFrame(Float64.(collect(1:8)), dt_index)

    result = rollapply(ts, mean, 3)
    @test length(result) == 6
    @test index(result) == dt_index[3:8]
    @test result[1, :rolling_x1_mean] ≈ mean([1.0, 2.0, 3.0])
end

# -- 9. isregular with DateTime index ------------------------------------------

@testset "isregular DateTime" begin
    regular_index = collect(DateTime(2020, 1, 1):Hour(1):DateTime(2020, 1, 1, 5))
    regular_ts = TSFrame(Float64.(1:6), regular_index)
    @test isregular(regular_ts)
    @test isregular(regular_ts, Hour(1))
    @test !isregular(regular_ts, Hour(2))

    # Irregular DateTime series
    irregular_index = [DateTime(2020, 1, 1), DateTime(2020, 1, 1, 1),
                       DateTime(2020, 1, 1, 4), DateTime(2020, 1, 1, 7)]
    irregular_ts = TSFrame(Float64.(1:4), irregular_index)
    @test !isregular(irregular_ts)
end
