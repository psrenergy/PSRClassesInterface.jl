using PSRClassesInterface.PSRDatabaseSQLite
using SQLite
using DataFrames
using Dates
using Test

function test_create_time_series()
    path_schema = joinpath(@__DIR__, "time_controller.sql")
    db_path = joinpath(@__DIR__, "test_create_time_series.sqlite")
    GC.gc()
    GC.gc()
    if isfile(db_path)
        rm(db_path)
    end
    
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    PSRDatabaseSQLite.SQLite.transaction(db.sqlite_db) do
        for i in 1:500
            df_timeseries_group1 = DataFrame(
                date_time = vcat([DateTime(0)],[DateTime(i) for i in 1900:1979]),
                some_vector1 = vcat([missing],[j for j in 1:80] .* i),
                some_vector2 = vcat([1.0],[missing for j in 1:10], [j for j in 1:10] .* i, [missing for j in 1:60]),
                some_vector3 = vcat([1.0], [missing for j in 1:80]),
                some_vector4 = vcat([missing], [missing for j in 1:80]),
            )
            PSRDatabaseSQLite.create_element!(
                db,
                "Resource";
                label = "Resource $i",
                group1 = df_timeseries_group1,
            )
        end
    end

    PSRDatabaseSQLite.close!(db) 
end

function test_read_time_series()
    db_path = joinpath(@__DIR__, "test_create_time_series.sqlite")

    db = PSRDatabaseSQLite.load_db(db_path; read_only = true)

    for date_time in [DateTime(i) for i in 1900:1901]
        @show date_time
        for i in 1:50
            PSRDatabaseSQLite.read_mapped_timeseries(
                db,
                "Resource",
                "some_vector1",
                date_time = date_time
            )

            PSRDatabaseSQLite.read_mapped_timeseries(
                db,
                "Resource",
                "some_vector2",
                date_time = date_time
            )

            PSRDatabaseSQLite.read_mapped_timeseries(
                db,
                "Resource",
                "some_vector3",
                date_time = date_time
            )
        end
    end


    PSRDatabaseSQLite.close!(db)
    rm(db_path)
end

test_create_time_series()
test_read_time_series()