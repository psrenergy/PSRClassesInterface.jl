module TestCreate

using PSRClassesInterface.OpenSQL
using SQLite
using Dates
using Test

function test_create_parameters()
    path_schema = joinpath(@__DIR__, "test_create_parameters.sql")
    db_path = joinpath(@__DIR__, "test_create_parameters.sqlite")
    db = OpenSQL.create_empty_db(db_path, path_schema; force = true)
    OpenSQL.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    OpenSQL.create_element!(db, "Resource"; label = "Resource 1", type = "E")
    OpenSQL.close!(db)
    rm(db_path)
    @test true
    return nothing
end

function test_create_non_existing_parameters()
    path_schema = joinpath(@__DIR__, "test_create_parameters.sql")
    db_path = joinpath(@__DIR__, "test_create_parameters.sqlite")
    db = OpenSQL.create_empty_db(db_path, path_schema; force = true)
    @test_throws ErrorException OpenSQL.create_element!(db, "Configuration"; label = "Toy Case", value5 = 1.0)
    @test_throws ErrorException OpenSQL.create_element!(db, "Resource"; label = "Resource 1", type3 = "E")
    OpenSQL.close!(db)
    rm(db_path)
    return nothing
end

function test_create_parameters_wrong_type()
    path_schema = joinpath(@__DIR__, "test_create_parameters.sql")
    db_path = joinpath(@__DIR__, "test_create_parameters.sqlite")
    db = OpenSQL.create_empty_db(db_path, path_schema; force = true)
    @test_throws SQLite.SQLiteException OpenSQL.create_element!(db, "Configuration"; label = "Toy Case", value1 = "wrong")
    OpenSQL.close!(db)
    rm(db_path)
    return nothing
end

function test_create_parameters_and_vectors()
    path_schema = joinpath(@__DIR__, "test_create_parameters_and_vectors.sql")
    db_path = joinpath(@__DIR__, "test_create_parameters_and_vectors.sqlite")
    db = OpenSQL.create_empty_db(db_path, path_schema; force = true)
    OpenSQL.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    OpenSQL.create_element!(db, "Resource"; label = "Resource 1", type = "E", some_value = [1.0, 2.0, 3.0])
    OpenSQL.create_element!(db, "Cost"; label = "Cost 1", value = 30)
    OpenSQL.create_element!(db, "Cost"; label = "Cost 2", value = 20)
    OpenSQL.create_element!(db, "Plant"; label = "Plant 1", capacity = 50.0, some_factor = [0.1, 0.3])
    OpenSQL.create_element!(db, "Plant"; label = "Plant 2", capacity = 50.0, some_factor = [0.1, 0.3, 0.5])
    @test_throws ErrorException OpenSQL.create_element!(db, "Plant"; label = "Plant 3", resource_id = 1)
    OpenSQL.close!(db)
    rm(db_path)
    @test true
    return nothing
end

function test_create_vectors_with_different_sizes_in_same_group()
    path_schema = joinpath(@__DIR__, "test_create_vectors_with_different_sizes_in_same_group.sql")
    db_path = joinpath(@__DIR__, "test_create_vectors_with_different_sizes_in_same_group.sqlite")
    db = OpenSQL.create_empty_db(db_path, path_schema; force = true)
    OpenSQL.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    @test_throws ErrorException OpenSQL.create_element!(db, "Resource"; label = "Resource 1", type = "E", some_vector1 = [1.0], some_vector2 = [1.0, 2.0])
    OpenSQL.close!(db)
    rm(db_path)
    @test true
    return nothing
end

function test_create_scalar_parameter_date()
    path_schema = joinpath(@__DIR__, "test_create_scalar_parameter_date.sql")
    db_path = joinpath(@__DIR__, "test_create_scalar_parameter_date.sqlite")
    db = OpenSQL.create_empty_db(db_path, path_schema; force = true)
    OpenSQL.create_element!(db, "Configuration"; label = "Toy Case", date_initial = Date(2000), date_final = DateTime(2001, 10, 12, 23, 45, 12))
    OpenSQL.create_element!(db, "Resource"; label = "Resource 1", date_initial_1 = "2000-01")
    @test_throws ArgumentError OpenSQL.create_element!(db, "Resource"; label = "Resource 2", date_initial_1 = "20001334")
    OpenSQL.close!(db)
    rm(db_path)
    @test true
    return nothing
end

function test_create_small_time_series_as_vectors()
    path_schema = joinpath(@__DIR__, "test_create_small_time_series_as_vectors.sql")
    db_path = joinpath(@__DIR__, "test_create_small_time_series_as_vectors.sqlite")
    db = OpenSQL.create_empty_db(db_path, path_schema; force = true)
    OpenSQL.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    OpenSQL.create_element!(db, "Resource"; label = "Resource 1", type = "E", date_of_modification = [Date(2000), Date(2001)], some_value = [1.0, 2.0])
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

TestCreate.runtests()

end