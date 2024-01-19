function update_scalar_attribute!(
    db::SQLite.DB,
    collection::String,
    attribute::String,
    id::Integer,
    val,
)
    sanity_check(collection, attribute)
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

function set_related!(
    db::DBInterface.Connection,
    table1::String,
    table2::String,
    id_1::Integer,
    id_2::Integer,
    relation_type::String,
)
    id_parameter_on_table_1 = lowercase(table2) * "_" * relation_type
    SQLite.execute(
        db,
        "UPDATE $table1 SET $id_parameter_on_table_1 = '$id_2' WHERE id = '$id_1'",
    )
    return nothing
end

function set_vector_related!(
    db::DBInterface.Connection,
    table1::String,
    table2::String,
    id_1::Integer,
    id_2::Integer,
    relation_type::String,
)
    relation_table = _relation_table_name(table1, table2)
    SQLite.execute(
        db,
        "INSERT INTO $relation_table (source_id, target_id, relation_type) VALUES ('$id_1', '$id_2', '$relation_type')",
    )
    return nothing
end

function set_related_time_series!(
    db::DBInterface.Connection,
    table::String;
    kwargs...,
)
    table_name = table * "_timeseries"
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
