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
    columns::String,
    id::String,
    vals::V,
) where {V <: AbstractVector}
    error("Updating vectors is not yet implemented.")
    return nothing
end
