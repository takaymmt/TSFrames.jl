using TSFrames

ts = TSFrame(DataFrame(a=["a", "b", "c"], b=[1,2, missing]), [1, 2, 3]) ;
NUM_COLUMNS = 5

###
# describe()
dd = TSFrames.describe(ts) ;
@test names(dd) == [ "variable", "mean", "min", "median", "max", "nmissing", "eltype" ] ;
@test dd[1, :variable] == :Index ;
@test dd[1, :min] == 1 ;
@test dd[1, :max] == 3 ;
@test dd[1, :nmissing] == 0 ;
@test dd[1, :eltype] == Int64 ;

@test dd[3, :variable] == :b ;
@test dd[3, :mean] == 1.5 ;
@test dd[3, :min] == 1 ;
@test dd[3, :median] == 1.5 ;
@test dd[3, :max] == 2 ;
@test dd[3, :nmissing] == 1 ;
@test dd[3, :eltype] == Union{Missing, Int64} ;

dd = TSFrames.describe(ts, :mean) ;
@test "mean" in names(dd) ;
@test !("median" in names(dd)) ;
@test dd[3, :mean] == 1.5 ;

dd = TSFrames.describe(ts, :mean, cols=:b) ;
@test DataFrames.nrow(dd) == 1 ;
@test DataFrames.ncol(dd) == 2 ;
@test dd[1, :variable] == :b ;
@test !("a" in dd[!, :variable]) ;
@test dd[1, :mean] == 1.5 ;
###

###
# lastindex()
@test lastindex(ts) == length(ts.coredata[!, :Index]);
###

###
# length()
@test length(ts) == length(ts.coredata[!, :Index]);
###

###
# size()
@test size(ts) == (length(ts.coredata[!, :Index]), length(ts.coredata[1, :]) - 1);
###

###
# names()
@test ["Index", names(ts)...] == names(ts.coredata);
###

###
# first()
@test first(ts).coredata == ts.coredata[[1], :] ;
###

###
# head()
@test head(ts, 2).coredata == ts.coredata[[1, 2], :];
###

###
# tail()
@test tail(ts, 2).coredata.Index == last(ts.coredata, 2).Index;
@test tail(ts, 2).coredata.a == last(ts.coredata, 2).a;
###

###
# _check_consistency()
@test TSFrames._check_consistency(ts) == true
@test TSFrames._check_consistency(TSFrame([:a, :b], [2,1])) == true;

ts = TSFrame(data_vector, 1:length(data_vector));
ts.coredata.Index = sample(index_integer, length(data_vector), replace=true);
@test TSFrames._check_consistency(ts) == false;
###

