ts = TSFrame(integer_data_vector, index_timetype)

@test_throws ArgumentError pctchange(ts, 0)
@test_throws ArgumentError pctchange(ts, -1)

# when period is something less than DATA_SIZE
for periods in [1, Int(floor(DATA_SIZE/2))]
    pctchange_ts = pctchange(ts, periods)

    # test that Index remains the same
    @test isequal(pctchange_ts[:, :Index], ts[:, :Index])

    # first periods values are missing
    @test isequal(Vector{Missing}(pctchange_ts[1:periods, :x1]), fill(missing, periods))

    # other elements are pct changes
    pctchange_output = pctchange_ts[(periods + 1):TSFrames.nrow(ts), :x1]
    correct_output = (ts[periods + 1:TSFrames.nrow(ts), :x1] - ts[1:TSFrames.nrow(ts) - periods, :x1]) ./ abs.(ts[1:TSFrames.nrow(ts) - periods, :x1])

    @test floor.(pctchange_output .* 100) == floor.(correct_output .* 100)
end

# when period is atleast DATA_SIZE
for periods in [DATA_SIZE, DATA_SIZE + 1]
    pctchange_ts = lag(ts, periods)
    @test isequal(pctchange_ts[:, :Index], ts[:, :Index])
    @test isequal(Vector{Missing}(pctchange_ts[1:DATA_SIZE, :x1]), fill(missing, DATA_SIZE))
end

@testset "pctchange multi-column" begin
    dates_mc = Date(2007, 1, 1) .+ Day.(0:4)
    col1 = [100.0, 110.0, 121.0, 133.1, 146.41]
    col2 = [200.0, 220.0, 242.0, 266.2, 292.82]
    ts_mc = TSFrame(DataFrame(Index = dates_mc, a = col1, b = col2))

    pct_mc = pctchange(ts_mc)

    # Index preserved
    @test isequal(pct_mc[:, :Index], ts_mc[:, :Index])

    # First row missing for both columns
    @test ismissing(pct_mc[1, :a])
    @test ismissing(pct_mc[1, :b])

    # Remaining rows: pctchange applied to each column independently
    for i in 2:5
        expected_a = (col1[i] - col1[i - 1]) / abs(col1[i - 1])
        expected_b = (col2[i] - col2[i - 1]) / abs(col2[i - 1])
        @test floor(pct_mc[i, :a] * 100) == floor(expected_a * 100)
        @test floor(pct_mc[i, :b] * 100) == floor(expected_b * 100)
    end
end

@testset "pctchange single row" begin
    ts_single = TSFrame(DataFrame(Index = [Date(2007, 1, 1)], x1 = [42.0]))

    pct_single = pctchange(ts_single)

    # Single row TSFrame: the only value should be missing
    @test TSFrames.nrow(pct_single) == 1
    @test ismissing(pct_single[1, :x1])
end

@testset "pctchange does not mutate source TSFrame" begin
    dates_mut = Date(2007, 1, 1) .+ Day.(0:4)
    vals = [100.0, 110.0, 121.0, 133.1, 146.41]
    ts_mut = TSFrame(DataFrame(Index = dates_mut, x1 = copy(vals)))
    original_vals = copy(ts_mut[:, :x1])

    _ = pctchange(ts_mut)

    @test isequal(ts_mut[:, :x1], original_vals)
end

@testset "pctchange with negative previous values (abs denominator)" begin
    # TSFrames uses abs(x_{t-k}) in the denominator, differing from pandas/R
    # which use signed x_{t-k}. This test pins the current behavior.
    ts = TSFrame(DataFrame(Index=1:3, val=[-2.0, 1.0, -4.0]))
    result = pctchange(ts, 1)
    @test ismissing(result[1, :val])
    # (1.0 - (-2.0)) / abs(-2.0) = 3.0 / 2.0 = 1.5
    @test result[2, :val] ≈ 1.5
    # (-4.0 - 1.0) / abs(1.0) = -5.0 / 1.0 = -5.0
    @test result[3, :val] ≈ -5.0

    # Multi-period: periods=2
    ts2 = TSFrame(DataFrame(Index=1:4, val=[-4.0, 2.0, -8.0, 6.0]))
    result2 = pctchange(ts2, 2)
    @test ismissing(result2[1, :val])
    @test ismissing(result2[2, :val])
    # (-8.0 - (-4.0)) / abs(-4.0) = -4.0 / 4.0 = -1.0
    @test result2[3, :val] ≈ -1.0
    # (6.0 - 2.0) / abs(2.0) = 4.0 / 2.0 = 2.0
    @test result2[4, :val] ≈ 2.0
end
