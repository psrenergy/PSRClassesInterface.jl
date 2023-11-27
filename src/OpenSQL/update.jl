function update!(
    db::SQLite.DB,
    table::String,
    column::String,
    id::String,
    val,
)
    sanity_check(db, table, column)
    DBInterface.execute(db, "UPDATE $table SET $column = '$val' WHERE id = '$id'")
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
