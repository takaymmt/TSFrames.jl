as = rand(-10000:10000, 100) / 77
bs = rand(-10000:10000, 100) / 77
ts = TSFrame(DataFrame(Index = 1:100, A = as, B = bs))

# testing sin function
sin_ts = sin.(ts)
@test typeof(sin_ts) == TSFrame
@test ts[:, :Index] == sin_ts[:, :Index]
for i in 1:100
    @test sin_ts[i, :A_sin] == sin(ts[i, :A])
    @test sin_ts[i, :B_sin] == sin(ts[i, :B])
end

# testing log function on one column
log_ts_A = log.(Complex.(ts[:, [:A]]))
@test typeof(log_ts_A) == TSFrame
@test ts[:, :Index] == log_ts_A[:, :Index]
for i in 1:100
    @test log_ts_A[i, :A_Complex_log] == log(Complex(ts[i, :A]))
end

@test 100 .* TSFrame(1:10) == TSFrame(100:100:1000)

@testset "broadcasting preserves missing" begin
    dates_m = Date(2010, 1, 1) .+ Day.(0:4)
    df_m = DataFrame(Index = dates_m, x1 = [1.0, missing, 3.0, missing, 5.0])
    ts_m = TSFrame(df_m)

    ts_m_sin = sin.(ts_m)
    @test typeof(ts_m_sin) == TSFrame
    @test ts_m_sin[:, :Index] == dates_m

    # Non-missing values are transformed
    @test ts_m_sin[1, :x1_sin] == sin(1.0)
    @test ts_m_sin[3, :x1_sin] == sin(3.0)
    @test ts_m_sin[5, :x1_sin] == sin(5.0)

    # Missing values propagate
    @test ismissing(ts_m_sin[2, :x1_sin])
    @test ismissing(ts_m_sin[4, :x1_sin])
end

@testset "broadcasting single column" begin
    ts_sc = TSFrame(DataFrame(Index = 1:5, val = [2.0, 4.0, 6.0, 8.0, 10.0]))

    ts_sc_sqrt = sqrt.(ts_sc)
    @test typeof(ts_sc_sqrt) == TSFrame
    @test TSFrames.nrow(ts_sc_sqrt) == 5
    @test ts_sc_sqrt[:, :Index] == collect(1:5)

    for i in 1:5
        @test ts_sc_sqrt[i, :val_sqrt] == sqrt(ts_sc[i, :val])
    end
end
