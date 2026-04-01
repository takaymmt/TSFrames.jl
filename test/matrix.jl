ts = TSFrame([random(100) random(100)])
matrix = Matrix(ts)

@test isequal(matrix[:, 1], ts[:, :x1])
@test isequal(matrix[:, 2], ts[:, :x2])

@testset "Matrix single column" begin
    ts_single = TSFrame(random(10))
    mat = Matrix(ts_single)
    @test size(mat) == (10, 1)
    @test isequal(mat[:, 1], ts_single[:, :x1])
end

@testset "Matrix three columns" begin
    ts_three = TSFrame([random(10) random(10) random(10)])
    mat = Matrix(ts_three)
    @test size(mat) == (10, 3)
    @test isequal(mat[:, 1], ts_three[:, :x1])
    @test isequal(mat[:, 2], ts_three[:, :x2])
    @test isequal(mat[:, 3], ts_three[:, :x3])
end

@testset "Matrix with missing values" begin
    dates = collect(Date(2020,1,1):Day(1):Date(2020,1,5))
    df_miss = DataFrame(Index=dates, x1=[1.0, missing, 3.0, missing, 5.0])
    ts_miss = TSFrame(df_miss)
    mat = Matrix(ts_miss)
    @test size(mat) == (5, 1)
    @test eltype(mat) == Union{Missing, Float64}
    @test mat[1, 1] == 1.0
    @test ismissing(mat[2, 1])
    @test mat[3, 1] == 3.0
    @test ismissing(mat[4, 1])
    @test mat[5, 1] == 5.0
end

@testset "Matrix integer data" begin
    ts_int = TSFrame(DataFrame(Index=collect(1:5), x1=collect(10:14), x2=collect(20:24)))
    mat = Matrix(ts_int)
    @test eltype(mat) == Int64
    @test mat[1, 1] == 10
    @test mat[1, 2] == 20
end

@testset "Matrix single row" begin
    ts_row = TSFrame(DataFrame(Index=[1], x1=[1.0], x2=[2.0], x3=[3.0]))
    mat = Matrix(ts_row)
    @test size(mat) == (1, 3)
    @test mat[1, 1] == 1.0
    @test mat[1, 2] == 2.0
    @test mat[1, 3] == 3.0
end

@testset "Matrix excludes Index" begin
    dates = collect(Date(2020,1,1):Day(1):Date(2020,1,5))
    ts_excl = TSFrame(DataFrame(Index=dates, a=1:5, b=6:10))
    mat = Matrix(ts_excl)
    ncols_ts = TSFrames.ncol(ts_excl)
    @test size(mat, 2) == ncols_ts
    @test size(mat, 2) == 2
    # Index values should not appear in the matrix
    @test size(mat, 1) == 5
end

@testset "Matrix roundtrip" begin
    data = [random(10) random(10)]
    ts_rt = TSFrame(data)
    mat = Matrix(ts_rt)
    @test size(mat) == size(data)
    for i in 1:size(data, 1), j in 1:size(data, 2)
        @test isequal(mat[i, j], data[i, j])
    end
end