module CommonErrors

using PSRClassesInterface.PSRDatabaseSQLite
using SQLite
using Test

function test_create_migration_with_existing_name()
    path_migrations_directory = joinpath(@__DIR__, "migrations")
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.create_migration(
        path_migrations_directory,
        3,
    )
    return nothing
end

function test_apply_migrations_in_inavlid_direction()
    path_migrations_directory = joinpath(@__DIR__, "migrations")
    db = SQLite.DB()
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.apply_migrations!(
        db,
        path_migrations_directory,
        3,
        2,
        :up,
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.apply_migrations!(
        db,
        path_migrations_directory,
        7,
        4,
        :down,
    )
    return nothing
end

function test_apply_migration_that_does_not_exist()
    path_migrations_directory = joinpath(@__DIR__, "migrations")
    db = SQLite.DB()
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.apply_migrations!(
        db,
        path_migrations_directory,
        245,
        3345,
        :up,
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.apply_migrations!(
        db,
        path_migrations_directory,
        134,
        335,
        :up,
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.apply_migrations!(
        db,
        path_migrations_directory,
        323,
        123,
        :down,
    )
    return nothing
end

function test_apply_invalid_range_of_migrations()
    path_migrations_directory = joinpath(@__DIR__, "migrations")
    db = SQLite.DB()
    PSRDatabaseSQLite.apply_migrations!(
        db,
        path_migrations_directory,
        3,
        3,
        :up,
    )
    @test true
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

CommonErrors.runtests()

end
