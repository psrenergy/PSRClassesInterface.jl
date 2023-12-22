module CommonErrors

using PSRClassesInterface
using SQLite
using Test

const PSRI = PSRClassesInterface

PSRI.OpenSQL.set_migrations_folder(joinpath(@__DIR__, "migrations"))

function test_create_migration_with_existing_name()
    @test_throws ErrorException PSRI.OpenSQL.create_migration(3)
    return nothing
end

function test_apply_migrations_in_inavlid_direction()
    db = SQLite.DB()
    @test_throws ErrorException PSRI.OpenSQL.apply_migrations!(
        db,
        3,
        2,
        :up,
    )
    @test_throws ErrorException PSRI.OpenSQL.apply_migrations!(
        db,
        7,
        4,
        :down,
    )
    return nothing
end

function test_apply_migration_that_does_not_exist()
    db = SQLite.DB()
    @test_throws ErrorException PSRI.OpenSQL.apply_migrations!(
        db,
        245,
        3345,
        :up,
    )
    @test_throws ErrorException PSRI.OpenSQL.apply_migrations!(
        db,
        134,
        335,
        :up,
    )
    @test_throws ErrorException PSRI.OpenSQL.apply_migrations!(
        db,
        323,
        123,
        :down,
    )
    return nothing
end

function test_apply_invalid_range_of_migrations()
    db = SQLite.DB()
    @test_throws ErrorException PSRI.OpenSQL.apply_migrations!(
        db,
        3,
        3,
        :up,
    )
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
