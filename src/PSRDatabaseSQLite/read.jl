const READ_METHODS_BY_CLASS_OF_ATTRIBUTE = Dict(
    ScalarParameter => "read_scalar_parameters",
    ScalarRelation => "read_scalar_relations",
    VectorParameter => "read_vector_parameters",
    VectorRelation => "read_vector_relations",
    TimeSeriesFile => "read_time_series_file",
)

# TODO rename to _get_id_of_element also it should pass a collection_id
function _get_id(
    db::DatabaseSQLite,
    collection_id::String,
    label::String,
)::Integer
    query = "SELECT id FROM $collection_id WHERE label = '$label'"
    df = DBInterface.execute(db.sqlite_db, query) |> DataFrame
    if isempty(df)
        psr_database_sqlite_error("label \"$label\" does not exist in collection \"$collection_id\".")
    end
    result = df[!, 1][1]
    return result
end

"""
TODO
"""
function read_scalar_parameters(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String;
    default::Union{Nothing, Any} = nothing,
)
    _throw_if_attribute_is_not_scalar_parameter(
        db,
        collection_id,
        attribute_id,
        :read,
    )

    attribute = _get_attribute(db, collection_id, attribute_id)
    table = _table_where_is_located(attribute)

    query = "SELECT $attribute_id FROM $table ORDER BY rowid"
    df = DBInterface.execute(db.sqlite_db, query) |> DataFrame
    results = df[!, 1]
    results = _treat_query_result(results, attribute, default)
    return results
end

function read_scalar_parameter(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
    label::String;
    default::Union{Nothing, Any} = nothing,
)
    _throw_if_attribute_is_not_scalar_parameter(
        db,
        collection_id,
        attribute_id,
        :read,
    )

    attribute = _get_attribute(db, collection_id, attribute_id)
    table = _table_where_is_located(attribute)
    id = _get_id(db, table, label)

    return read_scalar_parameter(db, collection_id, attribute_id, id; default)
end

function read_scalar_parameter(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
    id::Integer;
    default::Union{Nothing, Any} = nothing,
)
    _throw_if_attribute_is_not_scalar_parameter(
        db,
        collection_id,
        attribute_id,
        :read,
    )
    attribute = _get_attribute(db, collection_id, attribute_id)
    table = _table_where_is_located(attribute)

    query = "SELECT $attribute_id FROM $table WHERE id = '$id'"
    df = DBInterface.execute(db.sqlite_db, query) |> DataFrame
    results = df[!, 1]
    results = _treat_query_result(results, attribute, default)
    return results[1]
end

function read_vector_parameters(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String;
    default::Union{Nothing, Any} = nothing,
)
    _throw_if_attribute_is_not_vector_parameter(
        db,
        collection_id,
        attribute_id,
        :read,
    )
    attribute = _get_attribute(db, collection_id, attribute_id)
    ids_in_table = read_scalar_parameters(db, collection_id, "id")

    results = []
    for id in ids_in_table
        push!(results, _query_vector(db, attribute, id; default))
    end

    return results
end

function read_vector_parameter(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
    label::String;
    default::Union{Nothing, Any} = nothing,
)
    _throw_if_attribute_is_not_vector_parameter(
        db,
        collection_id,
        attribute_id,
        :read,
    )
    attribute = _get_attribute(db, collection_id, attribute_id)
    id = read_scalar_parameter(db, collection_id, "id", label)
    return _query_vector(db, attribute, id; default)
end

function _query_vector(
    db::DatabaseSQLite,
    attribute::VectorParameter,
    id::Integer;
    default::Union{Nothing, Any} = nothing,
)
    query = "SELECT $(attribute.id) FROM $(attribute.table_where_is_located) WHERE id = '$id' ORDER BY vector_index"
    df = DBInterface.execute(db.sqlite_db, query) |> DataFrame
    results = df[!, 1]
    results = _treat_query_result(results, attribute, default)
    return results
end

