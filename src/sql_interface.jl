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
        if startswith(table, "_" * collection * "_") && !endswith(table, "_TimeSeries")
            push!(vector_attributes, split(table, collection * "_")[end])
        end
    end
    if OpenSQL.has_time_series(db, collection)
        time_series_table = "_" * collection * "_TimeSeries"
        time_series_attributes = OpenSQL.column_names(db, time_series_table)
        deleteat!(time_series_attributes, findfirst(x -> x == "id", time_series_attributes))
        return vcat(columns, vector_attributes, time_series_attributes)
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
    time_series_table = OpenSQL._time_series_table_name(collection)

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
    return OpenSQL.create_related_time_series!(db, collection; kwargs...)
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
    time_series_table = OpenSQL._time_series_table_name(collection)

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
    time_series_table = OpenSQL._time_series_table_name(collection)

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
