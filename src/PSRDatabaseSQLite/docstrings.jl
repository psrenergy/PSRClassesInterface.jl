using TOML

struct GroupMap
    group_id::String
    parameters::Vector{TimeSeries{<:Number}}
    dimensions::Vector{String}
end

function _snake_case(string::String)
    string = replace(string, r"[\-\.\s]" => "_")
    words = lowercase.(split(string, r"(?=[A-Z])"))
    return join([i == 1 ? word : "_$word" for (i, word) in enumerate(words)])
end

function _get_parameter_metadata(parameter::Attribute, toml_map::Dict{Any, Any}, enum_map::Dict{String, Any})
    metadata = ""
    if haskey(toml_map, parameter.id)
        if haskey(toml_map[parameter.id], "tooltip")
            tooltip = if typeof(toml_map[parameter.id]["tooltip"]) == String
                toml_map[parameter.id]["tooltip"]
            else
                toml_map[parameter.id]["tooltip"]["en"]
            end
            if !ismissing(tooltip)
                metadata *= " $tooltip"
            end
        end
        if haskey(toml_map[parameter.id], "unit")
            unit = if typeof(toml_map[parameter.id]["unit"]) == String
                toml_map[parameter.id]["unit"]
            else
                toml_map[parameter.id]["unit"]["en"]
            end
            if !ismissing(unit)
                metadata *= " `[$unit]`"
            end
        end
        if haskey(toml_map[parameter.id], "enum")
            metadata *= "\n"
            for enum_value in enum_map[toml_map[parameter.id]["enum"]]
                value = if typeof(enum_value["label"]) == String
                    enum_value["label"]
                else
                    enum_value["label"]["en"]
                end
                metadata *= "   - `$(enum_value["id"])` [$(value)]"
                if !ismissing(parameter.default_value) && (parameter.default_value == enum_value["id"])
                    metadata *= " <default> \n"
                else
                    metadata *= "\n"
                end
            end
        elseif !ismissing(parameter.default_value)
            metadata *= " <default `$(parameter.default_value)`>"
        else
            metadata *= "\n"
        end
    end
    if isempty(metadata)
        return "\n"
    else
        return ":$metadata"
    end
end

function _get_collection_toml(collection::Collection, toml_path::String)
    toml_map = Dict()

    toml_reader = TOML.parsefile(toml_path)

    for attribute in toml_reader["attribute"]
        toml_map[attribute["id"]] = attribute
    end

    if haskey(toml_reader, "attribute_group")
        for attribute_group in toml_reader["attribute_group"]
            toml_map[attribute_group["id"]] = attribute_group
        end
    end

    return toml_map
end

function _get_enum_toml(collection::Collection, toml_path::String)
    if isfile(toml_path)
        toml_reader = TOML.parsefile(toml_path)
        return toml_reader
    end
    return Dict()
end

function _get_time_series_groups_map(
    parameters::OrderedDict{String, <:TimeSeries},
)
    groups_map = Dict{String, GroupMap}()
    for (key, parameter) in parameters
        if haskey(groups_map, parameter.group_id)
            push!(groups_map[parameter.group_id].parameters, parameter)
        else
            groups_map[parameter.group_id] = GroupMap(
                parameter.group_id,
                [parameter],
                parameter.dimension_names,
            )
        end
    end
    return groups_map
end

function _generate_docstrings(
    time_series_groups::Dict{String, GroupMap},
    toml_map::Dict{Any, Any},
    enum_map::Dict{String, Any},
)
    arguments = ""

    for (key, group) in time_series_groups
        entry = "Group `$(key)`:\n"
        for dimension in group.dimensions
            if dimension == "date_time"
                entry *= "- `date_time::Vector{DateTime}`: date and time of the time series \n"
            else
                entry *= "- `$(dimension)::Vector{Int64}`: dimension of the time series \n"
            end
        end
        for parameter in group.parameters
            entry *= "- `$(parameter.id)::Vector{$(parameter.type)}`"
            entry *= _get_parameter_metadata(parameter, toml_map, enum_map)
            if !ismissing(parameter.default_value)
                entry *= " (default: `$(parameter.default_value)`)"
            end
        end
        arguments *= entry
    end
    if length(arguments) > 0
        divider = """
        ---

        **Time Series Attributes**\n
        """
        arguments = divider * arguments
    end

    return arguments
end

function _generate_docstrings(
    parameters::OrderedDict{String, <:ScalarAttribute},
    toml_map::Dict{Any, Any},
    enum_map::Dict{String, Any};
    ignore_id::Bool = true,
)
    required_arguments = ""
    optional_arguments = ""

    for (key, parameter) in parameters
        if ignore_id && parameter.id == "id"
            continue
        end
        if parameter.not_null
            entry = "- `$(parameter.id)::$(parameter.type)`"
            entry *= _get_parameter_metadata(parameter, toml_map, enum_map)
            required_arguments *= entry * " \n"
        else
            entry = "- `$(parameter.id)::$(parameter.type)`"
            entry *= _get_parameter_metadata(parameter, toml_map, enum_map)
            optional_arguments *= entry * " \n"
        end
    end
    return required_arguments, optional_arguments
