const SQLInterface = OpenSQL.SQLInterface

function create_study(
    ::SQLInterface,
    path_db::AbstractString,
    path_schema::AbstractString;
    kwargs...,
)
    db = OpenSQL.create_empty_db(path_db, path_schema)
    OpenSQL.create_element!(db, "Configuration"; kwargs...)
    return db
end

load_study(::SQLInterface, data_path::String) = OpenSQL.load_db(data_path)

# Read
get_vector(db::OpenSQL.DB, collection::String, attribute::String, element_label::String) =
    OpenSQL.read_vector(
        db,
        collection,
        attribute,
        OpenSQL._get_id(db, collection, element_label),
    )

get_vectors(db::OpenSQL.DB, collection::String, attribute::String) =
    OpenSQL.read_vector(db, collection, attribute)

max_elements(db::OpenSQL.DB, collection::String) =
    length(get_parms(db, collection, "id"))

get_parm(db::OpenSQL.DB, collection::String, attribute::String, element_label::String) =
    OpenSQL.read_parameter(
        db,
        collection,
        attribute,
        OpenSQL._get_id(db, collection, element_label),
    )

get_parms(db::OpenSQL.DB, collection::String, attribute::String) =
    OpenSQL.read_parameter(db, collection, attribute)

function get_attributes(db::OpenSQL.DB, collection::String)
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

get_collections(db::OpenSQL.DB) = return OpenSQL.table_names(db)

function get_related(
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

get_vector_related(
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
create_element!(db::OpenSQL.DB, collection::String; kwargs...) =
    OpenSQL.create_element!(db, collection; kwargs...)

delete_element!(db::OpenSQL.DB, collection::String, element_label::String) =
    OpenSQL.delete!(db, collection, OpenSQL._get_id(db, collection, element_label))

set_parm!(
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

set_vector!(
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

set_related!(
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

set_vector_related!(
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

delete_relation!(
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
has_graf_file(db::OpenSQL.DB, collection::String, attribute::String) =
    OpenSQL.has_time_series(db, collection, attribute)

function link_series_to_file(
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

function link_series_to_files(
    db::OpenSQL.DB,
    collection::String;
    kwargs...,
)
    return OpenSQL.set_related_time_series!(db, collection; kwargs...)
end

function open(
    ::Type{OpenBinary.Reader},
    db::OpenSQL.DB,
    collection::String,
    attribute::String;
    kwargs...,
)
    if !has_graf_file(db, collection, attribute)
        error("Collection $collection does not have a graf file for attribute $attribute.")
    end
    time_series_table = OpenSQL._timeseries_table_name(collection)

    raw_files = get_parms(db, time_series_table, attribute)

    if OpenSQL.number_of_rows(db, time_series_table, attribute) == 0
        error("Collection $collection does not have a graf file for attribute $attribute.")
    end

    graf_file = raw_files[findfirst(x -> !ismissing(x), raw_files)]

    agents = get_parms(db, collection, "id")

    ior = open(
        OpenBinary.Reader,
        graf_file;
        header = agents,
        kwargs...,
    )

    return ior
end

function open(
    ::Type{OpenBinary.Writer},
    db::OpenSQL.DB,
    collection::String,
    attribute::String,
    path::String;
    kwargs...,
)
    if !has_graf_file(db, collection, attribute)
        error("Collection $collection does not have a graf file for attribute $attribute.")
    end
    time_series_table = OpenSQL._timeseries_table_name(collection)

    graf_file = if OpenSQL.number_of_rows(db, time_series_table, attribute) == 0
        link_series_to_file(db, collection, attribute, path)
        path
    else
        raw_files = get_parms(db, time_series_table, attribute)
        if raw_files[1] != path
            link_series_to_file(db, collection, attribute, path)
            path
        else
            raw_files[1]
        end
    end

    agents = get_parms(db, collection, "id")

    iow = open(
        OpenBinary.Writer,
        graf_file;
        agents = agents,
        kwargs...,
    )

    return iow
end
