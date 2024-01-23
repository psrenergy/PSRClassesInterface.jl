const READ_METHODS_BY_CLASS_OF_ATTRIBUTE = Dict(
    ScalarParameter => "read_scalar_parameter",
    ScalarRelationship => "read_scalar_relationship",
    VectorialParameter => "read_vectorial_parameter",
    VectorialRelationship => "read_vectorial_relationship",
)

# TODO rename to _get_id_of_element also it should pass a collection_name
function _get_id(db::SQLite.DB, collection_name::String, label::String)::Integer
    query = "SELECT id FROM $collection_name WHERE label = '$label'"
    df = DBInterface.execute(db, query) |> DataFrame
    if isempty(df)
        error("label \"$label\" does not exist in collection \"$collection_name\".")
    end
    result = df[!, 1][1]
    return result
end

"""
TODO
"""
function read_scalar_parameters(
    db::SQLite.DB,
    collection_name::String,
    attribute_name::String,
)
    _throw_if_attribute_is_not_scalar_parameter(collection_name, attribute_name, :read)

    attribute = _get_attribute(collection_name, attribute_name)
    table = attribute.table_where_is_located

    query = "SELECT $attribute_name FROM $table ORDER BY rowid"
    df = DBInterface.execute(db, query) |> DataFrame
    results = df[!, 1]
    return results
end

function read_scalar_parameter(
    db::SQLite.DB,
    collection_name::String,
    attribute_name::String,
    label::String,
)
    _throw_if_attribute_is_not_scalar_parameter(collection_name, attribute_name, :read)

    table = _get_collection_scalar_attribute_tables(db, collection)
    id = _get_id(db, table, label)

    return _read_scalar_parameter(db, collection, attribute, id)
end

function _read_scalar_parameter(
    db::SQLite.DB,
    collection_name::String,
    attribute_name::String,
    id::Integer,
)
    _throw_if_attribute_is_not_scalar_parameter(collection, attribute, :read)
    attribute = _get_attribute(collection_name, collection_name)
    table = attribute.table_where_is_located

    query = "SELECT $attribute_name FROM $table WHERE id = '$id'"
    df = DBInterface.execute(db, query) |> DataFrame
    results = df[!, 1]
    return results
end

function read_vectorial_parameters(
    db::SQLite.DB,
    collection_name::String,
    attribute_name::String,
)
    _throw_if_attribute_is_not_vectorial_parameter(collection_name, attribute_name, :read)
    attribute = _get_attribute(collection_name, attribute_name)
    ids_in_table = read_scalar_parameters(db, collection_name, "id")

    results = []
    for id in ids_in_table
        push!(results, _query_vector(db, attribute, id))
    end

    return results
end

function _query_vector(
    db::SQLite.DB,
    attribute::VectorialParameter,
    id::Integer,
)
    query = "SELECT $(attribute.name) FROM $(attribute.table_where_is_located) WHERE id = '$id' ORDER BY vector_index"
    df = DBInterface.execute(db, query) |> DataFrame
    result = df[!, 1]
    return result
end

"""
TODO
"""
function read_scalar_relationships(
    db::SQLite.DB,
    collection_from::String,
    collection_to::String,
    relation_type::String,
)
    map_of_elements = _get_scalar_relationship_map(
        db,
        collection_from,
        collection_to,
        relation_type,
    )
    names_in_collection_from = read_scalar_parameters(db, collection_to, "label")
    element_names = fill("", length(map_of_elements))
    for (i, id) in enumerate(map_of_elements)
        if !ismissing(id)
            element_names[i] = names_in_collection_from[id]
        end
    end
    return element_names
end

function _get_scalar_relationship_map(
    db::SQLite.DB,
    collection_from::String,
    collection_to::String,
    relation_type::String,
)
    attribute_on_collection_from = lowercase(collection_to) * "_" * relation_type
    _throw_if_attribute_is_not_scalar_relationship(collection_from, attribute_on_collection_from, :read)

    query = "SELECT $attribute_on_collection_from FROM $collection_from ORDER BY rowid"
    df = DBInterface.execute(db, query) |> DataFrame
    results = df[!, 1]
    num_results = length(results)
    map_of_indexes = Vector{Union{Int, Missing}}(undef, num_results)
    ids_in_collection_from = read_scalar_parameters(db, collection_from, "id")
    for i in 1:num_results
        if ismissing(results[i])
            map_of_indexes[i] = missing
        else
            map_of_indexes[i] = findfirst(isequal(results[i]), ids_in_collection_from)
        end
    end
    return results
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