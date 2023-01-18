# Check if study has a time series for a collection stored in a Graf file
function has_graf_file(data::Data, collection::String, attribute::Union{String, Nothing} = nothing)
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

# Add reference to graf file in JSON 
function link_series_to_file(
    data::Data, 
    collection::String,
    attribute::String,
    agent_attribute::String,
    file_name::String
    )
    if !haskey(data.raw, "GrafScenarios")
        data.raw["GrafScenarios"] = Vector{Dict{String,Any}}()
    end

    collection_elements = data.raw[collection]

    for element in collection_elements
        if haskey(element, attribute)
            pop!(element, attribute)
        end
    end
    
    graf_dict = Dict{String,Any}(
        "classname" => collection,
        "parmid"    => agent_attribute,
        "vector"    => attribute,
        "binary"    => [file_name * ".bin", file_name * ".hdr"]
    )

    push!(data.raw["GrafScenarios"], graf_dict)

    write_data(data)
    return
end