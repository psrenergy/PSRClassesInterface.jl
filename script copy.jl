using PSRClassesInterface.PSRDatabaseSQLite
using SQLite
using DataFrames
using Dates
using Test

abstract type TimeSeriesRequestStatus end


const CollectionAttributeElement = Tuple{String, String, Int}

struct TimeSeriesDidNotChange <: TimeSeriesRequestStatus end
struct TimeSeriesChanged <: TimeSeriesRequestStatus end

mutable struct TimeSeriesElementCache
    # The last date requested by the user
    last_date_requested::DateTime
    # The next available date after the last date requested
    next_date_possible::DateTime
end

# mutable struct TimeSeriesCache{T, N}
#     # Tell which dimensions were mapped in a given vector
#     # This is probably wrong
#     dimensions_mapped
#     data::Array{T, N} = fill(_psrdatabasesqlite_null_value(T), zeros(Int, N)...)
# end


# db_path = joinpath(@__DIR__, "test_create_time_series.sqlite")
# GC.gc()
# GC.gc()
# if isfile(db_path)
#     rm(db_path)
# end

function test_create_time_series()
    path_schema = raw"C:\Users\pedroripper\Documents\Github\PSRClassesInterface.jl\time_controller.sql" 
    db_path = joinpath(@__DIR__, "test_create_time_series.sqlite")
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
            println(i)
        end
    end

    PSRDatabaseSQLite.close!(db) 
end

function test_read_time_series()
    
    db_path = joinpath(@__DIR__, "test_create_time_series.sqlite")

    db = PSRDatabaseSQLite.load_db(db_path)

    some_vector1 = vcat([missing],[j for j in 1:80] .* i)
    some_vector2 = vcat([1.0],[missing for j in 1:10], [j for j in 1:10] .* i, [missing for j in 1:60])
    some_vector3 = vcat([1.0], [missing for j in 1:80])
    some_vector4 = vcat([missing], [missing for j in 1:80])

    # todos os agentes p cada tempo


    # tenta ler 10 vezes cada data


    for date_time in [DateTime(i) for i in 1900:1979]
        for i in 1:500
            results = PSRDatabaseSQLite.read_time_series_df(
                db,
                "Resource",
                "some_vector1",
                "Resource $i";
                date_time = date_time
                )
            @assert results.date_time[1] == string.([date_time])

            results = PSRDatabaseSQLite.read_time_series_df(
                db,
                "Resource",
                "some_vector2",
                "Resource $i";
                date_time = date_time
                )
            @assert results.date_time[1] == string.([date_time])

            results = PSRDatabaseSQLite.read_time_series_df(
                db,
                "Resource",
                "some_vector2",
                "Resource $i";
                date_time = date_time
                )
            @assert results.date_time[1] == string.([date_time])
            println(date_time)
        end

    end


    PSRDatabaseSQLite.close!(db)
    # rm(db_path)
    # @test true
end

test_create_time_series()
# test_read_time_series()