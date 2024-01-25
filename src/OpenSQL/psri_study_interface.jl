function PSRI.create_study(
    ::OpenSQLInterface,
    path_db::AbstractString;
    path_schema::String = "",
    path_migrations_directory::String = "",
    force::Bool = false,
    kwargs...,
)
    if !isempty(path_schema) && !isempty(path_migrations_directory)
        error("User must define wither a `path_schema` or a `path_migrations_directory`. Not both.")
    end

    opensql_db = if !isempty(path_schema)
        OpenSQL.create_empty_db_from_schema(path_db, path_schema; force)
    elseif !isempty(path_migrations_directory)
        OpenSQL.create_empty_db_from_migrations(path_db, path_migrations_directory; force)
    else
        error("User must provide either a `path_schema` or a `path_migrations_directory` to create a case.")
    end
    
    OpenSQL.create_element!(opensql_db, "Configuration"; kwargs...)
    return opensql_db
end

PSRI.load_study(
    ::OpenSQLInterface, 
    data_path::String
) = OpenSQL.load_db(data_path)

# Read
PSRI.get_vector(
    opensql_db::OpenSQLDataBase,
    collection::String,
    attribute::String,
    element_label::String,
) =
    OpenSQL.read_vector_parameter(
        opensql_db,
        collection,
        attribute,
        element_label,
    )

PSRI.get_vectors(opensql_db::OpenSQLDataBase, collection::String, attribute::String) =
    OpenSQL.read_vector_parameters(opensql_db, collection, attribute)

PSRI.max_elements(opensql_db::OpenSQLDataBase, collection::String) =
    length(PSRI.get_parms(opensql_db, collection, "id"))

PSRI.get_parm(
    opensql_db::OpenSQLDataBase,
    collection::String,
    attribute::String,
    element_label::String,
) =
    OpenSQL.read_scalar_parameter(
        opensql_db,
        collection,
        attribute,
        element_label,
    )

PSRI.get_parms(opensql_db::OpenSQLDataBase, collection::String, attribute::String) =
    OpenSQL.read_scalar_parameters(opensql_db, collection, attribute)

function PSRI.get_attributes(opensql_db::OpenSQLDataBase, collection::String)
    return OpenSQL._get_attribute_names(opensql_db, collection)
end

function PSRI.get_collections(opensql_db::OpenSQLDataBase)
    return OpenSQL._get_collection_names(opensql_db)
end

function PSRI.get_map(
    opensql_db::OpenSQLDataBase,
    source::String,
    target::String,
    relation_type::String,
)
    return _get_scalar_relation_map(
        opensql_db,
        source,
        target,
        relation_type,
    )
end

function PSRI.get_vector_map(
    opensql_db::OpenSQLDataBase,
    source::String,
    target::String,
    relation_type::String,
)
    return _get_vector_relation_map(
        opensql_db,
        source,
        target,
        relation_type,
    )
end

function PSRI.get_related(
    opensql_db::OpenSQLDataBase,
    source::String,
    target::String,
    source_label::String,
    relation_type::String,
)
    return OpenSQL.read_scalar_relation(
        opensql_db,
        source,
        target,
        relation_type,
        source_label,
    )
end

PSRI.get_vector_related(
    opensql_db::OpenSQLDataBase,
    source::String,
    target::String,
    source_label::String,
    relation_type::String
) = OpenSQL.read_vector_relation(
    opensql_db,
    source,
    target,
    source_label,
    relation_type,
)

# Modification
PSRI.create_element!(opensql_db::OpenSQLDataBase, collection::String; kwargs...) =
    OpenSQL.create_element!(opensql_db, collection; kwargs...)

PSRI.delete_element!(opensql_db::OpenSQLDataBase, collection::String, element_label::String) =
    OpenSQL.delete_element!(opensql_db, collection, element_label)

PSRI.set_parm!(
    opensql_db::OpenSQLDataBase,
    collection::String,
    attribute::String,
    element_label::String,
    value,
) = OpenSQL.update_scalar_parameter!(
    opensql_db,
    collection,
    attribute,
    element_label,
    value,
)

PSRI.set_vector!(
    opensql_db::OpenSQLDataBase,
    collection::String,
    attribute::String,
    element_label::String,
    values::AbstractVector,
) = OpenSQL.update_vector_parameters!(
    opensql_db,
    collection,
    attribute,
    element_label,
    values,
)

PSRI.set_related!(
    opensql_db::OpenSQLDataBase,
    source::String,
    target::String,
    source_label::String,
    target_label::String,
    relation_type::String,
) = OpenSQL.set_scalar_relation!(
    opensql_db,
    source,
    target,
    OpenSQL._get_id(opensql_db, source, source_label),
    OpenSQL._get_id(opensql_db, target, target_label),
    relation_type,
)

PSRI.set_vector_related!(
    opensql_db::OpenSQLDataBase,
    source::String,
    target::String,
    source_label::String,
    target_labels::Vector{String},
    relation_type::String,
) = OpenSQL.set_vector_relation!(
    opensql_db,
    source,
    target,
    source_label,
    target_labels,
    relation_type,
)

PSRI.delete_relation!(
    opensql_db::OpenSQLDataBase,
    source::String,
    target::String,
    source_label::String,
    target_label::String,
) = error("Not implemented in OpenSQL.")

# Graf files
function PSRI.link_series_to_file(
    opensql_db::OpenSQLDataBase,
    collection::String;
    kwargs...,
)
    return OpenSQL.set_time_series_file!(opensql_db, collection; kwargs...)
end
