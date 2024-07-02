module TestTimeController

using PSRClassesInterface.PSRDatabaseSQLite
using SQLite
using Dates
using DataFrames
using Test

function test_time_controller_read()
    path_schema = joinpath(@__DIR__, "test_time_controller.sql")
    db_path = joinpath(@__DIR__, "test_time_controller.sqlite")
    GC.gc()
    GC.gc()
    if isfile(db_path)
        rm(db_path)
    end

    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    PSRDatabaseSQLite.SQLite.transaction(db.sqlite_db) do
        for i in 1:500
            df_timeseries_group1 = DataFrame(;
                date_time = vcat([DateTime(0)], [DateTime(i) for i in 1900:1979]),
                some_vector1 = vcat([missing], [j for j in 1:80] .* i),
                some_vector2 = vcat([1.0], [missing for j in 1:10], [j for j in 1:10] .* i, [missing for j in 1:60]),
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
    db = PSRDatabaseSQLite.load_db(db_path; read_only = true)

    for (j, date_time) in enumerate([DateTime(i) for i in 1900:1979])
        some_vector1_check = vcat(Float64[j * k for k in 1:500])

        some_vector2_check = if j <= 10
            vcat([1.0 for k in 1:500])
        elseif j <= 20 && j > 10
            l_idx = indexin(j, 11:20)[1]
            vcat(Float64[l_idx * k for k in 1:500])
        else
            vcat([10.0 * k for k in 1:500])
        end
        some_vector3_check = vcat([1.0 for k in 1:500])
        some_vector4_check = vcat([missing for k in 1:500])

        cached_data_new = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector1",
            Float64;
            date_time = date_time,
        )
        for k in 1:500
            @test cached_data_new[k] == some_vector1_check[k]
        end

        cached_data_new = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector2",
            Float64;
            date_time = date_time,
        )
        for k in 1:500
            @test cached_data_new[k] == some_vector2_check[k]
        end

        cached_data_new = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector3",
            Float64;
            date_time = date_time,
        )

        for k in 1:500
            @test cached_data_new[k] == some_vector3_check[k]
        end

        cached_data_new = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector4",
            Float64;
            date_time = date_time,
        )

        for k in 1:500
            @test isnan(cached_data_new[k])
        end
    end

    PSRDatabaseSQLite.close!(db)
    return rm(db_path)
end

function test_time_controller_missing()
    path_schema = joinpath(@__DIR__, "test_time_controller.sql")
    db_path = joinpath(@__DIR__, "test_time_controller_missing.sqlite")
    GC.gc()
    GC.gc()
    if isfile(db_path)
        rm(db_path)
    end

    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
    PSRDatabaseSQLite.SQLite.transaction(db.sqlite_db) do
        df_timeseries_group1 = DataFrame(;
            date_time = vcat([DateTime(0)], [DateTime(2000), DateTime(2001), DateTime(2002)]),
            some_vector1 = vcat([missing], [3.0, 2.0, 1.0]),
        )
        PSRDatabaseSQLite.create_element!(
            db,
            "Resource";
            label = "Resource 1",
            group1 = df_timeseries_group1,
        )

        df_timeseries_group1 = DataFrame(;
            date_time = vcat([DateTime(0)], [DateTime(2000), DateTime(2001), DateTime(2002)]),
            some_vector1 = vcat([missing], [3.0, missing, 1.0]),
        )
        PSRDatabaseSQLite.create_element!(
            db,
            "Resource";
            label = "Resource 2",
            group1 = df_timeseries_group1,
        )

        df_timeseries_group1 = DataFrame(;
            date_time = vcat([DateTime(0)], [DateTime(2000), DateTime(2002)]),
            some_vector1 = vcat([missing], [1.0, 3.0]),
        )
        PSRDatabaseSQLite.create_element!(
            db,
            "Resource";
            label = "Resource 3",
            group1 = df_timeseries_group1,
        )

        df_timeseries_group1 = DataFrame(;
            date_time = vcat([DateTime(0)], [DateTime(2000), DateTime(2001), DateTime(2002)]),
            some_vector1 = [missing for i in 1:4],
        )
        return PSRDatabaseSQLite.create_element!(
            db,
            "Resource";
            label = "Resource 4",
            group1 = df_timeseries_group1,
        )
    end

    PSRDatabaseSQLite.close!(db)
    db = PSRDatabaseSQLite.load_db(db_path; read_only = true)

    cached_data_new = PSRDatabaseSQLite.read_mapped_timeseries(
        db,
        "Resource",
        "some_vector1",
        Float64;
        date_time = DateTime(2000),
    )
    @test cached_data_new[1] == 3.0
    @test cached_data_new[2] == 3.0
    @test cached_data_new[3] == 1.0
    @test isnan(cached_data_new[4])

    cached_data_new = PSRDatabaseSQLite.read_mapped_timeseries(
        db,
        "Resource",
        "some_vector1",
        Float64;
        date_time = DateTime(2001),
    )
    @test cached_data_new[1] == 2.0
    @test cached_data_new[2] == 3.0
    @test cached_data_new[3] == 1.0
    @test isnan(cached_data_new[4])

    cached_data_new = PSRDatabaseSQLite.read_mapped_timeseries(
        db,
        "Resource",
        "some_vector1",
        Float64;
        date_time = DateTime(2002),
    )
    @test cached_data_new[1] == 1.0
    @test cached_data_new[2] == 1.0
    @test cached_data_new[3] == 3.0
    @test isnan(cached_data_new[4])

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

TestTimeController.runtests()

end