function test_isregular()
    random(x) = rand(MersenneTwister(123), x)

    dates_day = collect(Date(2017,1,1):Day(1):Date(2017,1,10))
    dates_month = collect(Date(2017,1,1):Month(1):Date(2017,10,1))
    dates_rep = fill(Date(2017,1,1), 10)
    dates_rand = copy(dates_day)
    dates_rand[2] = Date(2017,10,9)
    dates_rand[4] = Date(2017, 7,27)
    dates_rand[7] = Date(2018,11,11)
    dates_eq = copy(dates_day)
    dates_eq[10] = Date(2017,1,9)

    ts_day = TSFrame(random(10), dates_day)
    ts_month = TSFrame(random(10), dates_month)
    ts_rep = TSFrame(random(10), dates_rep)
    ts_rand = TSFrame(random(10), dates_rand)
    ts_eq = TSFrame(random(10), dates_eq)

    @test isregular(dates_rand) == false
    @test isregular(dates_eq) == false
    @test isregular(dates_month, :month) == true
    @test isregular(dates_rep) == false
    @test isregular(dates_day) == true

    @test isregular(dates_day, Day(2)) == false
    @test isregular(dates_day, Month(1)) == false
    @test isregular(dates_month, Day(1)) == false
    @test isregular(dates_month, Month(1)) == true
    @test isregular(dates_rand, Day(1)) == false
    @test isregular(dates_rand, Month(1)) == false
    @test isregular(dates_eq, Day(1)) == false
    @test isregular(dates_rep, Month(1)) == false
    @test isregular(dates_day, Day(1)) == true
    @test isregular(dates_rep, Day(0)) == false

    @test isregular(dates_rand, Month(0)) == false
    @test isregular(dates_eq, Month(0)) == false
    @test isregular(dates_month, Month(0)) == false
    @test isregular(dates_rep, Month(0)) == false
    @test isregular(dates_day, Month(0)) == false

    @test isregular(ts_month, Month(1)) == true
    @test isregular(ts_rand) == false
    @test isregular(ts_eq) == false
    @test isregular(ts_day) == true
    @test isregular(ts_rep) == false

    @test isregular(ts_day, Day(2)) == false
    @test isregular(ts_day, Month(1)) == false
    @test isregular(ts_month, Day(1)) == false
    @test isregular(ts_month, Month(1)) == true
    @test isregular(ts_rand, Day(1)) == false
    @test isregular(ts_rand, Month(1)) == false
    @test isregular(ts_eq, Day(1)) == false
    @test isregular(ts_rep, Month(1)) == false
    @test isregular(ts_day, Day(1)) == true
    @test isregular(ts_rep, Day(0)) == false
    
    @test isregular(Date(2022,2,1):Week(1):Date(2022,4,1),Week(1)) == true
    @test isregular(Date(2022,2,1):Week(1):Date(2022,4,3),Week(1)) == true

    @test isregular(Date(2022,2,1):Month(1):Date(2022,4,1),Month(1)) == true
    @test isregular(Date(2022,2,1):Month(1):Date(2022,4,3),Month(1)) == true

    @test isregular(Date(2022,2,1):Year(1):Date(2023,4,1),Year(1)) == true
    @test isregular(Date(2022,2,1):Year(1):Date(2023,4,3),Year(1)) == true

    # leap year test 
    # 2020 was a leap year
    @test isregular(Date(2019,2,28):Year(1):Date(2022,2,28), :year) == true
    
    @test isregular(Date(2017,1,2):Month(2):Date(2017,9,10), :month) == true

    #irregular tests
    @test isregular(Date(2022,2,1):Week(1):Date(2022,4,3),Month(1)) == false
    @test isregular(Date(2022,2,1):Month(1):Date(2022,4,3),Year(1)) == false
    @test isregular(Date(2022,2,1):Year(1):Date(2023,4,3),Week(1)) == false

    #tests for Time
    @test isregular(Time(1):Hour(1):Time(3)) == true
    @test isregular(Time(1):Second(1):Time(2)) == true
    @test isregular([Time(1), Time(2), Time(7)]) == false

    #tests for DateTime
    @test isregular(DateTime(2022,2,1,4):Day(3):DateTime(2022,2,7,3)) == true
    @test isregular(DateTime(2022,2,1,4):Second(3):DateTime(2022,2,7,3)) == true
    @test isregular([DateTime(2022,2,1,4), DateTime(2022,2,2,4), DateTime(2022,2,3,2), DateTime(2022,2,4,4)]) == false

    #tests for size 1
    @test isregular([DateTime(2022,2,2,1)]) == false
    @test isregular([DateTime(2022,2,2,1)],Month(1)) == false
    @test isregular(TSFrame([1],[DateTime(2022,2,2,1)])) == false

    #some edge cases
    @test isregular([Date(2022,1,31), Date(2022,2,28), Date(2022,3,31)],Month(1)) == true
    @test isregular([Date(2022,1,31), Date(2022,2,28), Date(2022,3,28)],Month(1)) == false

    #test gettimeperiod
    @test TSFrames.gettimeperiod(Date(2022,2,2),Date(2022,4,7),Time) == Time(0)
    @test TSFrames.gettimeperiod(Date(2022,2,2),Date(2021,1,1),Day) == Day(0)
end

# Run each test
# NOTE: Do not forget to add any new test-function created above
# otherwise that test won't run.
test_isregular()

### TSFrames.rename!
old_names = ["x" * string(i) for i in 1:NUM_COLUMNS]
new_names = ["X" * string(i) for i in 1:NUM_COLUMNS]
duplicate_names = ["x1" for i in 1:NUM_COLUMNS]

# Index column not allowed
ts = TSFrame(Date; n = NUM_COLUMNS)
rand_index = random(1:NUM_COLUMNS)
new_names[rand_index] = "Index"
@test_throws ArgumentError TSFrames.rename!(ts, new_names)
@test_throws ArgumentError TSFrames.rename!(ts, Symbol.(new_names))
new_names[rand_index] = "X" * string(rand_index)

# rename!(ts::TSFrame, colnames::AbstractVector{String}; makeunique=false)
TSFrames.rename!(ts, new_names)
@test isequal(propertynames(ts.coredata), vcat([:Index], Symbol.(new_names)))

