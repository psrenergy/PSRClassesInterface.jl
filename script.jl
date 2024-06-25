using PSRClassesInterface.PSRDatabaseSQLite
using SQLite
using DataFrames
using Dates
using Test

db_path = joinpath(@__DIR__, "test_create_time_series.sqlite")
GC.gc()
GC.gc()
if isfile(db_path)
    rm(db_path)
end

function test_create_time_series()
    path_schema = raw"C:\Users\guilhermebodin\Documents\Github\PSRClassesInterface.jl\test\PSRDatabaseSQLite\test_create\test_create_time_series.sql" 
    db_path = joinpath(@__DIR__, "test_create_time_series.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    for i in 1:3
        df_timeseries_group1 = DataFrame(
            date = [DateTime(2000), DateTime(2001)],
            some_vector1 = [1.0, 2.0],
            some_vector2 = [2.0, 3.0]
        )
        df_timeseries_group2 = DataFrame(
            date = [DateTime(2000), DateTime(2000), DateTime(2001), DateTime(2001)],
            block = [1, 2, 1, 2],
            some_vector3 = [1.0, 2.0, 3.0, 4.0],
        )
        df_timeseries_group3 = DataFrame(
            date = [DateTime(2000), DateTime(2000), DateTime(2000), DateTime(2000), DateTime(2001), DateTime(2001), DateTime(2001), DateTime(2001)],
            block = [1, 1, 1, 1, 2, 2, 2, 2],
            segment = [1, 2, 3, 4, 1, 2, 3, 4],
            some_vector5 = [1.0, 2.0, 3.0, 4.0, 1, 2, 3, 4],
            some_vector6 = [1.0, 2.0, 3.0, 4.0, 1, 2, 3, 4],
        )
        PSRDatabaseSQLite.create_element!(
            db,
            "Resource";
            label = "Resource $i",
            group1 = df_timeseries_group1,
            group2 = df_timeseries_group2,
            group3 = df_timeseries_group3
        )
    end
    PSRDatabaseSQLite.close!(db)
    rm(db_path)
    @test true
end

test_create_time_series()