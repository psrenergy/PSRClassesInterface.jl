function PSRI.create_study(
    ::PSRDatabaseSQLiteInterface,
    path_db::AbstractString;
    path_schema::String = "",
    path_migrations_directory::String = "",
    force::Bool = false,
    kwargs...,
)
    if !isempty(path_schema) && !isempty(path_migrations_directory)
        error(
            "User must define wither a `path_schema` or a `path_migrations_directory`. Not both.",
        )
    end

    db = if !isempty(path_schema)
        PSRDatabaseSQLite.create_empty_db_from_schema(path_db, path_schema; force)
    elseif !isempty(path_migrations_directory)
        PSRDatabaseSQLite.create_empty_db_from_migrations(
            path_db,
            path_migrations_directory;
            force,
        )
    else
        error(
            "User must provide either a `path_schema` or a `path_migrations_directory` to create a case.",
        )
    end
    
    dict_kwargs = Dict(kwargs)
    if !haskey(dict_kwargs, :id)
        dict_kwargs[:id] = 1
    end

    PSRDatabaseSQLite.create_element!(db, "Configuration"; dict_kwargs...)
    return db
end

PSRI.load_study(
    ::PSRDatabaseSQLiteInterface,
    data_path::String,
) = PSRDatabaseSQLite.load_db(data_path)

# Read
PSRI.get_vector(
    db::PSRDBSQLite,
    collection::String,
    attribute::String,
    element_label::String;
    default::Union{Nothing, Any} = nothing,
) =
    PSRDatabaseSQLite.read_vector_parameter(
        db,
        collection,
        attribute,
        element_label;
        default,
    )

PSRI.get_vectors(db::PSRDBSQLite, collection::String, attribute::String) =
    PSRDatabaseSQLite.read_vector_parameters(db, collection, attribute)

PSRI.max_elements(db::PSRDBSQLite, collection::String) =
    length(PSRI.get_parms(db, collection, "id"))

PSRI.get_parm(
    db::PSRDBSQLite,
    collection::String,
    attribute::String,
    element_label::String;
    default::Union{Nothing, Any} = nothing,
) =
    PSRDatabaseSQLite.read_scalar_parameter(
        db,
        collection,
        attribute,
        element_label;
        default,
    )

PSRI.get_parms(
    db::PSRDBSQLite,
    collection::String,
    attribute::String;
    default::Union{Nothing, Any} = nothing,
) =
    PSRDatabaseSQLite.read_scalar_parameters(db, collection, attribute; default)

function PSRI.get_attributes(db::PSRDBSQLite, collection::String)
    return PSRDatabaseSQLite._get_attribute_names(db, collection)
end

function PSRI.get_collections(db::PSRDBSQLite)
    return PSRDatabaseSQLite._get_collection_names(db)
end

function PSRI.get_map(
    db::PSRDBSQLite,
    source::String,
    target::String,
    relation_type::String,
)
    return _get_scalar_relation_map(
        db,
        source,
        target,
        relation_type,
    )
end

function PSRI.get_vector_map(
    db::PSRDBSQLite,
    source::String,
    target::String,
    relation_type::String,
)
    return _get_vector_relation_map(
        db,
        source,
        target,
        relation_type,
    )
end

function PSRI.get_related(
    db::PSRDBSQLite,
    source::String,
    target::String,
    source_label::String,
    relation_type::String,
)
    return PSRDatabaseSQLite.read_scalar_relation(
        db,
        source,
        target,
        relation_type,
        source_label,
    )
end

PSRI.get_vector_related(
    db::PSRDBSQLite,
    source::String,
    target::String,
    source_label::String,
    relation_type::String,
) = PSRDatabaseSQLite.read_vector_relation(
    db,
    source,
    target,
    source_label,
    relation_type,
)

# Modification
PSRI.create_element!(db::PSRDBSQLite, collection::String; kwargs...) =
    PSRDatabaseSQLite.create_element!(db, collection; kwargs...)

PSRI.delete_element!(
    db::PSRDBSQLite,
    collection::String,
    element_label::String,
) =
    PSRDatabaseSQLite.delete_element!(db, collection, element_label)

PSRI.set_parm!(
    db::PSRDBSQLite,
    collection::String,
    attribute::String,
    element_label::String,
    value,
) = PSRDatabaseSQLite.update_scalar_parameter!(
    db,
    collection,
    attribute,
    element_label,
    value,
)

PSRI.set_vector!(
    db::PSRDBSQLite,
    collection::String,
    attribute::String,
    element_label::String,
    values::AbstractVector,
) = PSRDatabaseSQLite.update_vector_parameters!(
    db,
    collection,
    attribute,
    element_label,
    values,
)

PSRI.set_related!(
    db::PSRDBSQLite,
    source::String,
    target::String,
    source_label::String,
    target_label::String,
    relation_type::String,
) = PSRDatabaseSQLite.set_scalar_relation!(
    db,
    source,
    target,
    PSRDatabaseSQLite._get_id(db, source, source_label),
    PSRDatabaseSQLite._get_id(db, target, target_label),
    relation_type,
)

PSRI.set_vector_related!(
    db::PSRDBSQLite,
    source::String,
    target::String,
    source_label::String,
    target_labels::Vector{String},
    relation_type::String,
) = PSRDatabaseSQLite.set_vector_relation!(
    db,
    source,
    target,
    source_label,
    target_labels,
    relation_type,
)

PSRI.delete_relation!(
    db::PSRDBSQLite,
    source::String,
    target::String,
    source_label::String,
    target_label::String,
) = error("Not implemented in PSRDatabaseSQLite.")

# Graf files
function PSRI.link_series_to_file(
    db::PSRDBSQLite,
    collection::String;
    kwargs...,
)
    return PSRDatabaseSQLite.set_time_series_file!(db, collection; kwargs...)
end
