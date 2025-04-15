using TOML

function _snake_case(string)
    string = replace(string, r"[\-\.\s]" => "_")
    words = lowercase.(split(string, r"(?=[A-Z])"))
    return join([i==1 ? word : "_$word" for (i,word) in enumerate(words)])
end

function _get_parameter_metadata(parameter::String, toml_map::Dict{Any, Any})
    metadata = ""
    if haskey(toml_map, parameter)
        if haskey(toml_map[parameter], "tooltip")
            tooltip = toml_map[parameter]["tooltip"]["en"]
            if !ismissing(tooltip)
                metadata *= " $tooltip" 
            end
        end
        if haskey(toml_map[parameter], "unit")
            unit = toml_map[parameter]["unit"]
            if !ismissing(unit)
                metadata *= " `[$unit]`"
            end
        end
    end
    if isempty(metadata)
        return ""
    else
        return ":$metadata"
    end
end

function _get_collection_toml(collection::PSRDatabaseSQLite.Collection, toml_path::String)
    toml_map = Dict()

    toml_reader = TOML.parsefile(toml_path)

    for attribute in toml_reader["attribute"]
        toml_map[attribute["id"]] = attribute
    end
    
    for attribute_group in toml_reader["attribute_group"]
        toml_map[attribute_group["id"]] = attribute_group
    end

    return toml_map
end

function _generate_scalar_docstrings(
    parameters::OrderedCollections.OrderedDict{String, <: PSRClassesInterface.PSRDatabaseSQLite.ScalarAttribute},
    toml_map::Dict{Any, Any};
    ignore_id::Bool = true
)
    required_arguments = ""
    optional_arguments = ""

    for (key, parameter) in parameters
        if ignore_id && parameter.id == "id"
            continue
        end
        if parameter.not_null
            entry = "- `$(parameter.id)::$(parameter.type)`"
            entry *= _get_parameter_metadata(parameter.id, toml_map)
            if !ismissing(parameter.default_value)
                entry *= " (default: `$(parameter.default_value)`)"
            end
            required_arguments *= entry * ". \n"
        else 
            entry = "- `$(parameter.id)::$(parameter.type)`"
            entry *= _get_parameter_metadata(parameter.id, toml_map)
            if !ismissing(parameter.default_value)
                entry *= " (default: `$(parameter.default_value)`)"
            end
            optional_arguments *= entry * ". \n"
        end
    end
    return required_arguments, optional_arguments
end

function _generate_vector_docstrings(
    parameters::OrderedCollections.OrderedDict{String, <: PSRClassesInterface.PSRDatabaseSQLite.VectorAttribute},
    toml_map::Dict{Any, Any};
    ignore_id::Bool = true
)
    required_arguments = ""
    optional_arguments = ""

    for (key, parameter) in parameters
        if ignore_id && parameter.id == "id"
            continue
        end
        if parameter.not_null
            entry = "- `$(parameter.id)::Vector{$(parameter.type)}`"
            entry *= _get_parameter_metadata(parameter.id, toml_map)
            if !ismissing(parameter.default_value)
                entry *= " (default: `$(parameter.default_value)`)"
            end
            required_arguments *= entry * ". \n"
        else 
            entry = "- `$(parameter.id)::Vector{$(parameter.type)}`"
            entry *= _get_parameter_metadata(parameter.id, toml_map)
            if !ismissing(parameter.default_value)
                entry *= " (default: `$(parameter.default_value)`)"
            end
            optional_arguments *= entry * ". \n"
        end
    end
    return required_arguments, optional_arguments
end

function _get_time_series_groups_map(
    parameters::OrderedCollections.OrderedDict{String, <: PSRClassesInterface.PSRDatabaseSQLite.TimeSeries},
)
    groups_map = Dict()
    for (key, parameter) in parameters
        if haskey(groups_map, parameter.group_id)
            push!(groups_map[parameter.group_id]["parameters"], parameter)
        else
            groups_map[parameter.group_id] = Dict{String, Vector{Any}}()
            groups_map[parameter.group_id]["parameters"] = [parameter]
            groups_map[parameter.group_id]["dimensions"] = parameter.dimension_names
        end
    end
    return groups_map
end


function _generate_time_series_docstrings(
    time_series_groups::Dict{Any, Any},
    toml_map::Dict{Any, Any};
)
    arguments = ""

    for (key, group) in time_series_groups
        entry = "Group `$(key)`:\n"
        for dimension in group["dimensions"]
            if dimension == "date_time"
                entry *= "- `date_time::Vector{DateTime}`: date and time of the time series. \n"
            else
                entry *= "- `$(dimension)::Vector{Int64}`: dimension of the time series. \n"
            end
        end
        for parameter in group["parameters"]
            entry *= "- `$(parameter.id)::Vector{$(parameter.type)}`"
            entry *= _get_parameter_metadata(parameter.id, toml_map)
            if !ismissing(parameter.default_value)
                entry *= " (default: `$(parameter.default_value)`)"
            end
            entry *= ". \n"
        end
        arguments *= entry * "\n"
    end
    return arguments
end

function parameters_docstring(
    collection::PSRDatabaseSQLite.Collection; 
    model_database_folder::String = "",
    ignore_id::Bool = true
    )

    toml_map = if model_database_folder != ""
        toml_path = joinpath(model_database_folder, "ui", _snake_case(collection.id) * ".toml")
        _get_collection_toml(collection, toml_path)
    else
        Dict()
    end
    
    required_arguments = ""
    optional_arguments = ""
    time_series_arguments = ""


    scalar_required, scalar_optional = _generate_scalar_docstrings(
        collection.scalar_parameters,
        toml_map;
        ignore_id = ignore_id
    )
    required_arguments *= scalar_required
    optional_arguments *= scalar_optional

    scalar_relation_required, scalar_relation_optional = _generate_scalar_docstrings(
        collection.scalar_relations,
        toml_map;
        ignore_id = ignore_id
    )
    required_arguments *= scalar_relation_required
    optional_arguments *= scalar_relation_optional

    vector_required, vector_optional = _generate_vector_docstrings(
        collection.vector_parameters,
        toml_map;
        ignore_id = ignore_id
    )
    required_arguments *= vector_required
    optional_arguments *= vector_optional

    time_series_groups = _get_time_series_groups_map(
        collection.time_series
    )

    for group in keys(time_series_groups)
        required_arguments *= "- `$(group)::DataFrames.DataFrame: A dataframe containing time series attributes (described below).`\n"
    end

    time_series_arguments = _generate_time_series_docstrings(
        time_series_groups,
        toml_map;
    )
    


    docstring = """
    Required arguments:
    $required_arguments \n
    Optional arguments:
    $optional_arguments

    --- 

    ** Time Series Attributes **

    $time_series_arguments
    """
    return println(docstring)
end