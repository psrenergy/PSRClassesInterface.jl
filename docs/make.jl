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
        "OpenStudy Files and Structs" => String[
            "openstudy_files/file_diagram.md",
            "openstudy_files/pmd.md",
            "openstudy_files/model_template.md",
            "openstudy_files/relation_mapper.md",
            "openstudy_files/psrclasses.md",
        ],
        "PSRDatabaseSQLite Overview" => String[
            "psrdatabasesqlite/introduction.md",
            "psrdatabasesqlite/rules.md",
        ],
        "OpenStudy and OpenBinary Examples" => String[
            "examples/reading_parameters.md",
            "examples/reading_relations.md",
            "examples/graf_files.md",
            "examples/reading_demands.md",
            "examples/modification.md",
            "examples/custom_study.md",
        ],
        "PSRDatabaseSQLite Examples" => String[
            "sqlite_examples/migrations.md",
        ],
    ],
)

deploydocs(;
    repo = "github.com/psrenergy/PSRClassesInterface.jl.git",
    push_preview = true,
)
