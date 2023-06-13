using Documenter
using PSRClassesInterface
const PSRI = PSRClassesInterface

makedocs(;
    modules = [PSRClassesInterface],
    doctest = true,
    clean = true,
    format = Documenter.HTML(; mathengine = Documenter.MathJax2()),
    sitename = "PSRClassesInterface.jl",
    authors = "psrenergy",
    pages = [
        "Home" => "index.md",
        "manual.md",
        "Examples" => String[
            "examples/reading_parameters.md",
            "examples/reading_relations.md",
            "examples/graf_files.md",
            "examples/reading_demands.md",
            "examples/modification.md",
            "examples/custom_study.md",
        ],
        "File type manual" => String[
            "file_types/pmd.md"
        ]
    ],
)

deploydocs(;
    repo = "github.com/psrenergy/PSRClassesInterface.jl.git",
    push_preview = true,
)
