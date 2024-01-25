module InvalidMigrations

using PSRClassesInterface.OpenSQL
using SQLite
using Test

function test_invalid_migrations()
    path_migrations_directory = joinpath(@__DIR__, "migrations")
    @test_throws ErrorException OpenSQL.test_migrations(path_migrations_directory)
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
