module CreateDBFromMigrations

using PSRClassesInterface.PSRDatabaseSQLite
using SQLite
using Test

function test_create_database_from_migrations()
    path_migrations_directory = joinpath(@__DIR__, "migrations")
    @test PSRDatabaseSQLite.test_migrations(path_migrations_directory)
    db_path = joinpath(@__DIR__, "test_read.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_migrations(
        db_path, 
        path_migrations_directory; 
        force = true
    )

    PSRDatabaseSQLite.close!(db)
    rm(db_path)
    return nothing
end

function runtests()
    GC.gc()
    GC.gc()
    for name in names(@__MODULE__; all = true)
        if startswith("$name", "test_")
            @testset "$(name)" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
end

CreateDBFromMigrations.runtests()

end
