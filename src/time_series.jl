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

# Get GrafTable stored in a graf file for a collection
function get_series(
    data::Data, 
    collection::String, 
    attribute::String
    )
    if !has_graf_file(data, collection)
        error("No time series file for collection '$collection'")
    end

    graf_files = Vector{String}()

    for graf in data.raw["GrafScenarios"]
        if graf["classname"] == collection && graf["vector"] == attribute 
            append!(graf_files, graf["binary"])
        end
    end

    graf_file = first(graf_files)
    graf_path = joinpath(data.data_path, first(splitext(graf_file)))

    graf_table = GrafTable(graf_path)

    return graf_table
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