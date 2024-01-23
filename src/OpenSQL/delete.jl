"""
    delete_element!(db::SQLite.DB, collection::String, label::String)

Deletes an element from a collection.
"""
function delete_element!(
    db::SQLite.DB,
    collection::String,
    label::String,
)
    sanity_check(collection)
    id = _get_id(db, collection, label)
    _delete_element!(db, collection, id)
    return nothing
end

function _delete_element!(
    db::SQLite.DB,
    table::String,
    id::Integer,
)
    # This assumes that we have on cascade delete for every reference 
    DBInterface.execute(db, "DELETE FROM $table WHERE id = '$id'")
    return nothing
end
