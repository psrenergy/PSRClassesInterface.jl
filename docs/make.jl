using Documenter
using PSRClassesInterface

makedocs(;
    modules=[PSRClassesInterface],
    doctest=true,
    clean=true,
    format=Documenter.HTML(mathengine=Documenter.MathJax2()),
    sitename="PSRClassesInterface.jl",
    authors="psrenergy",
    pages=[
        "Home" => "index.md",
        "manual.md",
        "examples.md"
    ],
)

deploydocs(
        repo="github.com/psrenergy/PSRClassesInterface.jl.git",
        push_preview = true
    )