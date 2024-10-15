module TestUpdate

using PSRClassesInterface.PSRDatabaseSQLite
using SQLite
using Test

function test_create_scalar_relations()
    path_schema = joinpath(@__DIR__, "test_create_scalar_relations.sql")
    db_path = joinpath(@__DIR__, "test_create_scalar_relations.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    PSRDatabaseSQLite.create_element!(db, "Resource"; label = "Resource 1", type = "E")
    PSRDatabaseSQLite.create_element!(db, "Resource"; label = "Resource 2", type = "E")
    PSRDatabaseSQLite.create_element!(db, "Plant"; label = "Plant 1", capacity = 50.0)
    PSRDatabaseSQLite.create_element!(db, "Plant"; label = "Plant 2", capacity = 50.0)
    PSRDatabaseSQLite.create_element!(db, "Plant"; label = "Plant 3", capacity = 50.0)

    # Valid relations
    PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "Plant",
        "Resource",
        "Plant 1",
        "Resource 1",
        "id",
    )
    PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "Plant",
        "Resource",
        "Plant 1",
        "Resource 2",
        "id",
    )
    PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "Plant",
        "Resource",
        "Plant 2",
        "Resource 1",
        "id",
    )
    PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "Plant",
        "Resource",
        "Plant 3",
        "Resource 2",
        "id",
    )
    PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "Plant",
        "Plant",
        "Plant 3",
        "Plant 1",
        "turbine_to",
    )
    PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "Plant",
        "Plant",
        "Plant 1",
        "Plant 2",
        "spill_to",
    )

    # invalid relations
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "Plant",
        "Resource",
        "Plant 1",
        "Resource 1",
        "wrong",
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "Plant",
        "Resource",
        "Plant 1",
        "Resource 4",
        "id",
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "Plant",
        "Resource",
        "Plant 5",
        "Resource 1",
        "id",
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "Resource",
        "Resource",
        "Resource 1",
        "Resource 2",
        "wrong",
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "Plant",
        "Plant",
        "Plant 1",
        "Plant 2",
        "wrong",
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "Plant",
        "Plant",
        "Plant 1",
        "Plant 1",
        "turbine_to",
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "Plant",
        "Plant",
        "Plant 1",
        "Plant 2",
        "id",
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "Plant",
        "Plant",
        "Plant",
        "Plant",
        "id",
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "Plant",
        "Plant 1",
        "Plant",
        "Plant 2",
        "id",
    )

    PSRDatabaseSQLite.close!(db)
    return rm(db_path)
end

