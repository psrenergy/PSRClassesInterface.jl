"""
    execute_statements(db::SQLite.DB, file::String)

Execute all statements in a .sql file against a database.
"""
function execute_statements(db::SQLite.DB, file::String)
    if !isfile(file)
        error("file not found: $file")
    end
    #! format: off
    # We turn off formatting here because of this discussion
    # https://github.com/domluna/JuliaFormatter.jl/issues/751
    # I agree that open do blocks with return are slighly misleading.
    raw_statements = open(joinpath(file), "r") do io
        read(io, String)
    end
    #! format: on
    statements = split(raw_statements, ";")
    for statement in statements
        trated_statement = _treat_sql_statement(statement)
        if !isempty(trated_statement)
            try
                DBInterface.execute(db, trated_statement)
            catch e
                @error """
                        Error executing command: $trated_statement
                        error message: $(e.msg)
                        """
                rethrow(e)
            end
        end
    end
    return nothing
end

function _treat_sql_statement(statement::AbstractString)
    stripped_statement = strip(statement)
    return stripped_statement
end

function create_empty_db_from_schema(
    database_path::String,
    path_schema::String;
    force::Bool = false,
)
    opensql_db = try
        OpenSQLDatabase(
            database_path;
            path_schema = path_schema,
            force = force,
        )
    catch e
        rethrow(e)
    end
    return opensql_db
end

function create_empty_db_from_migrations(
    database_path::String,
    path_migrations_directory::String;
    force::Bool = false,
)
    opensql_db = try
        OpenSQLDatabase(
            database_path;
            path_migrations_directory = path_migrations_directory,
            force = force,
        )
    catch e
        rethrow(e)
    end
    return opensql_db
end

function load_db(database_path::String)
    opensql_db = try
        OpenSQLDatabase(
            database_path,
        )
    catch e
        rethrow(e)
    end
    return opensql_db
end

function _throw_if_file_exists(file::String, force::Bool)
    if isfile(file)
        if force
            rm(file)
        else
            error("file already exists: $file")
        end
    end
    return nothing
end

function _open_db_connection(database_path::String)
    db = SQLite.DB(database_path)
    return db
end

function column_names(db::SQLite.DB, table::String)
    cols = SQLite.columns(db, table) |> DataFrame
    return cols.name
end

function table_names(db::SQLite.DB)
    tbls = SQLite.tables(db) |> DataFrame
    return tbls.name
end

_timeseries_table_name(table::String) = table * "_timeseriesfiles"
_relation_table_name(table_1::String, table_2::String) = table_1 * "_relation_" * table_2
