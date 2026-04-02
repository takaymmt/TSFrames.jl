DATA_SIZE = 10
index_timetype = Date(2000, 1,1) + Day.(0:(DATA_SIZE - 1))
vec1 = collect(1:DATA_SIZE)
vec2 = collect(1:DATA_SIZE)
vec3 = collect(1:DATA_SIZE)
ts = TSFrame([vec1 vec2 vec3], index_timetype, colnames=[:A, :B, :C])

# tests for rollapply(ts::TSFrame, fun::Function, windowsize::Int; bycolumn=true)
@test_throws ArgumentError rollapply(ts, Statistics.mean, 0)

## testing for windowsize equal to 1, 5, DATA_SIZE and DATA_SIZE + 1
for windowsize in [1, 5, DATA_SIZE, DATA_SIZE + 1]
    windowsize = min(windowsize, DATA_SIZE)
    mean_ts = rollapply(ts, Statistics.mean, windowsize)
    @test propertynames(mean_ts.coredata) == [:Index, :rolling_A_mean, :rolling_B_mean, :rolling_C_mean]
    @test index(mean_ts) == index_timetype[windowsize:DATA_SIZE]
    outputs = Vector([mean(endindex - windowsize + 1:endindex) for endindex in windowsize:DATA_SIZE])
    @test mean_ts[:, :rolling_A_mean] == outputs
    @test mean_ts[:, :rolling_B_mean] == outputs
    @test mean_ts[:, :rolling_C_mean] == outputs
end

# tests for rollapply(ts::TSFrame, fun::Function, windowsize::Int; bycolumn=false)
@test_throws ArgumentError rollapply(ts, size, 0; bycolumn=false)

## testing for windowsize equal to 1, 5, DATA_SIZE and DATA_SIZE + 1
for windowsize in [1, 5, DATA_SIZE, DATA_SIZE + 1]
    windowsize = min(windowsize, DATA_SIZE)
    size_ts = rollapply(ts, size, windowsize; bycolumn=false)
    @test propertynames(size_ts.coredata) == [:Index, :rolling_size]
    @test index(size_ts) == index_timetype[windowsize:DATA_SIZE]
    @test size_ts[:, :rolling_size] == [(windowsize, TSFrames.ncol(ts)) for i in windowsize:DATA_SIZE]
end

# -- Additional rollapply tests --------------------------------------------------

# DateTime index rollapply test
@testset "rollapply DateTime index" begin
    dt_size = 10
    dt_index = collect(DateTime(2020, 1, 1):Hour(1):DateTime(2020, 1, 1) + Hour(dt_size - 1))
    dt_ts = TSFrame(collect(1:dt_size), dt_index)
    dt_roll = rollapply(dt_ts, Statistics.mean, 3)

    @test length(dt_roll) == dt_size - 3 + 1
    @test index(dt_roll) == dt_index[3:dt_size]
    # first window: mean(1,2,3) = 2.0
    @test dt_roll[1, :rolling_x1_mean] ≈ 2.0
    # last window: mean(8,9,10) = 9.0
    @test dt_roll[dt_size - 2, :rolling_x1_mean] ≈ 9.0
end

# Custom function test (range = maximum - minimum)
@testset "rollapply custom function" begin
    custom_size = 8
    custom_dates = Date(2020, 1, 1):Day(1):Date(2020, 1, custom_size) |> collect
    custom_ts = TSFrame(Float64.(collect(1:custom_size)), custom_dates)
    range_fun(x) = maximum(x) - minimum(x)
    custom_roll = rollapply(custom_ts, range_fun, 3)

    @test length(custom_roll) == custom_size - 3 + 1
    # range of any 3-element consecutive window of [1,2,...,8] is always 2.0
    for i in 1:length(custom_roll)
        @test custom_roll[i, :rolling_x1_range_fun] ≈ 2.0
    end
end

# Window size equal to nrow (single output row)
@testset "rollapply window equals nrow" begin
    full_size = 5
    full_dates = Date(2020, 1, 1):Day(1):Date(2020, 1, full_size) |> collect
    full_ts = TSFrame(Float64.(collect(1:full_size)), full_dates)
    full_roll = rollapply(full_ts, Statistics.mean, full_size)

    @test length(full_roll) == 1
    @test full_roll[1, :rolling_x1_mean] ≈ mean(1.0:5.0)
    @test index(full_roll) == [full_dates[end]]
end

# Window size = 1 (identity-like: each element is fun applied to itself)
@testset "rollapply window size 1" begin
    id_size = 6
    id_dates = Date(2020, 1, 1):Day(1):Date(2020, 1, id_size) |> collect
    id_vals = Float64.(collect(10:15))
    id_ts = TSFrame(id_vals, id_dates)
    id_roll = rollapply(id_ts, sum, 1)

    @test length(id_roll) == id_size
    @test index(id_roll) == id_dates
    # sum of a single element is the element itself
    @test id_roll[:, :rolling_x1_sum] ≈ id_vals
end

# Multi-column with custom function (bycolumn=true)
@testset "rollapply multi-column custom" begin
    mc_size = 6
    mc_dates = Date(2020, 1, 1):Day(1):Date(2020, 1, mc_size) |> collect
    mc_ts = TSFrame([Float64.(1:mc_size) Float64.(11:10+mc_size)], mc_dates, colnames=[:p, :q])
    mc_roll = rollapply(mc_ts, maximum, 2)

    @test length(mc_roll) == mc_size - 1
    # window [1,2] -> max=2, window [2,3] -> max=3, etc.
    @test mc_roll[:, :rolling_p_maximum] ≈ Float64.(2:mc_size)
    @test mc_roll[:, :rolling_q_maximum] ≈ Float64.(12:10+mc_size)
end
