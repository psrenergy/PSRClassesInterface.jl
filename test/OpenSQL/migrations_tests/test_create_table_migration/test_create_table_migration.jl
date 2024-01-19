module CreateTableMigration

using PSRClassesInterface.OpenSQL
using SQLite
using Test

OpenSQL.set_migrations_folder(joinpath(@__DIR__, "migrations"))

function test_create_table_migration()
    @test OpenSQL.test_migrations()
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

CreateTableMigration.runtests()

end
