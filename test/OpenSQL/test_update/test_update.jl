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
    OpenSQL.set_scalar_relationship!(
        db,
        "Plant",
        "Plant",
        "Plant 3",
        "Plant 1",
        "turbine_to",
    )
    OpenSQL.set_scalar_relationship!(db, "Plant", "Plant", "Plant 1", "Plant 2", "spill_to")

    # invalid relationships
    @test_throws ErrorException OpenSQL.set_scalar_relationship!(
        db,
        "Plant",
        "Resource",
        "Plant 1",
        "Resource 1",
        "wrong",
    )
    @test_throws ErrorException OpenSQL.set_scalar_relationship!(
        db,
        "Plant",
        "Resource",
        "Plant 1",
        "Resource 4",
        "id",
    )
    @test_throws ErrorException OpenSQL.set_scalar_relationship!(
        db,
        "Plant",
        "Resource",
        "Plant 5",
        "Resource 1",
        "id",
    )
    @test_throws ErrorException OpenSQL.set_scalar_relationship!(
        db,
        "Resource",
        "Resource",
        "Resource 1",
        "Resource 2",
        "wrong",
    )
    @test_throws ErrorException OpenSQL.set_scalar_relationship!(
        db,
        "Plant",
        "Plant",
        "Plant 1",
        "Plant 2",
        "wrong",
    )
    @test_throws ErrorException OpenSQL.set_scalar_relationship!(
        db,
        "Plant",
        "Plant",
        "Plant 1",
        "Plant 1",
        "turbine_to",
    )
    @test_throws ErrorException OpenSQL.set_scalar_relationship!(
        db,
        "Plant",
        "Plant",
        "Plant 1",
        "Plant 2",
        "id",
    )
    @test_throws ErrorException OpenSQL.set_scalar_relationship!(
        db,
        "Plant",
        "Plant",
        "Plant",
        "Plant",
        "id",
    )
    @test_throws ErrorException OpenSQL.set_scalar_relationship!(
        db,
        "Plant",
        "Plant 1",
        "Plant",
        "Plant 2",
        "id",
    )

    OpenSQL.close!(db)
    return rm(db_path)
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
    OpenSQL.create_element!(
        db,
        "Plant";
        label = "Plant 4",
        capacity = 51.0,
        some_factor = [0.1, 0.3],
    )

    @test_throws ErrorException OpenSQL.set_scalar_relationship!(
        db,
        "Plant",
        "Cost",
        "Plant 1",
        ["Cost 1"],
        "some_relation_type",
    )
    OpenSQL.set_vectorial_relationship!(
        db,
        "Plant",
        "Cost",
        "Plant 1",
        ["Cost 1"],
        "some_relation_type",
    )
    OpenSQL.set_vectorial_relationship!(
        db,
        "Plant",
        "Cost",
        "Plant 2",
        ["Cost 1", "Cost 2", "Cost 3"],
        "some_relation_type",
    )
    OpenSQL.set_vectorial_relationship!(
        db,
        "Plant",
        "Cost",
        "Plant 4",
        ["Cost 1", "Cost 3"],
        "id",
    )
    @test_throws ErrorException OpenSQL.set_vectorial_relationship!(
        db,
        "Plant",
        "Cost",
        "Plant 2",
        ["Cost 10", "Cost 2"],
        "some_relation_type",
    )
    @test_throws ErrorException OpenSQL.set_vectorial_relationship!(
        db,
        "Plant",
        "Cost",
        "Plant 2",
        ["Cost 1", "Cost 2", "Cost 3"],
        "wrong",
    )

    OpenSQL.close!(db)
    return rm(db_path)
end

