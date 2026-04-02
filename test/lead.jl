ts = TSFrame(integer_data_vector, index_timetype)

# when leading by somethng non-negative and atmost DATA_SIZE
for leadby in [0, 1, Int(floor(DATA_SIZE/2)), DATA_SIZE]
    ts_lead = lead(ts, leadby)

    # Index should be the same
    @test isequal(ts_lead[:, :Index], ts[:, :Index])

    # The last lead values must be missing
    @test isequal(Vector{Missing}(ts_lead[TSFrames.nrow(ts) - (leadby - 1):TSFrames.nrow(ts), :x1]), fill(missing, leadby))

    # The rest of the values must be shifted
    @test isequal(ts_lead[1:TSFrames.nrow(ts) - leadby, :x1], ts[leadby + 1:TSFrames.nrow(ts), :x1])
end

# when leading by something greater than DATA_SIZE
ts_lead = lead(ts, DATA_SIZE + 1)
@test isequal(ts_lead[:, :Index], ts[:, :Index])
@test isequal(Vector{Missing}(ts_lead[1:TSFrames.nrow(ts), :x1]), fill(missing, DATA_SIZE))

# when leading by something negative
ts_lead = lead(ts, -1)
@test isequal(ts_lead[:, :Index], ts[:, :Index])
@test isequal(ts_lead[1, :x1], missing)
@test isequal(ts_lead[2:TSFrames.nrow(ts), :x1], ts[1:TSFrames.nrow(ts) - 1, :x1])

# -- Additional lead tests ------------------------------------------------------

# Multi-column lead test
@testset "lead multi-column" begin
    mc_dates = Date(2020, 1, 1):Day(1):Date(2020, 1, 10) |> collect
    mc_ts = TSFrame([collect(1:10) collect(11:20) collect(21:30)], mc_dates, colnames=[:a, :b, :c])
    mc_lead = lead(mc_ts, 3)

    @test isequal(mc_lead[:, :Index], mc_ts[:, :Index])
    # last 3 rows of all columns should be missing
    @test all(ismissing, mc_lead[8:10, :a])
    @test all(ismissing, mc_lead[8:10, :b])
    @test all(ismissing, mc_lead[8:10, :c])
    # first 7 rows should be shifted forward
    @test isequal(mc_lead[1:7, :a], mc_ts[4:10, :a])
    @test isequal(mc_lead[1:7, :b], mc_ts[4:10, :b])
    @test isequal(mc_lead[1:7, :c], mc_ts[4:10, :c])
end

# DateTime index lead test
@testset "lead DateTime index" begin
    dt_index = collect(DateTime(2020, 1, 1):Hour(1):DateTime(2020, 1, 1, 9))
    dt_ts = TSFrame(collect(1:10), dt_index)
    dt_lead = lead(dt_ts, 4)

    @test isequal(dt_lead[:, :Index], dt_ts[:, :Index])
    @test all(ismissing, dt_lead[7:10, :x1])
    @test isequal(dt_lead[1:6, :x1], dt_ts[5:10, :x1])
end

# Single-row edge case
@testset "lead single row" begin
    single_ts = TSFrame([99], [Date(2020, 6, 15)])
    single_lead = lead(single_ts, 1)

    @test length(single_lead) == 1
    @test isequal(single_lead[1, :x1], missing)
    @test isequal(single_lead[:, :Index], single_ts[:, :Index])
end

# Large lead value (lead > nrow) - all values should be missing
@testset "lead out-of-bounds" begin
    oob_dates = Date(2020, 1, 1):Day(1):Date(2020, 1, 5) |> collect
    oob_ts = TSFrame(collect(1:5), oob_dates)
    oob_lead = lead(oob_ts, 20)

    @test isequal(oob_lead[:, :Index], oob_ts[:, :Index])
    @test all(ismissing, oob_lead[:, :x1])
end

# Default argument (lead=1) test
@testset "lead default argument" begin
    def_dates = Date(2020, 1, 1):Day(1):Date(2020, 1, 5) |> collect
    def_ts = TSFrame(collect(10:14), def_dates)
    lead_default = lead(def_ts)
    lead_explicit = lead(def_ts, 1)

    @test isequal(lead_default[:, :x1], lead_explicit[:, :x1])
    @test isequal(lead_default[:, :Index], lead_explicit[:, :Index])
end

# Negative lead is equivalent to lag
@testset "lead negative equals lag" begin
    neg_dates = Date(2020, 1, 1):Day(1):Date(2020, 1, 10) |> collect
    neg_ts = TSFrame(collect(1:10), neg_dates)
    lead_neg = lead(neg_ts, -3)
    lagged_pos = lag(neg_ts, 3)

    @test isequal(lead_neg[:, :x1], lagged_pos[:, :x1])
    @test isequal(lead_neg[:, :Index], lagged_pos[:, :Index])
end
