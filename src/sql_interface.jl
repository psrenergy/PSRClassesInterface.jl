const SQLInterface = OpenSQL.SQLInterface

function create_study(
    ::SQLInterface;
    data_path::AbstractString = pwd(),
    schema::AbstractString = "schema",
    study_collection::String = "PSRStudy",
    kwargs...,
)
    path_db = joinpath(data_path, "psrclasses.sqlite")
    path_schema = joinpath(data_path, "$(schema).sql")
    db = OpenSQL.create_empty_db(path_db, path_schema)
    OpenSQL.create_element!(db, study_collection; kwargs...)
    return db
end

load_study(::SQLInterface; data_path::String) = OpenSQL.load_db(data_path)

# Read
get_vector(db::OpenSQL.DB, table::String, vector_name::String, element_id::String) =
    OpenSQL.read_vector(db, table, vector_name, element_id)

get_vectors(db::OpenSQL.DB, table::String, vector_name::String) =
    OpenSQL.read_vector(db, table, vector_name)

max_elements(db::OpenSQL.DB, collection::String) =
    length(get_parms(db, collection, "id"))

get_parm(db::OpenSQL.DB, collection::String, attribute::String, element_id::String) =
    OpenSQL.read_parameter(db, collection, attribute, element_id)

get_parms(db::OpenSQL.DB, collection::String, attribute::String) =
    OpenSQL.read_parameter(db, collection, attribute)

function get_attributes(db::OpenSQL.DB, collection::String)
    columns = OpenSQL.column_names(db, collection)

    tables = OpenSQL.table_names(db)
    vector_attributes = Vector{String}()
    for table in tables
        if startswith(table, "_" * collection * "_")
            push!(vector_attributes, split(table, collection * "_")[end])
        end
    end
    return vcat(columns, vector_attributes)
end

get_collections(db::OpenSQL.DB) = return OpenSQL.table_names(db)

# Modification
create_element!(db::OpenSQL.DB, collection::String; kwargs...) =
    OpenSQL.create_element!(db, collection; kwargs...)

delete_element!(db::OpenSQL.DB, collection::String, element_id::String) =
    OpenSQL.delete!(db, collection, element_id)

set_parm!(
    db::OpenSQL.DB,
    collection::String,
    attribute::String,
    element_id::String,
    value,
) = OpenSQL.update!(db, collection, attribute, element_id, value)

set_vector!(
    db::OpenSQL.DB,
    collection::String,
    attribute::String,
    element_id::String,
    values::AbstractVector,
) = OpenSQL.update!(db, collection, attribute, element_id, values)

set_related!(
    db::OpenSQL.DB,
    source::String,
    target::String,
    source_id::String,
    target_id::String,
) = OpenSQL.set_related!(db, source, target, source_id, target_id)

delete_relation!(
    db::OpenSQL.DB,
    source::String,
    target::String,
    source_id::String,
    target_id::String,
) = OpenSQL.delete_relation!(db, source, target, source_id, target_id)
