module TestValidDatabaseDefinitions

using PSRClassesInterface.OpenSQL
using SQLite
using Test

function test_invalid_database_without_configuration_table()
    path_schema =
        joinpath(@__DIR__, "test_invalid_database_without_configuration_table.sql")
    db_path = joinpath(@__DIR__, "test_invalid_database_without_configuration_table.sqlite")
    @test_throws ErrorException OpenSQL.create_empty_db_from_schema(
        db_path,
        path_schema;
        force = true,
    )
    rm(db_path)
    return nothing
end

function test_invalid_database_with_duplicated_attributes()
    path_schema = joinpath(@__DIR__, "test_create_duplicated_attributes.sql")
    db_path = joinpath(@__DIR__, "test_create_duplicated_attributes.sqlite")
    @test_throws ErrorException OpenSQL.create_empty_db_from_schema(
        db_path,
        path_schema;
        force = true,
    )
    rm(db_path)
    return nothing
end

function test_invalid_database_with_invalid_collection_name()
    path_schema =
        joinpath(@__DIR__, "test_invalid_database_with_invalid_collection_name.sql")
    db_path =
        joinpath(@__DIR__, "test_invalid_database_with_invalid_collection_name.sqlite")
    @test_throws ErrorException OpenSQL.create_empty_db_from_schema(
        db_path,
        path_schema;
        force = true,
    )
    rm(db_path)
    return nothing
end

function test_invalid_database_vector_table_without_vector_index()
    path_schema =
        joinpath(@__DIR__, "test_invalid_database_vector_table_without_vector_index.sql")
    db_path =
        joinpath(@__DIR__, "test_invalid_database_vector_table_without_vector_index.sqlite")
    @test_throws ErrorException OpenSQL.create_empty_db_from_schema(
        db_path,
        path_schema;
        force = true,
    )
    rm(db_path)
    return nothing
end

function test_invalid_duplicated_collection_definition()
    path_schema = joinpath(@__DIR__, "test_invalid_duplicated_collection_definition.sql")
    db_path = joinpath(@__DIR__, "test_invalid_duplicated_collection_definition.sqlite")
    @test_throws SQLite.SQLiteException OpenSQL.create_empty_db_from_schema(
        db_path,
        path_schema;
        force = true,
    )
    rm(db_path)
    return nothing
end

function test_valid_database()
    path_schema = joinpath(@__DIR__, "test_valid_database.sql")
    db_path = joinpath(@__DIR__, "test_valid_database.sqlite")
    db = OpenSQL.create_empty_db_from_schema(db_path, path_schema; force = true)
    OpenSQL.close!(db)
    @test true
    rm(db_path)
    return nothing
end

function test_invalid_foreign_key_has_not_null_constraint()
    path_schema = joinpath(@__DIR__, "test_invalid_foreign_key_has_not_null_constraint.sql")
    db_path = joinpath(@__DIR__, "test_invalid_foreign_key_has_not_null_constraint.sqlite")
    @test_throws ErrorException OpenSQL.create_empty_db_from_schema(
        db_path,
        path_schema;
        force = true,
    )
    @test true
    rm(db_path)
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

TestValidDatabaseDefinitions.runtests()

end
