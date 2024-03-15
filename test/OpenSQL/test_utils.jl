module TestUtils

using PSRClassesInterface
using SQLite
using Test

const PSRI = PSRClassesInterface

function test_extra_lines_sql_file()
    db = PSRI.OpenSQL.SQLite.DB()
    PSRI.OpenSQL.execute_statements(
        db,
        joinpath(@__DIR__, "data", "example_of_sql_files", "extra_lines.sql"),
    )
    return nothing
end

function runtests()
    for name in names(@__MODULE__; all = true)
        if startswith("$name", "test_")
            @testset "$(name)" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
end

TestUtils.runtests()

end
