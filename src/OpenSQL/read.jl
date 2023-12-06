function read_parameter(
    db::SQLite.DB,
    table::String,
    column::String,
)
    if !column_exist_in_table(db, table, column) && is_vector_parameter(db, table, column)
        error("column $column is a vector parameter, use `read_vector` instead.")
    end

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
    if !column_exist_in_table(db, table, column) && is_vector_parameter(db, table, column)
        error("column $column is a vector parameter, use `read_vector` instead.")
    end

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
    table_name = _vector_table_name(table, vector_name)
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
    table_name = _vector_table_name(table, vector_name)
    sanity_check(db, table_name, vector_name)

    query = "SELECT $vector_name FROM $table_name WHERE id = '$id' ORDER BY idx"
    df = DBInterface.execute(db, query) |> DataFrame
    # This could be a missing value
    result = df[!, 1]
    return result
end

function number_of_rows(db::SQLite.DB, table::String, column::String)
    sanity_check(db, table, column)
    query = "SELECT COUNT($column) FROM $table"
    df = DBInterface.execute(db, query) |> DataFrame
    return df[!, 1][1]
end

function read_vector_related(
    db::SQLite.DB,
    table::String,
    id::String,
    relation_type::String,
)
    sanity_check(db, table, "id")
    table_as_source = table * "_relation_"
    table_as_target = "_relation_" * table

    tables = table_names(db)

    table_relations_source = tables[findall(x -> startswith(x, table_as_source), tables)]

    table_relations_target = tables[findall(x -> endswith(x, table_as_target), tables)]

    related = []

    for relation_table in table_relations_source
        query = "SELECT target_id FROM $relation_table WHERE source_id = '$id' AND relation_type = '$relation_type'"
        df = DBInterface.execute(db, query) |> DataFrame
        if !isempty(df)
            push!(related, df[!, 1][1])
        end
    end

    for relation_table in table_relations_target
        query = "SELECT source_id FROM $relation_table WHERE target_id = '$id' AND relation_type = '$relation_type'"
        df = DBInterface.execute(db, query) |> DataFrame
        if !isempty(df)
            push!(related, df[!, 1][1])
        end
    end

    return related
end

function read_related(
    db::SQLite.DB,
    table_1::String,
    table_2::String,
    table_1_id::String,
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
