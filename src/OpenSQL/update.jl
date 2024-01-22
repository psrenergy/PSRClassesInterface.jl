const UPDATE_METHODS_BY_CLASS_OF_ATTRIBUTE = Dict(
    ScalarParameter => "update_scalar_parameters!",
    ScalarRelationship => "set_relationship!",
    VectorialParameter => "update_vectorial_attributes!",
    VectorialRelationship => "set_relationship!",
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
    id = _get_id(db, collection, label)
    _update_scalar_attributes!(db, collection, attribute, id, val)
    return nothing
end

function _update_scalar_attributes!(
    db::SQLite.DB,
    collection::String,
    attribute::String,
    id::Integer,
    val,
)
    sanity_check(collection, attribute)
    table_name = _table_where_attribute_is_located(collection, attribute)
    DBInterface.execute(db, "UPDATE $table_name SET $attribute = '$val' WHERE id = '$id'")
    return nothing
end

function set_relationship!(
    db::SQLite.DB,
    collection_from::String,
    collection_to::String,
    label_collection_from::String,
    label_collection_to::String,
    relation_type::String,
)
    id_collection_from = _get_id(db, collection_from, label_collection_from)
    id_collection_to = _get_id(db, collection_to, label_collection_to)
    _throw_if_relationship_does_not_exist(collection_from, collection_to, relation_type)
    set_relationship!(
        db,
        collection_from,
        collection_to,
        id_collection_from,
        id_collection_to,
        relation_type,
    )
    return nothing
end

function set_relationship!(
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
    SQLite.execute(
        db,
        "UPDATE $table_name SET $attribute_name = '$id_collection_to' WHERE id = '$id_collection_from'",
    )
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
            Error updating element $label in collection $collection
            """
        rethrow(e)
    end
end

"""
    update_vectorial_attributes!(
        db::SQLite.DB,
        collection::String,
        label::String;
        kwargs...
    )

We msust point out that this function deletes the previous vectorial attributes and creates new ones.

"""
function update_vectorial_attributes!(
    db::SQLite.DB,
    collection::String,
    label::String;
    kwargs...
)
    sanity_check(collection)
    @assert !isempty(kwargs)
    dict_vectorial_attributes = Dict()

    for (key, value) in kwargs
        if isa(value, AbstractVector)
            _throw_if_not_vectorial_attribute(collection, string(key))
            if isempty(value)
                error("Cannot update the attribute $key with an empty vector.")
            end
            dict_vectorial_attributes[key] = value
        else
            error("The value of the attribute \"$key\" is not a vector.")
        end
    end

    _convert_date_to_string!(Dict(), dict_vectorial_attributes)

    _delete_vectorial_attributes!(db, collection, label, string.(keys(dict_vectorial_attributes)))

    if !isempty(dict_vectorial_attributes)
        id = _get_id(db, collection, label)
        _create_vectors!(db, collection, id, dict_vectorial_attributes)
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
        # TODO we could validate if the path exists
        _validate_time_series_attribute_value(value)
        dict_time_series[key] = [value]
    end
    df = DataFrame(dict_time_series)
    SQLite.load!(df, db, table_name)
    return nothing
end