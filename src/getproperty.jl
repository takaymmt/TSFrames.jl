"""
    getproperty(ts::TSFrame, f::Symbol)

Delegate property access to the underlying `DataFrame` (`ts.coredata`), except
for `:coredata` itself which returns the field directly.  This allows
DataFrame-level operations such as `ts.x1` (column access) or `ts.nrow` to
work transparently on a `TSFrame`.
"""
function Base.getproperty(ts::TSFrame, f::Symbol)
    return (f == :coredata) ? getfield(ts, :coredata) : getproperty(ts.coredata, f)
end
