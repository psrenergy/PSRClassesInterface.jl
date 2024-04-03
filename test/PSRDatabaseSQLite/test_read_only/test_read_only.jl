module TestReadOnly

using PSRClassesInterface.PSRDatabaseSQLite
using SQLite
using Dates
using Test

function test_read_only()
    path_schema = joinpath(@__DIR__, "test_read_only.sql")
    db_path = joinpath(@__DIR__, "test_read_only.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(
        db,
        "Configuration";
        label = "Toy Case",
        date_initial = DateTime(2020, 1, 1),
    )
    PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 1",
        some_value = [1, 2, 3.0],
    )
    PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 2",
        some_value = [1, 2, 4.0],
    )

    PSRDatabaseSQLite.close!(db)

    db = PSRDatabaseSQLite.load_db(db_path, true)

    @test PSRDatabaseSQLite.read_scalar_parameters(db, "Configuration", "label") ==
          ["Toy Case"]
    @test PSRDatabaseSQLite.read_scalar_parameters(db, "Resource", "label") ==
          ["Resource 1", "Resource 2"]
    @test PSRDatabaseSQLite.read_scalar_parameter(db, "Resource", "label", "Resource 1") ==
          "Resource 1"

    @test_throws SQLite.SQLiteException PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 3",
        some_value = [1, 2, 3.0],
    )

    PSRDatabaseSQLite.close!(db)
    return rm(db_path)
end

function runtests()
    Base.GC.gc()
    Base.GC.gc()
    for name in names(@__MODULE__; all = true)
        if startswith("$name", "test_")
            @testset "$(name)" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
end

TestReadOnly.runtests()

end
