function _create_scalar_attributes!(
    db::DatabaseSQLite,
    collection_id::String,
    scalar_attributes,
)
    attributes = string.(keys(scalar_attributes))
    _throw_if_collection_or_attribute_do_not_exist(db, collection_id, attributes)

    _replace_scalar_relation_labels_with_id!(db, collection_id, scalar_attributes)

    table = _get_collection_scalar_attribute_tables(db.sqlite_db, collection_id)

    if isempty(scalar_attributes)
        DBInterface.execute(db.sqlite_db, "INSERT INTO $table DEFAULT VALUES")
    else
        cols = join(keys(scalar_attributes), ", ")
        vals = join(values(scalar_attributes), "', '")

        DBInterface.execute(db.sqlite_db, "INSERT INTO $table ($cols) VALUES ('$vals')")
    end
    return nothing
end

function _insert_vectors_from_df(
    db::DatabaseSQLite,
    df::DataFrame,
    table_name::String,
)
    # Code to insert rows without using a transaction
    cols = join(string.(names(df)), ", ")
    num_cols = size(df, 2)
    for row in eachrow(df)
        query = "INSERT INTO $table_name ($cols) VALUES ("
        for (i, value) in enumerate(row)
            if ismissing(value)
                query *= "NULL, "
            else
                query *= "\'$value\', "
            end
            if i == num_cols
                query = query[1:end-2]
                query *= ")"
            end
        end
        DBInterface.execute(db.sqlite_db, query)
    end
    return nothing
end

function _create_vector_group!(
    db::DatabaseSQLite,
    collection_id::String,
    group::String,
    id::Integer,
    vector_attributes::Vector{String},
    group_vector_attributes,
)
    vectors_group_table_name = _vectors_group_table_name(collection_id, group)
    _throw_if_collection_or_attribute_do_not_exist(
        db,
        collection_id,
        vector_attributes,
    )
    _replace_vector_relation_labels_with_ids!(
        db,
        collection_id,
        group_vector_attributes,
    )
    _all_vector_of_group_must_have_same_size!(
        group_vector_attributes,
        vector_attributes,
        vectors_group_table_name,
    )
    df = DataFrame(group_vector_attributes)
    num_values = size(df, 1)
    ids = fill(id, num_values)
    vector_index = collect(1:num_values)
    DataFrames.insertcols!(df, 1, :vector_index => vector_index)
    DataFrames.insertcols!(df, 1, :id => ids)
    _insert_vectors_from_df(db, df, vectors_group_table_name)
    return nothing
end

function _create_vectors!(
    db::DatabaseSQLite,
    collection_id::String,
    id::Integer,
    dict_vector_attributes,
)
    # separate vectors by groups
    map_of_groups_to_vector_attributes =
        _map_of_groups_to_vector_attributes(db, collection_id)
    for (group, vector_attributes) in map_of_groups_to_vector_attributes
        group_vector_attributes = Dict()
        for vector_attribute in Symbol.(vector_attributes)
            if haskey(dict_vector_attributes, vector_attribute)
                group_vector_attributes[vector_attribute] =
                    dict_vector_attributes[vector_attribute]
            end
        end
        if isempty(group_vector_attributes)
            continue
        end
        _create_vector_group!(
            db,
            collection_id,
            group,
            id,
            vector_attributes,
            group_vector_attributes,
        )
    end
    return nothing
end

function _create_time_series!(
    db::DatabaseSQLite,
    collection_id::String,
    id::Integer,
    dict_timeseries_attributes,
)
    for (group, df) in dict_timeseries_attributes
        timeseries_group_table_name = _timeseries_group_table_name(collection_id, string(group))
        ids = fill(id, nrow(df))
        DataFrames.insertcols!(df, 1, :id => ids)
        # Convert datetime column to string
        df[!, :date_time] = string.(df[!, :date_time])
        # Add missing columns
        missing_names_in_df = setdiff(_attributes_in_timeseries_group(db, collection_id, string(group)), string.(names(df)))
        for missing_attribute in missing_names_in_df
            df[!, Symbol(missing_attribute)] = fill(missing, nrow(df))
        end
        _insert_vectors_from_df(db, df, timeseries_group_table_name)
    end
end

