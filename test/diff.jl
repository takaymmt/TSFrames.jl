ts = TSFrame(integer_data_vector, index_timetype)

# when period is atmost DATA_SIZE
for period in [1, Int(floor(DATA_SIZE/2)), DATA_SIZE]
    ts_diff = diff(ts, period)

    # Index should be the same
    @test isequal(ts_diff[:, :Index], ts[:, :Index])

    # the first period values must be missing
    @test isequal(Vector{Missing}(ts_diff[1:period, :x1]), fill(missing, period))

    # the rest of the values must be the differences
    @test isequal(ts_diff[(period + 1):TSFrames.nrow(ts), :x1], ts[(period + 1):TSFrames.nrow(ts), :x1] - ts[1:TSFrames.nrow(ts) - period, :x1])
end

# when period is greater than DATA_SIZE
ts_diff = diff(ts, DATA_SIZE + 1)
@test isequal(ts_diff[:, :Index], ts[:, :Index])
@test isequal(Vector{Missing}(ts_diff[1:DATA_SIZE, :x1]), fill(missing, DATA_SIZE))

@testset "diff throws on invalid period" begin
    ts_err = TSFrame(integer_data_vector, index_timetype)
    @test_throws ArgumentError diff(ts_err, 0)
    @test_throws ArgumentError diff(ts_err, -1)
end

@testset "diff multi-column" begin
    dates_mc = Date(2007, 1, 1) .+ Day.(0:9)
    col1 = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
    col2 = [5, 15, 25, 35, 45, 55, 65, 75, 85, 95]
    ts_mc = TSFrame(DataFrame(Index = dates_mc, a = col1, b = col2))

    ts_mc_diff = diff(ts_mc)

    # Index should remain the same
    @test isequal(ts_mc_diff[:, :Index], ts_mc[:, :Index])

    # First row should be missing for both columns
    @test ismissing(ts_mc_diff[1, :a])
    @test ismissing(ts_mc_diff[1, :b])

    # Remaining rows should be the differences
    for i in 2:10
        @test ts_mc_diff[i, :a] == col1[i] - col1[i - 1]
        @test ts_mc_diff[i, :b] == col2[i] - col2[i - 1]
    end

    # Multi-column diff with periods > 1
    ts_mc_diff3 = diff(ts_mc, 3)
    for i in 1:3
        @test ismissing(ts_mc_diff3[i, :a])
        @test ismissing(ts_mc_diff3[i, :b])
    end
    for i in 4:10
        @test ts_mc_diff3[i, :a] == col1[i] - col1[i - 3]
        @test ts_mc_diff3[i, :b] == col2[i] - col2[i - 3]
    end
end

@testset "diff extreme Int values (C1 regression)" begin
    ts = TSFrame(Float64[1.0, 2.0, 3.0], Date(2020,1,1):Day(1):Date(2020,1,3) |> collect)
    # periods > nrow should return all-missing
    result = diff(ts, 100)
    @test TSFrames.nrow(result) == 3
    @test all(ismissing, result[:, 1])
    # typemax(Int) should not crash
    result_max = diff(ts, typemax(Int))
    @test TSFrames.nrow(result_max) == 3
    @test all(ismissing, result_max[:, 1])
end

@testset "diff empty TSFrame returns correct eltype" begin
    empty_ts = TSFrame(Float64[], Date[])
    result = diff(empty_ts)
    @test TSFrames.nrow(result) == 0
    one_ts = TSFrame(Float64[1.0], [Date(2020,1,1)])
    @test eltype(result[:, 1]) == eltype(diff(one_ts)[:, 1])
end
