module TestCreate

using PSRClassesInterface.PSRDatabaseSQLite
using SQLite
using Dates
using Test

function test_create_parameters()
    path_schema = joinpath(@__DIR__, "test_create_parameters.sql")
    db_path = joinpath(@__DIR__, "test_create_parameters.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    @test_throws ErrorException PSRDatabaseSQLite.create_element!(
        db,
        "Configuration";
        label = "Toy Case",
        value1 = "wrong",
    )
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    PSRDatabaseSQLite.create_element!(db, "Resource"; label = "Resource 2")
    PSRDatabaseSQLite.create_element!(db, "Resource"; label = "Resource 1", type = "E")
    @test_throws ErrorException PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 4",
        type3 = "E",
    )
    @test_throws ErrorException PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 5",
        value1 = "wrong",
    )
    PSRDatabaseSQLite.close!(db)
    rm(db_path)
    @test true
    return nothing
end

function test_create_parameters_and_vectors()
    path_schema = joinpath(@__DIR__, "test_create_parameters_and_vectors.sql")
    db_path = joinpath(@__DIR__, "test_create_parameters_and_vectors.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 1",
        type = "E",
        some_value = [1.0, 2.0, 3.0],
    )
    PSRDatabaseSQLite.create_element!(db, "Cost"; label = "Cost 1", value = 30.0)
    PSRDatabaseSQLite.create_element!(db, "Cost"; label = "Cost 2", value = 20.0)
    PSRDatabaseSQLite.create_element!(
        db,
        "Plant";
        label = "Plant 1",
        capacity = 50.0,
        some_factor = [0.1, 0.3],
    )
    PSRDatabaseSQLite.create_element!(
        db,
        "Plant";
        label = "Plant 2",
        capacity = 50.0,
        some_factor = [0.1, 0.3, 0.5],
    )
    @test_throws ErrorException PSRDatabaseSQLite.create_element!(
        db,
        "Plant";
        label = "Plant 3",
        generation = "some_file.txt",
    )
    @test_throws ErrorException PSRDatabaseSQLite.create_element!(
        db,
        "Plant";
        label = "Plant 2",
        capacity = 50.0,
        some_factor = [],
    )
    PSRDatabaseSQLite.create_element!(db, "Plant"; label = "Plant 3", resource_id = 1)
    @test_throws ErrorException PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 1",
        type = "E",
        some_value = 1.0,
    )
    PSRDatabaseSQLite.close!(db)
    rm(db_path)
    @test true
    return nothing
end

function test_create_with_transaction()
    path_schema = joinpath(@__DIR__, "test_create_parameters_and_vectors.sql")
    db_path = joinpath(@__DIR__, "test_create_parameters_and_vectors.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    PSRDatabaseSQLite.SQLite.transaction(db.sqlite_db) do
        for i in 1:10
            PSRDatabaseSQLite.create_element!(
                db,
                "Plant";
                label = "Plant $i",
                capacity = 5.0 * i,
            )
        end
    end
    PSRDatabaseSQLite.close!(db)
    rm(db_path)
    @test true
end

function test_create_vectors_with_different_sizes_in_same_group()
    path_schema =
        joinpath(@__DIR__, "test_create_vectors_with_different_sizes_in_same_group.sql")
    db_path =
        joinpath(@__DIR__, "test_create_vectors_with_different_sizes_in_same_group.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    @test_throws ErrorException PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 1",
        type = "E",
        some_vector1 = [1.0],
        some_vector2 = [1.0, 2.0],
    )
    PSRDatabaseSQLite.close!(db)
    rm(db_path)
    @test true
    return nothing
end

function test_create_scalar_parameter_date()
    path_schema = joinpath(@__DIR__, "test_create_scalar_parameter_date.sql")
    db_path = joinpath(@__DIR__, "test_create_scalar_parameter_date.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(
        db,
        "Configuration";
        label = "Toy Case",
        date_initial = DateTime(2000),
        date_final = DateTime(2001, 10, 12, 23, 45, 12),
    )
    @test_throws ErrorException PSRDatabaseSQLite.create_element!(
        db,
        "Configuration";
        label = "Toy Case",
        date_initial = Date(2000),
        date_final = DateTime(2001, 10, 12, 23, 45, 12),
    )
    @test_throws ErrorException PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 1",
        date_initial_1 = "2000-01",
    )
    @test_throws ErrorException PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 2",
        date_initial_1 = "20001334",
    )
    PSRDatabaseSQLite.close!(db)
    rm(db_path)
    @test true
    return nothing
end

function test_create_small_time_series_as_vectors()
    path_schema = joinpath(@__DIR__, "test_create_small_time_series_as_vectors.sql")
    db_path = joinpath(@__DIR__, "test_create_small_time_series_as_vectors.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 1",
        type = "E",
        date_of_modification = [DateTime(2000), DateTime(2001)],
        some_value = [1.0, 2.0],
    )
    @test_throws ErrorException PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 2",
        type = "E",
        date_of_modification = [DateTime(2002), DateTime(2001)],
        some_value = [1.0, 2.0],
    )
    PSRDatabaseSQLite.close!(db)
    return rm(db_path)
end

function test_create_vectors_with_relations()
    path_schema = joinpath(@__DIR__, "test_create_vectors_with_relations.sql")
    db_path = joinpath(@__DIR__, "test_create_vectors_with_relations.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", some_value = 1.0)
    PSRDatabaseSQLite.create_element!(db, "Product"; label = "Sugar", unit = "Kg")
    PSRDatabaseSQLite.create_element!(db, "Product"; label = "Sugarcane", unit = "ton")
    PSRDatabaseSQLite.create_element!(db, "Product"; label = "Molasse", unit = "ton")
    PSRDatabaseSQLite.create_element!(db, "Product"; label = "Bagasse", unit = "ton")
    @test_throws ErrorException PSRDatabaseSQLite.create_element!(
        db,
        "Product",
        label = "Bagasse 2",
        unit = 30,
    )
    PSRDatabaseSQLite.create_element!(db, "Process";
        label = "Sugar Mill",
        product_input = ["Sugarcane"],
        factor_input = [1.0],
        product_output = ["Sugar", "Molasse", "Bagasse"],
        factor_output = [0.3, 0.3, 0.4],
    )

    @test_throws ErrorException PSRDatabaseSQLite.create_element!(db, "Process";
        label = "Sugar Mill 2",
        product_input = ["Sugar"],
        factor_input = ["wrong"],
        product_output = ["Sugarcane"],
        factor_output = [1.0],
    )

    @test_throws ErrorException PSRDatabaseSQLite.create_element!(db, "Process";
        label = "Sugar Mill 3",
        product_input = ["Some Sugar"],
        factor_input = [1.0],
        product_output = ["Sugarcane"],
        factor_output = [1.0],
    )

    @test_throws ErrorException PSRDatabaseSQLite.create_element!(db, "Process";
        label = "Sugar Mill 3",
        product_input = ["Some Sugar"],
        factor_input = [],
        product_output = ["Sugarcane"],
        factor_output = [1.0],
    )

    PSRDatabaseSQLite.close!(db)
    GC.gc()
    GC.gc()
    rm(db_path)
    @test true
    return nothing
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

TestCreate.runtests()

end
