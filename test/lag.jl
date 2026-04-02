ts = TSFrame(integer_data_vector, index_timetype)

# lagging by something atmost DATA_SIZE
for lagby in [0, 1, Int(floor(DATA_SIZE/2)), DATA_SIZE]
    lagged_ts = lag(ts, lagby)

    # test that Index remains the same
    @test isequal(lagged_ts[:, :Index], ts[:, :Index])

    # first lagby values are missing
    @test isequal(Vector{Missing}(lagged_ts[1:lagby, :x1]), fill(missing, lagby))

    # other elements are shifted
    isequal(lagged_ts[(lagby + 1):length(ts), :x1], ts[1:(length(ts) - lagby), :x1])
end

# lagging by something greater than DATA_SIZE
lagged_ts = lag(ts, DATA_SIZE + 1)
@test isequal(lagged_ts[:, :Index], ts[:, :Index])
@test isequal(Vector{Missing}(lagged_ts[1:DATA_SIZE, :x1]), fill(missing, DATA_SIZE))

# lagging by a negative integer
lagged_ts = lag(ts, -1)
@test isequal(lagged_ts[:, :Index], ts[:, :Index])
@test isequal(lagged_ts[TSFrames.nrow(ts), :x1], missing)
@test isequal(lagged_ts[1:TSFrames.nrow(ts) - 1, :x1], ts[2:TSFrames.nrow(ts), :x1])

# -- Additional lag tests -------------------------------------------------------

# Multi-column lag test
@testset "lag multi-column" begin
    mc_dates = Date(2020, 1, 1):Day(1):Date(2020, 1, 10) |> collect
    mc_ts = TSFrame([collect(1:10) collect(11:20) collect(21:30)], mc_dates, colnames=[:a, :b, :c])
    mc_lagged = lag(mc_ts, 2)

    @test isequal(mc_lagged[:, :Index], mc_ts[:, :Index])
    # first 2 rows of all columns should be missing
    @test all(ismissing, mc_lagged[1:2, :a])
    @test all(ismissing, mc_lagged[1:2, :b])
    @test all(ismissing, mc_lagged[1:2, :c])
    # remaining rows should be shifted
    @test isequal(mc_lagged[3:10, :a], mc_ts[1:8, :a])
    @test isequal(mc_lagged[3:10, :b], mc_ts[1:8, :b])
    @test isequal(mc_lagged[3:10, :c], mc_ts[1:8, :c])
end

# DateTime index lag test
@testset "lag DateTime index" begin
    dt_index = collect(DateTime(2020, 1, 1):Hour(1):DateTime(2020, 1, 1, 9))
    dt_ts = TSFrame(collect(1:10), dt_index)
    dt_lagged = lag(dt_ts, 3)

    @test isequal(dt_lagged[:, :Index], dt_ts[:, :Index])
    @test all(ismissing, dt_lagged[1:3, :x1])
    @test isequal(dt_lagged[4:10, :x1], dt_ts[1:7, :x1])
end

# Single-row edge case
@testset "lag single row" begin
    single_ts = TSFrame([42], [Date(2020, 1, 1)])
    single_lagged = lag(single_ts, 1)

    @test length(single_lagged) == 1
    @test isequal(single_lagged[1, :x1], missing)
    @test isequal(single_lagged[:, :Index], single_ts[:, :Index])
end

# Default argument (lag=1) test
@testset "lag default argument" begin
    def_dates = Date(2020, 1, 1):Day(1):Date(2020, 1, 5) |> collect
    def_ts = TSFrame(collect(1:5), def_dates)
    lagged_default = lag(def_ts)
    lagged_explicit = lag(def_ts, 1)

    @test isequal(lagged_default[:, :x1], lagged_explicit[:, :x1])
    @test isequal(lagged_default[:, :Index], lagged_explicit[:, :Index])
end

# Lag/lead symmetry: lag(lead(ts,1),1) == ts for middle rows
@testset "lag/lead symmetry" begin
    sym_dates = Date(2020, 1, 1):Day(1):Date(2020, 1, 10) |> collect
    sym_ts = TSFrame(collect(1:10), sym_dates)
    roundtripped = lag(lead(sym_ts, 1), 1)

    # middle rows (2 through 9) should match original
    @test isequal(roundtripped[2:9, :x1], sym_ts[2:9, :x1])
end

# Out-of-bounds lag value (lag > nrow) - all values should be missing
@testset "lag out-of-bounds" begin
    oob_dates = Date(2020, 1, 1):Day(1):Date(2020, 1, 5) |> collect
    oob_ts = TSFrame(collect(1:5), oob_dates)
    oob_lagged = lag(oob_ts, 10)

    @test isequal(oob_lagged[:, :Index], oob_ts[:, :Index])
    @test all(ismissing, oob_lagged[:, :x1])
end

# Negative lag is equivalent to lead
@testset "lag negative equals lead" begin
    neg_dates = Date(2020, 1, 1):Day(1):Date(2020, 1, 10) |> collect
    neg_ts = TSFrame(collect(1:10), neg_dates)
    lagged_neg = lag(neg_ts, -2)
    led_pos = lead(neg_ts, 2)

    @test isequal(lagged_neg[:, :x1], led_pos[:, :x1])
    @test isequal(lagged_neg[:, :Index], led_pos[:, :Index])
end
