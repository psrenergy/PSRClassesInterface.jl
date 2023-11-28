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

function create_empty_db(database_path::String, file::String)
    if isfile(database_path)
        error("file already exists: $database_path")
    end
    db = SQLite.DB(database_path)
    execute_statements(db, file)
    return db
end

function load_db(database_path::String)
    if !isfile(database_path)
        error("file not found: $database_path")
    end
    db = SQLite.DB(database_path)
    return db
end

function set_related!(
    db::SQLite.DB,
    table1::String,
    table2::String,
    id_1::String,
    id_2::String,
)
    id_parameter_on_table_1 = lowercase(table2) * "_id"
    SQLite.execute(
        db,
        "UPDATE $table1 SET $id_parameter_on_table_1 = '$id_2' WHERE id = '$id_1'",
    )
    return nothing
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

function id_exist_in_table(db::SQLite.DB, table::String, id::String)
    sanity_check(db, table, "id")
    query = "SELECT COUNT(id) FROM $table WHERE id = '$id'"
    df = DBInterface.execute(db, query) |> DataFrame
    if df[!, 1][1] == 0
        error("id \"$id\" does not exist in table \"$table\".")
    end
    return nothing
end

function is_vector_parameter(db::SQLite.DB, table::String, column::String)
    return table_exist_in_db(db, "_" * table * "_" * column)
end

close(db::SQLite.DB) = DBInterface.close!(db)
