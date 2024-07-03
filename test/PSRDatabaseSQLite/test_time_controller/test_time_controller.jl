module TestTimeController

using PSRClassesInterface.PSRDatabaseSQLite
using SQLite
using Dates
using DataFrames
using Test

function _test_cache(cached_data, answer)
    @test length(cached_data) == length(answer)
    for i in eachindex(cached_data)
        if isnan(answer[i])
            @test isnan(cached_data[i])
        else
            @test cached_data[i] == answer[i]
        end
    end
end

# For each date, test the returned value with the expected value
function test_time_controller_read()
    path_schema = joinpath(@__DIR__, "test_time_controller.sql")
    db_path = joinpath(@__DIR__, "test_time_controller_read.sqlite")
    GC.gc()
    GC.gc()
    if isfile(db_path)
        rm(db_path)
    end

    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)

    df = DataFrame(;
        date_time = [DateTime(2000), DateTime(2001), DateTime(2002)],
        some_vector1 = [missing, 1.0, 2.0],
        some_vector2 = [1.0, 2.0, 3.0],
        some_vector3 = [3.0, 2.0, 1.0],
        some_vector4 = [1.0, missing, 5.0],
        some_vector5 = [missing, missing, missing],
        some_vector6 = [6.0, missing, missing],
    )
    PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 1",
        group1 = df,
    )

    PSRDatabaseSQLite.close!(db)
    db = PSRDatabaseSQLite.load_db(db_path; read_only = true)

    some_vector1_answer = [[NaN], [1.0], [2.0]]
    some_vector2_answer = [[1.0], [2.0], [3.0]]
    some_vector3_answer = [[3.0], [2.0], [1.0]]
    some_vector4_answer = [[1.0], [1.0], [5.0]]
    some_vector5_answer = [[NaN], [NaN], [NaN]]
    some_vector6_answer = [[6.0], [6.0], [6.0]]

    # test for dates in correct sequence
    for d_i in eachindex(df.date_time)
        cached_1 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector1",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_1, some_vector1_answer[d_i])

        cached_2 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector2",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_2, some_vector2_answer[d_i])

        cached_3 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector3",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_3, some_vector3_answer[d_i])

        cached_4 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector4",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_4, some_vector4_answer[d_i])

        cached_5 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector5",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_5, some_vector5_answer[d_i])

        cached_6 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector6",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_6, some_vector6_answer[d_i])
    end

    # test for dates in reverse sequence
    for d_i in reverse(eachindex(df.date_time))
        cached_1 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector1",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_1, some_vector1_answer[d_i])

        cached_2 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector2",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_2, some_vector2_answer[d_i])

        cached_3 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector3",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_3, some_vector3_answer[d_i])

        cached_4 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector4",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_4, some_vector4_answer[d_i])

        cached_5 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector5",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_5, some_vector5_answer[d_i])

        cached_6 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector6",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_6, some_vector6_answer[d_i])
    end

    # test for dates in random sequence
    for d_i in [2, 1, 3]
        cached_1 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector1",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_1, some_vector1_answer[d_i])

        cached_2 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector2",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_2, some_vector2_answer[d_i])

        cached_3 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector3",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_3, some_vector3_answer[d_i])

        cached_4 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector4",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_4, some_vector4_answer[d_i])

        cached_5 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector5",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_5, some_vector5_answer[d_i])

        cached_6 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector6",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_6, some_vector6_answer[d_i])
    end

    PSRDatabaseSQLite.close!(db)
    return rm(db_path)
end