"""
TODO
"""
function read_scalar_relations(
    db::DatabaseSQLite,
    collection_from::String,
    collection_to::String,
    relation_type::String,
)
    map_of_elements = _get_scalar_relation_map(
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

function read_scalar_relation(
    db::DatabaseSQLite,
    collection_from::String,
    collection_to::String,
    relation_type::String,
    collection_from_label::String,
)
    relations = read_scalar_relations(
        db,
        collection_from,
        collection_to,
        relation_type,
    )
    labels_in_collection_from = read_scalar_parameters(db, collection_from, "label")
    index_of_label = findfirst(isequal(collection_from_label), labels_in_collection_from)
    return relations[index_of_label]
end

function _get_scalar_relation_map(
    db::DatabaseSQLite,
    collection_from::String,
    collection_to::String,
    relation_type::String,
)
    attribute_on_collection_from = lowercase(collection_to) * "_" * relation_type
    _throw_if_attribute_is_not_scalar_relation(
        db,
        collection_from,
        attribute_on_collection_from,
        :read,
    )
    attribute = _get_attribute(db, collection_from, attribute_on_collection_from)

    query = "SELECT $(attribute.id) FROM $(attribute.table_where_is_located) ORDER BY rowid"
    df = DBInterface.execute(db.sqlite_db, query) |> DataFrame
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

function read_vector_relations(
    db::DatabaseSQLite,
    collection_from::String,
    collection_to::String,
    relation_type::String,
)
    map_of_vector_with_indexes = _get_vector_relation_map(
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

function read_vector_relation(
    db::DatabaseSQLite,
    collection_from::String,
    collection_to::String,
    collection_from_label::String,
    relation_type::String,
)
    relations = read_vector_relations(
        db,
        collection_from,
        collection_to,
        relation_type,
    )
    labels_in_collection_from = read_scalar_parameters(db, collection_from, "label")
    index_of_label = findfirst(isequal(collection_from_label), labels_in_collection_from)
    return relations[index_of_label]
end

function _get_vector_relation_map(
    db::DatabaseSQLite,
    collection_from::String,
    collection_to::String,
    relation_type::String,
)
    attribute_on_collection_from = lowercase(collection_to) * "_" * relation_type
    _throw_if_attribute_is_not_vector_relation(
        db,
        collection_from,
        attribute_on_collection_from,
        :read,
    )
    attribute = _get_attribute(db, collection_from, attribute_on_collection_from)

    query = "SELECT id, vector_index, $(attribute.id) FROM $(attribute.table_where_is_located) ORDER BY rowid, vector_index"
    df = DBInterface.execute(db.sqlite_db, query) |> DataFrame
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
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
)
    _throw_if_attribute_is_not_time_series_file(
        db,
        collection_id,
        attribute_id,
        :read,
    )
    attribute = _get_attribute(db, collection_id, attribute_id)
    table = attribute.table_where_is_located

    query = "SELECT $(attribute.id) FROM $table ORDER BY rowid"
    df = DBInterface.execute(db.sqlite_db, query) |> DataFrame
    if size(df, 1) > 1
        psr_database_sqlite_error(
            "Table $table has more than one row. As a time series file, it should have only one row.",
        )
    end
    results = df[!, 1][1]
    return results
end

function _treat_query_result(
    query_results::Vector{Missing},
    attribute::Attribute,
    default::Union{Nothing, Any},
)
    type_of_attribute = _type(attribute)
    default = if isnothing(default)
        _opensql_default_value_for_type(type_of_attribute)
    else
        default
    end
    final_results = fill(default, length(query_results))
    return final_results
end
function _treat_query_result(
    query_results::Vector{Union{Missing, T}},
    attribute::Attribute,
    default::Union{Nothing, Any},
) where {T <: Union{Int64, Float64}}
    type_of_attribute = _type(attribute)
    default = if isnothing(default)
        _opensql_default_value_for_type(type_of_attribute)
    else
        if isa(default, type_of_attribute)
            default
        else
            psr_database_sqlite_error(
                "default value must be of the same type as attribute \"$(attribute.id)\": $(type_of_attribute). User inputed $(typeof(default)): default.",
            )
        end
    end
    final_results = fill(default, length(query_results))
    for i in eachindex(final_results)
        if !ismissing(query_results[i])
            final_results[i] = query_results[i]
        end
    end
    return final_results
end
function _treat_query_result(
    query_results::Vector{<:Union{Missing, String}},
    attribute::Attribute,
    default::Union{Nothing, Any},
)
    type_of_attribute = _type(attribute)
    default = if isnothing(default)
        _opensql_default_value_for_type(type_of_attribute)
    else
        if isa(default, type_of_attribute)
            default
        else
            psr_database_sqlite_error(
                "default value must be of the same type as attribute \"$(attribute.id)\": $(type_of_attribute). User inputed $(typeof(default)): default.",
            )
        end
    end
    final_results = fill(default, length(query_results))
    for i in eachindex(final_results)
        if !ismissing(query_results[i])
            if isa(default, String)
                final_results[i] = query_results[i]
            else
                final_results[i] = DateTime(query_results[i])
            end
        end
    end
    return final_results
end
_treat_query_result(
    results::Vector{T},
    ::Attribute,
    ::Union{Nothing, Any},
) where {T <: Union{Int64, Float64}} = results

_opensql_default_value_for_type(::Type{Float64}) = NaN
_opensql_default_value_for_type(::Type{Int64}) = typemin(Int64)
_opensql_default_value_for_type(::Type{String}) = ""
_opensql_default_value_for_type(::Type{DateTime}) = typemin(DateTime)
