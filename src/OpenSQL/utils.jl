function execute_statements(db::SQLite.DB, file::String)
    if !isfile(file)
        error("file not found: $file")
    end
    statements = open(joinpath(file), "r") do io
        return read(io, String)
    end
    commands = split(statements, ";")
    for command in commands
        if !isempty(command)
            SQLite.execute(db, command)
        end
    end
    return nothing
end

function create_empty_db(path_db::String, path_schema::String)
    if isfile(path_db)
        error("file already exists: $path_db")
    end
    db = SQLite.DB(path_db)
    execute_statements(db, path_schema)
    validate_database(db)
    return db
end

function load_db(database_path::String)
    if !isfile(database_path)
        error("file not found: $database_path")
    end
    db = SQLite.DB(database_path)
    validate_database(db)
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

function column_exist_in_table(db::SQLite.DB, table::String, column::String)
    cols = column_names(db, table)
    return column in cols
end

function table_exist_in_db(db::SQLite.DB, table::String)
    tbls = table_names(db)
    return table in tbls
end

function id_exist_in_table(db::SQLite.DB, table::String, id::Integer)
    sanity_check(db, table, "id")
    query = "SELECT COUNT(id) FROM $table WHERE id = '$id'"
    df = DBInterface.execute(db, query) |> DataFrame
    if df[!, 1][1] == 0
        error("id \"$id\" does not exist in table \"$table\".")
    end
    return nothing
end

function is_vector_parameter(db::SQLite.DB, table::String, column::String)
    return table_exist_in_db(db, _vector_table_name(table, column))
end

function are_related(
    db::SQLite.DB,
    table_1::String,
    table_2::String,
    table_1_id::Integer,
    table_2_id::Integer,
)
    sanity_check(db, table_1, "id")
    sanity_check(db, table_2, "id")
    id_exist_in_table(db, table_1, table_1_id)
    id_exist_in_table(db, table_2, table_2_id)

    columns = column_names(db, table_1)
    possible_relations = filter(x -> startswith(x, lowercase(table_2)), columns)

    for relation in possible_relations
        if read_parameter(db, table_1, relation, table_1_id) == table_2_id
            return true
        end
    end
    return false
end

function has_time_series(db::SQLite.DB, table::String)
    time_series_table = _timeseries_table_name(table)
    return table_exist_in_db(db, time_series_table)
end

function has_time_series(db::SQLite.DB, table::String, column::String)
    sanity_check(db, table, "id")
    time_series_table = _timeseries_table_name(table)
    if table_exist_in_db(db, time_series_table)
        if column in column_names(db, time_series_table)
            return true
        else
            return false
        end
    else
        return false
    end
end

get_vector_attribute_name(table::String) = split(table, "_vector_")[end]
get_collections_from_relation_table(table::String) = split(table, "_relation_")

function _column_valid_types(db::SQLite.DB, table::String, column::String)
    column_index = findfirst(x -> x == column, column_names(db, table))
    raw_type = SQLite.columns(db, table).type[column_index]
    if raw_type == "INTEGER"
        return Union{Int32, Int64}
    elseif raw_type == "REAL"
        return Union{Float32, Float64}
    elseif raw_type == "TEXT"
        return String
    else
        error("type \"$raw_type\" not supported.")
    end
end

_timeseries_table_name(table::String) = table * "_timeseries"
_vector_table_name(table::String, column::String) = table * "_vector_" * column
_relation_table_name(table_1::String, table_2::String) = table_1 * "_relation_" * table_2

close(db::SQLite.DB) = DBInterface.close!(db)
