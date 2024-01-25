function PSRI.create_study(
    ::SQLInterface,
    path_db::AbstractString,
    path_schema::AbstractString;
    kwargs...,
)
    db = OpenSQL.create_empty_db_from_schema(path_db, path_schema)
    OpenSQL.create_element!(db, "Configuration"; kwargs...)
    return db
end

function PSRI.create_study(
    ::SQLInterface,
    path_db::AbstractString;
    kwargs...,
)
    db = OpenSQL.create_empty_db_from_schema(path_db)
    OpenSQL.create_element!(db, "Configuration"; kwargs...)
    return db
end

PSRI.load_study(::SQLInterface, data_path::String) = OpenSQL.load_db(data_path)

# Read
PSRI.get_vector(
    db::OpenSQL.DB,
    collection::String,
    attribute::String,
    element_label::String,
) =
    OpenSQL.read_vector_parameter(
        db,
        collection,
        attribute,
        element_label,
    )

PSRI.get_vectors(db::OpenSQL.DB, collection::String, attribute::String) =
    OpenSQL.read_vector_parameters(db, collection, attribute)

PSRI.max_elements(db::OpenSQL.DB, collection::String) =
    length(PSRI.get_parms(db, collection, "id"))

PSRI.get_parm(
    db::OpenSQL.DB,
    collection::String,
    attribute::String,
    element_label::String,
) =
    OpenSQL.read_scalar_parameter(
        db,
        collection,
        attribute,
        element_label,
    )

PSRI.get_parms(db::OpenSQL.DB, collection::String, attribute::String) =
    OpenSQL.read_scalar_parameters(db, collection, attribute)

function PSRI.get_attributes(::OpenSQL.DB, collection::String)
    return OpenSQL._get_attribute_names(collection)
end

function PSRI.get_collections(::OpenSQL.DB)
    return OpenSQL._get_collection_names()
end

function PSRI.get_map(
    db::OpenSQL.DB,
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
    db::OpenSQL.DB,
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
    db::OpenSQL.DB,
    source::String,
    target::String,
    source_label::String,
    relation_type::String,
)
    return OpenSQL.read_scalar_relation(
        db,
        source,
        target,
        relation_type,
        source_label,
    )
end

PSRI.get_vector_related(
    db::OpenSQL.DB,
    source::String,
    target::String,
    source_label::String,
    relation_type::String
) = OpenSQL.read_vector_relation(
    db,
    source,
    target,
    source_label,
    relation_type,
)

# Modification
PSRI.create_element!(db::OpenSQL.DB, collection::String; kwargs...) =
    OpenSQL.create_element!(db, collection; kwargs...)

PSRI.delete_element!(db::OpenSQL.DB, collection::String, element_label::String) =
    OpenSQL.delete_element!(db, collection, element_label)

PSRI.set_parm!(
    db::OpenSQL.DB,
    collection::String,
    attribute::String,
    element_label::String,
    value,
) = OpenSQL.update_scalar_parameter!(
    db,
    collection,
    attribute,
    element_label,
    value,
)

PSRI.set_vector!(
    db::OpenSQL.DB,
    collection::String,
    attribute::String,
    element_label::String,
    values::AbstractVector,
) = OpenSQL.update_vector_parameters!(
    db,
    collection,
    attribute,
    element_label,
    values,
)

PSRI.set_related!(
    db::OpenSQL.DB,
    source::String,
    target::String,
    source_label::String,
    target_label::String,
    relation_type::String,
) = OpenSQL.set_scalar_relation!(
    db,
    source,
    target,
    OpenSQL._get_id(db, source, source_label),
    OpenSQL._get_id(db, target, target_label),
    relation_type,
)

PSRI.set_vector_related!(
    db::OpenSQL.DB,
    source::String,
    target::String,
    source_label::String,
    target_labels::Vector{String},
    relation_type::String,
) = OpenSQL.set_vector_relation!(
    db,
    source,
    target,
    source_label,
    target_labels,
    relation_type,
)

PSRI.delete_relation!(
    db::OpenSQL.DB,
    source::String,
    target::String,
    source_label::String,
    target_label::String,
) = error("Not implemented in OpenSQL.")

# Graf files
function PSRI.link_series_to_file(
    db::OpenSQL.DB,
    collection::String;
    kwargs...,
)
    return OpenSQL.set_time_series_file!(db, collection; kwargs...)
end
