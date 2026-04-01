ts = TSFrame(df_integer_index)
@test ts.data == ts[:, :data]

@testset "getproperty coredata" begin
    ts_gp = TSFrame(df_integer_index)
    @test isa(ts_gp.coredata, DataFrame)
    @test :Index in propertynames(ts_gp.coredata)
    @test :data in propertynames(ts_gp.coredata)
    @test DataFrames.nrow(ts_gp.coredata) == length(index(ts_gp))
end

@testset "getproperty Index column" begin
    ts_gp = TSFrame(df_timetype_index)
    @test ts_gp.Index == index(ts_gp)
    @test length(ts_gp.Index) == length(index(ts_gp))
    @test eltype(ts_gp.Index) == eltype(index(ts_gp))
end

@testset "getproperty multi-column" begin
    dates = collect(Date(2020,1,1):Day(1):Date(2020,1,5))
    df_multi = DataFrame(Index=dates, col_a=1:5, col_b=6:10, col_c=11:15)
    ts_multi = TSFrame(df_multi)
    @test ts_multi.col_a == collect(1:5)
    @test ts_multi.col_b == collect(6:10)
    @test ts_multi.col_c == collect(11:15)
end

@testset "getproperty returns correct type" begin
    ts_gp = TSFrame(df_integer_index)
    @test isa(ts_gp.data, AbstractVector)
    @test isa(ts_gp.Index, AbstractVector)
end

@testset "getproperty nonexistent column throws" begin
    ts_gp = TSFrame(df_integer_index)
    @test_throws ArgumentError ts_gp.nonexistent_column
end
