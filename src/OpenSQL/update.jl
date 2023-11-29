function update!(
    db::SQLite.DB,
    table::String,
    column::String,
    id::String,
    val::T,
) where {T <: ValidOpenSQLDataType}
    sanity_check(db, table, column)
    DBInterface.execute(db, "UPDATE $table SET $column = '$val' WHERE id = '$id'")
    return nothing
end

function update!(
    db::SQLite.DB,
    table::String,
    column::String,
    val::T,
) where {T <: ValidOpenSQLDataType}
    sanity_check(db, table, column)
    DBInterface.execute(db, "UPDATE $table SET $column = '$val'")
    return nothing
end

function update!(
    db::SQLite.DB,
    table::String,
    column::String,
    id::String,
    vals::V,
) where {V <: AbstractVector}
    if !is_vector_parameter(db, table, column)
        error("Column $column is not a vector parameter.")
    end

    vector_table = _vector_table_name(table, column)

    current_vector = read_vector(db, table, column, id)
    current_length = length(current_vector)

    for idx in 1:current_length
        DBInterface.execute(
            db,
            "DELETE FROM $vector_table WHERE id = '$id' AND idx = $idx",
        )
    end

    create_vector!(db, table, id, column, vals)

    return nothing
end
