# Benchmark: TSFrame construction
#
# Tests various ways to construct TSFrame objects:
#   - TSFrame(DataFrame) with existing Index column
#   - TSFrame(matrix, dates)
#   - TSFrame(vector, dates)

using BenchmarkTools, Dates, DataFrames, Random
using TSFrames

const BENCH_CONSTRUCTION = BenchmarkGroup()

for (label, n) in [("small", 100), ("medium", 10_000), ("large", 1_000_000)]
    rng = MersenneTwister(42)
    dates = Date(2000, 1, 1) .+ Day.(0:n-1)
    close_prices = cumsum(randn(rng, n)) .+ 100.0
    volume = abs.(randn(rng, n)) .* 1_000_000

    grp = BenchmarkGroup()

    # TSFrame from DataFrame with Index column
    df_with_index = DataFrame(Index=dates, close=close_prices, volume=volume)
    grp["from_dataframe_with_index"] = @benchmarkable TSFrame($df_with_index)

    # TSFrame from DataFrame without Index (uses first column as index)
    df_dates_first = DataFrame(dates=dates, close=close_prices, volume=volume)
    grp["from_dataframe_first_col"] = @benchmarkable TSFrame($df_dates_first, :dates)

    # TSFrame from matrix + dates
    mat = hcat(close_prices, volume)
    grp["from_matrix_and_dates"] = @benchmarkable TSFrame($mat, $dates)

    # TSFrame from vector + dates
    grp["from_vector_and_dates"] = @benchmarkable TSFrame($close_prices, $dates)

    # TSFrame with issorted=true, copycols=false (fast path)
    df_sorted = DataFrame(Index=dates, close=close_prices, volume=volume)
    grp["from_dataframe_sorted_nocopy"] = @benchmarkable TSFrame($df_sorted; issorted=true, copycols=false)

    BENCH_CONSTRUCTION[label] = grp
end
