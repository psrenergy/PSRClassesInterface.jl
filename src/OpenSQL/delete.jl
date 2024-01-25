"""
TODO
"""
function delete_element!(
    opensql_db::OpenSQLDataBase,
    collection_name::String,
    label::String,
)
    _throw_if_collection_does_not_exist(opensql_db, collection_name)
    id = _get_id(opensql_db, collection_name, label)
    _delete_element!(opensql_db, collection_name, id)
    return nothing
end

function _delete_element!(
    opensql_db::OpenSQLDataBase,
    collection_name::String,
    id::Integer,
)
    # This assumes that we have on cascade delete for every reference 
    DBInterface.execute(
        opensql_db.sqlite_db,
        "DELETE FROM $collection_name WHERE id = '$id'",
    )
    return nothing
end
