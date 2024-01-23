module TestRead

using PSRClassesInterface.OpenSQL
using SQLite
using Test

function test_read_parameters()
    path_schema = joinpath(@__DIR__, "test_read.sql")
    db_path = joinpath(@__DIR__, "test_read.sqlite")
    db = OpenSQL.create_empty_db(db_path, path_schema; force = true)
    OpenSQL.create_element!(db, "Configuration"; label = "Toy Case")
    OpenSQL.create_element!(db, "Resource"; label = "Resource 1", some_value = [1, 2, 3.0])
    OpenSQL.create_element!(db, "Resource"; label = "Resource 2", some_value = [1, 2, 4.0])
    OpenSQL.create_element!(db, "Plant"; label = "Plant 1", capacity = 2.02, some_factor = [1.0])
    OpenSQL.create_element!(db, "Plant"; label = "Plant 2", capacity = 53.0, some_factor = [1.0, 2.0])
    OpenSQL.create_element!(db, "Plant"; label = "Plant 3", capacity = 54.0)

    @test OpenSQL.read_scalar_parameters(db, "Configuration", "label") == ["Toy Case"]
    @test OpenSQL.read_scalar_parameters(db, "Resource", "label") == ["Resource 1", "Resource 2"]
    @test_throws ErrorException OpenSQL.read_scalar_parameters(db, "Resource", "capacity")
    @test OpenSQL.read_scalar_parameters(db, "Plant", "label") == ["Plant 1", "Plant 2", "Plant 3"]
    @test OpenSQL.read_scalar_parameters(db, "Plant", "capacity") == [2.02, 53.0, 54.0]
    @test_throws ErrorException OpenSQL.read_scalar_parameters(db, "Resource", "some_value")
    @test_throws ErrorException OpenSQL.read_vectorial_parameters(db, "Plant", "capacity")
    @test OpenSQL.read_vectorial_parameters(db, "Resource", "some_value") == [[1, 2, 3.0], [1, 2, 4.0]]
    @test OpenSQL.read_vectorial_parameters(db, "Plant", "some_factor") == [[1.0], [1.0, 2.0], []]

    OpenSQL.update_element!(db, "Plant", "Plant 1"; capacity = 2.0)
    @test OpenSQL.read_scalar_parameters(db, "Plant", "capacity") == [2.0, 53.0, 54.0]
    # TODO read an updated vectorial parameter

    OpenSQL.delete_element!(db, "Resource", "Resource 1")
    @test OpenSQL.read_scalar_parameters(db, "Resource", "label") == ["Resource 2"]

    OpenSQL.close!(db)
    rm(db_path)
end

function test_read_relationships()
    path_schema = joinpath(@__DIR__, "test_read.sql")
    db_path = joinpath(@__DIR__, "test_read.sqlite")
    db = OpenSQL.create_empty_db(db_path, path_schema; force = true)
    OpenSQL.create_element!(db, "Configuration"; label = "Toy Case")
    OpenSQL.create_element!(db, "Resource"; label = "Resource 1", some_value = [1, 2, 3.0])
    OpenSQL.create_element!(db, "Resource"; label = "Resource 2", some_value = [1, 2, 4.0])
    OpenSQL.create_element!(db, "Cost"; label = "Cost 1")
    OpenSQL.create_element!(db, "Cost"; label = "Cost 2")
    OpenSQL.create_element!(db, "Plant"; label = "Plant 1", capacity = 2.02, some_factor = [1.0])
    OpenSQL.create_element!(db, "Plant"; label = "Plant 2", capacity = 53.0, some_factor = [1.0, 2.0])
    OpenSQL.create_element!(db, "Plant"; label = "Plant 3", capacity = 54.0)

    OpenSQL.set_scalar_relationship!(db, "Plant", "Resource", "Plant 1", "Resource 1", "id")
    OpenSQL.set_scalar_relationship!(db, "Plant", "Plant", "Plant 3", "Plant 2", "turbine_to")
    OpenSQL.set_scalar_relationship!(db, "Plant", "Resource", "Plant 1", "Resource 1", "id")
    OpenSQL.set_vectorial_relationship!(db, "Plant", "Cost",  "Plant 1", ["Cost 1"], "id")
    OpenSQL.set_vectorial_relationship!(db, "Plant", "Cost",  "Plant 2", ["Cost 1", "Cost 2"], "id")

    @test OpenSQL.read_scalar_relationships(db, "Plant", "Resource", "id") == ["Resource 1", "", ""]
    @test OpenSQL.read_scalar_relationships(db, "Plant", "Plant", "turbine_to") == ["", "", "Plant 2"]
end

function test_read_all_attributes_at_once()

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

TestRead.runtests()

end