function _create_element!(
    db::DatabaseSQLite,
    collection_id::String;
    kwargs...,
)
    _throw_if_collection_does_not_exist(db, collection_id)
    dict_scalar_attributes = Dict{Symbol, Any}()
    dict_vector_attributes = Dict{Symbol, Any}()
    dict_timeseries_attributes = Dict{Symbol, Any}()

    # Validate that the arguments will be valid
    for (key, value) in kwargs
        if isa(value, AbstractVector)
            _throw_if_not_vector_attribute(db, collection_id, string(key))
            if isempty(value)
                psr_database_sqlite_error(
                    "Cannot create the attribute \"$key\" with an empty vector.",
                )
            end
            dict_vector_attributes[key] = value
        elseif isa(value, DataFrame)
            _throw_if_not_timeseries_group(db, collection_id, string(key))
            dict_timeseries_attributes[key] = value
        else
            _throw_if_is_time_series_file(db, collection_id, string(key))
            _throw_if_not_scalar_attribute(db, collection_id, string(key))
            dict_scalar_attributes[key] = value
        end
    end

    _validate_attribute_types_on_creation!(
        db,
        collection_id,
        dict_scalar_attributes,
        dict_vector_attributes,
    )

    _create_scalar_attributes!(db, collection_id, dict_scalar_attributes)

    if !isempty(dict_vector_attributes)
        id = get(
            dict_scalar_attributes,
            :id,
            _get_id(db, collection_id, dict_scalar_attributes[:label]),
        )
        _create_vectors!(db, collection_id, id, dict_vector_attributes)
    end

    if !isempty(dict_timeseries_attributes)
        id = get(
            dict_scalar_attributes,
            :id,
            _get_id(db, collection_id, dict_scalar_attributes[:label]),
        )
        _create_time_series!(db, collection_id, id, dict_timeseries_attributes)
    end

    return nothing
end

function create_element!(
    db::DatabaseSQLite,
    collection_id::String;
    kwargs...,
)
    try
        _create_element!(db, collection_id; kwargs...)
    catch e
        @error """
               Error creating element in collection \"$collection_id\"
               error message: $(e.msg)
               """
        rethrow(e)
    end
    return nothing
end

function _all_vector_of_group_must_have_same_size!(
    group_vector_attributes,
    vector_attributes::Vector{String},
    table_name::String,
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
        psr_database_sqlite_error(
            "All vectors of table \"$table_name\" must have the same length. These are the current lengths: $(_show_sizes_of_vectors_in_string(dict_of_lengths)) ",
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
    collection_id::String,
    dict_scalar_attributes,
)
    if collection_id == "Configuration"
        return 1
    elseif haskey(dict_scalar_attributes, :label)
        return dict_scalar_attributes[:label]
    elseif haskey(dict_scalar_attributes, :id)
        return dict_scalar_attributes[:id]
    else
        psr_database_sqlite_error(
            "No label or id was provided for collection $collection_id.",
        )
    end
end

function _replace_scalar_relation_labels_with_id!(
    db::DatabaseSQLite,
    collection_id::String,
    scalar_attributes,
)
    for (key, value) in scalar_attributes
        if _is_scalar_relation(db, collection_id, string(key)) &&
           isa(value, String)
            scalar_relation = _get_attribute(db, collection_id, string(key))
            collection_to = scalar_relation.relation_collection
            scalar_attributes[key] = _get_id(db, collection_to, value)
        end
    end
    return nothing
end

function _replace_vector_relation_labels_with_ids!(
    db::DatabaseSQLite,
    collection_id::String,
    vector_attributes,
)
    for (key, value) in vector_attributes
        if _is_vector_relation(db, collection_id, string(key)) &&
           isa(value, Vector{String})
            vector_relation = _get_attribute(db, collection_id, string(key))
            collection_to = vector_relation.relation_collection
            vec_of_ids = zeros(Int, length(value))
            for i in eachindex(value)
                vec_of_ids[i] = _get_id(db, collection_to, value[i])
            end
            vector_attributes[key] = vec_of_ids
        end
    end
    return nothing
end

function _validate_attribute_types_on_creation!(
    db::DatabaseSQLite,
    collection_id::String,
    dict_scalar_attributes::AbstractDict,
    dict_vector_attributes::AbstractDict,
)
    label_or_id = _get_label_or_id(collection_id, dict_scalar_attributes)
    _validate_attribute_types!(
        db,
        collection_id,
        label_or_id,
        dict_scalar_attributes,
        dict_vector_attributes,
    )
    return nothing
end
