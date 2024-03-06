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
