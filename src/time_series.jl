# Check if study has a time series for a collection stored in a Graf file
function has_graf_file(data::Data, collection::String)
    _check_collection_in_study(data, collection)

    if !haskey(data.raw, collection)   
        error("No '$collection' elements in this study")
    end

    if !haskey(data.raw, "GrafScenarios")   
        return false
    end

    for graf in data.raw["GrafScenarios"]
        if graf["classname"] == collection
            return true
        end
    end

    return false
end

# Get time series stored in a graf file for a collection
function get_time_series(data::Data, collection::String)
    if !has_graf_file(data, collection)
        error("No time series file for collection '$collection'")
    end

    graf_files = Vector{String}()

    for graf in data.raw["GrafScenarios"]
        if graf["classname"] == collection
            append!(graf_files, graf["binary"])
        end
    end

    graf_file = first(graf_files)
    graf_path = joinpath(data.data_path, first(splitext(graf_file)))

    time_series_data = file_to_array(
        OpenBinary.Reader, 
        graf_path;
        use_header=false
    )

    return time_series_data
end
