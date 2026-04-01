# constants
DATA_SIZE_1 = 200
DATA_SIZE_2 = 200

index_timetype1 = Date(2007, 1,1) + Day.(0:(DATA_SIZE_1 - 1))
index_timetype2 = Date(2007, 1, 1) + Day(DATA_SIZE_1) + Day.(0:(DATA_SIZE_2 - 1))

# testing setequal and orderequal
df1 = DataFrame(x1 = random(200), x2 = random(200))
df2 = DataFrame(x2 = random(200), x1 = random(200))
ts1 = TSFrame(df1, index_timetype1)
ts2 = TSFrame(df2, index_timetype2)
ts_setequal = TSFrames.vcat(ts1, ts2, colmerge=:setequal)

@test propertynames(ts_setequal.coredata) == [:Index, :x1, :x2]
@test ts_setequal[1:DATA_SIZE_1, :Index] == ts1[:, :Index]
@test ts_setequal[DATA_SIZE_1 + 1:DATA_SIZE_1 + DATA_SIZE_2, :Index] == ts2[:, :Index]
@test ts_setequal[1:DATA_SIZE_1, :x1] == ts1[:, :x1]
@test ts_setequal[DATA_SIZE_1 + 1:DATA_SIZE_1 + DATA_SIZE_2, :x1] == ts2[:, :x1]
@test ts_setequal[1:DATA_SIZE_1, :x2] == ts1[:, :x2]
@test ts_setequal[DATA_SIZE_1 + 1:DATA_SIZE_1 + DATA_SIZE_2, :x2] == ts2[:, :x2]

df2 = DataFrame(x1 = random(200), x2 = random(200))
ts2 = TSFrame(df2, index_timetype2)
ts_orderequal = TSFrames.vcat(ts1, ts2, colmerge=:orderequal)

@test propertynames(ts_orderequal.coredata) == [:Index, :x1, :x2]
@test ts_orderequal[1:DATA_SIZE_1, :Index] == ts1[:, :Index]
@test ts_orderequal[DATA_SIZE_1 + 1:DATA_SIZE_1 + DATA_SIZE_2, :Index] == ts2[:, :Index]
@test ts_orderequal[1:DATA_SIZE_1, :x1] == ts1[:, :x1]
@test ts_orderequal[DATA_SIZE_1 + 1:DATA_SIZE_1 + DATA_SIZE_2, :x1] == ts2[:, :x1]
@test ts_orderequal[1:DATA_SIZE_1, :x2] == ts1[:, :x2]
@test ts_orderequal[DATA_SIZE_1 + 1:DATA_SIZE_1 + DATA_SIZE_2, :x2] == ts2[:, :x2]

# testing union and intersection
df1 = DataFrame(x1 = random(200), x2 = random(200))
df2 = DataFrame(x2 = random(200), x3 = random(200))
ts1 = TSFrame(df1, index_timetype1)
ts2 = TSFrame(df2, index_timetype2)

ts_intersect = TSFrames.vcat(ts1, ts2, colmerge=:intersect)

@test propertynames(ts_intersect.coredata) == [:Index, :x2]
@test ts_intersect[1:DATA_SIZE_1, :Index] == ts1[:, :Index]
@test ts_intersect[DATA_SIZE_1 + 1:DATA_SIZE_1 + DATA_SIZE_2, :Index] == ts2[:, :Index]
@test ts_intersect[1:DATA_SIZE_1, :x2] == ts1[:, :x2]
@test ts_intersect[DATA_SIZE_1 + 1:DATA_SIZE_1 + DATA_SIZE_2, :x2] == ts2[:, :x2]

ts_union = TSFrames.vcat(ts1, ts2, colmerge=:union)

@test propertynames(ts_union.coredata) == [:Index, :x1, :x2, :x3]
@test ts_union[1:DATA_SIZE_1, :Index] == ts1[:, :Index]
@test ts_union[DATA_SIZE_1 + 1:DATA_SIZE_1 + DATA_SIZE_2, :Index] == ts2[:, :Index]
@test ts_union[1:DATA_SIZE_1, :x1] == ts1[:, :x1]
@test isequal(Vector{Missing}(ts_union[DATA_SIZE_1 + 1:DATA_SIZE_1 + DATA_SIZE_2, :x1]), fill(missing, DATA_SIZE_2))
@test ts_union[1:DATA_SIZE_1, :x2] == ts1[:, :x2]
@test ts_union[DATA_SIZE_1 + 1:DATA_SIZE_1 + DATA_SIZE_2, :x2] == ts2[:, :x2]
@test isequal(Vector{Missing}(ts_union[1:DATA_SIZE_1, :x3]), fill(missing, DATA_SIZE_1))
@test ts_union[DATA_SIZE_1 + 1:DATA_SIZE_1 + DATA_SIZE_2, :x3] == ts2[:, :x3]

@testset "vcat overlapping index" begin
    # Two TSFrames sharing some index values
    overlap_dates_1 = Date(2010, 1, 1) .+ Day.(0:4)   # Jan 1-5
    overlap_dates_2 = Date(2010, 1, 3) .+ Day.(0:4)   # Jan 3-7
    vals1 = [1.0, 2.0, 3.0, 4.0, 5.0]
    vals2 = [30.0, 40.0, 50.0, 60.0, 70.0]
    ts_ov1 = TSFrame(DataFrame(Index = overlap_dates_1, x1 = vals1))
    ts_ov2 = TSFrame(DataFrame(Index = overlap_dates_2, x1 = vals2))

    # vcat simply concatenates rows; overlapping index values result in
    # duplicate index entries (DataFrames.vcat does not deduplicate).
    # TSFrame constructor sorts by Index, so duplicates are adjacent.
    ts_ov = TSFrames.vcat(ts_ov1, ts_ov2)

    # Total rows = sum of both (no dedup)
    @test TSFrames.nrow(ts_ov) == 10

    # The overlapping dates (Jan 3, 4, 5) appear twice each
    idx = ts_ov[:, :Index]
    @test count(==(Date(2010, 1, 3)), idx) == 2
    @test count(==(Date(2010, 1, 4)), idx) == 2
    @test count(==(Date(2010, 1, 5)), idx) == 2

    # Non-overlapping dates appear once
    @test count(==(Date(2010, 1, 1)), idx) == 1
    @test count(==(Date(2010, 1, 2)), idx) == 1
    @test count(==(Date(2010, 1, 6)), idx) == 1
    @test count(==(Date(2010, 1, 7)), idx) == 1
end
