module ChainingMigrations

using PSRClassesInterface
using SQLite
using Test

const PSRI = PSRClassesInterface

PSRI.OpenSQL.set_migrations_folder(joinpath(@__DIR__, "migrations"))

function test_chaining_migrations()
    @test PSRI.OpenSQL.test_migrations()
    return nothing
end

function test_applying_migrations_from_a_certain_point()
    db = SQLite.DB()
    PSRI.OpenSQL.apply_migrations!(db, "initial", "add_test_3", :up)
    PSRI.OpenSQL.apply_migrations!(db, "add_test_3", "initial", :down)
    @test PSRI.OpenSQL.db_is_empty(db)
    db = SQLite.DB()
    PSRI.OpenSQL.apply_migrations!(db, "initial", "drop_test_2", :up)
    db = SQLite.DB()
    PSRI.OpenSQL.apply_migrations!(db, "initial", "add_test_3", :up)
    PSRI.OpenSQL.apply_migrations!(db, "add_test_3", "drop_test_2", :down)
    PSRI.OpenSQL.apply_migration!(db, "initial", :down)
    @test PSRI.OpenSQL.db_is_empty(db)
    PSRI.OpenSQL.apply_migrations!(db, 1, 3, :up)
    PSRI.OpenSQL.apply_migrations!(db, 3, 2, :down)
    PSRI.OpenSQL.apply_migration!(db, 1, :down)
    @test PSRI.OpenSQL.db_is_empty(db)
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
