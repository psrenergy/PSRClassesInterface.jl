const READ_METHODS_BY_CLASS_OF_ATTRIBUTE = Dict(
    ScalarParameter => "read_scalar_parameter",
    ScalarRelationship => "read_scalar_relationship",
    VectorialParameter => "read_vectorial_parameter",
    VectorialRelationship => "read_vectorial_relationship",
)

function _get_id(db::SQLite.DB, table::String, label::String)::Integer
    query = "SELECT id FROM $table WHERE label = '$label'"
    df = DBInterface.execute(db, query) |> DataFrame
    if isempty(df)
        error("label \"$label\" does not exist in table \"$table\".")
    end
    result = df[!, 1][1]
    return result
end

function read_scalar_parameter(
    db::SQLite.DB,
    collection::String,
    attribute::String,
)
    _throw_if_attribute_is_not_scalar_parameter(collection, attribute, :read)

    table = _get_collection_scalar_attribute_tables(db, collection)

    query = "SELECT $attribute FROM $table ORDER BY rowid"
    df = DBInterface.execute(db, query) |> DataFrame
    # TODO it can have missing values, we should decide what to do with this.
    results = df[!, 1]
    return results
end

function read_scalar_parameter(
    db::SQLite.DB,
    collection::String,
    attribute::String,
    id::Integer,
)
    _throw_if_attribute_is_not_scalar_parameter(collection, attribute, :read)
    query = "SELECT $attribute FROM $collection WHERE id = '$id'"
    df = DBInterface.execute(db, query) |> DataFrame
    # This could be a missing value
    if isempty(df)
        error("id \"$id\" does not exist in table \"$collection\".")
    end
    result = df[!, 1][1]
    return result
end

function read_vectorial_parameter(
    db::SQLite.DB,
    collection::String,
    attribute::String,
)
    _throw_if_attribute_is_not_vectorial_parameter(collection, attribute)
    table_name = _table_where_attribute_is_located(collection, attribute)
    ids_in_table = read_scalar_parameter(db, collection, "id")

    results = []
    for id in ids_in_table
        push!(results, _query_vector(db, table_name, attribute, id))
    end

    return results
end

function read_vectorial_parameter(
    db::SQLite.DB,
    collection::String,
    attribute::String,
    id::Integer,
)
    _throw_if_attribute_is_not_vectorial_parameter(collection, attribute, :read)
    table_name = _table_where_attribute_is_located(collection, attribute)
    result = _query_vector(db, table_name, attribute, id)

    return result
end

function _query_vector(
    db::SQLite.DB,
    table_name::String,
    attribute::String,
    id::Integer,
)
    query = "SELECT $attribute FROM $table_name WHERE id = '$id' ORDER BY vector_index"
    df = DBInterface.execute(db, query) |> DataFrame
    # This could be a missing value
    result = df[!, 1]
    return result
end

function read_scalar_relationship(
    db::SQLite.DB,
    collection_from::String,
    collection_to::String,
    relation_type::String,
)
    attribute_on_collection_from = lowercase(collection_to) * "_" * relation_type
    _throw_if_attribute_is_not_scalar_relationship(collection_from, attribute_on_collection_from)

    query = "SELECT $attribute_on_collection_from FROM $collection_from ORDER BY rowid"
    df = DBInterface.execute(db, query) |> DataFrame
    results = df[!, 1]
    return results
end

function read_scalar_relationship(
    db::SQLite.DB,
    collection_from::String,
    collection_to::String,
    collection_from_id::Integer,
    relation_type::String,
)
    attribute_on_collection_from = lowercase(collection_to) * "_" * relation_type
    _throw_if_attribute_is_not_scalar_relationship(collection, attribute)

    query = "SELECT $attribute_on_collection_from FROM $collection_from WHERE id = '$collection_from_id'"
    df = DBInterface.execute(db, query) |> DataFrame
    if isempty(df)
        error("id \"$collection_from_id\" does not exist in table \"$collection_from\".")
    end
    result = df[!, 1][1]
    return result
end


function number_of_rows(db::SQLite.DB, table::String, column::String)
    sanity_check(table, column)
    query = "SELECT COUNT($column) FROM $table"
    df = DBInterface.execute(db, query) |> DataFrame
    return df[!, 1][1]
end

function read_vectorial_relationship(
    db::SQLite.DB,
    collection_from::String,
    collection_to::String,
    id_collection_from::Integer,
    relation_type::String,
)
    attribute_on_collection_from = lowercase(collection_to) * "_" * relation_type
    _throw_if_attribute_is_not_vectorial_relationship(collection_from, attribute_on_collection_from)

    table_name = _table_where_attribute_is_located(collection_from, attribute_on_collection_from)

    query = "SELECT $attribute_on_collection_from FROM $table_name WHERE id = '$id_collection_from' ORDER BY rowid"
    df = DBInterface.execute(db, query) |> DataFrame
    if isempty(df)
        error("id \"$collection_from_id\" does not exist in table \"$collection_from\".")
    end
    result = df[!, 1]
    return result
end