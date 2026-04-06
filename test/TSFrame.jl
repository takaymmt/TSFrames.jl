function test_df_index_integer()
    df = DataFrame(A=["a", "b"], B=[1, 2])
    @test_throws ArgumentError TSFrame(df)
    df = DataFrame(A=[:a, :b], B=[1, 2])
    @test_throws ArgumentError TSFrame(df)

    ts = TSFrame(df_integer_index, 1)
    @test typeof(ts) == TSFrames.TSFrame
    @test ts.coredata == df_integer_index
end

function test_df_index_timetype()
    ts = TSFrame(df_timetype_index, 1)
    @test typeof(ts) == TSFrames.TSFrame
    @test ts.coredata == df_timetype_index
end

function test_df_index_symbol()
    ts = TSFrame(df_integer_index, :Index)
    @test typeof(ts) == TSFrames.TSFrame
    @test ts.coredata == df_integer_index
end

function test_df_index_string()
    ts = TSFrame(df_integer_index, "Index")
    @test typeof(ts) == TSFrames.TSFrame
    @test ts.coredata == df_integer_index
end

function test_df_index_range()
    ts = TSFrame(df_vector, index_range)
    @test typeof(ts) == TSFrames.TSFrame
    @test ts.coredata[!, :data] == df_vector[!, :data]
end

function test_vector_index_vector_integer()
    ts = TSFrame(data_vector, index_integer)
    @test typeof(ts) == TSFrames.TSFrame
    @test ts.coredata[!, :Index] == index_integer
    @test ts.coredata[!, 2] == data_vector
end

function test_vector_index_vector_timetype()
    ts = TSFrame(data_vector, index_timetype)
    @test typeof(ts) == TSFrames.TSFrame
    @test ts.coredata[!, :Index] == index_timetype
    @test ts.coredata[!, 2] == data_vector
end

function test_vector()
    ts = TSFrame(data_vector)
    @test typeof(ts) == TSFrames.TSFrame
    @test ts.coredata[!, :Index] == collect(1:length(data_vector))
    @test ts.coredata[!, 2] == data_vector
end

function test_array()
    ts = TSFrame(data_array)
    @test typeof(ts) == TSFrames.TSFrame
    @test typeof(ts.coredata) == DataFrames.DataFrame
    @test ts.coredata[!, :Index] == collect(1:size(data_vector)[1])
    @test Matrix(ts.coredata[!, Not(:Index)]) == data_array
end

function test_colnames()
    random(x) = rand(MersenneTwister(123), x)
    dates = collect(Date(2017,1,1):Day(1):Date(2017,1,10))

    ts = TSFrame(random(10), colnames=[:A])
    @test names(ts.coredata) == ["Index", "A"]

    ts = TSFrame(random(10), dates, colnames=[:A])
    @test names(ts.coredata) == ["Index", "A"]

    ts = TSFrame([random(10) random(10)], colnames=[:A, :B])
    @test names(ts.coredata) == ["Index", "A", "B"]

    ts = TSFrame([random(10) random(10)], dates, colnames=[:A, :B])
    @test names(ts.coredata) == ["Index", "A", "B"]
end

function test_empty_timeframe_cons() 
    #test for int type
    tfi1 = TSFrame(Int, n=1)
    tfi2 = TSFrame(Int, n=2)

    @test size(tfi1)==(0, 1)
    @test size(tfi2)==(0, 2)

    @test TSFrames.nrow(tfi1)==0
    @test TSFrames.nrow(tfi2)==0

    @test TSFrames.ncol(tfi1)==1
    @test TSFrames.ncol(tfi2)==2

    @test eltype(index(tfi1))==Int
    @test eltype(index(tfi2))==Int

    #test for date type
    tfd1 = TSFrame(Date, n=1)
    tfd2 = TSFrame(Date, n=2)

    @test size(tfd1)==(0, 1)
    @test size(tfd2)==(0, 2)

    @test TSFrames.nrow(tfd1)==0
    @test TSFrames.nrow(tfd2)==0

    @test TSFrames.ncol(tfd1)==1
    @test TSFrames.ncol(tfd2)==2

    @test eltype(index(tfd1))==Date
    @test eltype(index(tfd2))==Date

    #test for errors
    @test_throws DomainError TSFrame(Int, n=-1)
    @test_throws DomainError TSFrame(Int, n=0)
    @test_throws DomainError TSFrame(Date, n=-1)
    @test_throws DomainError TSFrame(Date, n=0)

    # testing empty constructor for specific column names and types
    ts_empty_int = TSFrame(Int, [(Int, :col1), (Float64, :col2), (String, :col3)])
    ts_empty_date = TSFrame(Date, [(Int, :col1), (Float64, :col2), (String, :col3)])

    @test size(ts_empty_int)==(0, 3)
    @test size(ts_empty_date)==(0, 3)

    @test TSFrames.nrow(ts_empty_int)==0
    @test TSFrames.nrow(ts_empty_date)==0

    @test TSFrames.ncol(ts_empty_int)==3
    @test TSFrames.ncol(ts_empty_date)==3

    @test isempty(setdiff(propertynames(ts_empty_int.coredata), [:Index, :col1, :col2, :col3]))
    @test isempty(setdiff(propertynames(ts_empty_date.coredata), [:Index, :col1, :col2, :col3]))

    @test eltype(index(ts_empty_int))==Int
    @test eltype(index(ts_empty_date))==Date

    @test eltype(ts_empty_int[:, :col1])==Int
    @test eltype(ts_empty_date[:, :col1])==Int

    @test eltype(ts_empty_int[:, :col2])==Float64
    @test eltype(ts_empty_date[:, :col2])==Float64

    @test eltype(ts_empty_int[:, :col3])==String
    @test eltype(ts_empty_date[:, :col3])==String
