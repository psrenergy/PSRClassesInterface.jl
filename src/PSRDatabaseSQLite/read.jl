const READ_METHODS_BY_CLASS_OF_ATTRIBUTE = Dict(
    ScalarParameter => "read_scalar_parameters",
    ScalarRelation => "read_scalar_relations",
    VectorParameter => "read_vector_parameters",
    VectorRelation => "read_vector_relations",
    TimeSeries => "read_time_series_row",
    TimeSeriesFile => "read_time_series_file",
)

function number_of_elements(db::DatabaseSQLite, collection_id::String)::Int
    query = "SELECT COUNT(*) FROM $collection_id"
    result = DBInterface.execute(db.sqlite_db, query)
    for row in result
        return row[1]
    end
end

function _get_id(
    db::DatabaseSQLite,
    collection_id::String,
    label::String,
)::Integer
    query = "SELECT id FROM $collection_id WHERE label = '$label'"
    df = DBInterface.execute(db.sqlite_db, query) |> DataFrame
    if isempty(df)
        psr_database_sqlite_error(
            "label \"$label\" does not exist in collection \"$collection_id\".",
        )
    end
    result = df[!, 1][1]
    return result
end

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

    query = "SELECT $attribute_id FROM $table ORDER BY id"
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

    id = _get_id(db, collection_id, label)

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

    results = Vector{attribute.type}[]
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

function end_date_query(db::DatabaseSQLite, attribute::Attribute)
    # First checks if the date or dimension value is within the range of the data.
    # Then it queries the closest date before the provided date.
    # If there is no date query the data with date 0 (which will probably return no data.)
    end_date_query = "SELECT MAX(DATE(date_time)) FROM $(attribute.table_where_is_located)"
    end_date = DBInterface.execute(db.sqlite_db, end_date_query) |> DataFrame
    if isempty(end_date)
        return DateTime(0)
    end
    return DateTime(end_date[!, 1][1])
end

function closest_date_query(db::DatabaseSQLite, attribute::Attribute, dim_value::DateTime)
    closest_date_query_earlier = "SELECT DISTINCT date_time FROM $(attribute.table_where_is_located) WHERE $(attribute.id) IS NOT NULL AND DATE(date_time) <= DATE('$(dim_value)') ORDER BY DATE(date_time) DESC LIMIT 1"
    closest_date = DBInterface.execute(db.sqlite_db, closest_date_query_earlier) |> DataFrame
    if isempty(closest_date)
        return DateTime(0)
    end
    return DateTime(closest_date[!, 1][1])
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
    num_elements = length(names_in_collection_to)
    replace_dict = Dict{Any, String}(zip(collect(1:num_elements), names_in_collection_to))
    push!(replace_dict, _psrdatabasesqlite_null_value(Int) => "")
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

    query = "SELECT $(attribute.id) FROM $(attribute.table_where_is_located)"
    df = DBInterface.execute(db.sqlite_db, query) |> DataFrame
    results = df[!, 1]
    num_results = length(results)
    map_of_indexes = -1 * ones(Int, num_results)
    ids_in_collection_to = read_scalar_parameters(db, collection_to, "id")
    for i in 1:num_results
        if ismissing(results[i])
            map_of_indexes[i] = _psrdatabasesqlite_null_value(Int)
        else
            map_of_indexes[i] = findfirst(isequal(results[i]), ids_in_collection_to)
        end
    end
    return map_of_indexes
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
    num_elements = length(names_in_collection_to)
    replace_dict = Dict{Any, String}(zip(collect(1:num_elements), names_in_collection_to))
    push!(replace_dict, _psrdatabasesqlite_null_value(Int) => "")

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

    query = "SELECT id, vector_index, $(attribute.id) FROM $(attribute.table_where_is_located) ORDER BY id, vector_index"
    df = DBInterface.execute(db.sqlite_db, query) |> DataFrame
    id = df[!, 1]
    results = df[!, 3]

    ids_in_collection_from = read_scalar_parameters(db, collection_from, "id")
    ids_in_collection_to = read_scalar_parameters(db, collection_to, "id")
    num_ids = length(ids_in_collection_from)
    map_of_vector_with_indexes = Vector{Vector{Int}}(undef, num_ids)
    for i in 1:num_ids
        map_of_vector_with_indexes[i] = Vector{Int}(undef, 0)
    end

    num_rows = size(df, 1)
    for i in 1:num_rows
        index_of_id = findfirst(isequal(id[i]), ids_in_collection_from)
        index_of_id_collection_to = findfirst(isequal(results[i]), ids_in_collection_to)
        if isnothing(index_of_id)
            continue
        end
        if isnothing(index_of_id_collection_to)
            push!(
                map_of_vector_with_indexes[index_of_id],
                _psrdatabasesqlite_null_value(Int),
            )
        else
            push!(map_of_vector_with_indexes[index_of_id], index_of_id_collection_to)
        end
    end

    return map_of_vector_with_indexes