end

function _generate_docstrings(
    parameters::OrderedDict{String, <:VectorAttribute},
    toml_map::Dict{Any, Any},
    enum_map::Dict{String, Any};
    ignore_id::Bool = true,
)
    required_arguments = ""
    optional_arguments = ""

    for (key, parameter) in parameters
        if ignore_id && parameter.id == "id"
            continue
        end
        if parameter.not_null
            entry = "- `$(parameter.id)::Vector{$(parameter.type)}`"
            entry *= _get_parameter_metadata(parameter, toml_map, enum_map)
            required_arguments *= entry * " \n"
        else
            entry = "- `$(parameter.id)::Vector{$(parameter.type)}`"
            entry *= _get_parameter_metadata(parameter, toml_map, enum_map)
            optional_arguments *= entry * " \n"
        end
    end
    return required_arguments, optional_arguments
end

function _generate_docstrings(
    parameters::OrderedDict{String, TimeSeriesFile},
    toml_map::Dict{Any, Any},
    enum_map::Dict{String, Any};
)
    arguments = ""

    for (key, parameter) in parameters
        entry = "- `$(parameter.id)::$(parameter.type)`"
        entry *= _get_parameter_metadata(parameter, toml_map, enum_map)
        arguments *= entry * " \n"
    end
    return arguments
end

function collection_docstring(
    model_folder::String,
    collection::String;
    ignore_id::Bool = true,
)
    docstring = ""

    mktempdir() do temp_folder
        study = create_empty_db_from_migrations(
            joinpath(temp_folder, "$(collection)_study.db"),
            joinpath(model_folder, "migrations"),
        )

        collection = study.collections_map[collection]

        toml_path = joinpath(model_folder, "ui", _snake_case(collection.id) * ".toml")
        attribute_toml_map = _get_collection_toml(collection, toml_path)

        enum_toml_map = _get_enum_toml(collection, joinpath(model_folder, "ui", "enum.toml"))
        required_arguments = ""
        optional_arguments = ""
        time_series_arguments = ""

        scalar_required, scalar_optional = _generate_docstrings(
            collection.scalar_parameters,
            attribute_toml_map,
            enum_toml_map;
            ignore_id = ignore_id,
        )
        required_arguments *= scalar_required
        optional_arguments *= scalar_optional

        scalar_relation_required, scalar_relation_optional = _generate_docstrings(
            collection.scalar_relations,
            attribute_toml_map,
            enum_toml_map;
            ignore_id = ignore_id,
        )
        required_arguments *= scalar_relation_required
        optional_arguments *= scalar_relation_optional

        vector_required, vector_optional = _generate_docstrings(
            collection.vector_parameters,
            attribute_toml_map,
            enum_toml_map;
            ignore_id = ignore_id,
        )
        required_arguments *= vector_required
        optional_arguments *= vector_optional

        vector_relation_required, vector_relation_optional = _generate_docstrings(
            collection.vector_relations,
            attribute_toml_map,
            enum_toml_map;
            ignore_id = ignore_id,
        )
        required_arguments *= vector_relation_required
        optional_arguments *= vector_relation_optional

        if length(required_arguments) > 0
            required_arguments = "Required arguments:\n" * required_arguments
        end
        if length(optional_arguments) > 0
            optional_arguments = "Optional arguments:\n" * optional_arguments
        end

        time_series_groups = _get_time_series_groups_map(
            collection.time_series,
        )

        for group in keys(time_series_groups)
            required_arguments *= "- `$(group)::DataFrames.DataFrame: A dataframe containing time series attributes (described below).`\n"
        end

        time_series_arguments = _generate_docstrings(
            time_series_groups,
            attribute_toml_map,
            enum_toml_map,
        )

        docstring *= "$(required_arguments)$(optional_arguments)$(time_series_arguments)"

        close!(study)
        return rm(study.database_path; force = true)
    end

    return docstring
end

function time_series_files_docstrings(
    model_folder::String,
    ignore_id::Bool = true,
)
    docstring = ""

    mktempdir() do temp_folder
        study = create_empty_db_from_migrations(
            joinpath(temp_folder, "time_series_files_study.db"),
            joinpath(model_folder, "migrations"),
        )

        for (key, collection) in study.collections_map
            toml_path = joinpath(model_folder, "ui", _snake_case(collection.id) * ".toml")
            attribute_toml_map = _get_collection_toml(collection, toml_path)

            enum_toml_map = _get_enum_toml(collection, joinpath(model_folder, "ui", "enum.toml"))

            if length(collection.time_series_files) == 0
                continue
            end
            collection_docstring = "Collection: `$(key)`\n"

            arguments = _generate_docstrings(
                collection.time_series_files,
                attribute_toml_map,
                enum_toml_map,
            )

            collection_docstring *= arguments
            collection_docstring *= "\n"
            docstring *= collection_docstring
        end

        close!(study)
        return rm(study.database_path; force = true)
    end

    return docstring
end