# rename!(ts::TSFrame, colnames::AbstractVector{Symbol}; makeunique=false)
TSFrames.rename!(ts, Symbol.(old_names))
@test isequal(propertynames(ts.coredata), vcat([:Index], Symbol.(old_names)))

# rename!(ts::TSFrame, colnames::AbstractVector{String}; makeunique=true)
TSFrames.rename!(ts, duplicate_names, makeunique=true)
@test isequal(propertynames(ts.coredata), vcat([:Index], [:x1], Symbol.(["x1_" * string(i) for i in 1:NUM_COLUMNS - 1])))

# rename!(ts::TSFrame, colnames::AbstractVector{Symbol}; makeunique=true)
TSFrames.rename!(ts, Symbol.(duplicate_names), makeunique=true)
@test isequal(propertynames(ts.coredata), vcat([:Index], [:x1], Symbol.(["x1_" * string(i) for i in 1:NUM_COLUMNS - 1])))

# rename!(ts::TSFrame, d::AbstractVector{<:Pair})
pairs_sym_sym = [Symbol("x" * string(i)) => Symbol("X" * string(i)) for i in 1:NUM_COLUMNS]
pairs_sym_string = [Symbol("x" * string(i)) => "X" * string(i) for i in 1:NUM_COLUMNS]
pairs_string_sym = ["x" * string(i) => Symbol("X" * string(i)) for i in 1:NUM_COLUMNS]
pairs_string_string = ["x" * string(i) => "X" * string(i) for i in 1:NUM_COLUMNS]
rand_index = random(1:NUM_COLUMNS)

## Symbol => Symbol
ts = TSFrame(Date; n=NUM_COLUMNS)
TSFrames.rename!(ts, pairs_sym_sym)
@test isequal(propertynames(ts.coredata), vcat([:Index], Symbol.("X" * string(i) for i in 1:NUM_COLUMNS)))

## Symbol => String
ts = TSFrame(Date; n=NUM_COLUMNS)
TSFrames.rename!(ts, pairs_sym_string)
@test isequal(propertynames(ts.coredata), vcat([:Index], Symbol.("X" * string(i) for i in 1:NUM_COLUMNS)))

## String => Symbol
ts = TSFrame(Date; n=NUM_COLUMNS)
TSFrames.rename!(ts, pairs_string_sym)
@test isequal(propertynames(ts.coredata), vcat([:Index], Symbol.("X" * string(i) for i in 1:NUM_COLUMNS)))

## String => String
ts = TSFrame(Date; n=NUM_COLUMNS)
TSFrames.rename!(ts, pairs_string_string)
@test isequal(propertynames(ts.coredata), vcat([:Index], Symbol.("X" * string(i) for i in 1:NUM_COLUMNS)))

## cannot map Index to any other name or map any other column to Index
@test_throws ArgumentError TSFrames.rename!(ts, vcat([:Index => :nonIndex], pairs_sym_sym))
@test_throws ArgumentError TSFrames.rename!(ts, vcat([:Index => "nonIndex"], pairs_sym_string))
@test_throws ArgumentError TSFrames.rename!(ts, vcat(["Index" => :nonIndex], pairs_string_sym))
@test_throws ArgumentError TSFrames.rename!(ts, vcat(["nonIndex" => "nonIndex"], pairs_string_string))

pairs_sym_sym[rand_index] = Symbol("x" * string(rand_index)) => :Index
pairs_sym_string[rand_index] = Symbol("x" * string(rand_index)) => "Index"
pairs_string_sym[rand_index] = "x" * string(rand_index) => :Index
pairs_string_string[rand_index] = "x" * string(rand_index) => "Index"
@test_throws ArgumentError TSFrames.rename!(ts, pairs_sym_sym)
@test_throws ArgumentError TSFrames.rename!(ts, pairs_sym_string)
@test_throws ArgumentError TSFrames.rename!(ts, pairs_string_sym)
@test_throws ArgumentError TSFrames.rename!(ts, pairs_string_string)

# rename!(ts::TSFrame, d::AbstractDict)
dict_sym_sym = Dict([Symbol("x" * string(i)) => Symbol("X" * string(i)) for i in 1:NUM_COLUMNS])
dict_sym_string = Dict([Symbol("x" * string(i)) => "X" * string(i) for i in 1:NUM_COLUMNS])
dict_string_sym = Dict(["x" * string(i) => Symbol("X" * string(i)) for i in 1:NUM_COLUMNS])
dict_string_string = Dict(["x" * string(i) => "X" * string(i) for i in 1:NUM_COLUMNS])

