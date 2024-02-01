module TestDelete

using PSRClassesInterface.PSRDatabaseSQLite
using SQLite
using Test

function test_delete_element()
    path_schema = joinpath(@__DIR__, "test_delete_element.sql")
    db_path = joinpath(@__DIR__, "test_delete_element.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case")
    PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 1",
        some_value = [1, 2, 3.0],
        some_other_value = [1.0, 4.0, 5.0],
    )
    PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 2",
        some_value = [1, 2, 3.0],
        some_other_value = [1.0, 4.0, 5.0],
    )
    PSRDatabaseSQLite.create_element!(db, "Plant"; label = "Plant 1", capacity = 50.0)
    PSRDatabaseSQLite.create_element!(
        db,
        "Plant";
        label = "Plant 2",
        capacity = 50.0,
        plant_turbine_to = "Plant 1",
    )
    PSRDatabaseSQLite.create_element!(db, "Plant"; label = "Plant 3", capacity = 50.0)
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.delete_element!(db, "Plant", "Plant 14")
    @test_throws SQLite.SQLiteException PSRDatabaseSQLite.create_element!(
        db,
        "Plant";
        label = "Plant 3",
    )
    PSRDatabaseSQLite.delete_element!(db, "Plant", "Plant 3")
    PSRDatabaseSQLite.create_element!(db, "Plant"; label = "Plant 3")
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.delete_element!(
        db,
        "SomeCollection",
        "Plant 2",
    )
    PSRDatabaseSQLite.close!(db)
    return rm(db_path)
end

function test_delete_cascade()
    path_schema = joinpath(@__DIR__, "test_delete_cascade.sql")
    db_path = joinpath(@__DIR__, "test_delete_cascade.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case")
    PSRDatabaseSQLite.create_element!(
        db,
        "ThermalPlant";
        label = "Thermal 1",
    )
    PSRDatabaseSQLite.create_element!(
        db,
        "ThermalPlant";
        label = "Thermal 2",
    )
    PSRDatabaseSQLite.create_element!(
        db,
        "MultiFuelThermalPlant";
        label = "Multi Fuel Thermal 1",
    )
    PSRDatabaseSQLite.create_element!(
        db,
        "MultiFuelThermalPlant";
        label = "Multi Fuel Thermal 2",
    )
    PSRDatabaseSQLite.create_element!(
        db,
        "Fuel";
        label = "Fuel 1",
    )
    PSRDatabaseSQLite.create_element!(
        db,
        "Fuel";
        label = "Fuel 2",
    )
    PSRDatabaseSQLite.create_element!(
        db,
        "Fuel";
        label = "Fuel 3",
    )

    PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "ThermalPlant",
        "Fuel",
        "Thermal 1",
        "Fuel 1",
        "id",
    )

    PSRDatabaseSQLite.set_scalar_relation!(
        db,
        "ThermalPlant",
        "Fuel",
        "Thermal 2",
        "Fuel 2",
        "id",
    )

    @test PSRDatabaseSQLite.read_scalar_relations(db, "ThermalPlant", "Fuel", "id") == ["Fuel 1", "Fuel 2"]
    @test PSRDatabaseSQLite._get_scalar_relation_map(db, "ThermalPlant", "Fuel", "id") == [1, 2]

    PSRDatabaseSQLite.delete_element!(db, "Fuel", "Fuel 1")

    @test PSRDatabaseSQLite.read_scalar_relations(db, "ThermalPlant", "Fuel", "id") == ["", "Fuel 2"]
    @test PSRDatabaseSQLite._get_scalar_relation_map(db, "ThermalPlant", "Fuel", "id") == [typemin(Int), 1]
    fuel_labels = PSRDatabaseSQLite.read_scalar_parameters(db, "Fuel", "label")
    @test findfirst(isequal("Fuel 2"), fuel_labels) == 1

    # Create new element again
    PSRDatabaseSQLite.create_element!(
        db,
        "Fuel";
        label = "Fuel 1",
    )

    PSRDatabaseSQLite.set_vector_relation!(
        db,
        "MultiFuelThermalPlant",
        "Fuel",
        "Multi Fuel Thermal 1",
        ["Fuel 1", "Fuel 2"],
        "id",
    )

    PSRDatabaseSQLite.set_vector_relation!(
        db,
        "MultiFuelThermalPlant",
        "Fuel",
        "Multi Fuel Thermal 2",
        ["Fuel 2", "Fuel 3"],
        "id",
    )

    @test PSRDatabaseSQLite.read_vector_relations(db, "MultiFuelThermalPlant", "Fuel", "id") == [["Fuel 1", "Fuel 2"], ["Fuel 2", "Fuel 3"]]
    @test PSRDatabaseSQLite.read_scalar_parameters(db, "Fuel", "label") == ["Fuel 2", "Fuel 3", "Fuel 1"]
    @test PSRDatabaseSQLite._get_vector_relation_map(db, "MultiFuelThermalPlant", "Fuel", "id") == [[3, 1], [1, 2]]

    PSRDatabaseSQLite.delete_element!(db, "Fuel", "Fuel 2")

    @test PSRDatabaseSQLite.read_vector_relations(db, "MultiFuelThermalPlant", "Fuel", "id") == [["Fuel 1", ""], ["", "Fuel 3"]]
    @test PSRDatabaseSQLite._get_vector_relation_map(db, "MultiFuelThermalPlant", "Fuel", "id") == [[2, typemin(Int)], [typemin(Int), 1]]

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

TestDelete.runtests()

end
