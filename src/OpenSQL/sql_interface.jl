function PSRI.create_study(
    ::SQLInterface,
    path_db::AbstractString,
    path_schema::AbstractString;
    kwargs...,
)
    db = OpenSQL.create_empty_db(path_db, path_schema)
    if haskey(kwargs, :id)
        OpenSQL.create_element!(db, "Configuration"; kwargs...)
    else
        OpenSQL.create_element!(db, "Configuration"; id = 1, kwargs...)
    end
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
    OpenSQL.read_vector(
        db,
        collection,
        attribute,
        OpenSQL._get_id(db, collection, element_label),
    )

PSRI.get_vectors(db::OpenSQL.DB, collection::String, attribute::String) =
    OpenSQL.read_vector(db, collection, attribute)

PSRI.max_elements(db::OpenSQL.DB, collection::String) =
    length(PSRI.get_parms(db, collection, "id"))

PSRI.get_parm(
    db::OpenSQL.DB,
    collection::String,
    attribute::String,
    element_label::String,
) =
    OpenSQL.read_parameter(
        db,
        collection,
        attribute,
        OpenSQL._get_id(db, collection, element_label),
    )

PSRI.get_parms(db::OpenSQL.DB, collection::String, attribute::String) =
    OpenSQL.read_parameter(db, collection, attribute)

function PSRI.get_attributes(db::OpenSQL.DB, collection::String)
    columns = OpenSQL.column_names(db, collection)

    tables = OpenSQL.table_names(db)
    vector_attributes = Vector{String}()
    for table in tables
        if startswith(table, collection * "_vector_")
            push!(vector_attributes, OpenSQL.get_vector_attribute_name(table))
        end
    end
    if OpenSQL.has_time_series(db, collection)
        time_series_table = OpenSQL._timeseries_table_name(collection)
        time_series_attributes = OpenSQL.column_names(db, time_series_table)
        return vcat(columns, vector_attributes, time_series_attributes)
    end
    return vcat(columns, vector_attributes)
end

PSRI.get_collections(db::OpenSQL.DB) = return OpenSQL.table_names(db)

function PSRI.get_related(
    db::OpenSQL.DB,
    source::String,
    target::String,
    source_label::String,
    relation_type::String,
)
    id = OpenSQL.read_related(
        db,
        source,
        target,
        OpenSQL._get_id(db, source, source_label),
        relation_type,
    )
    return OpenSQL.read_parameter(db, target, "label", id)
end

PSRI.get_vector_related(
    db::OpenSQL.DB,
    source::String,
    source_label::String,
    relation_type::String,
) = OpenSQL.read_vector_related(
    db,
    source,
    OpenSQL._get_id(db, source, source_label),
    relation_type,
)

# Modification
PSRI.create_element!(db::OpenSQL.DB, collection::String; kwargs...) =
    OpenSQL.create_element!(db, collection; kwargs...)

PSRI.delete_element!(db::OpenSQL.DB, collection::String, element_label::String) =
    OpenSQL.delete!(db, collection, OpenSQL._get_id(db, collection, element_label))

PSRI.set_parm!(
    db::OpenSQL.DB,
    collection::String,
    attribute::String,
    element_label::String,
    value,
) = OpenSQL.update!(
    db,
    collection,
    attribute,
    OpenSQL._get_id(db, collection, element_label),
    value,
)

PSRI.set_vector!(
    db::OpenSQL.DB,
    collection::String,
    attribute::String,
    element_label::String,
    values::AbstractVector,
) = OpenSQL.update!(
    db,
    collection,
    attribute,
    OpenSQL._get_id(db, collection, element_label),
    values,
)

PSRI.set_related!(
    db::OpenSQL.DB,
    source::String,
    target::String,
    source_label::String,
    target_label::String,
    relation_type::String,
) = OpenSQL.set_related!(
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
    target_label::String,
    relation_type::String,
) = OpenSQL.set_vector_related!(
    db,
    source,
    target,
    OpenSQL._get_id(db, source, source_label),
    OpenSQL._get_id(db, target, target_label),
    relation_type,
)

PSRI.delete_relation!(
    db::OpenSQL.DB,
    source::String,
    target::String,
    source_label::String,
    target_label::String,
) = OpenSQL.delete_relation!(
    db,
    source,
    target,
    OpenSQL._get_id(db, source, source_label),
    OpenSQL._get_id(db, target, target_label),
)

# Graf files
PSRI.has_graf_file(db::OpenSQL.DB, collection::String, attribute::String) =
    OpenSQL.has_time_series(db, collection, attribute)

function PSRI.link_series_to_file(
    db::OpenSQL.DB,
    collection::String,
    attribute::String,
    file_path::String,
)
    if !OpenSQL.has_time_series(db, collection, attribute)
        error("Collection $collection does not have a graf file for attribute $attribute.")
    end
    time_series_table = OpenSQL._timeseries_table_name(collection)

    if OpenSQL.number_of_rows(db, time_series_table, attribute) == 0
        OpenSQL.create_parameters!(db, time_series_table, Dict(attribute => file_path))
    else
        OpenSQL.update!(db, time_series_table, attribute, file_path)
    end
    return nothing
end

function PSRI.link_series_to_file(
    db::OpenSQL.DB,
    collection::String;
    kwargs...,
)
    return OpenSQL.set_related_time_series!(db, collection; kwargs...)
end
