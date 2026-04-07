"""
### Frequency conversion

Set of convenience methods for frequency conversion of `TimeType`
index types. Internally, they call `endpoints()` to do the actual
conversion. `n` is the number of periods of the `period` type. For
example, `to_monthly(tsf, 2)` will resample the time series to "every
2 months".

```julia
to_period(tsf::TSFrame, period::T)::TSFrame where {T<:Period}
to_yearly(tsf::TSFrame, n=1)::TSFrame
to_quarterly(tsf::TSFrame, n=1)::TSFrame
to_monthly(tsf::TSFrame, n=1)::TSFrame
to_weekly(tsf::TSFrame, n=1)::TSFrame
to_daily(tsf::TSFrame, n=1)::TSFrame
to_hourly(tsf::TSFrame, n=1)::TSFrame
to_minutes(tsf::TSFrame, n=1)::TSFrame
to_seconds(tsf::TSFrame, n=1)::TSFrame
to_milliseconds(tsf::TSFrame, n=1)::TSFrame
to_microseconds(tsf::TSFrame, n=1)::TSFrame
to_nanoseconds(tsf::TSFrame, n=1)::TSFrame
```
"""
function to_period(tsf::TSFrame, period::T)::TSFrame where {T<:Period}
    ep = endpoints(tsf, period)
    TSFrame(tsf.coredata[ep, :], :Index; issorted = true, copycols = false)
end

for (fname, PType) in [
    (:to_yearly,       :Year),
    (:to_quarterly,    :Quarter),
    (:to_monthly,      :Month),
    (:to_weekly,       :Week),
    (:to_daily,        :Day),
    (:to_hourly,       :Hour),
    (:to_minutes,      :Minute),
    (:to_seconds,      :Second),
    (:to_milliseconds, :Millisecond),
    (:to_microseconds, :Microsecond),
    (:to_nanoseconds,  :Nanosecond)
]
    @eval function $fname(tsf::TSFrame, n=1)::TSFrame
        n >= 1 || throw(ArgumentError("n must be >= 1, got $n"))
        ep = endpoints(tsf, $PType(n))
        TSFrame(tsf.coredata[ep, :], :Index; issorted = true, copycols = false)
    end
end
