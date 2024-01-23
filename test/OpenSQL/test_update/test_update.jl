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
    @test_throws ErrorException OpenSQL.set_scalar_relationship!(db, "Plant", "Plant", "Plant", "Plant", "id")
    @test_throws ErrorException OpenSQL.set_scalar_relationship!(db, "Plant", "Plant 1", "Plant", "Plant 2", "id")

    OpenSQL.close!(db)
    rm(db_path)
end

function test_create_vectorial_relationships()
    path_schema = joinpath(@__DIR__, "test_create_vectorial_relationships.sql")
    db_path = joinpath(@__DIR__, "test_create_vectorial_relationships.sqlite")
    db = OpenSQL.create_empty_db(db_path, path_schema; force = true)
    OpenSQL.create_element!(db, "Configuration"; label = "Toy Case")
    OpenSQL.create_element!(db, "Cost"; label = "Cost 1")
    OpenSQL.create_element!(db, "Cost"; label = "Cost 2")
    OpenSQL.create_element!(db, "Cost"; label = "Cost 3")
    OpenSQL.create_element!(db, "Cost"; label = "Cost 4")
    OpenSQL.create_element!(db, "Plant"; label = "Plant 1", capacity = 49.0)
    OpenSQL.create_element!(db, "Plant"; label = "Plant 2", capacity = 50.0)
    OpenSQL.create_element!(db, "Plant"; label = "Plant 3", capacity = 51.0)
    OpenSQL.create_element!(db, "Plant"; label = "Plant 4", capacity = 51.0, some_factor = [0.1, 0.3])

    @test_throws ErrorException OpenSQL.set_scalar_relationship!(db, "Plant", "Cost", "Plant 1", ["Cost 1"], "some_relation_type")
    OpenSQL.set_vectorial_relationship!(db, "Plant", "Cost", "Plant 1", ["Cost 1"], "some_relation_type")
    OpenSQL.set_vectorial_relationship!(db, "Plant", "Cost", "Plant 2", ["Cost 1", "Cost 2", "Cost 3"], "some_relation_type")
    OpenSQL.set_vectorial_relationship!(db, "Plant", "Cost", "Plant 4", ["Cost 1", "Cost 3"], "id")
    @test_throws ErrorException OpenSQL.set_vectorial_relationship!(db, "Plant", "Cost", "Plant 2", ["Cost 10", "Cost 2"], "some_relation_type")
    @test_throws ErrorException OpenSQL.set_vectorial_relationship!(db, "Plant", "Cost", "Plant 2", ["Cost 1", "Cost 2", "Cost 3"], "wrong")

    OpenSQL.close!(db)
    # rm(db_path)
end

function test_update_scalar_parameters()
    path_schema = joinpath(@__DIR__, "test_update_scalar_parameters.sql")
    db_path = joinpath(@__DIR__, "test_update_scalar_parameters.sqlite")
    db = OpenSQL.create_empty_db(db_path, path_schema; force = true)
    OpenSQL.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    OpenSQL.create_element!(db, "Resource"; label = "Resource 1", type = "E")
    OpenSQL.create_element!(db, "Resource"; label = "Resource 2", type = "E")

    @test_throws ErrorException OpenSQL.update_element!(db, "Resource", "Resource 1"; type = "D", some_value = 1.0)
    @test_throws ErrorException OpenSQL.update_element!(db, "Resource", "Resource 4"; type = "D", some_value = 1.0)
    OpenSQL.update_element!(db, "Resource", "Resource 1"; type = "D", some_value_1 = 1.0)
    OpenSQL.update_element!(db, "Resource", "Resource 1"; type = "D", some_value_1 = 1.0, some_value_2 = 90.0)
    @test_throws ErrorException OpenSQL.update_element!(db, "Resource", "Resource 1"; type = "D", some_value_1 = 1.0, some_value_2 = "wrong!")
    @test_throws ErrorException OpenSQL.update_element!(db, "Resource", "Resource 1"; cost_id = 2)
    OpenSQL.close!(db)
    rm(db_path)
end

function test_update_vectorial_parameters()
    path_schema = joinpath(@__DIR__, "test_update_vectorial_parameters.sql")
    db_path = joinpath(@__DIR__, "test_update_vectorial_parameters.sqlite")
    db = OpenSQL.create_empty_db(db_path, path_schema; force = true)
    OpenSQL.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    OpenSQL.create_element!(db, "Resource"; label = "Resource 1", type = "E", some_value_1 = [1.0, 2.0, 3.0])
    OpenSQL.create_element!(db, "Resource"; label = "Resource 2", type = "E")

    # OpenSQL.update_vectorial_attributes!(db, "Resource", "Resource 1"; some_value_1 = [4.0, 5.0, 6.0])
    # OpenSQL.update_vectorial_attributes!(db, "Resource", "Resource 1"; some_value_2 = [0.0, 5.0, 6.0])
    # @test_throws ErrorException OpenSQL.update_vectorial_attributes!(db, "Resource", "Resource 4"; some_value_1 = [1.0, 2.0, 3.0])
    # @test_throws ErrorException OpenSQL.update_vectorial_attributes!(db, "Resource", "Resource 1"; some_value_3 = [1.0, 2.0, 3.0])
    # OpenSQL.update_vectorial_attributes!(db, "Resource", "Resource 1"; some_value_1 = [1.0, 2.0, 3.0], some_value_2 = [90, 80, 70])
    # @test_throws ErrorException OpenSQL.update_vectorial_attributes!(db, "Resource", "Resource 1"; some_value_2 = [0.0, 5.0, 6.0, 9.0])
    # @test_throws SQLite.SQLiteException OpenSQL.update_vectorial_attributes!(db, "Resource", "Resource 1"; some_value_2 = [90, 80, "wrong!"])
    OpenSQL.close!(db)
    rm(db_path)

    # OpenSQL.update_element!(db, "Product", "Sugar"; label = "New Sugar")
    # OpenSQL.update_element!(db, "Product", "Sugar"; unit = "Kg")
    # OpenSQL.update_element!(db, "Product", "Sugar"; unit = 30)

    # OpenSQL.update_element!(db, "Process", "Sugar Mill"; factor_output = [0.3, 0.4, 0.6])
    # # Shoudl error
    # OpenSQL.update_element!(db, "Process", "Sugar Mill"; factor_output = [0.3, 0.4, 0.6, 0.7])
    # OpenSQL.update_element!(db, "Process", "Sugar Mill"; 
    #     factor_output = [0.3, 0.4, 0.6, 0.7], 
    #     product_output = ["Sugar", "Molasse", "Bagasse", "Bagasse 2"]
    # )
    # # should error
    # OpenSQL.update_element!(db, "Process", "Sugar Mill"; 
    #     factor_output = [0.3, 0.4, 0.6, 0.7], 
    #     product_output = ["Sugar", "Molasse", "Bagasse 2"]
    # )

    # OpenSQL.update_element!(db, "Process", "Sugar Mill"; 
    #     factor_output = [0.3, 0.4], 
    #     product_output = ["Sugar", "Molasse"]
    # )
    # error("Vectors cannot be update with update_element!. This is the case because ")

    # read 
    # # ela modifica
    # deleta
    # create
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