end

function read_time_series_file(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
)::String
    _throw_if_attribute_is_not_time_series_file(
        db,
        collection_id,
        attribute_id,
        :read,
    )
    attribute = _get_attribute(db, collection_id, attribute_id)
    table = attribute.table_where_is_located

    query = "SELECT $(attribute.id) FROM $table"
    df = DBInterface.execute(db.sqlite_db, query) |> DataFrame
    result = df[!, 1]
    if isempty(result)
        return ""
    elseif size(df, 1) > 1
        psr_database_sqlite_error(
            "Table $table has more than one row. As a time series file, it should have only one row.",
        )
    elseif ismissing(result[1])
        return ""
    else
        return result[1]
    end
end

function read_time_series_row(
    db,
    collection_id::String,
    attribute_id::String;
    date_time::DateTime,
)
    _throw_if_attribute_is_not_time_series(
        db,
        collection_id,
        attribute_id,
        :read,
    )
    @assert _is_read_only(db) "Time series mapping only works in read only databases"

    collection_attribute = _collection_attribute(collection_id, attribute_id)
    attribute = _get_attribute(db, collection_id, attribute_id)

    T = attribute.type

    if _time_controller_collection_is_empty(db, collection_id)
        return Vector{T}(undef, 0)
    end
    if !haskey(db._time_controller.cache, collection_attribute)
        db._time_controller.cache[collection_attribute] = _start_time_controller_cache(db, attribute, date_time, T)
    end
    cache = db._time_controller.cache[collection_attribute]
    data = query_data_in_time_controller(cache, date_time)
    return data
end

function _read_time_series_table(
    db::DatabaseSQLite,
    attribute::Attribute,
    id::Int,
)
    query = string("SELECT ", join(attribute.dimension_names, ",", ", "), ", ", attribute.id)
    query *= " FROM $(attribute.table_where_is_located) WHERE id = '$id'"
    return DBInterface.execute(db.sqlite_db, query) |> DataFrame
end

function read_time_series_table(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
    label::String,
)
    _throw_if_attribute_is_not_time_series(
        db,
        collection_id,
        attribute_id,
        :read,
    )
    attribute = _get_attribute(db, collection_id, attribute_id)
    id = _get_id(db, collection_id, label)

    return _read_time_series_table(
        db,
        attribute,
        id,
    )
end

function _treat_query_result(
    query_results::Vector{Missing},
    attribute::Attribute,
    default::Union{Nothing, Any},
)
    type_of_attribute = _type(attribute)
    default = if isnothing(default)
        _psrdatabasesqlite_null_value(type_of_attribute)
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
        _psrdatabasesqlite_null_value(type_of_attribute)
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
        _psrdatabasesqlite_null_value(type_of_attribute)
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

_psrdatabasesqlite_null_value(::Type{Float64}) = NaN
_psrdatabasesqlite_null_value(::Type{Int64}) = typemin(Int64)
_psrdatabasesqlite_null_value(::Type{String}) = ""
_psrdatabasesqlite_null_value(::Type{DateTime}) = typemin(DateTime)

function _is_null_in_db(value::Float64)
    return isnan(value)
end
function _is_null_in_db(value::Int64)
    return value == typemin(Int64)
end
function _is_null_in_db(value::String)
    return isempty(value)
end
function _is_null_in_db(value::DateTime)
    return value == typemin(DateTime)
end
