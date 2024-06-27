module TestRead

using PSRClassesInterface.PSRDatabaseSQLite
using SQLite
using Dates
using DataFrames
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
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.read_scalar_parameter(
        db,
        "Plant",
        "capacity",
        "Plant 5",
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.read_scalar_parameters(
        db,
        "Resource",
        "capacity",
    )
    @test PSRDatabaseSQLite.read_scalar_parameters(db, "Plant", "label") ==
          ["Plant 1", "Plant 2", "Plant 3", "Plant 4"]
    @test PSRDatabaseSQLite.read_scalar_parameters(db, "Plant", "capacity") ==
          [2.02, 53.0, 54.0, 53.0]
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.read_scalar_parameters(
        db,
        "Resource",
        "some_value",
    )
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.read_vector_parameters(
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
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.read_vector_parameter(
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
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.read_scalar_relations(
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
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.read_vector_relations(
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
    @test_throws PSRDatabaseSQLite.DatabaseException PSRDatabaseSQLite.read_time_series_file(
        db,
        "Plant",
        "spill",
    )
    PSRDatabaseSQLite.set_time_series_file!(db, "Plant"; wind_speed = "some_file3.txt")
    @test PSRDatabaseSQLite.read_time_series_file(db, "Plant", "wind_speed") ==
          "some_file3.txt"
    @test PSRDatabaseSQLite.read_time_series_file(db, "Plant", "wind_direction") ==
          "some_file2"
    PSRDatabaseSQLite.close!(db)
    return rm(db_path)
end

function test_read_timeseries_single()
    path_schema = joinpath(@__DIR__, "test_read_time_series.sql")
    db_path = joinpath(@__DIR__, "test_read_time_series.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)

    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)

    for i in 1:3
        df_timeseries_group1 = DataFrame(;
            date_time = [DateTime(2000), DateTime(2001)],
            some_vector1 = [1.0, 2.0] .* i,
            some_vector2 = [2.0, 3.0] .* i,
        )
        df_timeseries_group2 = DataFrame(;
            date_time = [DateTime(2000), DateTime(2000), DateTime(2001), DateTime(2001)],
            block = [1, 2, 1, 2],
            some_vector3 = [1.0, missing, 3.0, 4.0] .* i,
        )
        df_timeseries_group3 = DataFrame(;
            date_time = [
                DateTime(2000),
                DateTime(2000),
                DateTime(2000),
                DateTime(2000),
                DateTime(2001),
                DateTime(2001),
                DateTime(2001),
                DateTime(2009),
            ],
            block = [1, 1, 1, 1, 2, 2, 2, 2],
            segment = [1, 2, 3, 4, 1, 2, 3, 4],
            some_vector5 = [1.0, 2.0, 3.0, 4.0, 1, 2, 3, 4] .* i,
            some_vector6 = [1.0, 2.0, 3.0, 4.0, 1, 2, 3, 4] .* i,
        )
        PSRDatabaseSQLite.create_element!(
            db,
            "Resource";
            label = "Resource $i",
            group1 = df_timeseries_group1,
            group2 = df_timeseries_group2,
            group3 = df_timeseries_group3,
        )
    end

    # some errors

    df_empty = PSRDatabaseSQLite.read_time_series_df(
        db,
        "Resource",
        "some_vector1",
        "Resource 1";
        date_time = DateTime(1998),
    )
    @test isempty(df_empty)

    df_empty = PSRDatabaseSQLite.read_time_series_df(
        db,
        "Resource",
        "some_vector1",
        "Resource 1";
        date_time = DateTime(2030),
    )
    @test isempty(df_empty)

    df_empty = PSRDatabaseSQLite.read_time_series_df(
        db,
        "Resource",
        "some_vector5",
        "Resource 1";
        date_time = DateTime(2030),
        block = 20,
    )
    @test isempty(df_empty)

    df_wrong_date = PSRDatabaseSQLite.read_time_series_df(
        db,
        "Resource",
        "some_vector5",
        "Resource 1";
        date_time = DateTime(2003),
    )
    @test df_wrong_date.date_time[1] == string(DateTime(2001))

    # return single dataframe

    for i in 1:3
        df_timeseries_group1 = DataFrame(;
            date_time = [DateTime(2000), DateTime(2001)],
            some_vector1 = [1.0, 2.0] .* i,
            some_vector2 = [2.0, 3.0] .* i,
        )
        df_timeseries_group2 = DataFrame(;
            date_time = [DateTime(2000), DateTime(2000), DateTime(2001), DateTime(2001)],
            block = [1, 2, 1, 2],
            some_vector3 = [1.0, missing, 3.0, 4.0] .* i,
        )
        df_timeseries_group3 = DataFrame(;
            date_time = [
                DateTime(2000),
                DateTime(2000),
                DateTime(2000),
                DateTime(2000),
                DateTime(2001),
                DateTime(2001),
                DateTime(2001),
                DateTime(2009),
            ],
            block = [1, 1, 1, 1, 2, 2, 2, 2],
            segment = [1, 2, 3, 4, 1, 2, 3, 4],
            some_vector5 = [1.0, 2.0, 3.0, 4.0, 1, 2, 3, 4] .* i,
            some_vector6 = [1.0, 2.0, 3.0, 4.0, 1, 2, 3, 4] .* i,
        )

        for row in eachrow(df_timeseries_group1)
            df = PSRDatabaseSQLite.read_time_series_df(
                db,
                "Resource",
                "some_vector1",
                "Resource $i";
                row.date_time,
            )
            @test df.date_time == string.([row.date_time])
            @test df.some_vector1 == [row.some_vector1]

            df = PSRDatabaseSQLite.read_time_series_df(
                db,
                "Resource",
                "some_vector2",
                "Resource $i";
                row.date_time,
            )
            @test df.date_time == string.([row.date_time])
            @test df.some_vector2 == [row.some_vector2]
        end

        for row in eachrow(df_timeseries_group2)

            # single element query

            df = PSRDatabaseSQLite.read_time_series_df(
                db,
                "Resource",
                "some_vector3",
                "Resource $i";
                row.date_time,
                block = row.block,
            )
            if ismissing(row.some_vector3)
                @test ismissing(df.some_vector3[1])
            else
                @test df.some_vector3 == [row.some_vector3]
            end
            @test df.block == [row.block]

            df = PSRDatabaseSQLite.read_time_series_df(
                db,
                "Resource",
                "some_vector4",
                "Resource $i";
                row.date_time,
                block = row.block,
            )
            @test ismissing(df.some_vector4[1])

            # two-element query

            df = PSRDatabaseSQLite.read_time_series_df(
                db,
                "Resource",
                "some_vector3",
                "Resource $i";
                row.date_time,
            )
            df_to_compare = df_timeseries_group2[
                (df_timeseries_group2.date_time.==row.date_time), :]
            @test size(df, 1) == size(df_to_compare, 1)
            for df_i in 1:size(df, 1)
                if ismissing(df_to_compare.some_vector3[df_i])
                    @test ismissing(df.some_vector3[df_i])
                else
                    @test df.some_vector3[df_i] == df_to_compare.some_vector3[df_i]
                end
                @test df.block[df_i] == df_to_compare.block[df_i]
            end

            # all elements query

            df = PSRDatabaseSQLite.read_time_series_df(
                db,
                "Resource",
                "some_vector3",
                "Resource $i";
            )
            for df_i in 1:size(df, 1)
                if ismissing(df_timeseries_group2.some_vector3[df_i])
                    @test ismissing(df.some_vector3[df_i])
                else
                    @test df.some_vector3[df_i] == df_timeseries_group2.some_vector3[df_i]
                end
                @test df.block[df_i] == df_timeseries_group2.block[df_i]
                @test df.date_time[df_i] == string.(df_timeseries_group2.date_time[df_i])
            end
        end

        for row in eachrow(df_timeseries_group3)

            # single element query

            df = PSRDatabaseSQLite.read_time_series_df(
                db,
                "Resource",
                "some_vector5",
                "Resource $i";
                row.date_time,
                block = row.block,
                segment = row.segment,
            )
            @test df.date_time == string.([row.date_time])
            @test df.block == [row.block]
            @test df.segment == [row.segment]
            @test df.some_vector5 == [row.some_vector5]

            df = PSRDatabaseSQLite.read_time_series_df(
                db,
                "Resource",
                "some_vector6",
                "Resource $i";
                row.date_time,
                block = row.block,
                segment = row.segment,
            )
            @test df.date_time == string.([row.date_time])
            @test df.block == [row.block]
            @test df.segment == [row.segment]
            @test df.some_vector6 == [row.some_vector6]

            # two-element query

            df = PSRDatabaseSQLite.read_time_series_df(
                db,
                "Resource",
                "some_vector5",
                "Resource $i";
                row.date_time,
                block = row.block,
            )
            df_to_compare = df_timeseries_group3[
                (df_timeseries_group3.date_time.==row.date_time).&(df_timeseries_group3.block.==row.block), :]
            @test size(df, 1) == size(df_to_compare, 1)
            for df_i in 1:size(df, 1)
                @test df.some_vector5[df_i] == df_to_compare.some_vector5[df_i]
                @test df.block[df_i] == df_to_compare.block[df_i]
            end

            df = PSRDatabaseSQLite.read_time_series_df(
                db,
                "Resource",
                "some_vector5",
                "Resource $i";
                row.date_time,
                segment = row.segment,
            )

            df_to_compare = df_timeseries_group3[
                (df_timeseries_group3.date_time.==row.date_time).&(df_timeseries_group3.segment.==row.segment), :]
            @test size(df, 1) == size(df_to_compare, 1)
            for df_i in 1:size(df, 1)
                @test df.some_vector5[df_i] == df_to_compare.some_vector5[df_i]
                @test df.block[df_i] == df_to_compare.block[df_i]
            end

            df = PSRDatabaseSQLite.read_time_series_df(
                db,
                "Resource",
                "some_vector6",
                "Resource $i";
                row.date_time,
                block = row.block,
                segment = row.segment,
            )

            df_to_compare = df_timeseries_group3[
                (df_timeseries_group3.date_time.==row.date_time).&(df_timeseries_group3.block.==row.block).&(df_timeseries_group3.segment.==row.segment),
                :]
            @test size(df, 1) == size(df_to_compare, 1)
            for df_i in 1:size(df, 1)
                @test df.some_vector6[df_i] == df_to_compare.some_vector6[df_i]
                @test df.block[df_i] == df_to_compare.block[df_i]
                @test df.segment[df_i] == df_to_compare.segment[df_i]
                @test df.date_time[df_i] == string.(df_to_compare.date_time[df_i])
            end

            # three-element query

            df = PSRDatabaseSQLite.read_time_series_df(
                db,
                "Resource",
                "some_vector5",
                "Resource $i";
                row.date_time,
            )
            df_to_compare = df_timeseries_group3[
                (df_timeseries_group3.date_time.==row.date_time), :]
            @test size(df, 1) == size(df_to_compare, 1)
            for df_i in 1:size(df, 1)
                @test df.some_vector5[df_i] == df_to_compare.some_vector5[df_i]
                @test df.block[df_i] == df_to_compare.block[df_i]
                @test df.segment[df_i] == df_to_compare.segment[df_i]
            end

            # all elements query

            df = PSRDatabaseSQLite.read_time_series_df(
                db,
                "Resource",
                "some_vector5",
                "Resource $i";
            )
            for df_i in 1:size(df, 1)
                @test df.some_vector5[df_i] == df_timeseries_group3.some_vector5[df_i]
                @test df.block[df_i] == df_timeseries_group3.block[df_i]
                @test df.segment[df_i] == df_timeseries_group3.segment[df_i]
                @test df.date_time[df_i] == string.(df_timeseries_group3.date_time[df_i])
            end
        end
    end

    PSRDatabaseSQLite.close!(db)
    GC.gc()
    GC.gc()
    rm(db_path)
    @test true
    return nothing
end

function test_read_timeseries_multiple()
    path_schema = joinpath(@__DIR__, "test_read_time_series.sql")
    db_path = joinpath(@__DIR__, "test_read_time_series.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)

    PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)

    for i in 1:3
        df_timeseries_group1 = DataFrame(;
            date_time = [DateTime(2000), DateTime(2001)],
            some_vector1 = [1.0, 2.0] .* i,
            some_vector2 = [2.0, 3.0] .* i,
        )
        df_timeseries_group2 = DataFrame(;
            date_time = [DateTime(2000), DateTime(2000), DateTime(2001), DateTime(2001)],
            block = [1, 2, 1, 2],
            some_vector3 = [1.0, missing, 3.0, 4.0] .* i,
        )
        df_timeseries_group3 = DataFrame(;
            date_time = [
                DateTime(2000),
                DateTime(2000),
                DateTime(2000),
                DateTime(2000),
                DateTime(2001),
                DateTime(2001),
                DateTime(2001),
                DateTime(2009),
            ],
            block = [1, 1, 1, 1, 2, 2, 2, 2],
            segment = [1, 2, 3, 4, 1, 2, 3, 4],
            some_vector5 = [1.0, 2.0, 3.0, 4.0, 1, 2, 3, 4] .* i,
            some_vector6 = [1.0, 2.0, 3.0, 4.0, 1, 2, 3, 4] .* i,
        )
        PSRDatabaseSQLite.create_element!(
            db,
            "Resource";
            label = "Resource $i",
            group1 = df_timeseries_group1,
            group2 = df_timeseries_group2,
            group3 = df_timeseries_group3,
        )
    end

    # return multiple DataFrames

    dates_df1 = [DateTime(2000), DateTime(2001)]
    some_vector1 = [[1.0, 2.0, 3.0] .* i for i in 1:3]
    some_vector2 = [[2.0, 3.0, 4.0] .* i for i in 1:3]

    for i in eachindex(dates_df1)
        dfs = PSRDatabaseSQLite.read_time_series_dfs(
            db,
            "Resource",
            "some_vector1";
            date_time = dates_df1[i],
        )

        for j in 1:3
            df = dfs[j]
            @test df.date_time == string.([dates_df1[i]])
            @test df.some_vector1 == [some_vector1[j][i]]
        end

        dfs = PSRDatabaseSQLite.read_time_series_dfs(
            db,
            "Resource",
            "some_vector2";
            date_time = dates_df1[i],
        )

        for j in 1:3
            df = dfs[j]
            @test df.date_time == string.([dates_df1[i]])
            @test df.some_vector2 == [some_vector2[j][i]]
        end
    end

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

TestRead.runtests()

end
