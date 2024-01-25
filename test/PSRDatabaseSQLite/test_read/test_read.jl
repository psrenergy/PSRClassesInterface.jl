module TestRead

using PSRClassesInterface.PSRDatabaseSQLite
using SQLite
using Dates
using Test

function test_read_parameters()
    path_schema = joinpath(@__DIR__, "test_read.sql")
    db_path = joinpath(@__DIR__, "test_read.sqlite")
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
    PSRDatabaseSQLite.create_element!(db, "Cost"; label = "Cost 1")
    PSRDatabaseSQLite.create_element!(db, "Cost"; label = "Cost 2", value = 10.0)
    PSRDatabaseSQLite.create_element!(
        db,
        "Plant";
        label = "Plant 1",
        capacity = 2.02,
        some_factor = [1.0],
        date_some_date = [DateTime(2020, 1, 1)],
    )
    PSRDatabaseSQLite.create_element!(
        db,
        "Plant";
        label = "Plant 2",
        capacity = 53.0,
        some_factor = [1.0, 2.0],
        date_some_date = [DateTime(2020, 1, 1), DateTime(2020, 1, 2)],
    )
    PSRDatabaseSQLite.create_element!(db, "Plant"; label = "Plant 3", capacity = 54.0)
    PSRDatabaseSQLite.create_element!(
        db,
        "Plant";
        label = "Plant 4",
        capacity = 53.0,
        some_factor = [1.0, 2.0],
    )

    @test PSRDatabaseSQLite.read_scalar_parameters(db, "Configuration", "label") ==
          ["Toy Case"]
    @test PSRDatabaseSQLite.read_scalar_parameters(db, "Configuration", "date_initial") ==
          [DateTime(2020, 1, 1)]
    @test PSRDatabaseSQLite.read_scalar_parameters(db, "Resource", "label") ==
          ["Resource 1", "Resource 2"]
    @test PSRDatabaseSQLite.read_scalar_parameter(db, "Resource", "label", "Resource 1") ==
          "Resource 1"
    @test PSRDatabaseSQLite.read_scalar_parameters(db, "Cost", "value") == [100.0, 10.0]
    @test any(
        isnan,
        PSRDatabaseSQLite.read_scalar_parameters(db, "Cost", "value_without_default"),
    )
    @test PSRDatabaseSQLite.read_scalar_parameters(
        db,
        "Cost",
        "value_without_default";
        default = 2.0,
    ) == [2.0, 2.0]
    @test PSRDatabaseSQLite.read_scalar_parameter(db, "Plant", "capacity", "Plant 3") ==
          54.0
    @test_throws ErrorException PSRDatabaseSQLite.read_scalar_parameter(
        db,
        "Plant",
        "capacity",
        "Plant 5",
    )
    @test_throws ErrorException PSRDatabaseSQLite.read_scalar_parameters(
        db,
        "Resource",
        "capacity",
    )
    @test PSRDatabaseSQLite.read_scalar_parameters(db, "Plant", "label") ==
          ["Plant 1", "Plant 2", "Plant 3", "Plant 4"]
    @test PSRDatabaseSQLite.read_scalar_parameters(db, "Plant", "capacity") ==
          [2.02, 53.0, 54.0, 53.0]
    @test_throws ErrorException PSRDatabaseSQLite.read_scalar_parameters(
        db,
        "Resource",
        "some_value",
    )
    @test_throws ErrorException PSRDatabaseSQLite.read_vector_parameters(
        db,
        "Plant",
        "capacity",
    )
    @test PSRDatabaseSQLite.read_vector_parameters(db, "Resource", "some_value") ==
          [[1, 2, 3.0], [1, 2, 4.0]]
    @test PSRDatabaseSQLite.read_vector_parameters(db, "Plant", "some_factor") ==
          [[1.0], [1.0, 2.0], Float64[], [1.0, 2.0]]
    @test PSRDatabaseSQLite.read_vector_parameter(db, "Plant", "some_factor", "Plant 1") ==
          [1.0]
    @test PSRDatabaseSQLite.read_vector_parameter(db, "Plant", "some_factor", "Plant 2") ==
          [1.0, 2.0]
    @test PSRDatabaseSQLite.read_vector_parameter(db, "Plant", "some_factor", "Plant 3") ==
          Float64[]
    @test PSRDatabaseSQLite.read_vector_parameter(
        db,
        "Plant",
        "date_some_date",
        "Plant 2",
    ) ==
          [DateTime(2020, 1, 1), DateTime(2020, 1, 2)]
    @test PSRDatabaseSQLite.read_vector_parameter(
        db,
        "Plant",
        "date_some_date",
        "Plant 3",
    ) ==
          DateTime[]
    @test PSRDatabaseSQLite.read_vector_parameter(
        db,
        "Plant",
        "date_some_date",
        "Plant 4",
    ) ==
          DateTime[typemin(DateTime), typemin(DateTime)]
    @test_throws ErrorException PSRDatabaseSQLite.read_vector_parameter(
        db,
        "Plant",
        "some_factor",
        "Plant 500",
    )

    PSRDatabaseSQLite.update_scalar_parameter!(db, "Plant", "capacity", "Plant 1", 2.0)
    @test PSRDatabaseSQLite.read_scalar_parameters(db, "Plant", "capacity") ==
          [2.0, 53.0, 54.0, 53.0]
    PSRDatabaseSQLite.delete_element!(db, "Resource", "Resource 1")
    @test PSRDatabaseSQLite.read_scalar_parameters(db, "Resource", "label") ==
          ["Resource 2"]

    PSRDatabaseSQLite.close!(db)
    return rm(db_path)
