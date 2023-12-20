module InvalidMigrations

using PSRClassesInterface
using SQLite
using Test

const PSRI = PSRClassesInterface

PSRI.OpenSQL.set_migrations_folder(joinpath(@__DIR__, "migrations"))

function test_invalid_migrations()
    @test_throws ErrorException PSRI.OpenSQL.test_migrations()
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

InvalidMigrations.runtests()

end
