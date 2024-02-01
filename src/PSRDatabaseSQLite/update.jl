const UPDATE_METHODS_BY_CLASS_OF_ATTRIBUTE = Dict(
    ScalarParameter => "update_scalar_parameter!",
    ScalarRelation => "set_scalar_relation!",
    VectorParameter => "update_vector_parameter!",
    VectorRelation => "set_vector_relation!",
    TimeSeriesFile => "set_time_series_file!",
)

function update_scalar_parameter!(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
    label::String,
    val,
)
    _throw_if_collection_or_attribute_do_not_exist(
        db,
        collection_id,
        attribute_id,
    )
    _throw_if_attribute_is_not_scalar_parameter(
        db,
        collection_id,
        attribute_id,
        :update,
    )
    attribute = _get_attribute(db, collection_id, attribute_id)
    _validate_scalar_parameter_type(attribute, label, val)
    id = _get_id(db, collection_id, label)
    _update_scalar_parameter!(db, collection_id, attribute_id, id, val)
    return nothing
end

function _update_scalar_parameter!(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
    id::Integer,
    val,
)
    attribute = _get_attribute(db, collection_id, attribute_id)
    new_value = _convert_date_to_string(val)
    table_name = attribute.table_where_is_located
    DBInterface.execute(
        db.sqlite_db,
        "UPDATE $table_name SET $attribute_id = '$new_value' WHERE id = '$id'",
    )
    return nothing
end

function update_vector_parameters!(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
    label::String,
    vals::Vector{<:Any},
)
    _throw_if_collection_or_attribute_do_not_exist(
        db,
        collection_id,
        attribute_id,
    )
    _throw_if_attribute_is_not_vector_parameter(
        db,
        collection_id,
        attribute_id,
        :update,
    )
    attribute = _get_attribute(db, collection_id, attribute_id)
    _validate_vector_parameter_type(attribute, label, vals)
    id = _get_id(db, collection_id, label)
    return _update_vector_parameters!(db, collection_id, attribute_id, id, vals)
end

function _update_vector_parameters!(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
    id::Integer,
    vals::Vector{<:Any},
)
    attribute = _get_attribute(db, collection_id, attribute_id)
    group_id = attribute.group_id
    new_vals = _convert_date_to_string(vals)
    table_name = attribute.table_where_is_located
    num_new_elements = length(vals)
    df_num_rows =
        DBInterface.execute(
            db.sqlite_db,
            "SELECT $(attribute_id) FROM $table_name WHERE id = '$id'",
        ) |> DataFrame
    num_rows_in_query = size(df_num_rows, 1)
    if num_rows_in_query != num_new_elements
        if num_rows_in_query == 0
            # If there are no rows in the table we can create them
            _create_vectors!(
                db,
                collection_id,
                id,
                Dict(Symbol(attribute_id) => vals),
            )
        else
            # If there are rows in the table we must check that the number of rows is the same as the number of new relations
            psr_database_sqlite_error(
                "There is currently a vector of $num_rows_in_query elements in the group $group_id. " *
                "User is trying to set a vector of length $num_new_elements. This is invalid. " *
                "If you want to change the number of elements in the group you might have to delete " *
                "the element and create it again with the new vector.",
            )
        end
    else
        # Update the elements
        for (i, val) in enumerate(new_vals)
            DBInterface.execute(
                db.sqlite_db,
                "UPDATE $table_name SET $attribute_id = '$val' WHERE id = '$id' AND vector_index = '$i'",
            )
        end
    end
    return nothing
end

# Helper to guide user to correct method
function set_scalar_relation!(
    db::DatabaseSQLite,
    collection_from::String,
    collection_to::String,
    label_collection_from::String,
    label_collection_to::Vector{String},
    relation_type::String,
)
    psr_database_sqlite_error("Please use the method `set_vector_relation!` to set a vector relation")
    return nothing
end

function set_scalar_relation!(
    db::DatabaseSQLite,
    collection_from::String,
    collection_to::String,
    label_collection_from::String,
    label_collection_to::String,
    relation_type::String,
)
    attribute_id = lowercase(collection_to) * "_" * relation_type
    _throw_if_attribute_is_not_scalar_relation(
        db,
        collection_from,
        attribute_id,
        :update,
    )
    id_collection_from = _get_id(db, collection_from, label_collection_from)
    id_collection_to = _get_id(db, collection_to, label_collection_to)
    set_scalar_relation!(
        db,
        collection_from,
        collection_to,
        id_collection_from,
        id_collection_to,
        relation_type,
    )
    return nothing
end

