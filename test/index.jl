ts = TSFrame(df_timetype_index)

@test index(ts) == df_timetype_index[!, :Index]

@testset "index with integer index" begin
    int_idx = collect(1:10)
    ts_int = TSFrame(DataFrame(Index=int_idx, x1=1.0:10.0))
    @test index(ts_int) == int_idx
    @test length(index(ts_int)) == 10
end

@testset "index with DateTime index" begin
    dt_idx = collect(DateTime(2020,1,1):Hour(1):DateTime(2020,1,1)+Hour(9))
    ts_dt = TSFrame(rand(10), dt_idx)
    @test isa(index(ts_dt), Vector{DateTime})
    @test length(index(ts_dt)) == 10
end

@testset "index is sorted" begin
    unsorted_dates = [Date(2020,1,5), Date(2020,1,1), Date(2020,1,3), Date(2020,1,2), Date(2020,1,4)]
    ts_unsorted = TSFrame(rand(5), unsorted_dates)
    @test issorted(index(ts_unsorted))
    @test index(ts_unsorted) == sort(unsorted_dates)
end

@testset "index single row" begin
    ts_single = TSFrame(DataFrame(Index=[Date(2020,1,1)], x1=[42.0]))
    @test length(index(ts_single)) == 1
    @test index(ts_single) == [Date(2020,1,1)]
end

@testset "index returns correct type" begin
    dates = collect(Date(2020,1,1):Day(1):Date(2020,1,10))
    ts_date = TSFrame(rand(10), dates)
    @test eltype(index(ts_date)) == Date

    ts_int = TSFrame(DataFrame(Index=collect(1:5), x1=rand(5)))
    @test eltype(index(ts_int)) == Int64

    dt_idx = collect(DateTime(2020,1,1):Hour(1):DateTime(2020,1,1)+Hour(4))
    ts_datetime = TSFrame(rand(5), dt_idx)
    @test eltype(index(ts_datetime)) == DateTime
end
