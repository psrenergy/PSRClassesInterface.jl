function read_parameter(
    db::SQLite.DB,
    table::String,
    column::String,
)
    sanity_check(db, table, column)

    query = "SELECT $column FROM $table"
    df = DBInterface.execute(db, query) |> DataFrame
    # TODO it can have missing values, we should decide what to do with this.
    results = df[!, 1]
    return results
end

function read_parameter(
    db::SQLite.DB,
    table::String,
    column::String,
    id::String,
)
    sanity_check(db, table, column)

    query = "SELECT $column FROM $table WHERE id = '$id'"
    df = DBInterface.execute(db, query) |> DataFrame
    # This could be a missing value
    if isempty(df)
        error("id \"$id\" does not exist in table \"$table\".")
    end
    result = df[!, 1][1]
    return result
end

function read_vector(
    db::SQLite.DB,
    table::String,
    vector_name::String,
)
    table_name = "_" * table * "_" * vector_name
    sanity_check(db, table_name, vector_name)
    ids_in_table = read_parameter(db, table, "id")

    results = []
    for id in ids_in_table
        push!(results, read_vector(db, table, vector_name, id))
    end

    return results
end

function read_vector(
    db::SQLite.DB,
    table::String,
    vector_name::String,
    id::String,
)
    table_name = "_" * table * "_" * vector_name
    sanity_check(db, table_name, vector_name)

    query = "SELECT $vector_name FROM $table_name WHERE id = '$id' ORDER BY idx"
    df = DBInterface.execute(db, query) |> DataFrame
    # This could be a missing value
    result = df[!, 1]
    return result
end
