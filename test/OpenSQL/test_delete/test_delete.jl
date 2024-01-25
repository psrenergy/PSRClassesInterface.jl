module TestDelete

using PSRClassesInterface.OpenSQL
using SQLite
using Test

function test_delete_element()
    path_schema = joinpath(@__DIR__, "test_delete_element.sql")
    db_path = joinpath(@__DIR__, "test_delete_element.sqlite")
    db = OpenSQL.create_empty_db_from_schema(db_path, path_schema; force = true)
    OpenSQL.create_element!(db, "Configuration"; label = "Toy Case")
    OpenSQL.create_element!(db, "Resource"; label = "Resource 1", some_value = [1, 2, 3.0], some_other_value = [1.0, 4.0, 5.0])
    OpenSQL.create_element!(db, "Resource"; label = "Resource 2", some_value = [1, 2, 3.0], some_other_value = [1.0, 4.0, 5.0])
    OpenSQL.create_element!(db, "Plant"; label = "Plant 1", capacity = 50.0)
    OpenSQL.create_element!(db, "Plant"; label = "Plant 2", capacity = 50.0, plant_turbine_to = "Plant 1")
    OpenSQL.create_element!(db, "Plant"; label = "Plant 3", capacity = 50.0)
    @test_throws ErrorException OpenSQL.delete_element!(db, "Plant", "Plant 14")
    @test_throws SQLite.SQLiteException OpenSQL.create_element!(db, "Plant"; label = "Plant 3")
    OpenSQL.delete_element!(db, "Plant", "Plant 3")
    OpenSQL.create_element!(db, "Plant"; label = "Plant 3")
    @test_throws ErrorException OpenSQL.delete_element!(db, "SomeCollection", "Plant 2")
    OpenSQL.close!(db)
    rm(db_path)
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

TestDelete.runtests()

end