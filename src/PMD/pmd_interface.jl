function PSRI.get_attribute_struct(data::DataStruct, collection::String, attribute::String)
    collection_struct = data[collection]

    attribute, _ = PSRI._trim_multidimensional_attribute(attribute)

    if !haskey(collection_struct, attribute)
        error("No information for attribute '$attribute' found in collection '$collection'")
    end

    return collection_struct[attribute]::Attribute
end

function PSRI.get_attributes(data::DataStruct, collection::String)
    return sort!(collect(keys(data[collection])))
end

function PSRI.get_collections(data::DataStruct)
    return sort(collect(keys(data)))
end
