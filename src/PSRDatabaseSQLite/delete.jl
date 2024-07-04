"""
TODO
"""
function delete_element!(
    db::DatabaseSQLite,
    collection_id::String,
    label::String,
)
    _throw_if_collection_does_not_exist(db, collection_id)
    id = _get_id(db, collection_id, label)
    delete_element!(db, collection_id, id)
    return nothing
end

function delete_element!(
    db::DatabaseSQLite,
    collection_id::String,
    id::Integer,
)
    # This assumes that we have on cascade delete for every reference 
    DBInterface.execute(
        db.sqlite_db,
        "DELETE FROM $collection_id WHERE id = '$id'",
    )
    return nothing
end

function _delete_time_series!(
    db::DatabaseSQLite,
    collection_id::String,
    group_id::String,
    id::Integer,
)
    time_series_table_name = "$(collection_id)_time_series_$(group_id)"

    DBInterface.execute(
        db.sqlite_db,
        "DELETE FROM $(time_series_table_name) WHERE id = '$id'",
    )
    return nothing
end

function delete_time_series!(
    db::DatabaseSQLite,
    collection_id::String,
    group_id::String,
    label::String,
)
    _throw_if_collection_does_not_exist(db, collection_id)
    id = _get_id(db, collection_id, label)

    _delete_time_series!(db, collection_id, group_id, id)

    return nothing
end
