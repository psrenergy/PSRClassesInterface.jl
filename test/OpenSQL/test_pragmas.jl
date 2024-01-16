module TestPragmas

using PSRClassesInterface
using SQLite
using Test

const PSRI = PSRClassesInterface

function test_valid_pragmas_database()
    db = SQLite.DB()

    DBInterface.execute(db,
        """
        PRAGMA user_version = 2;
        """,
    )

    PSRI.OpenSQL._validate_database_pragmas(db)
    return nothing
end

function test_no_user_version_database()
    db = SQLite.DB()

    @test_throws ErrorException PSRI.OpenSQL._validate_database_pragmas(db)
    return nothing
end

function test_no_necessary_pragma()
    db = SQLite.DB()

    @test_throws ErrorException PSRI.OpenSQL._validate_database_pragmas(db)
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

TestPragmas.runtests()

end