function set_scalar_relation!(
    db::DatabaseSQLite,
    collection_from::String,
    collection_to::String,
    id_collection_from::Integer,
    id_collection_to::Integer,
    relation_type::String,
)
    if collection_from == collection_to && id_collection_from == id_collection_to
        psr_database_sqlite_error("Cannot set a relation between the same element.")
    end
    attribute_id = lowercase(collection_to) * "_" * relation_type
    attribute = _get_attribute(db, collection_from, attribute_id)
    table_name = _table_where_is_located(attribute)
    DBInterface.execute(
        db.sqlite_db,
        "UPDATE $table_name SET $attribute_id = '$id_collection_to' WHERE id = '$id_collection_from'",
    )
    return nothing
end

function set_vector_relation!(
    db::DatabaseSQLite,
    collection_from::String,
    collection_to::String,
    label_collection_from::String,
    labels_collection_to::Vector{String},
    relation_type::String,
)
    attribute_id = lowercase(collection_to) * "_" * relation_type
    _throw_if_attribute_is_not_vector_relation(
        db,
        collection_from,
        attribute_id,
        :update,
    )
    id_collection_from = _get_id(db, collection_from, label_collection_from)
    ids_collection_to = Vector{Int}(undef, length(labels_collection_to))
    for (i, label) in enumerate(labels_collection_to)
        ids_collection_to[i] = _get_id(db, collection_to, label)
    end
    set_vector_relation!(
        db,
        collection_from,
        collection_to,
        id_collection_from,
        ids_collection_to,
        relation_type,
    )
    return nothing
end

function set_vector_relation!(
    db::DatabaseSQLite,
    collection_from::String,
    collection_to::String,
    id_collection_from::Integer,
    ids_collection_to::Vector{<:Integer},
    relation_type::String,
)
    if collection_from == collection_to && id_collection_from in ids_collection_to
        psr_database_sqlite_error("Cannot set a relation between the same element.")
    end
    attribute_id = lowercase(collection_to) * "_" * relation_type
    attribute = _get_attribute(db, collection_from, attribute_id)
    group_id = attribute.group_id
    table_name = attribute.table_where_is_located
    num_new_relations = length(ids_collection_to)
    df_num_rows =
        DBInterface.execute(
            db.sqlite_db,
            "SELECT $(attribute_id) FROM $table_name WHERE id = '$id_collection_from'",
        ) |> DataFrame
    num_rows_in_query = size(df_num_rows, 1)
    if num_rows_in_query != num_new_relations
        if num_rows_in_query == 0
            # If there are no rows in the table we can create them
            _create_vectors!(
                db,
                collection_from,
                id_collection_from,
                Dict(Symbol(attribute_id) => ids_collection_to),
            )
        else
            # If there are rows in the table we must check that the number of rows is the same as the number of new relations
            psr_database_sqlite_error(
                "There is currently a vector of $num_rows_in_query elements in the group $group_id. " *
                "User is trying to set a vector of $num_new_relations relations. This is invalid. " *
                "If you want to change the number of elements in the group you might have to update " *
                "the vectors in the group before setting this relation. Another option is to delete " *
                "the element and create it again with the new vector.",
            )
        end
    else
        # Update the elements
        for (i, id_collection_to) in enumerate(ids_collection_to)
            DBInterface.execute(
                db.sqlite_db,
                "UPDATE $table_name SET $attribute_id = '$id_collection_to' WHERE id = '$id_collection_from' AND vector_index = '$i'",
            )
        end
    end
    return nothing
end

function set_time_series_file!(
    db::DatabaseSQLite,
    collection_id::String;
    kwargs...,
)
    _throw_if_collection_does_not_exist(db, collection_id)
    table_name = collection_id * "_timeseriesfiles"
    dict_time_series = Dict()
    for (key, value) in kwargs
        if !isa(value, AbstractString)
            psr_database_sqlite_error(
                "As a time_series_file the value of the attribute $key must be a String. User inputed $(typeof(value)): $value.",
            )
        end
        _throw_if_attribute_is_not_time_series_file(
            db,
            collection_id,
            string(key),
            :update,
        )
        _validate_time_series_attribute_value(value)
        dict_time_series[key] = value
    end
    # Count the number of elements in the time series
    df_count = DBInterface.execute(
        db.sqlite_db,
        "SELECT COUNT(*) FROM $table_name",
    ) |> DataFrame
    num_elements = df_count[1, 1]
    if num_elements == 0
        cols = join(keys(dict_time_series), ", ")
        vals = join(values(dict_time_series), "', '")
        DBInterface.execute(
            db.sqlite_db,
            "INSERT INTO $table_name ($cols) VALUES ('$vals')",
        )
    elseif num_elements == 1
        cols_vals = join(
            [string(key, " = '", value, "'") for (key, value) in dict_time_series],
            ", ",
        )
        DBInterface.execute(
            db.sqlite_db,
            """
            WITH TimeSeriesUpdate AS
            (
                SELECT * FROM $table_name
            )
            UPDATE $table_name
                SET $cols_vals
            """
        )
    else
        psr_database_sqlite_error(
            "There are currently $num_elements time series files in the collection $collection_id. " *
            "This is invalid, there should be only one entry in this table."
        )
            
    end
    return nothing
end
