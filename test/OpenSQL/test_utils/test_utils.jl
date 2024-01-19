module TestUtils

using PSRClassesInterface.OpenSQL
using SQLite
using Test

function test_extra_lines_sql_file()
    db = OpenSQL.SQLite.DB()
    OpenSQL.execute_statements(
        db,
        joinpath(@__DIR__, "extra_lines.sql"),
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