end

@testset "issorted in constructor" begin
    unsorted = randperm(1000)
    unsorted_frame = TSFrame(1:1000, unsorted; issorted = true)
    @test !(issorted(unsorted_frame.coredata[!, :Index]))
    sorted_frame = TSFrame(1:1000, unsorted; issorted = false)
    @test issorted(sorted_frame.coredata[!, :Index])
    unsorted_dataframe = DataFrame(:myind => unsorted)
    unsorted_tsframe_from_dataframe = TSFrame(unsorted_dataframe, :myind; issorted = true)
    @test unsorted_dataframe[!, :myind] == unsorted_tsframe_from_dataframe.coredata[!, :Index]
end

# Run each test
# NOTE: Do not forget to add any new test-function created above
# otherwise that test won't run.
test_df_index_integer()
test_df_index_timetype()
test_df_index_symbol()
test_df_index_string()
test_df_index_range()
test_vector_index_vector_integer()
test_vector_index_vector_timetype()
test_vector()
test_array()
test_colnames()
test_empty_timeframe_cons()

@testset "empty TSFrame from empty DataFrame" begin
    df = DataFrame(Index=Date[], x1=Float64[])
    ts = TSFrame(df)
    @test TSFrames.nrow(ts) == 0
    @test TSFrames.ncol(ts) == 1
    @test length(index(ts)) == 0
    @test eltype(index(ts)) == Date

    # Empty DataFrame with Int index
    df_int = DataFrame(Index=Int[], x1=Float64[])
    ts_int = TSFrame(df_int)
    @test TSFrames.nrow(ts_int) == 0
    @test TSFrames.ncol(ts_int) == 1
    @test length(index(ts_int)) == 0
    @test eltype(index(ts_int)) == Int
end

@testset "empty TSFrame from typed constructor with column specs" begin
    # Typed constructor with column type/name pairs (complementing test_empty_timeframe_cons)
    ts = TSFrame(Date, [(Float64, :price), (Int, :volume)])
    @test TSFrames.nrow(ts) == 0
    @test TSFrames.ncol(ts) == 2
    @test length(index(ts)) == 0
    @test eltype(index(ts)) == Date
    @test eltype(ts.coredata[:, :price]) == Float64
    @test eltype(ts.coredata[:, :volume]) == Int

    # Using String column names
    ts_str = TSFrame(Int, [(String, "name"), (Float64, "score")])
    @test TSFrames.nrow(ts_str) == 0
    @test TSFrames.ncol(ts_str) == 2
    @test eltype(index(ts_str)) == Int
end

@testset "single row TSFrame" begin
    ts = TSFrame(DataFrame(Index=[Date(2020, 1, 1)], x1=[42.0]))
    @test TSFrames.nrow(ts) == 1
    @test TSFrames.ncol(ts) == 1
    @test first(index(ts)) == Date(2020, 1, 1)
    @test ts[1, :x1] == 42.0

    # Single row with integer index
    ts_int = TSFrame([99.0], [1])
    @test TSFrames.nrow(ts_int) == 1
    @test TSFrames.ncol(ts_int) == 1
    @test first(index(ts_int)) == 1
    @test ts_int[1, :x1] == 99.0
end

