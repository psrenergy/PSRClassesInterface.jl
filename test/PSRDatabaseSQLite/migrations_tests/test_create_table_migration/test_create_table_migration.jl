module CreateTableMigration

using PSRClassesInterface.PSRDatabaseSQLite
using SQLite
using Test

function test_create_table_migration()
    path_migrations_directory = joinpath(@__DIR__, "migrations")
    @test PSRDatabaseSQLite.test_migrations(path_migrations_directory)
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
