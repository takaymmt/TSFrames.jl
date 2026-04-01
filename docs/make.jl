using TSFrames
using Documenter

DocMeta.setdocmeta!(TSFrames, :DocTestSetup, :(using TSFrames, DataFrames, Dates, Statistics); recursive=true)

makedocs(;
    modules=[TSFrames],
    authors="xKDR Forum",
    sitename="TSFrames.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://xKDR.github.io/TSFrames.jl",
        assets=String[],
    ),
    pages=[
        "Introduction" => "index.md",
        "Basic demo of TSFrames" => "demo_finance.md",
        "User guide" => "user_guide.md",
        "API reference" => "api.md",
    ],
    doctest=false,
    warnonly=true,
)

deploydocs(;
    repo="github.com/xKDR/TSFrames.jl",
    devbranch="main",
    target = "build",
    push_preview = true,
)
