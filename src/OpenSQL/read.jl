const READ_METHODS_BY_CLASS_OF_ATTRIBUTE = Dict(
    ScalarParameter => "read_scalar_parameter",
    ScalarRelationship => "read_scalar_relationship",
    VectorialParameter => "read_vectorial_parameter",
    VectorialRelationship => "read_vectorial_relationship",
)

function _throw_if_not_scalar_parameter(
    collection::String,
    attribute::String,
)
    sanity_check(collection, attribute)

    if !_is_scalar_parameter(collection, attribute)
        correct_composity_type = _attribute_composite_type(collection, attribute)
        string_of_composite_types = _string_for_composite_types(correct_composity_type)
        correct_method_to_use = READ_METHODS_BY_CLASS_OF_ATTRIBUTE[correct_composity_type]
        error("Attribute $attribute is not a scalar parameter. It is a $string_of_composite_types. Try using $correct_method_to_use instead.")
    end
    return nothing
end

function _throw_if_not_vectorial_parameter(
    collection::String,
    attribute::String,
)
    sanity_check(collection, attribute)

    if !_is_vectorial_parameter(collection, attribute)
        correct_composity_type = _attribute_composite_type(collection, attribute)
        string_of_composite_types = _string_for_composite_types(correct_composity_type)
        correct_method_to_use = READ_METHODS_BY_CLASS_OF_ATTRIBUTE[correct_composity_type]
        error("Attribute $attribute is not a vectorial parameter. It is a $string_of_composite_types. Try using $correct_method_to_use instead.")
    end
    return nothing
end

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
    _throw_if_not_scalar_parameter(collection, attribute)

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
    _throw_if_not_scalar_parameter(collection, attribute)
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
    _throw_if_not_vectorial_parameter(collection, attribute)
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
    _throw_if_not_vectorial_parameter(collection, attribute)
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
    query = "SELECT $attribute FROM $table_name WHERE id = '$id' ORDER BY idx"
    df = DBInterface.execute(db, query) |> DataFrame
    # This could be a missing value
    result = df[!, 1]
    return result
end

function read_scalar_relationship(
    db::SQLite.DB,
    collection_from::String,
    collection_to::String,
    collection_from_id::Integer,
    relation_type::String,
)
    attribute_on_collection_1 = lowercase(collection_to) * "_" * relation_type

    query = "SELECT $attribute_on_collection_1 FROM $collection_from WHERE id = '$collection_from_id'"
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