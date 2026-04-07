"""
    f.(ts::TSFrame; renamecols=true)

Apply a unary function `f` element-wise to every data column of `ts`.
The resulting columns are named `"<original>_<f>"` when `renamecols=true`
(default), or kept as-is when `renamecols=false`.

# Example
```julia
ts2 = log.(ts)          # applies log element-wise; columns renamed to x1_log, …
ts3 = log.(ts; renamecols=false)  # columns keep original names
```
"""
function Base.Broadcast.broadcasted(f, ts::TSFrame; renamecols=true)
    return TSFrame(
        select(
            ts.coredata,
            :Index,
            Not(:Index) .=> (x -> f.(x)) => colname -> string(colname, "_", Symbol(f)),
            renamecols = renamecols
        )
    )
end

"""
    f.(arg, ts::TSFrame; renamecols=false)

Apply a binary function `f(arg, x)` element-wise to every data column of `ts`,
where `arg` is a scalar (or broadcastable) left-hand operand.
Column names are preserved by default (`renamecols=false`).

# Example
```julia
ts2 = (+).(10, ts)      # adds 10 to each element; column names unchanged
```
"""
function Base.Broadcast.broadcasted(f, arg, ts::TSFrame; renamecols=false)
    return TSFrame(
        select(
            ts.coredata,
            :Index,
            Not(:Index) .=> (x -> f(arg, x)),
            renamecols = renamecols
        )
    )
end
