const UPDATE_METHODS_BY_CLASS_OF_ATTRIBUTE = Dict(
    ScalarParameter => "update_element!",
    ScalarRelationship => "set_scalar_relationship!",
    VectorialParameter => "update_element!",
    VectorialRelationship => "set_vectorial_relationship!",
)

function _update_scalar_attributes!(
    db::SQLite.DB, 
    collection::String, 
    label::String,
    dict_scalar_attributes::AbstractDict,
)
    for (attribute, val) in dict_scalar_attributes
        attribute_name = string(attribute)
        _update_scalar_attributes!(db, collection, attribute_name, label, val)
    end
    return nothing
end

function _update_scalar_attributes!(
    db::SQLite.DB,
    collection::String,
    attribute::String,
    label::String,
    val,
)
    sanity_check(collection, attribute)
    id = _get_id(db, collection, label)
    _update_scalar_attributes!(db, collection, attribute, id, val)
    return nothing
end

function _update_scalar_attributes!(
    db::SQLite.DB,
    collection_name::String,
    attribute_name::String,
    id::Integer,
    val,
)
    attribute = _get_attribute(collection_name, attribute_name)
    table_name = attribute.table_where_is_located
    DBInterface.execute(db, "UPDATE $table_name SET $attribute_name = '$val' WHERE id = '$id'")
    return nothing
end

function _update_element!(
    db::SQLite.DB,
    collection::String,
    label::String;
    kwargs...
)
    sanity_check(collection)
    @assert !isempty(kwargs)
    dict_scalar_attributes = Dict()
    dict_vectorial_attributes = Dict()

    for (key, value) in kwargs
        if isa(value, AbstractVector)
            _throw_if_not_vectorial_attribute(collection, string(key))
            if isempty(value)
                error("Cannot update the attribute $key with an empty vector.")
            end
            dict_vectorial_attributes[key] = value
        else
            _throw_if_not_scalar_attribute(collection, string(key))
            dict_scalar_attributes[key] = value
        end
    end

    _validate_attribute_types!(collection, label, dict_scalar_attributes, dict_vectorial_attributes)
    _convert_date_to_string!(dict_scalar_attributes, dict_vectorial_attributes)

    if isempty(dict_vectorial_attributes)
        _update_scalar_attributes!(db, collection, label, dict_scalar_attributes)
    else
        # Read the element
        # modify the vectorial attributes
        # create a check point
        # delete the element
        # create new the element
        # Roll back if not succedded
        error()
    end
end

"""
    update_element!(
        db::SQLite.DB,
        collection::String,
        label::String;
        kwargs...
    )
"""
function update_element!(
    db::SQLite.DB,
    collection::String,
    label::String;
    kwargs...
)
    try 
        _update_element!(db, collection, label; kwargs...)
    catch e
        @error """
            Error updating element \"$label\" in collection \"$collection\"
            error message: $(e.msg)
            """
        rethrow(e)
    end
end

# Helper to guide user to correct method
function set_scalar_relationship!(
    db::SQLite.DB,
    collection_from::String,
    collection_to::String,
    label_collection_from::String,
    label_collection_to::Vector{String},
    relation_type::String,
)
    error("Please use the method `set_vectorial_relationship!` to set a vectorial relationship")
    return nothing
end

function set_scalar_relationship!(
    db::SQLite.DB,
    collection_from::String,
    collection_to::String,
    label_collection_from::String,
    label_collection_to::String,
    relation_type::String,
)
    attribute_name = lowercase(collection_to) * "_" * relation_type
    _throw_if_attribute_is_not_scalar_relationship(collection_from, attribute_name, :update)
    id_collection_from = _get_id(db, collection_from, label_collection_from)
    id_collection_to = _get_id(db, collection_to, label_collection_to)
    set_scalar_relationship!(
        db,
        collection_from,
        collection_to,
        id_collection_from,
        id_collection_to,
        relation_type,
    )
    return nothing
end

function set_scalar_relationship!(
    db::SQLite.DB,
    collection_from::String,
    collection_to::String,
    id_collection_from::Integer,
    id_collection_to::Integer,
    relation_type::String,
)
    if collection_from == collection_to && id_collection_from == id_collection_to
        error("Cannot set a relationship between the same element.")
    end
    attribute_name = lowercase(collection_to) * "_" * relation_type
    table_name = _table_where_attribute_is_located(collection_from, attribute_name)
    DBInterface.execute(
        db,
        "UPDATE $table_name SET $attribute_name = '$id_collection_to' WHERE id = '$id_collection_from'",
    )
    return nothing
end

function set_vectorial_relationship!(
    db::SQLite.DB,
    collection_from::String,
    collection_to::String,
    label_collection_from::String,
    labels_collection_to::Vector{String},
    relation_type::String,
)
    attribute_name = lowercase(collection_to) * "_" * relation_type
    _throw_if_attribute_is_not_vectorial_relationship(collection_from, attribute_name, :update)
    id_collection_from = _get_id(db, collection_from, label_collection_from)
    ids_collection_to = Vector{Int}(undef, length(labels_collection_to))
    for (i, label) in enumerate(labels_collection_to)
        ids_collection_to[i] = _get_id(db, collection_to, label)
    end
    set_vectorial_relationship!(
        db,
        collection_from,
        collection_to,
        id_collection_from,
        ids_collection_to,
        relation_type,
    )
    return nothing
end

function set_vectorial_relationship!(
    db::SQLite.DB,
    collection_from::String,
    collection_to::String,
    id_collection_from::Integer,
    ids_collection_to::Vector{<:Integer},
    relation_type::String,
)
    if collection_from == collection_to && id_collection_from in ids_collection_to
        error("Cannot set a relationship between the same element.")
    end
    attribute_name = lowercase(collection_to) * "_" * relation_type
    attribute = _get_attribute(collection_from, attribute_name)
    group = attribute.group
    table_name = attribute.table_where_is_located
    num_new_relations = length(ids_collection_to)
    df_num_rows = DBInterface.execute(db, "SELECT $(attribute_name) FROM $table_name WHERE id = '$id_collection_from'") |> DataFrame
    num_rows_in_query = size(df_num_rows, 1)
    if num_rows_in_query != num_new_relations
        if num_rows_in_query == 0
            # If there are no rows in the table we can create them
            _create_vectors!(db, collection_from, id_collection_from, Dict(Symbol(attribute_name) => ids_collection_to))
        else
            # If there are rows in the table we must check that the number of rows is the same as the number of new relations
            error(
                "There are currently a vector of $num_rows_in_query elements in the group $group. " * 
                "User is trying to set a vector of $num_new_relations relations. This is invalid. " * 
                "If you want to change the number of elements in the group you might have to update " *
                "the vectors in the group before setting this relation. Another option is to delete " *
                "the element and create it again with the new vector."
            )
        end
    else
        # Update the elements
        for (i, id_collection_to) in enumerate(ids_collection_to)
            DBInterface.execute(
                db,
                "UPDATE $table_name SET $attribute_name = '$id_collection_to' WHERE id = '$id_collection_from' AND vector_index = '$i'",
            )
        end
    end
    return nothing
end

function set_related_time_series!(
    db::DBInterface.Connection,
    table::String;
    kwargs...,
)
    table_name = table * "_timeseriesfiles"
    dict_time_series = Dict()
    for (key, value) in kwargs
        @assert isa(value, String)
        _validate_time_series_attribute_value(value)
        dict_time_series[key] = [value]
    end
    df = DataFrame(dict_time_series)
    SQLite.load!(df, db, table_name)
    return nothing
end