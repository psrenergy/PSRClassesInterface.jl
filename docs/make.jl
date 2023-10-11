using Documenter
using DocumenterDiagrams

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
        "Files and Structs manual" => String[
            "file_types/file_diagram.md",
            "file_types/pmd.md",
            "file_types/model_template.md",
            "file_types/relation_mapper.md",
            "file_types/psrclasses.md",
        ],
        "Examples" => String[
            "examples/reading_parameters.md",
            "examples/reading_relations.md",
            "examples/graf_files.md",
            "examples/reading_demands.md",
            "examples/modification.md",
            "examples/custom_study.md",
        ],
    ],
)

deploydocs(;
    repo = "github.com/psrenergy/PSRClassesInterface.jl.git",
    push_preview = true,
)
