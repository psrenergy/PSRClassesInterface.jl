const READ_METHODS_BY_CLASS_OF_ATTRIBUTE = Dict(
    ScalarParameter => "read_scalar_parameters",
    ScalarRelationship => "read_scalar_relationships",
    VectorialParameter => "read_vectorial_parameters",
    VectorialRelationship => "read_vectorial_relationships",
    TimeSeriesFile => "read_time_series_file",
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

    table = _get_collection_scalar_attribute_tables(db, collection_name)
    id = _get_id(db, table, label)

    return read_scalar_parameter(db, collection_name, attribute_name, id)
end

function read_scalar_parameter(
    db::SQLite.DB,
    collection_name::String,
    attribute_name::String,
    id::Integer,
)
    _throw_if_attribute_is_not_scalar_parameter(collection_name, attribute_name, :read)
    attribute = _get_attribute(collection_name, attribute_name)
    table = attribute.table_where_is_located

    query = "SELECT $attribute_name FROM $table WHERE id = '$id'"
    df = DBInterface.execute(db, query) |> DataFrame
    results = df[!, 1][1]
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

function read_vectorial_parameter(
    db::SQLite.DB,
    collection_name::String,
    attribute_name::String,
    label::String,
)
    _throw_if_attribute_is_not_vectorial_parameter(collection_name, attribute_name, :read)
    attribute = _get_attribute(collection_name, attribute_name)
    id = read_scalar_parameter(db, collection_name, "id", label)
    return _query_vector(db, attribute, id)
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
    names_in_collection_to = read_scalar_parameters(db, collection_to, "label")
    ids_in_collection_to = read_scalar_parameters(db, collection_to, "id")
    replace_dict = Dict{Any, String}(zip(ids_in_collection_to, names_in_collection_to))
    push!(replace_dict, missing => "")
    return replace(map_of_elements, replace_dict...)
end

function read_scalar_relationship(
    db::SQLite.DB,
    collection_from::String,
    collection_to::String,
    collection_from_label::String,
    relation_type::String,
)
    relations = read_scalar_relationships(
        db,
        collection_from,
        collection_to,
        relation_type,
    )
    labels_in_collection_from = read_scalar_parameters(db, collection_from, "label")
    index_of_label = findfirst(isequal(collection_from_label), labels_in_collection_from)
    return relations[index_of_label]
end

function _get_scalar_relationship_map(
    db::SQLite.DB,
    collection_from::String,
    collection_to::String,
    relation_type::String,
)
    attribute_on_collection_from = lowercase(collection_to) * "_" * relation_type
    _throw_if_attribute_is_not_scalar_relationship(collection_from, attribute_on_collection_from, :read)
    attribute = _get_attribute(collection_from, attribute_on_collection_from)

    query = "SELECT $(attribute.name) FROM $(attribute.table_where_is_located) ORDER BY rowid"
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

function read_vectorial_relationships(
    db::SQLite.DB,
    collection_from::String,
    collection_to::String,
    relation_type::String,
)
    map_of_vector_with_indexes = _get_vectorial_relationship_map(
        db,
        collection_from,
        collection_to,
        relation_type,
    )

    names_in_collection_to = read_scalar_parameters(db, collection_to, "label")
    ids_in_collection_to = read_scalar_parameters(db, collection_to, "id")
    replace_dict = Dict{Any, String}(zip(ids_in_collection_to, names_in_collection_to))
    push!(replace_dict, missing => "")

    map_with_labels = Vector{Vector{String}}(undef, length(map_of_vector_with_indexes))

    for (i, vector_with_indexes) in enumerate(map_of_vector_with_indexes)
        map_with_labels[i] = replace(vector_with_indexes, replace_dict...)
    end
    
    return map_with_labels
end

function read_vectorial_relationship(
    db::SQLite.DB,
    collection_from::String,
    collection_to::String,
    collection_from_label::String,
    relation_type::String,
)
    relations = read_vectorial_relationships(
        db,
        collection_from,
        collection_to,
        relation_type,
    )
    labels_in_collection_from = read_scalar_parameters(db, collection_from, "label")
    index_of_label = findfirst(isequal(collection_from_label), labels_in_collection_from)
    return relations[index_of_label]
end

function _get_vectorial_relationship_map(
    db::SQLite.DB,
    collection_from::String,
    collection_to::String,
    relation_type::String,
)
    attribute_on_collection_from = lowercase(collection_to) * "_" * relation_type
    _throw_if_attribute_is_not_vectorial_relationship(collection_from, attribute_on_collection_from, :read)
    attribute = _get_attribute(collection_from, attribute_on_collection_from)

    query = "SELECT id, vector_index, $(attribute.name) FROM $(attribute.table_where_is_located) ORDER BY rowid, vector_index"
    df = DBInterface.execute(db, query) |> DataFrame
    id = df[!, 1]
    results = df[!, 3]

    ids_in_collection_from = read_scalar_parameters(db, collection_from, "id")
    num_ids = length(ids_in_collection_from)
    map_of_vector_with_indexes = Vector{Vector{Union{Int, Missing}}}(undef, num_ids)
    for i in 1:num_ids
        map_of_vector_with_indexes[i] = Vector{Union{Int, Missing}}(undef, 0)
    end

    num_rows = size(df, 1)
    for i in 1:num_rows
        index_of_id = findfirst(isequal(id[i]), ids_in_collection_from)
        if index_of_id !== nothing
            push!(map_of_vector_with_indexes[index_of_id], results[i])
        end
    end

    return map_of_vector_with_indexes
end

function read_time_series_file(
    db::SQLite.DB,
    collection_name::String,
    attribute_name::String,
)
    _throw_if_attribute_is_not_time_series_file(collection_name, attribute_name, :read)
    attribute = _get_attribute(collection_name, attribute_name)
    table = attribute.table_where_is_located

    query = "SELECT $(attribute.name) FROM $table ORDER BY rowid"
    df = DBInterface.execute(db, query) |> DataFrame
    if size(df, 1) > 1
        error("Table $table has more than one row. As a time series file, it should have only one row.")
    end
    results = df[!, 1][1]
    return results
end