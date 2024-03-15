function _get_id(db::SQLite.DB, table::String, label::String)
    query = "SELECT id FROM $table WHERE label = '$label'"
    df = DBInterface.execute(db, query) |> DataFrame
    if isempty(df)
        error("label \"$label\" does not exist in table \"$table\".")
    end
    result = df[!, 1][1]
    return result
end

function read_parameter(
    db::SQLite.DB,
    table::String,
    column::String,
)
    if !column_exist_in_table(table, column) && is_vector_parameter(table, column)
        error("column $column is a vector parameter, use `read_vector` instead.")
    end

    sanity_check(table, column)

    query = "SELECT $column FROM $table ORDER BY rowid"
    df = DBInterface.execute(db, query) |> DataFrame
    # TODO it can have missing values, we should decide what to do with this.
    results = df[!, 1]
    return results
end

function read_parameter(
    db::SQLite.DB,
    table::String,
    column::String,
    id::Integer,
)
    if !column_exist_in_table(table, column) && is_vector_parameter(table, column)
        error("column $column is a vector parameter, use `read_vector` instead.")
    end

    sanity_check(table, column)

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
    table_name = _vector_table_name(table, vector_name)
    sanity_check(table_name, vector_name)
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
    id::Integer,
)
    table_name = _vector_table_name(table, vector_name)
    sanity_check(table_name, vector_name)

    query = "SELECT $vector_name FROM $table_name WHERE id = '$id' ORDER BY idx"
    df = DBInterface.execute(db, query) |> DataFrame
    # This could be a missing value
    result = df[!, 1]
    return result
end

function number_of_rows(db::SQLite.DB, table::String, column::String)
    sanity_check(table, column)
    query = "SELECT COUNT($column) FROM $table"
    df = DBInterface.execute(db, query) |> DataFrame
    return df[!, 1][1]
end

function read_vector_related(
    db::SQLite.DB,
    table::String,
    id::Integer,
    relation_type::String,
)
    sanity_check(table, "id")
    table_as_source = table * "_relation_"
    table_as_target = "_relation_" * table

    tables = table_names(db)

    table_relations_source = tables[findall(x -> startswith(x, table_as_source), tables)]

    table_relations_target = tables[findall(x -> endswith(x, table_as_target), tables)]

    related = []

    for relation_table in table_relations_source
        _, target = split(relation_table, "_relation_")
        query = "SELECT target_id FROM $relation_table WHERE source_id = '$id' AND relation_type = '$relation_type' ORDER BY rowid"
        df = DBInterface.execute(db, query) |> DataFrame
        if !isempty(df)
            push!(related, read_parameter(db, String(target), "label", df[!, 1][1]))
        end
    end

    for relation_table in table_relations_target
        _, source = split(relation_table, "_relation_")
        query = "SELECT source_id FROM $relation_table WHERE target_id = '$id' AND relation_type = '$relation_type' ORDER BY rowid"
        df = DBInterface.execute(db, query) |> DataFrame
        if !isempty(df)
            push!(related, read_parameter(db, String(source), "label", df[!, 1][1]))
        end
    end

    return related
end

function read_related(
    db::SQLite.DB,
    table_1::String,
    table_2::String,
    table_1_id::Integer,
    relation_type::String,
)
    id_parameter_on_table_1 = lowercase(table_2) * "_" * relation_type

    query = "SELECT $id_parameter_on_table_1 FROM $table_1 WHERE id = '$table_1_id'"
    df = DBInterface.execute(db, query) |> DataFrame
    if isempty(df)
        error("id \"$table_1_id\" does not exist in table \"$table_1\".")
    end
    result = df[!, 1][1]
    return result
end
