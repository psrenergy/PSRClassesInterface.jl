module ChainingMigrations

using PSRClassesInterface.PSRDatabaseSQLite
using SQLite
using Test

function test_chaining_migrations()
    path_migrations_directory = joinpath(@__DIR__, "migrations")
    @test PSRDatabaseSQLite.test_migrations(path_migrations_directory)
    return nothing
end

function test_applying_migrations_from_a_certain_point()
    path_migrations_directory = joinpath(@__DIR__, "migrations")
    db = SQLite.DB()
    PSRDatabaseSQLite.apply_migrations!(db, path_migrations_directory, 0, 3, :up)
    PSRDatabaseSQLite.apply_migrations!(db, path_migrations_directory, 3, 0, :down)
    @test PSRDatabaseSQLite.db_is_empty(db)
    db = SQLite.DB()
    PSRDatabaseSQLite.apply_migrations!(db, path_migrations_directory, 0, 2, :up)
    db = SQLite.DB()
    PSRDatabaseSQLite.apply_migrations!(db, path_migrations_directory, 0, 3, :up)
    PSRDatabaseSQLite.apply_migrations!(db, path_migrations_directory, 3, 2, :down)
    PSRDatabaseSQLite.apply_migrations!(db, path_migrations_directory, 2, 0, :down)
    @test PSRDatabaseSQLite.db_is_empty(db)
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

ChainingMigrations.runtests()

end