end

function test_read_relations()
    path_schema = joinpath(@__DIR__, "test_read.sql")
    db_path = joinpath(@__DIR__, "test_read.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case")
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
    PSRDatabaseSQLite.create_element!(db, "Cost"; label = "Cost 1")
    PSRDatabaseSQLite.create_element!(db, "Cost"; label = "Cost 2")
    PSRDatabaseSQLite.create_element!(
        db,
        "Plant";
        label = "Plant 1",
        capacity = 2.02,
        some_factor = [1.0],
    )
    PSRDatabaseSQLite.create_element!(
        db,
        "Plant";
        label = "Plant 2",
        capacity = 53.0,
        some_factor = [1.0, 2.0],
    )
    PSRDatabaseSQLite.create_element!(db, "Plant"; label = "Plant 3", capacity = 54.0)

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
        "Plant",
        "Plant 3",
        "Plant 2",
        "turbine_to",
    )
    PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "Plant",
        "Resource",
        "Plant 1",
        "Resource 1",
        "id",
    )
    PSRDatabaseSQLite.set_vector_relation!(db, "Plant", "Cost", "Plant 1", ["Cost 1"], "id")
    PSRDatabaseSQLite.set_vector_relation!(
        db,
        "Plant",
        "Cost",
        "Plant 2",
        ["Cost 1", "Cost 2"],
        "id",
    )

    @test PSRDatabaseSQLite.read_scalar_relations(db, "Plant", "Resource", "id") ==
          ["Resource 1", "", ""]
    @test PSRDatabaseSQLite.read_scalar_relations(db, "Plant", "Plant", "turbine_to") ==
          ["", "", "Plant 2"]
    @test_throws ErrorException PSRDatabaseSQLite.read_scalar_relations(
        db,
        "Plant",
        "Cost",
        "id",
    )
    @test PSRDatabaseSQLite.read_vector_relations(db, "Plant", "Cost", "id") ==
          [["Cost 1"], ["Cost 1", "Cost 2"], String[]]
    PSRDatabaseSQLite.set_vector_relation!(db, "Plant", "Cost", "Plant 1", ["Cost 2"], "id")
    @test PSRDatabaseSQLite.read_vector_relations(db, "Plant", "Cost", "id") ==
          [["Cost 2"], ["Cost 1", "Cost 2"], String[]]
    @test_throws ErrorException PSRDatabaseSQLite.read_vector_relations(
        db,
        "Plant",
        "Resource",
        "id",
    )
    @test PSRDatabaseSQLite.read_vector_relation(db, "Plant", "Cost", "Plant 1", "id") ==
          ["Cost 2"]
    @test PSRDatabaseSQLite.read_vector_relation(db, "Plant", "Cost", "Plant 2", "id") ==
          ["Cost 1", "Cost 2"]

    PSRDatabaseSQLite.close!(db)
    return rm(db_path)
end

function test_read_time_series_files()
    path_schema = joinpath(@__DIR__, "test_read.sql")
    db_path = joinpath(@__DIR__, "test_read.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case")
    PSRDatabaseSQLite.create_element!(db, "Plant"; label = "Plant 1")

    PSRDatabaseSQLite.set_time_series_file!(
        db,
        "Plant";
        wind_speed = "some_file.txt",
        wind_direction = "some_file2",
    )
    @test PSRDatabaseSQLite.read_time_series_file(db, "Plant", "wind_speed") ==
          "some_file.txt"
    @test PSRDatabaseSQLite.read_time_series_file(db, "Plant", "wind_direction") ==
          "some_file2"
    @test_throws ErrorException PSRDatabaseSQLite.read_time_series_file(
        db,
        "Plant",
        "spill",
    )
    PSRDatabaseSQLite.set_time_series_file!(db, "Plant"; wind_speed = "some_file3.txt")
    @test PSRDatabaseSQLite.read_time_series_file(db, "Plant", "wind_speed") ==
          "some_file3.txt"
    @test PSRDatabaseSQLite.read_time_series_file(db, "Plant", "wind_direction") |>
          ismissing
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
