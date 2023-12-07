using QWave
using Documenter

DocMeta.setdocmeta!(QWave, :DocTestSetup, :(using QWave); recursive=true)

makedocs(;
    modules=[QWave],
    authors="Jan Kuhfeld <jan.kuhfeld@rub.de> and contributors",
    repo="https://github.com/jqfeld/QWave.jl/blob/{commit}{path}#{line}",
    sitename="QWave.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://jqfeld.github.io/QWave.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/jqfeld/QWave.jl",
    devbranch="main",
)