@testset "TSFrame with missing values in data" begin
    ts = TSFrame(DataFrame(Index=[1, 2, 3], x1=[1.0, missing, 3.0]))
    @test TSFrames.nrow(ts) == 3
    @test TSFrames.ncol(ts) == 1
    @test ts[1, :x1] == 1.0
    @test ismissing(ts[2, :x1])
    @test ts[3, :x1] == 3.0
    @test eltype(ts.coredata[:, :x1]) == Union{Missing, Float64}

    # Multiple columns with missing
    ts2 = TSFrame(DataFrame(Index=[1, 2], x1=[missing, 1], x2=[2.0, missing]))
    @test TSFrames.nrow(ts2) == 2
    @test TSFrames.ncol(ts2) == 2
    @test ismissing(ts2[1, :x1])
    @test ismissing(ts2[2, :x2])
end

@testset "TSFrame with duplicate index values" begin
    # Constructor does not reject duplicate index values; it sorts them
    ts = TSFrame(DataFrame(Index=[1, 1, 2], x1=[10.0, 20.0, 30.0]))
    @test TSFrames.nrow(ts) == 3
    @test TSFrames.ncol(ts) == 1
    @test index(ts) == [1, 1, 2]
    @test issorted(index(ts))

    # Duplicate Date index
    ts_date = TSFrame(DataFrame(Index=[Date(2020,1,1), Date(2020,1,1), Date(2020,1,2)],
                                x1=[1.0, 2.0, 3.0]))
    @test TSFrames.nrow(ts_date) == 3
    @test index(ts_date)[1] == index(ts_date)[2]
end

@testset "TSFrame copycols=false" begin
    idx = [1, 2, 3]
    vals = [10.0, 20.0, 30.0]
    df = DataFrame(Index=idx, x1=vals)
    ts = TSFrame(df; copycols=false)
    @test typeof(ts) == TSFrames.TSFrame
    @test TSFrames.nrow(ts) == 3
    @test TSFrames.ncol(ts) == 1
    @test ts[1, :x1] == 10.0
    @test ts[3, :x1] == 30.0
end

@testset "TSFrame from external vector with unsorted index aligns data" begin
    # Regression test: external index vector must sort both index AND data rows together
    dates = [Date(2020,1,3), Date(2020,1,1), Date(2020,1,2)]
    values = [30.0, 10.0, 20.0]
    df = DataFrame(x1 = values)
    ts = TSFrame(df, dates)
    @test issorted(index(ts))
    @test index(ts) == [Date(2020,1,1), Date(2020,1,2), Date(2020,1,3)]
    @test ts.coredata[1, :x1] == 10.0
    @test ts.coredata[2, :x1] == 20.0
    @test ts.coredata[3, :x1] == 30.0
end

@testset "TSFrame accepts Integer subtypes as index" begin
    # Int8 index
    ts_i8 = TSFrame(rand(5), Int8.(1:5))
    @test ts_i8 isa TSFrame
    @test TSFrames.nrow(ts_i8) == 5
    # UInt32 index
    ts_u32 = TSFrame(rand(5), UInt32.(1:5))
    @test ts_u32 isa TSFrame
    @test TSFrames.nrow(ts_u32) == 5
    # BigInt index
    ts_big = TSFrame(rand(3), BigInt.(1:3))
    @test ts_big isa TSFrame
    @test TSFrames.nrow(ts_big) == 3
    # DataFrame with Integer index column
    ts_df = TSFrame(DataFrame(x=rand(4)), Int16.(1:4))
    @test ts_df isa TSFrame
    # Float64 index should still be rejected
    @test_throws ArgumentError TSFrame(DataFrame(Index=[1.0, 2.0], x=[1, 2]))
end

@testset "TSFrame from DataFrame with unsorted index column" begin
    # When constructing from a DataFrame with an index *column*, the
    # DataFrame is sorted by the index column so data stays aligned.
    df = DataFrame(Index=[3, 1, 2], x1=[30.0, 10.0, 20.0])
    ts = TSFrame(df)
    @test TSFrames.nrow(ts) == 3
    @test TSFrames.ncol(ts) == 1
    @test issorted(index(ts))
    @test index(ts) == [1, 2, 3]
    # Data is reordered together with index (DataFrame sort)
    @test ts.coredata[1, :x1] == 10.0
    @test ts.coredata[2, :x1] == 20.0
    @test ts.coredata[3, :x1] == 30.0

    # Same with Date index column
    df_date = DataFrame(Index=[Date(2020,1,3), Date(2020,1,1), Date(2020,1,2)],
                        x1=[30.0, 10.0, 20.0])
    ts_date = TSFrame(df_date)
    @test issorted(index(ts_date))
    @test index(ts_date) == [Date(2020,1,1), Date(2020,1,2), Date(2020,1,3)]
    @test ts_date.coredata[1, :x1] == 10.0
    @test ts_date.coredata[2, :x1] == 20.0
    @test ts_date.coredata[3, :x1] == 30.0
end