## Symbol => Symbol
ts = TSFrame(Date; n=NUM_COLUMNS)
TSFrames.rename!(ts, dict_sym_sym)
@test isequal(propertynames(ts.coredata), vcat([:Index], Symbol.("X" * string(i) for i in 1:NUM_COLUMNS)))

## Symbol => String
ts = TSFrame(Date; n=NUM_COLUMNS)
TSFrames.rename!(ts, dict_sym_string)
@test isequal(propertynames(ts.coredata), vcat([:Index], Symbol.("X" * string(i) for i in 1:NUM_COLUMNS)))

## String => Symbol
ts = TSFrame(Date; n=NUM_COLUMNS)
TSFrames.rename!(ts, dict_string_sym)
@test isequal(propertynames(ts.coredata), vcat([:Index], Symbol.("X" * string(i) for i in 1:NUM_COLUMNS)))

## String => String
ts = TSFrame(Date; n=NUM_COLUMNS)
TSFrames.rename!(ts, dict_string_string)
@test isequal(propertynames(ts.coredata), vcat([:Index], Symbol.("X" * string(i) for i in 1:NUM_COLUMNS)))

# rename!(ts::TSFrame, (from => to)::Pair...)
pairs_sym_sym = [Symbol("x" * string(i)) => Symbol("X" * string(i)) for i in 1:NUM_COLUMNS]
pairs_sym_string = [Symbol("x" * string(i)) => "X" * string(i) for i in 1:NUM_COLUMNS]
pairs_string_sym = ["x" * string(i) => Symbol("X" * string(i)) for i in 1:NUM_COLUMNS]
pairs_string_string = ["x" * string(i) => "X" * string(i) for i in 1:NUM_COLUMNS]

## Symbol => Symbol
ts = TSFrame(Date; n=NUM_COLUMNS)
TSFrames.rename!(ts, pairs_sym_sym...)
@test isequal(propertynames(ts.coredata), vcat([:Index], Symbol.("X" * string(i) for i in 1:NUM_COLUMNS)))

## Symbol => String
ts = TSFrame(Date; n=NUM_COLUMNS)
TSFrames.rename!(ts, pairs_sym_string...)
@test isequal(propertynames(ts.coredata), vcat([:Index], Symbol.("X" * string(i) for i in 1:NUM_COLUMNS)))

## String => Symbol
ts = TSFrame(Date; n=NUM_COLUMNS)
TSFrames.rename!(ts, pairs_string_sym...)
@test isequal(propertynames(ts.coredata), vcat([:Index], Symbol.("X" * string(i) for i in 1:NUM_COLUMNS)))

## String => String
ts = TSFrame(Date; n=NUM_COLUMNS)
TSFrames.rename!(ts, pairs_string_string...)
@test isequal(propertynames(ts.coredata), vcat([:Index], Symbol.("X" * string(i) for i in 1:NUM_COLUMNS)))

# rename!(f::Function, ts::TSFrame)
ts = TSFrame(Date; n=NUM_COLUMNS)
TSFrames.rename!(uppercase, ts)
@test isequal(propertynames(ts.coredata), vcat([:Index], Symbol.("X" * string(i) for i in 1:NUM_COLUMNS)))

###
# iterate()
@testset "iterate" begin
    ts_iter = TSFrame(DataFrame(a=[10, 20, 30], b=[1.0, 2.0, 3.0]), [1, 2, 3])

    # iterate yields expected number of items
    count = 0
    for row in ts_iter
        count += 1
    end
    @test count == 3

    # each yielded item is a NamedTuple with :Index and data columns
    first_item = first(collect(ts_iter))
    @test first_item isa NamedTuple
    @test :Index in keys(first_item)
    @test :a in keys(first_item)
    @test :b in keys(first_item)

    # collect works and returns the correct number of elements
    collected = collect(ts_iter)
    @test length(collected) == 3

    # collected elements have correct data
    @test collected[1].Index == 1
    @test collected[1].a == 10
    @test collected[1].b == 1.0
    @test collected[3].Index == 3
    @test collected[3].a == 30
    @test collected[3].b == 3.0

    # row-based iteration with field access
    sum_a = 0
    for row in ts_iter
        sum_a += row.a
    end
    @test sum_a == 60

    # iterate on single-row TSFrame
    ts_single = TSFrame(DataFrame(x=[42]), [1])
    items = collect(ts_single)
    @test length(items) == 1
    @test items[1] isa NamedTuple
    @test items[1].Index == 1
    @test items[1].x == 42
