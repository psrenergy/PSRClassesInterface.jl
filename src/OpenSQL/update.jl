const UPDATE_METHODS_BY_CLASS_OF_ATTRIBUTE = Dict(
    ScalarParameter => "update_scalar_parameters!",
    ScalarRelationship => "set_scalar_relationship!",
    VectorialParameter => "update_vectorial_parameters!",
    VectorialRelationship => "set_vectorial_relationship!",
)

function update_scalar_parameters!(
    db::SQLite.DB, 
    collection::String, 
    label::String;
    kwargs...
)
    for (attribute, val) in kwargs
        attribute_name = string(attribute)
        if isa(val, AbstractVector)
            error("Cannot update scalar parameter $attribute_name with a vector.")
        end
        update_scalar_parameter!(db, collection, attribute_name, label, val)
    end
    return nothing
end

function update_scalar_parameter!(
    db::SQLite.DB,
    collection::String,
    attribute::String,
    label::String,
    val,
)
    id = _get_id(db, collection, label)
    update_scalar_parameter!(db, collection, attribute, id, val)
    return nothing
end

function update_scalar_parameter!(
    db::SQLite.DB,
    collection::String,
    attribute::String,
    id::Integer,
    val,
)
    sanity_check(collection, attribute)
    _throw_if_attribute_is_not_scalar_parameter(collection, attribute, :update)
    DBInterface.execute(db, "UPDATE $collection SET $attribute = '$val' WHERE id = '$id'")
    return nothing
end

function update_vectorial_attribute!(
    db::SQLite.DB,
    collection::String,
    attribute::String,
    id::Integer,
    vals::V,
) where {V <: AbstractVector}
    if !_is_vectorial_parameter(collection, attribute)
        error("Attribute $attribute is not a vectorial parameter.")
    end

    table_name = _table_where_attribute_is_located(collection, attribute)

    current_vector = read_vectorial_parameter(db, collection, attribute, id)
    current_length = length(current_vector)

    # TODO isso aqui deveria estar numa transaction, se não puder dar update tem que dar erro e voltar o que estava antes
    for idx in 1:current_length
        # TODO - Bodin deve ter uma forma melhor de fazer esse delete, acho que no final
        # seria equivalente a deletar todos os ids
        DBInterface.execute(
            db,
            "DELETE FROM $table_name WHERE id = '$id' AND idx = $idx",
        )
    end

    _create_vectors!(db, collection, id, Dict(Symbol(attribute) => vals))

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
    db::DBInterface.Connection,
    collection_from::String,
    collection_to::String,
    id_collection_from::Integer,
    id_collection_to::Integer,
    relation_type::String,
)
    if collection_from == collection_to && id_collection_from == id_collection_to
        error("Cannot set a relationship between the same element.")
    end
    _throw_if_scalar_relationship_does_not_exist(collection_from, collection_to, relation_type)
    attribute_name = lowercase(collection_to) * "_" * relation_type
    table_name = _table_where_attribute_is_located(collection_from, attribute_name)
    SQLite.execute(
        db,
        "UPDATE $table_name SET $attribute_name = '$id_collection_to' WHERE id = '$id_collection_from'",
    )
    return nothing
end

function set_vectorial_relationship!(
    db::DBInterface.Connection,
    collection_from::String,
    collection_to::String,
    id_collection_from::Integer,
    id_collection_to::Integer,
    relation_type::String,
)
    _throw_if_vectorial_relationship_does_not_exist(collection_from, collection_to, relation_type)
    attribute_name = lowercase(collection_to) * "_" * relation_type
    table_name = _table_where_attribute_is_located(collection_from, attribute_name)
    SQLite.execute(
        db,
        "UPDATE $table_name SET $attribute_name = '$id_collection_to' WHERE id = '$id_collection_from'",
    )
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
