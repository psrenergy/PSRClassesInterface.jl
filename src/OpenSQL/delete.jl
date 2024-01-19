function delete!(
    db::SQLite.DB,
    table::String,
    id::Integer,
)
    sanity_check(table, "id")
    id_exist_in_table(db, table, id)

    DBInterface.execute(db, "DELETE FROM $table WHERE id = '$id'")

    # TODO We might want to delete corresponding entries in the vector tables too
    return nothing
end
