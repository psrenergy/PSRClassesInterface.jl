function trim_multidimensional_attribute(attribute::String)
    regex = r"([a-zA-Z_&]+)\([0-9]+(\,[0-9]+)*\)"

    m = match(regex, attribute)

    if isnothing(m)
        return attribute
    else
        return m[1]
    end
end

function get_attributes(data::AbstractData, collection::String)
    return get_attributes(get_data_struct(data), collection)
end

function get_attributes(data::DataStruct, collection::String)
    return sort!(collect(keys(data[collection])))
end

function get_attribute_struct(data::AbstractData, collection::String, attribute::String)
    return get_attribute_struct(get_data_struct(data), collection, attribute)
end

function get_attribute_struct(data::DataStruct, collection::String, attribute::String)
    collection_struct = data[collection]
    
    attribute = trim_multidimensional_attribute(attribute)


    if !haskey(collection_struct, attribute)
        error("Attribute '$attribute' not found in collection '$collection'")
    else
        return collection_struct[attribute]::Attribute
    end
end

function get_collections(data::AbstractData)
    return get_collections(get_data_struct(data))
end

function get_collections(data::DataStruct)
    return sort(collect(keys(data)))
end

function get_relations(::AbstractData, collection::String)
    return get_relations(collection)
end

function get_relations(::DataStruct, collection::String)
    return get_relations(collection)
end

function get_relations(collection::String)
    if haskey(_RELATIONS, collection)
        return keys(_RELATIONS[collection])
    end

    return Tuple{String,RelationType}[]
end