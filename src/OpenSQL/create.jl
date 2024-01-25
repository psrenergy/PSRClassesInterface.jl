function _create_scalar_attributes!(
    opensql_db::OpenSQLDataBase,
    collection_name::String,
    scalar_attributes,
)
    attributes = string.(keys(scalar_attributes))
    _throw_if_collection_or_attribute_do_not_exist(opensql_db, collection_name, attributes)

    _replace_scalar_relation_labels_with_id!(opensql_db, collection_name, scalar_attributes)

    table = _get_collection_scalar_attribute_tables(opensql_db.sqlite_db, collection_name)

    cols = join(keys(scalar_attributes), ", ")
    vals = join(values(scalar_attributes), "', '")

    DBInterface.execute(opensql_db.sqlite_db, "INSERT INTO $table ($cols) VALUES ('$vals')")
    return nothing
end

function _create_vector_group!(
    opensql_db::OpenSQLDataBase,
    collection_name::String,
    group::String,
    id::Integer,
    vector_attributes::Vector{String},
    group_vector_attributes,
)
    vectors_group_table_name = _vectors_group_table_name(collection_name, group)
    _throw_if_collection_or_attribute_do_not_exist(opensql_db, collection_name, vector_attributes)
    _replace_vector_relation_labels_with_ids!(opensql_db, collection_name, group_vector_attributes)
    _all_vector_of_group_must_have_same_size!(
        group_vector_attributes, 
        vector_attributes, 
        vectors_group_table_name
    )
    df = DataFrame(group_vector_attributes)
    num_values = size(df, 1)
    ids = fill(id, num_values)
    vector_index = collect(1:num_values)
    DataFrames.insertcols!(df, :id => ids, :vector_index => vector_index)
    SQLite.load!(df, opensql_db.sqlite_db, vectors_group_table_name)
    return nothing
end

function _create_vectors!(opensql_db::OpenSQLDataBase, collection_name::String, id::Integer, dict_vector_attributes)
    # separate vectors by groups
    map_of_groups_to_vector_attributes = _map_of_groups_to_vector_attributes(opensql_db, collection_name)
    for (group, vector_attributes) in map_of_groups_to_vector_attributes
        group_vector_attributes = Dict()
        for vector_attribute in Symbol.(vector_attributes)
            if haskey(dict_vector_attributes, vector_attribute)
                group_vector_attributes[vector_attribute] = dict_vector_attributes[vector_attribute]
            end
        end
        if isempty(group_vector_attributes)
            continue
        end
        _create_vector_group!(opensql_db, collection_name, group, id, vector_attributes, group_vector_attributes)
    end
    return nothing
end

function _create_element!(
    opensql_db::OpenSQLDataBase,
    collection_name::String;
    kwargs...,
)
    _throw_if_collection_does_not_exist(opensql_db, collection_name)
    _validate_create_elements_kwargs(collection_name, kwargs)
    dict_scalar_attributes = Dict{Symbol, Any}()
    dict_vector_attributes = Dict{Symbol, Any}()

    for (key, value) in kwargs
        if isa(value, AbstractVector)
            _throw_if_not_vector_attribute(opensql_db, collection_name, string(key))
            if isempty(value)
                error("Cannot create the attribute $key with an empty vector.")
            end
            dict_vector_attributes[key] = value
        else
            _throw_if_is_time_series_file(opensql_db, collection_name, string(key))
            _throw_if_not_scalar_attribute(opensql_db, collection_name, string(key))
            dict_scalar_attributes[key] = value
        end
    end

    _validate_attribute_types_on_creation!(opensql_db, collection_name, dict_scalar_attributes, dict_vector_attributes)
    _convert_date_to_string!(dict_scalar_attributes, dict_vector_attributes)

    _create_scalar_attributes!(opensql_db, collection_name, dict_scalar_attributes)

    if !isempty(dict_vector_attributes)
        id = get(dict_scalar_attributes, :id, _get_id(opensql_db, collection_name, dict_scalar_attributes[:label]))
        _create_vectors!(opensql_db, collection_name, id, dict_vector_attributes)
    end

    return nothing
end

function create_element!(
    opensql_db::OpenSQLDataBase,
    collection_name::String;
    kwargs...,
)
    try 
        _create_element!(opensql_db, collection_name; kwargs...)
    catch e
        @error """
               Error creating element in collection $collection_name
               error message: $(e.msg)
               """
        rethrow(e)
    end
    return nothing
