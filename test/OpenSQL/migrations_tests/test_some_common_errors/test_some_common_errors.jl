module CommonErrors

using PSRClassesInterface
using SQLite
using Test

const PSRI = PSRClassesInterface


PSRI.OpenSQL.set_migrations_folder(joinpath(@__DIR__, "migrations"))

function test_create_migration_with_existing_name()
    @test_throws ErrorException PSRI.OpenSQL.create_migration("add_test_3")
    return nothing
end

function test_apply_migrations_in_inavlid_direction()
    db = SQLite.DB()
    @test_throws ErrorException PSRI.OpenSQL.apply_migrations!(db, "add_test_3", "drop_test_2", :up)
    @test_throws ErrorException PSRI.OpenSQL.apply_migrations!(db, "create_first_snapshot", "add_test_3", :down)
    return nothing
end

function test_apply_migration_that_does_not_exist()
    db = SQLite.DB()
    @test_throws ErrorException PSRI.OpenSQL.apply_migrations!(db, "test_2", "add_test_3", :up)
    @test_throws ErrorException PSRI.OpenSQL.apply_migrations!(db, "create_table", "add_test_3", :up)
    @test_throws ErrorException PSRI.OpenSQL.apply_migrations!(db, "add_test_3", "create_table", :down)
    return nothing
end

function test_apply_invalid_range_of_migrations()
    db = SQLite.DB()
    @test_throws ErrorException PSRI.OpenSQL.apply_migrations!(db, "add_test_3", "add_test_3", :up)
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