end
###

###
# ndims()
@testset "ndims" begin
    # ndims on type
    @test ndims(TSFrame) == 2

    # ndims on instance (dispatches via Type, since ndims is defined for Type{TSFrame})
    ts_nd = TSFrame(DataFrame(a=[1, 2], b=[3, 4]), [1, 2])
    @test ndims(typeof(ts_nd)) == 2
end
###

###
# ==(equality)
@testset "==" begin
    ts_eq1 = TSFrame(DataFrame(a=[1, 2, 3], b=[4.0, 5.0, 6.0]), [1, 2, 3])
    ts_eq2 = TSFrame(DataFrame(a=[1, 2, 3], b=[4.0, 5.0, 6.0]), [1, 2, 3])

    # identical TSFrames are equal
    @test ts_eq1 == ts_eq2

    # different data makes them not equal
    ts_eq3 = TSFrame(DataFrame(a=[1, 2, 99], b=[4.0, 5.0, 6.0]), [1, 2, 3])
    @test !(ts_eq1 == ts_eq3)

    # different index makes them not equal
    ts_eq4 = TSFrame(DataFrame(a=[1, 2, 3], b=[4.0, 5.0, 6.0]), [1, 2, 4])
    @test !(ts_eq1 == ts_eq4)

    # == with missing throws (due to Bool return type annotation on ==)
    ts_m1 = TSFrame(DataFrame(a=[1, missing, 3]), [1, 2, 3])
    ts_m2 = TSFrame(DataFrame(a=[1, missing, 3]), [1, 2, 3])
    @test_throws MethodError (ts_m1 == ts_m2)
end
###

###
# isequal()
@testset "isequal" begin
    ts_ie1 = TSFrame(DataFrame(a=[1, 2, 3], b=[4.0, 5.0, 6.0]), [1, 2, 3])
    ts_ie2 = TSFrame(DataFrame(a=[1, 2, 3], b=[4.0, 5.0, 6.0]), [1, 2, 3])

    # identical TSFrames are isequal
    @test isequal(ts_ie1, ts_ie2)

    # self-equality
    @test isequal(ts_ie1, ts_ie1)

    # different data makes them not isequal
    ts_ie3 = TSFrame(DataFrame(a=[1, 2, 99], b=[4.0, 5.0, 6.0]), [1, 2, 3])
    @test !isequal(ts_ie1, ts_ie3)

    # isequal handles missing correctly (missing is isequal to missing)
    ts_im1 = TSFrame(DataFrame(a=[1, missing, 3]), [1, 2, 3])
    ts_im2 = TSFrame(DataFrame(a=[1, missing, 3]), [1, 2, 3])
    @test isequal(ts_im1, ts_im2)

    # isequal returns false when missing vs non-missing
    ts_im3 = TSFrame(DataFrame(a=[1, 2, 3]), [1, 2, 3])
    @test !isequal(ts_im1, ts_im3)
end
###

###
# nr() / nc() aliases
@testset "nr and nc aliases" begin
    ts_alias = TSFrame(DataFrame(a=[1, 2, 3], b=[4, 5, 6]), [1, 2, 3])

    # nr is alias for nrow
    @test nr(ts_alias) == TSFrames.nrow(ts_alias)
    @test nr(ts_alias) == 3

    # nc is alias for ncol
    @test nc(ts_alias) == TSFrames.ncol(ts_alias)
    @test nc(ts_alias) == 2
end
###

###
# cbind / rbind aliases
@testset "cbind and rbind aliases" begin
    # cbind is alias for join
    ts_cb1 = TSFrame(DataFrame(a=[1, 2, 3]), [1, 2, 3])
    ts_cb2 = TSFrame(DataFrame(b=[4, 5, 6]), [1, 2, 3])
    result_cb = cbind(ts_cb1, ts_cb2)
    @test TSFrames.ncol(result_cb) == 2
    @test TSFrames.nrow(result_cb) == 3

    # rbind is alias for vcat
    ts_rb1 = TSFrame(DataFrame(a=[1, 2]), [1, 2])
    ts_rb2 = TSFrame(DataFrame(a=[3, 4]), [3, 4])
    result_rb = rbind(ts_rb1, ts_rb2)
    @test TSFrames.nrow(result_rb) == 4
    @test TSFrames.ncol(result_rb) == 1
end
###