end

function _all_vector_of_group_must_have_same_size!(
    group_vector_attributes,
    vector_attributes::Vector{String},
    table_name::String
)
    vector_attributes = Symbol.(vector_attributes)
    if isempty(group_vector_attributes)
        return nothing
    end
    dict_of_lengths = Dict{String, Int}()
    for (k, v) in group_vector_attributes
        dict_of_lengths[string(k)] = length(v)
    end
    unique_lengths = unique(values(dict_of_lengths))
    if length(unique_lengths) > 1
        error(
            "All vectors of table $table_name must have the same length. These are the current lengths: $(_show_sizes_of_vectors_in_string(dict_of_lengths)) "
        )
    end
    length_first_vector = unique_lengths[1]
    # fill missing vectors with missing values
    for vector_attribute in vector_attributes
        if !haskey(group_vector_attributes, vector_attribute)
            group_vector_attributes[vector_attribute] = fill(missing, length_first_vector)
        end
    end
    return nothing
end

function _show_sizes_of_vectors_in_string(dict_of_lengths::Dict{String, Int})
    string_sizes = ""
    for (k, v) in dict_of_lengths
        string_sizes *= "\n - $k: $v"
    end
    return string_sizes
end

function _get_label_or_id(
    collection_name::String, 
    dict_scalar_attributes
)
    if haskey(dict_scalar_attributes, :label)
        return dict_scalar_attributes[:label]
    elseif haskey(dict_scalar_attributes, :id)
        return dict_scalar_attributes[:id]
    else
        error("No label or id was provided for collection $collection.")
    end
end

function _convert_date_to_string!(
    dict_scalar_attributes::AbstractDict,
    dict_vector_attributes::AbstractDict,
)
    for (key, value) in dict_scalar_attributes
        if startswith(string(key), "date")
            dict_scalar_attributes[key] = _convert_date_to_string(value)
        end
    end
    for (key, value) in dict_vector_attributes
        if startswith(string(key), "date")
            dict_vector_attributes[key] = _convert_date_to_string(value)
        end
    end
    return nothing
end

function _convert_date_to_string(
    value::TimeType
)
    return string(DateTime(value))
end

function _convert_date_to_string(
    values::AbstractVector{<:TimeType}
)
    dates = DateTime.(values)
    if !issorted(dates)
        error("Vector of dates must be sorted.")
    end
    return string.(dates)
end
_convert_date_to_string(value) = value

function _replace_scalar_relation_labels_with_id!(
    opensql_db::OpenSQLDataBase, 
    collection_name::String, 
    scalar_attributes
)
    for (key, value) in scalar_attributes
        if _is_scalar_relation(opensql_db, collection_name, string(key)) && isa(value, String)
            scalar_relation = _get_attribute(opensql_db, collection_name, string(key))
            collection_to = scalar_relation.relation_collection
            scalar_attributes[key] = _get_id(opensql_db, collection_to, value)
        end
    end
    return nothing
end

function _replace_vector_relation_labels_with_ids!(
    opensql_db::OpenSQLDataBase, 
    collection_name::String, 
    vector_attributes
)
    for (key, value) in vector_attributes
        if _is_vector_relation(opensql_db, collection_name, string(key)) && isa(value, Vector{String})
            vector_relation = _get_attribute(opensql_db, collection_name, string(key))
            collection_to = vector_relation.relation_collection
            vec_of_ids = zeros(Int, length(value))
            for i in eachindex(value)
                vec_of_ids[i] = _get_id(opensql_db, collection_to, value[i])
            end
            vector_attributes[key] = vec_of_ids
        end
    end
    return nothing
end

function _validate_attribute_types_on_creation!(
    opensql_db::OpenSQLDataBase,
    collection_name::String,
    dict_scalar_attributes::AbstractDict,
    dict_vector_attributes::AbstractDict,
)
    label_or_id = _get_label_or_id(collection_name, dict_scalar_attributes)
    _validate_attribute_types!(opensql_db, collection_name, label_or_id, dict_scalar_attributes, dict_vector_attributes)
    return nothing
end

function _validate_create_elements_kwargs(collection_name::String, kwargs)
    if !haskey(kwargs, :label)
        @warn("Creating an element in collection \"$collection_name\" without \"label\"")
        if !haskey(kwargs, :id)
            error("User tried to create an element in collection \"$collection_name\" without \"id\" nor \"label\". This is not allowed.")
        end
    end
    return nothing
end