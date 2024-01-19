module TestUpdate

using PSRClassesInterface.OpenSQL
using SQLite
using Test

function test_create_scalar_relationships()
    path_schema = joinpath(@__DIR__, "test_create_scalar_relationships.sql")
    db_path = joinpath(@__DIR__, "test_create_scalar_relationships.sqlite")
    db = OpenSQL.create_empty_db(db_path, path_schema; force = true)
    OpenSQL.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    OpenSQL.create_element!(db, "Resource"; label = "Resource 1", type = "E")
    OpenSQL.create_element!(db, "Resource"; label = "Resource 2", type = "E")
    OpenSQL.create_element!(db, "Plant"; label = "Plant 1", capacity = 50.0)
    OpenSQL.create_element!(db, "Plant"; label = "Plant 2", capacity = 50.0)
    OpenSQL.create_element!(db, "Plant"; label = "Plant 3", capacity = 50.0)

    # Valid relationships
    OpenSQL.set_scalar_relationship!(db, "Plant", "Resource", "Plant 1", "Resource 1", "id")
    OpenSQL.set_scalar_relationship!(db, "Plant", "Resource", "Plant 1", "Resource 2", "id")
    OpenSQL.set_scalar_relationship!(db, "Plant", "Resource", "Plant 2", "Resource 1", "id")
    OpenSQL.set_scalar_relationship!(db, "Plant", "Resource", "Plant 3", "Resource 2", "id")
    OpenSQL.set_scalar_relationship!(db, "Plant", "Plant", "Plant 3", "Plant 1", "turbine_to")
    OpenSQL.set_scalar_relationship!(db, "Plant", "Plant", "Plant 1", "Plant 2", "spill_to")

    # invalid relationships
    @test_throws ErrorException OpenSQL.set_scalar_relationship!(db, "Plant", "Resource", "Plant 1", "Resource 1", "wrong")
    @test_throws ErrorException OpenSQL.set_scalar_relationship!(db, "Plant", "Resource", "Plant 1", "Resource 4", "id")
    @test_throws ErrorException OpenSQL.set_scalar_relationship!(db, "Plant", "Resource", "Plant 5", "Resource 1", "id")
    @test_throws ErrorException OpenSQL.set_scalar_relationship!(db, "Resource", "Resource", "Resource 1", "Resource 2", "wrong")
    @test_throws ErrorException OpenSQL.set_scalar_relationship!(db, "Plant", "Plant", "Plant 1", "Plant 2", "wrong")
    @test_throws ErrorException OpenSQL.set_scalar_relationship!(db, "Plant", "Plant", "Plant 1", "Plant 1", "turbine_to")
    @test_throws ErrorException OpenSQL.set_scalar_relationship!(db, "Plant", "Plant", "Plant 1", "Plant 2", "id")

    OpenSQL.close!(db)
end

function test_create_vectorial_relationships()

end

function test_update_scalar_parameters()
    path_schema = joinpath(@__DIR__, "test_update_scalar_parameters.sql")
    db_path = joinpath(@__DIR__, "test_update_scalar_parameters.sqlite")
    db = OpenSQL.create_empty_db(db_path, path_schema; force = true)
    OpenSQL.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    OpenSQL.create_element!(db, "Resource"; label = "Resource 1", type = "E")
    OpenSQL.create_element!(db, "Resource"; label = "Resource 2", type = "E")

    @test_throws ErrorException OpenSQL.update_scalar_parameters!(db, "Resource", "Resource 1"; type = "D", some_value = 1.0)
    @test_throws ErrorException OpenSQL.update_scalar_parameters!(db, "Resource", "Resource 4"; type = "D", some_value = 1.0)
    OpenSQL.update_scalar_parameters!(db, "Resource", "Resource 1"; type = "D", some_value_1 = 1.0)
    OpenSQL.update_scalar_parameters!(db, "Resource", "Resource 1"; type = "D", some_value_1 = 1.0, some_value_2 = 90)
    @test_throws SQLite.SQLiteException OpenSQL.update_scalar_parameters!(db, "Resource", "Resource 1"; type = "D", some_value_1 = 1.0, some_value_2 = "wrong!")
    @test_throws ErrorException OpenSQL.update_scalar_parameters!(db, "Resource", "Resource 1"; cost_id = 2)
end

function test_update_vectorial_parameters()

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

TestUpdate.runtests()

end