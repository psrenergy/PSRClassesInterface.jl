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

function delete_relation!(
    db::SQLite.DB,
    table_1::String,
    table_2::String,
    table_1_id::Integer,
    table_2_id::Integer,
)
    if !are_related(db, table_1, table_2, table_1_id, table_2_id)
        error(
            "Element with id $table_1_id from table $table_1 is not related to element with id $table_2_id from table $table_2.",
        )
    end

    id_parameter_on_table_1 = lowercase(table_2) * "_id"

    DBInterface.execute(
        db,
        "UPDATE $table_1 SET $id_parameter_on_table_1 = NULL WHERE id = '$table_1_id'",
    )

    return nothing
end
