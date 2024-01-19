function _create_scalar_attributes!(
    db::SQLite.DB,
    collection::String,
    scalar_attributes,
)
    attributes = string.(keys(scalar_attributes))
    sanity_check(collection, attributes)

    table = _get_collection_scalar_attribute_tables(db, collection)

    cols = join(keys(scalar_attributes), ", ")
    vals = join(values(scalar_attributes), "', '")

    DBInterface.execute(db, "INSERT INTO $table ($cols) VALUES ('$vals')")
    return nothing
end

function _create_vector_group!(
    db::SQLite.DB,
    collection::String,
    group::String,
    id::Integer,
    vector_attributes::Vector{String},
    group_vectorial_attributes,
)
    vectors_group_table_name = _vectors_group_table_name(collection, group)
    sanity_check(collection, vector_attributes)
    _all_vector_of_group_must_have_same_size!(group_vectorial_attributes, vector_attributes, group)
    df = DataFrame(group_vectorial_attributes)
    num_values = size(df, 1)
    ids = fill(id, num_values)
    idx = collect(1:num_values)
    DataFrames.insertcols!(df, :id => ids, :idx => idx)
    SQLite.load!(df, db, vectors_group_table_name)
    return nothing
end

function _create_vectors!(db::SQLite.DB, collection::String, id::Integer, dict_vectorial_attributes)
    # separate vectors by groups
    map_of_groups_to_vector_attributes = _map_of_groups_to_vector_attributes(collection)
    for (group, vector_attributes) in map_of_groups_to_vector_attributes
        group_vectorial_attributes = Dict()
        for vector_attribute in Symbol.(vector_attributes)
            if haskey(dict_vectorial_attributes, vector_attribute)
                group_vectorial_attributes[vector_attribute] = dict_vectorial_attributes[vector_attribute]
            end
        end
        if isempty(group_vectorial_attributes)
            continue
        end
        _create_vector_group!(db, collection, group, id, vector_attributes, group_vectorial_attributes)
    end
    return nothing
end

function _create_element!(
    db::SQLite.DB,
    collection::String;
    kwargs...,
)
    sanity_check(collection)
    @assert !isempty(kwargs)
    dict_scalar_attributes = Dict()
    dict_vectorial_attributes = Dict()

    for (key, value) in kwargs
        if isa(value, AbstractVector)
            dict_vectorial_attributes[key] = value
        else
            dict_scalar_attributes[key] = value
        end
    end

    _create_scalar_attributes!(db, collection, dict_scalar_attributes)

    if !isempty(dict_vectorial_attributes)
        id = get(dict_scalar_attributes, :id, _get_id(db, collection, dict_scalar_attributes[:label]))
        _create_vectors!(db, collection, id, dict_vectorial_attributes)
    end

    return nothing
end

function create_element!(
    db::SQLite.DB,
    collection::String;
    kwargs...,
)
    try 
        _create_element!(db, collection; kwargs...)
    catch e
        @error """
               Error creating element in collection $collection
               error message: $(e.msg)
               """
        rethrow(e)
    end
    return nothing
end

function _all_vector_of_group_must_have_same_size!(
    group_vectorial_attributes,
    vector_attributes::Vector{String},
    group_name::String
)
    vector_attributes = Symbol.(vector_attributes)
    if isempty(group_vectorial_attributes)
        return nothing
    end
    dict_of_lengths = Dict{String, Int}()
    for (k, v) in group_vectorial_attributes
        dict_of_lengths[string(k)] = length(v)
    end
    unique_lengths = unique(values(dict_of_lengths))
    if length(unique_lengths) > 1
        error(
            "All vectors of group $group_name must have the same length. These are the current lengths: $(_show_sizes_of_vectors_in_string(dict_of_lengths)) "
        )
    end
    length_first_vector = unique_lengths[1]
    # fill missing vectors with missing values
    for vector_attribute in vector_attributes
        if !haskey(group_vectorial_attributes, vector_attribute)
            group_vectorial_attributes[vector_attribute] = fill(missing, length_first_vector)
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