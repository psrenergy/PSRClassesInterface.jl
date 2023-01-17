# Check if study has a time series for a collection stored in a Graf file
function has_graf_file(data::Data, collection::String, attribute::String)
    _check_collection_in_study(data, collection)

    if !haskey(data.raw, collection)   
        error("No '$collection' elements in this study")
    end

    if !haskey(data.raw, "GrafScenarios")   
        return false
    end

    for graf in data.raw["GrafScenarios"]
        if graf["classname"] == collection && graf["vector"] == attribute
            return true
        end
    end

    return false
end

# Get time series stored in a graf file for a collection
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

    time_series_data = file_to_array(
        OpenBinary.Reader, 
        graf_path;
        use_header=false
    )

    return time_series_data
end

function set_series!(
    data::Data, 
    collection::String, 
    attribute::String, 
    file_name::String = "grafscenarios"
    )
    

    
end

# function set_series!(
#     data::Data,
#     path::String,
#     data::Array{Float64,4};
#     collection::String,
#     agent_attribute::String,
#     unit::String = "",
#     initial_stage::Int32,
#     initial_year::Int32,
# )
#     attributes = _get_indexed_attributes(data, collection, index, indexing_attribute)

#     valid = true

#     if length(buffer) != length(attributes)
#         valid = false
#     end

#     for attribute in attributes
#         if !haskey(buffer, attribute)
#             valid = false
#             break
#         end
#     end

#     if !valid
#         missing_attrs = setdiff(attributes, keys(buffer))

#         for attribute in missing_attrs
#             @error "Missing attribute '$(attribute)'"
#         end

#         invalid_attrs = setdiff(keys(buffer), attributes)

#         for attribute in invalid_attrs
#             @error "Invalid attribute '$(attribute)'"
#         end

#         error("Invalid attributes for series indexed by $(indexing_attribute)")
#     end

#     new_length = nothing

#     for vector in values(buffer)
#         if isnothing(new_length)
#             new_length = length(vector)
#         end

#         if length(vector) != new_length
#             error("All vectors must be of the same length in a series")
#         end
#     end

#     element = _get_element(data, collection, index)

#     # validate types
#     for (attribute, vector) in buffer
#         attribute_struct = get_attribute_struct(data, collection, attribute)
#         _check_type(attribute_struct, eltype(vector), collection, attribute)
#     end

#     for (attribute, vector) in buffer
#         # protect user's data
#         element[attribute] = deepcopy(vector)
#     end

#     return nothing
# end