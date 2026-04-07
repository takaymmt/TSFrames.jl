"""
Tables.jl integration for TSFrame.

`TSFrame` satisfies both the row-access and column-access interfaces defined by
[Tables.jl](https://github.com/JuliaData/Tables.jl), making it compatible with
any Tables.jl-consuming package (e.g. CSV, Arrow, DataFrames).

**Important**: row-level interfaces (`Tables.rows`, `Tables.rowtable`,
`Tables.namedtupleiterator`) include the `:Index` column.  Consumers that
expect only data columns must drop `:Index` manually.
"""
Tables.istable(::Type{TSFrame}) = true

Tables.rowaccess(::Type{TSFrame}) = true
Tables.rows(ts::TSFrame) = DataFrames.eachrow(ts.coredata)
Tables.rowcount(ts::TSFrame) = TSFrames.nrow(ts)

Tables.columnaccess(::Type{TSFrame}) = true
Tables.columns(ts::TSFrame) = DataFrames.eachcol(ts.coredata)

Tables.rowtable(ts::TSFrame) = Tables.rowtable(ts.coredata)
Tables.columntable(ts::TSFrame) = Tables.columntable(ts.coredata)

Tables.namedtupleiterator(ts::TSFrame) = Tables.namedtupleiterator(ts.coredata)

Tables.schema(ts::TSFrame) = Tables.schema(ts.coredata)

Tables.materializer(::Type{<:TSFrame}) = TSFrame
