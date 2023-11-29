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

    DBInterface.execute(db, "UPDATE $vector_table SET $column = '$vals' WHERE id = '$id'")

    error("Updating vectors is not yet implemented.")
    return nothing
end
