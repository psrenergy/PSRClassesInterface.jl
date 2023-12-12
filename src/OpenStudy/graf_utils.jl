# Check if study has a time series for a collection stored in a Graf file
function PSRI.has_graf_file(
    data::Data,
    collection::String,
    attribute::Union{String, Nothing} = nothing,
)
    _check_collection_in_study(data, collection)

    if !haskey(data.raw, collection)
        return false
    end

    if !haskey(data.raw, "GrafScenarios")
        return false
    end

    for graf in data.raw["GrafScenarios"]
        if graf["classname"] == collection
            if isnothing(attribute)
                return true
            end
            if graf["vector"] == attribute
                return true
            end
        end
    end

    return false
end

function _get_graf_filename(data::Data, collection::String, attribute::String)
    if !PSRI.has_graf_file(data, collection, attribute)
        error("Collection '$collection' does not have a Graf file for '$attribute'.")
    end

    for graf in data.raw["GrafScenarios"]
        if graf["classname"] == collection
            if graf["vector"] == attribute
                return first(splitext(first(graf["binary"])))
            end
        end
    end
    return
end

function _get_graf_agents(graf_file::String)
    ior = PSRI.open(PSRI.OpenBinary.Reader, graf_file; use_header = false)
    return ior.agent_names
end

# Checks if names for Agents in Study are equal to the ones in Graf file
function _validate_json_graf(
    agent_attribute::String,
    elements::Vector{Dict{String, Any}},
    graf_file::String,
)
    ior = PSRI.open(PSRI.OpenBinary.Reader, graf_file; use_header = false)

    agents_json = Vector{String}()
    for element in elements
        push!(agents_json, element[agent_attribute])
    end

    if sort(agents_json) != sort(ior.agent_names)
        error("Agent names from your Study are different from the ones in Graf file")
    end

    return
end

# Add reference to graf file in JSON 
function PSRI.link_series_to_file(
    data::Data,
    collection::String,
    attribute::String,
    agent_attribute::String,
    file_name::String,
)
    if !haskey(data.raw, "GrafScenarios")
        data.raw["GrafScenarios"] = Vector{Dict{String, Any}}()
    end

    if _get_attribute_type(data, collection, agent_attribute) != String
        error("Attribute '$agent_attribute' can only be an Attribute of type String")
    end

    collection_elements = data.raw[collection]

    _validate_json_graf(agent_attribute, collection_elements, file_name)

    for element in collection_elements
        if haskey(element, attribute)
            pop!(element, attribute)
        end
    end

    graf_dict = Dict{String, Any}(
        "classname" => collection,
        "parmid" => agent_attribute,
        "vector" => attribute,
        "binary" => [file_name * ".bin", file_name * ".hdr"],
    )

    push!(data.raw["GrafScenarios"], graf_dict)

    PSRI.write_data(data)
    return
end
