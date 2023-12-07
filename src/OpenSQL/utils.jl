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

function check_if_column_exists(db::SQLite.DB, table::String, column::String)
    if !column_exist_in_table(db, table, column)
        # TODO we could make a suggestion on the closest string and give an error like
        # Did you mean xxxx?
        error("column $column does not exist in table $table.")
    end
    return nothing
end

function check_if_table_exists(db::SQLite.DB, table::String)
    if !table_exist_in_db(db, table)
        # TODO we could make a suggestion on the closest string and give an error like
        # Did you mean xxxx?
        error("table $table does not exist in database.")
    end
    return nothing
end

function sanity_check(db::SQLite.DB, table::String, column::String)
    # TODO We could make an option to disable sanity checks globally.
    check_if_table_exists(db, table)
    check_if_column_exists(db, table, column)
    return nothing
end

function sanity_check(db::SQLite.DB, table::String, columns::Vector{String})
    # TODO We could make an option to disable sanity checks globally.
    check_if_table_exists(db, table)
    for column in columns
        check_if_column_exists(db, table, column)
    end
    return nothing
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
        if parse(Int, read_parameter(db, table_1, relation, table_1_id)) == table_2_id
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

_timeseries_table_name(table::String) = table * "_timeseries"
_vector_table_name(table::String, column::String) = table * "_vector_" * column
_relation_table_name(table_1::String, table_2::String) = table_1 * "_relation_" * table_2

close(db::SQLite.DB) = DBInterface.close!(db)
