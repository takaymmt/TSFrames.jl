# Constants
YEAR = 2022
MONTH = 1
DAYS = 15

dates = Date(YEAR, MONTH, 1):Day(1):Date(YEAR, MONTH, DAYS)
ts = TSFrame(1:DAYS, dates)

@test Tables.istable(ts)

# testing Tables.rows
@test Tables.rowaccess(ts)
@test first(Tables.rows(ts))[:Index] == Date(YEAR, MONTH, 1)
@test first(Tables.rows(ts))[:x1] == 1

# testing Tables.rowcount
@test Tables.rowcount(ts)==15
@test Tables.rowcount(TSFrame(1:10))==10
@test Tables.rowcount(TSFrame(1:1))==1
@test Tables.rowcount(TSFrame(Int))==0
@test Tables.rowcount(TSFrame(Int,n=1))==0
@test Tables.rowcount(TSFrame(Int,n=2))==0

# testing Tables.columns
@test Tables.columns(ts).Index == dates
@test Tables.columns(ts).x1 == 1:DAYS

# testing Tables.rowtable
rowTable = Tables.rowtable(ts)
@test typeof(rowTable) == Vector{NamedTuple{(:Index, :x1), Tuple{Date, Int64}}}
@test first(rowTable) == (Index=Date(YEAR, MONTH, 1), x1=1)

# testing Tables.columntable
columnTable = Tables.columntable(ts)
@test typeof(columnTable) == NamedTuple{(:Index, :x1), Tuple{Vector{Date}, Vector{Int64}}}
@test columnTable[:Index] == dates
@test columnTable[:x1] == 1:DAYS

# testing Tables.namedtupleiterator
namedtuple = first(Tables.namedtupleiterator(ts))
@test namedtuple == first(Tables.rowtable(ts))

# testing Tables.schema
@test Tables.schema(ts).names == (:Index, :x1)
@test Tables.schema(ts).types == (Date, Int64)

# testing Tables.materializer
@test Tables.materializer(ts) == TSFrame

@testset "Tables roundtrip" begin
    dates_rt = Date(2022, 3, 1):Day(1):Date(2022, 3, 10)
    ts_rt = TSFrame(DataFrame(Index = collect(dates_rt), a = 1:10, b = 11:20))

    # Convert to columntable and back
    ct = Tables.columntable(ts_rt)
    ts_from_ct = TSFrame(DataFrame(ct))

    @test TSFrames.nrow(ts_from_ct) == TSFrames.nrow(ts_rt)
    @test ts_from_ct[:, :Index] == ts_rt[:, :Index]
    @test ts_from_ct[:, :a] == ts_rt[:, :a]
    @test ts_from_ct[:, :b] == ts_rt[:, :b]

    # Convert to rowtable and back
    rt = Tables.rowtable(ts_rt)
    ts_from_rt = TSFrame(DataFrame(rt))

    @test TSFrames.nrow(ts_from_rt) == TSFrames.nrow(ts_rt)
    @test ts_from_rt[:, :Index] == ts_rt[:, :Index]
    @test ts_from_rt[:, :a] == ts_rt[:, :a]
    @test ts_from_rt[:, :b] == ts_rt[:, :b]

    # Roundtrip via materializer
    mat = Tables.materializer(ts_rt)
    ts_materialized = mat(ct)
    @test typeof(ts_materialized) == TSFrame
    @test TSFrames.nrow(ts_materialized) == 10
    @test ts_materialized[:, :Index] == ts_rt[:, :Index]
    @test ts_materialized[:, :a] == ts_rt[:, :a]
    @test ts_materialized[:, :b] == ts_rt[:, :b]
end
