using Radixsort
using Documenter

DocMeta.setdocmeta!(Radixsort, :DocTestSetup, :(using Radixsort); recursive=true)

makedocs(;
    modules=[Radixsort],
    authors="Robert Rudolph",
    repo="https://github.com/rryi/Radixsort.jl/blob/{commit}{path}#{line}",
    sitename="Radixsort.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://rryi.github.io/Radixsort.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/rryi/Radixsort.jl",
)