function test_time_controller_read_more_agents()
    path_schema = joinpath(@__DIR__, "test_time_controller.sql")
    db_path = joinpath(@__DIR__, "test_time_controller_read_multiple.sqlite")
    GC.gc()
    GC.gc()
    if isfile(db_path)
        rm(db_path)
    end

    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)

    df = DataFrame(;
        date_time = [DateTime(2000), DateTime(2001), DateTime(2002)],
        some_vector1 = [missing, 1.0, 2.0],
        some_vector2 = [1.0, missing, 5.0],
    )
    PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 1",
        group1 = df,
    )

    df2 = DataFrame(;
        date_time = [DateTime(2000), DateTime(2001), DateTime(2002)],
        some_vector1 = [missing, 10.0, 20.0],
        some_vector2 = [10.0, missing, 50.0],
    )
    PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 2",
        group1 = df2,
    )

    PSRDatabaseSQLite.close!(db)
    db = PSRDatabaseSQLite.load_db(db_path; read_only = true)

    some_vector1_answer = [[NaN, NaN], [1.0, 10.0], [2.0, 20.0]]
    some_vector2_answer = [[1.0, 10.0], [1.0, 10.0], [5.0, 50.0]]

    # test for dates in correct sequence
    for d_i in eachindex(df.date_time)
        cached_1 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector1",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_1, some_vector1_answer[d_i])

        cached_2 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector2",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_2, some_vector2_answer[d_i])
    end

    PSRDatabaseSQLite.close!(db)
    return rm(db_path)
end

function test_time_controller_empty()
    path_schema = joinpath(@__DIR__, "test_time_controller.sql")
    db_path = joinpath(@__DIR__, "test_time_controller_read_empty.sqlite")
    GC.gc()
    GC.gc()
    if isfile(db_path)
        rm(db_path)
    end

    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)

    PSRDatabaseSQLite.close!(db)
    db = PSRDatabaseSQLite.load_db(db_path; read_only = true)

    empty_cache = PSRDatabaseSQLite.read_mapped_timeseries(
        db,
        "Resource",
        "some_vector1",
        Float64;
        date_time = DateTime(2000),
    )
    _test_cache(empty_cache, [])

    PSRDatabaseSQLite.close!(db)
    return rm(db_path)
end

function test_time_controller_filled_then_empty()
    path_schema = joinpath(@__DIR__, "test_time_controller.sql")
    db_path = joinpath(@__DIR__, "test_time_controller_read_filled_then_empty.sqlite")
    GC.gc()
    GC.gc()
    if isfile(db_path)
        rm(db_path)
    end

    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)
    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)

    df = DataFrame(;
        date_time = [DateTime(2000), DateTime(2001), DateTime(2002)],
        some_vector1 = [missing, 1.0, 2.0],
        some_vector2 = [1.0, missing, 5.0],
    )
    PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 1",
        group1 = df,
    )

    df2 = DataFrame(;
        date_time = [DateTime(2000), DateTime(2001), DateTime(2002)],
        some_vector1 = [missing, 10.0, 20.0],
        some_vector2 = [10.0, missing, 50.0],
    )
    PSRDatabaseSQLite.create_element!(
        db,
        "Resource";
        label = "Resource 2",
        group1 = df2,
    )

    PSRDatabaseSQLite.close!(db)
    db = PSRDatabaseSQLite.load_db(db_path; read_only = true)

    some_vector1_answer = [[NaN, NaN], [1.0, 10.0], [2.0, 20.0]]
    some_vector2_answer = [[1.0, 10.0], [1.0, 10.0], [5.0, 50.0]]

    # test for dates in correct sequence
    for d_i in eachindex(df.date_time)
        cached_1 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector1",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_1, some_vector1_answer[d_i])

        cached_2 = PSRDatabaseSQLite.read_mapped_timeseries(
            db,
            "Resource",
            "some_vector2",
            Float64;
            date_time = DateTime(df.date_time[d_i]),
        )
        _test_cache(cached_2, some_vector2_answer[d_i])
    end

    PSRDatabaseSQLite.close!(db)

    db = PSRDatabaseSQLite.load_db(db_path; read_only = false)

    PSRDatabaseSQLite.delete_element!(db, "Resource", "Resource 1")
    PSRDatabaseSQLite.delete_element!(db, "Resource", "Resource 2")

    PSRDatabaseSQLite.close!(db)

    db = PSRDatabaseSQLite.load_db(db_path; read_only = true)

    empty_cache = PSRDatabaseSQLite.read_mapped_timeseries(
        db,
        "Resource",
        "some_vector1",
        Float64;
        date_time = DateTime(2000),
    )
    _test_cache(empty_cache, [])

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