function test_create_vector_relations()
    path_schema = joinpath(@__DIR__, "test_create_vector_relations.sql")
    db_path = joinpath(@__DIR__, "test_create_vector_relations.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case")
    PSRDatabaseSQLite.create_element!(db, "Cost"; label = "Cost 1")
    PSRDatabaseSQLite.create_element!(db, "Cost"; label = "Cost 2")
    PSRDatabaseSQLite.create_element!(db, "Cost"; label = "Cost 3")
    PSRDatabaseSQLite.create_element!(db, "Cost"; label = "Cost 4")
    PSRDatabaseSQLite.create_element!(db, "Plant"; label = "Plant 1", capacity = 49.0)
    PSRDatabaseSQLite.create_element!(db, "Plant"; label = "Plant 2", capacity = 50.0)
    PSRDatabaseSQLite.create_element!(db, "Plant"; label = "Plant 3", capacity = 51.0)
    PSRDatabaseSQLite.create_element!(
        db,
        "Plant";
        label = "Plant 4",
        capacity = 51.0,
        some_factor = [0.1, 0.3],
    )

    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "Plant",
        "Cost",
        "Plant 1",
        ["Cost 1"],
        "some_relation_type",
    )
    PSRDatabaseSQLite.set_vector_relation!(
        db,
        "Plant",
        "Cost",
        "Plant 1",
        ["Cost 1"],
        "some_relation_type",
    )
    PSRDatabaseSQLite.set_vector_relation!(
        db,
        "Plant",
        "Cost",
        "Plant 2",
        ["Cost 1", "Cost 2", "Cost 3"],
        "some_relation_type",
    )
    PSRDatabaseSQLite.set_vector_relation!(
        db,
        "Plant",
        "Cost",
        "Plant 4",
        ["Cost 1", "Cost 3"],
        "id",
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.set_vector_relation!(
        db,
        "Plant",
        "Cost",
        "Plant 2",
        ["Cost 10", "Cost 2"],
        "some_relation_type",
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.set_vector_relation!(
        db,
        "Plant",
        "Cost",
        "Plant 2",
        ["Cost 1", "Cost 2", "Cost 3"],
        "wrong",
    )

    PSRDatabaseSQLite.close!(db)
    return rm(db_path)
end

function test_update_scalar_parameters()
    path_schema = joinpath(@__DIR__, "test_update_scalar_parameters.sql")
    db_path = joinpath(@__DIR__, "test_update_scalar_parameters.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    PSRDatabaseSQLite.create_element!(db, "Resource"; label = "Resource 1", type = "E")
    PSRDatabaseSQLite.create_element!(db, "Resource"; label = "Resource 2", type = "E")
    PSRDatabaseSQLite.create_element!(db, "Cost"; label = "Cost 1")
    PSRDatabaseSQLite.create_element!(db, "Cost"; label = "Cost 2")

    PSRDatabaseSQLite.update_scalar_parameter!(db, "Resource", "type", "Resource 1", "D")
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.update_scalar_parameter!(
        db,
        "Resource",
        "some_value",
        "Resource 4",
        1.0,
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.update_scalar_parameter!(
        db,
        "Resource",
        "invented_attribute",
        "Resource 4",
        1.0,
    )
    PSRDatabaseSQLite.update_scalar_parameter!(
        db,
        "Resource",
        "some_value_1",
        "Resource 1",
        1.0,
    )
    PSRDatabaseSQLite.update_scalar_parameter!(
        db,
        "Resource",
        "some_value_1",
        "Resource 1",
        1.0,
    )
    PSRDatabaseSQLite.update_scalar_parameter!(
        db,
        "Resource",
        "some_value_2",
        "Resource 1",
        99.0,
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.update_scalar_parameter!(
        db,
        "Resource",
        "some_value_2",
        "Resource 1",
        "wrong!",
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.update_scalar_parameter!(
        db,
        "Resource",
        "cost_id",
        "Resource 1",
        "something",
    )
    PSRDatabaseSQLite.close!(db)
    return rm(db_path)
end

function test_update_vector_parameters()
    path_schema = joinpath(@__DIR__, "test_update_vector_parameters.sql")
    db_path = joinpath(@__DIR__, "test_update_vector_parameters.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0,
        some_value_1 = [1.0, 2.0, 3.0])
    PSRDatabaseSQLite.update_vector_parameters!(
        db,
        "Configuration",
        "some_value_1",
        "Toy Case",
        [4.0, 5.0, 6.0],
    )
    PSRDatabaseSQLite.update_vector_parameters!(
        db,
        "Configuration",
        "some_value_1",
        "Toy Case",
        [4.0, 5.0, 6.0, 10.0],
    )

    PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 1",
        type = "E",
        some_value_1 = [1.0, 2.0, 3.0],
    )
    PSRDatabaseSQLite.create_element!(db, "Resource"; label = "Resource 2", type = "E")

    PSRDatabaseSQLite.update_vector_parameters!(
        db,
        "Resource",
        "some_value_1",
        "Resource 1",
        [4.0, 5.0, 6.0],
    )
    PSRDatabaseSQLite.update_vector_parameters!(
        db,
        "Resource",
        "some_value_2",
        "Resource 1",
        [4.0, 5.0, 6.0],
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.update_vector_parameters!(
        db,
        "Resource",
        "some_value_3",
        "Resource 1",
        [4.0, 5.0, 6.0],
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.update_vector_parameters!(
        db,
        "Resource",
        "some_value_1",
        "Resource 1",
        [1, 2, 3],
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.update_vector_parameters!(
        db,
        "Resource",
        "some_value_1",
        "Resource 1",
        [4.0, 5.0, 6.0, 7.0],
    )
    PSRDatabaseSQLite.close!(db)
    return rm(db_path)
end

function test_create_time_series_files()
    path_schema = joinpath(@__DIR__, "test_create_time_series_files.sql")
    db_path = joinpath(@__DIR__, "test_create_time_series_files.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    PSRDatabaseSQLite.create_element!(db, "Resource"; label = "Resource 1")
    PSRDatabaseSQLite.set_time_series_file!(db, "Resource"; wind_speed = "some_file.txt")
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.set_time_series_file!(
        db,
        "Resource";
        wind_speed = ["some_file.txt"],
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.set_time_series_file!(
        db,
        "Resource";
        label = "RS",
    )
    PSRDatabaseSQLite.set_time_series_file!(
        db,
        "Resource";
        wind_speed = "some_other_file.txt",
    )
    PSRDatabaseSQLite.set_time_series_file!(
        db,
        "Resource";
        wind_speed = "speed.txt",
        wind_direction = "direction.txt",
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.set_time_series_file!(
        db,
        "Resource";
        wind_speed = "C:\\Users\\some_user\\some_file.txt",
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.set_time_series_file!(
        db,
        "Resource";
        wind_speed = "~/some_user/some_file.txt",
    )
    PSRDatabaseSQLite.close!(db)
    return rm(db_path)
end

function test_update_time_series()
    path_schema = joinpath(@__DIR__, "test_update_time_series.sql")
    db_path = joinpath(@__DIR__, "test_update_time_series.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Plant"; label = "Solar")
    @test PSRDatabaseSQLite.read_time_series_file(db, "Plant", "generation") == ""
    PSRDatabaseSQLite.set_time_series_file!(db, "Plant"; generation = "hrrnew.csv")
    @test PSRDatabaseSQLite.read_time_series_file(db, "Plant", "generation") == "hrrnew.csv"
    PSRDatabaseSQLite.set_time_series_file!(db, "Plant"; generation = "hrrnew2.csv")
    @test PSRDatabaseSQLite.read_time_series_file(db, "Plant", "generation") ==
          "hrrnew2.csv"
    PSRDatabaseSQLite.close!(db)

    db = PSRDatabaseSQLite.load_db(db_path)
    @test PSRDatabaseSQLite.read_time_series_file(db, "Plant", "generation") ==
          "hrrnew2.csv"
    PSRDatabaseSQLite.set_time_series_file!(db, "Plant"; generation = "hrrnew3.csv")
    @test PSRDatabaseSQLite.read_time_series_file(db, "Plant", "generation") ==
          "hrrnew3.csv"

    PSRDatabaseSQLite.create_element!(db, "Resource"; label = "Resource 1")
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.set_time_series_file!(
        db,
        "Resource";
        wind_speed = "some_file.txt",
    )
    PSRDatabaseSQLite.set_time_series_file!(db, "Resource"; generation = "gen.txt")
    @test PSRDatabaseSQLite.read_time_series_file(db, "Resource", "generation") == "gen.txt"
    @test PSRDatabaseSQLite.read_time_series_file(db, "Resource", "other_generation") == ""

    PSRDatabaseSQLite.set_time_series_file!(
        db,
        "Resource";
        generation = "gen.txt",
        other_generation = "other_gen.txt",
    )
    @test PSRDatabaseSQLite.read_time_series_file(db, "Resource", "generation") == "gen.txt"
    @test PSRDatabaseSQLite.read_time_series_file(db, "Resource", "other_generation") ==
          "other_gen.txt"

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

TestUpdate.runtests()

end
