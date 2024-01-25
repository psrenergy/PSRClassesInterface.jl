module ChainingMigrations

using PSRClassesInterface.OpenSQL
using SQLite
using Test

function test_chaining_migrations()
    path_migrations_directory = joinpath(@__DIR__, "migrations")
    @test OpenSQL.test_migrations(path_migrations_directory)
    return nothing
end

function test_applying_migrations_from_a_certain_point()
    path_migrations_directory = joinpath(@__DIR__, "migrations")
    db = SQLite.DB()
    OpenSQL.apply_migrations!(db, path_migrations_directory, 1, 3, :up)
    OpenSQL.apply_migrations!(db, path_migrations_directory, 3, 1, :down)
    @test OpenSQL.db_is_empty(db)
    db = SQLite.DB()
    OpenSQL.apply_migrations!(db, path_migrations_directory, 1, 2, :up)
    db = SQLite.DB()
    OpenSQL.apply_migrations!(db, path_migrations_directory, 1, 3, :up)
    OpenSQL.apply_migrations!(db, path_migrations_directory, 3, 2, :down)
    OpenSQL.apply_migration!(db, path_migrations_directory, 1, :down)
    @test OpenSQL.db_is_empty(db)
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