function test_update_scalar_parameters()
    path_schema = joinpath(@__DIR__, "test_update_scalar_parameters.sql")
    db_path = joinpath(@__DIR__, "test_update_scalar_parameters.sqlite")
    db = OpenSQL.create_empty_db(db_path, path_schema; force = true)
    OpenSQL.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    OpenSQL.create_element!(db, "Resource"; label = "Resource 1", type = "E")
    OpenSQL.create_element!(db, "Resource"; label = "Resource 2", type = "E")
    OpenSQL.create_element!(db, "Cost"; label = "Cost 1")
    OpenSQL.create_element!(db, "Cost"; label = "Cost 2")

    OpenSQL.update_scalar_parameter!(db, "Resource", "type", "Resource 1", "D")
    @test_throws ErrorException OpenSQL.update_scalar_parameter!(
        db,
        "Resource",
        "some_value",
        "Resource 4",
        1.0,
    )
    @test_throws ErrorException OpenSQL.update_scalar_parameter!(
        db,
        "Resource",
        "invented_attribute",
        "Resource 4",
        1.0,
    )
    OpenSQL.update_scalar_parameter!(db, "Resource", "some_value_1", "Resource 1", 1.0)
    OpenSQL.update_scalar_parameter!(db, "Resource", "some_value_1", "Resource 1", 1.0)
    OpenSQL.update_scalar_parameter!(db, "Resource", "some_value_2", "Resource 1", 99.0)
    @test_throws ErrorException OpenSQL.update_scalar_parameter!(
        db,
        "Resource",
        "some_value_2",
        "Resource 1",
        "wrong!",
    )
    @test_throws ErrorException OpenSQL.update_scalar_parameter!(
        db,
        "Resource",
        "cost_id",
        "Resource 1",
        "something",
    )
    OpenSQL.close!(db)
    return rm(db_path)
end

function test_update_vectorial_parameters()
    path_schema = joinpath(@__DIR__, "test_update_vectorial_parameters.sql")
    db_path = joinpath(@__DIR__, "test_update_vectorial_parameters.sqlite")
    db = OpenSQL.create_empty_db(db_path, path_schema; force = true)
    OpenSQL.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    OpenSQL.create_element!(
        db,
        "Resource";
        label = "Resource 1",
        type = "E",
        some_value_1 = [1.0, 2.0, 3.0],
    )
    OpenSQL.create_element!(db, "Resource"; label = "Resource 2", type = "E")

    OpenSQL.update_vectorial_parameters!(
        db,
        "Resource",
        "some_value_1",
        "Resource 1",
        [4.0, 5.0, 6.0],
    )
    OpenSQL.update_vectorial_parameters!(
        db,
        "Resource",
        "some_value_2",
        "Resource 1",
        [4.0, 5.0, 6.0],
    )
    @test_throws ErrorException OpenSQL.update_vectorial_parameters!(
        db,
        "Resource",
        "some_value_3",
        "Resource 1",
        [4.0, 5.0, 6.0],
    )
    @test_throws ErrorException OpenSQL.update_vectorial_parameters!(
        db,
        "Resource",
        "some_value_1",
        "Resource 1",
        [1, 2, 3],
    )
    @test_throws ErrorException OpenSQL.update_vectorial_parameters!(
        db,
        "Resource",
        "some_value_1",
        "Resource 1",
        [4.0, 5.0, 6.0, 7.0],
    )
    OpenSQL.close!(db)
    return rm(db_path)
end

function test_create_time_series_files()
    path_schema = joinpath(@__DIR__, "test_create_time_series_files.sql")
    db_path = joinpath(@__DIR__, "test_create_time_series_files.sqlite")
    db = OpenSQL.create_empty_db(db_path, path_schema; force = true)
    OpenSQL.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    OpenSQL.create_element!(db, "Resource"; label = "Resource 1")
    OpenSQL.set_time_series_file!(db, "Resource"; wind_speed = "some_file.txt")
    @test_throws ErrorException OpenSQL.set_time_series_file!(
        db,
        "Resource";
        wind_speed = ["some_file.txt"],
    )
    @test_throws ErrorException OpenSQL.set_time_series_file!(db, "Resource"; label = "RS")
    OpenSQL.set_time_series_file!(db, "Resource"; wind_speed = "some_other_file.txt")
    OpenSQL.set_time_series_file!(
        db,
        "Resource";
        wind_speed = "speed.txt",
        wind_direction = "direction.txt",
    )
    @test_throws ErrorException OpenSQL.set_time_series_file!(
        db,
        "Resource";
        wind_speed = "C:\\Users\\some_user\\some_file.txt",
    )
    @test_throws ErrorException OpenSQL.set_time_series_file!(
        db,
        "Resource";
        wind_speed = "~/some_user/some_file.txt",
    )
    OpenSQL.close!(db)
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

TestUpdate.runtests()

end
