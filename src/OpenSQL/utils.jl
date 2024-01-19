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

"""
    create_empty_db(database_path::String, path_schema::String)
    create_empty_db(database_path::String)

This function comes in two flavours:

    create_empty_db(database_path::String, path_schema::String)

Creates a new database with the schema given in `path_schema`.

    create_empty_db(database_path::String)

Creates a new database by applying upwards all migrations in the migrations folder See more in [TODO ref to migrations.].
"""
function create_empty_db end

function create_empty_db(database_path::String, path_schema::String; force::Bool = false)
    _throw_if_file_exists(database_path, force)
    db = _open_db_connection(database_path)
    try 
        execute_statements(db, path_schema)
        _validate_database(db)
        _save_collections_database_map(db)
    catch e
        close!(db)
        rethrow(e)
    end
    return db
end

function create_empty_db(database_path::AbstractString; force::Bool = false)
    _throw_if_file_exists(database_path, force)
    db = _open_db_connection(database_path)
    try 
        _apply_all_up_migrations(db)
        _validate_database(db)
        _save_collections_database_map(db)
    catch e
        close!(db)
        rethrow(e)
    end
    return db
end

function load_db(database_path::String)
    if !isfile(database_path)
        error("file not found: $database_path")
    end
    db = _open_db_connection(database_path)
    try 
        _validate_database(db)
        _save_collections_database_map(db)
    catch e
        close!(db)
        rethrow(e)
    end
    return db
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

function id_exist_in_table(db::SQLite.DB, table::String, id::Integer)
    sanity_check(table, "id")
    query = "SELECT COUNT(id) FROM $table WHERE id = '$id'"
    df = DBInterface.execute(db, query) |> DataFrame
    if df[!, 1][1] == 0
        error("id \"$id\" does not exist in table \"$table\".")
    end
    return nothing
end

function has_time_series(db::SQLite.DB, table::String)
    time_series_table = _timeseries_table_name(table)
    return table_exist_in_db(time_series_table)
end

function has_time_series(db::SQLite.DB, table::String, column::String)
    sanity_check(table, "id")
    time_series_table = _timeseries_table_name(table)
    if table_exist_in_db(time_series_table)
        if column in column_names(db, time_series_table)
            return true
        else
            return false
        end
    else
        return false
    end
end

_timeseries_table_name(table::String) = table * "_timeseries"
_relation_table_name(table_1::String, table_2::String) = table_1 * "_relation_" * table_2

close!(db::SQLite.DB) = DBInterface.close!(db)
function _force_gc()
    GC.gc()
    GC.gc()
    return nothing
end