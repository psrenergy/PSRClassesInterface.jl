function _get_indexed_attributes(
    data::Data,
    collection::String,
    index::Int,
    indexing_attribute::String,
)
    element = _get_element(data, collection, index)

    class_struct = data.data_struct[collection]

    attributes = String[]

    for (attribute, attribute_data) in class_struct
        if haskey(element, attribute) &&
           (attribute_data.index == indexing_attribute || attribute == indexing_attribute)
            push!(attributes, attribute)
        end
    end

    sort!(attributes)

    return attributes
end

function _get_attribute_type(data::Data, collection::String, attribute::String)
    attribute_data = get_attribute_struct(data, collection, attribute)
    return attribute_data.type::Type{<:MainTypes}
end

function write_data(data::Data, path::Union{AbstractString, Nothing} = nothing)
    # Retrieves JSON-like raw data
    raw_data = _raw(data)

    if isnothing(path)
        path = joinpath(data.data_path, "psrclasses.json")
    end

    # Writes to file
    Base.open(path, "w") do io
        return JSON.print(io, raw_data)
    end

    return nothing
end

function Base.show(io::IO, data::Data)
    return summary(io, data)
end

function _list_attributes_and_types(data::Data, collection::String, attributes::Set{String})
    items = String[]

    for attr in sort(collect(attributes))
        attr_struct = get_attribute_struct(data, collection, attr)

        type = if attr_struct.is_vector
            "Vector{$(attr_struct.type)}"
        else
            "$(attr_struct.type)"
        end

        push!(items, "$attr :: $type")
    end

    return join(items, "\n    ")
end


function _cast_element!(data::Data, collection::String, element::Dict{String, Any})
    for (attribute, value) in element
        if _has_relation_attribute(data.relation_mapper, collection, attribute) ||
           attribute == "reference_id"
            continue
        end
        T = _get_attribute_type(data, collection, attribute)

        if is_vector_attribute(data, collection, attribute)
            element[attribute] = _cast_vector(T, value)
        else
            element[attribute] = _cast(T, value)
        end
    end

    return nothing
end

function _rectify_study_data!(data::Data)
    for (collection, elements) in data.raw
        for element in 1:length(elements)
            _cast_element!(data, collection, data.raw[collection][element])
        end
    end
end

summary(io::IO, args...) = print(io, summary(args...))

function summary(data::Data)
    collections = get_collections(data)

    if isempty(collections)
        return """
            PSRClasses Study with no collections
            """
    else
        return """
            PSRClasses Study with $(length(collections)) collections:
                $(join(collections, "\n    "))
            """
    end
end



function is_vector_attribute(data::Data, collection::String, attribute::String)
    return get_attribute_struct(data, collection, attribute).is_vector
end

function get_attribute_index(data::Data, collection::String, attribute::String)
    index = get_attribute_struct(data, collection, attribute).index

    if isnothing(index) || isempty(index)
        return nothing
    else
        return index
    end
end

function summary(data::Data, collection::String)
    attributes = sort(get_attributes(data, collection))

    if isempty(attributes)
        return """
            PSRClasses Collection '$collection' with no attributes
            """
    else
        max_length = maximum(length.(attributes))
        lines = String[]

        for attribute in attributes
            name = rpad(attribute, max_length)
            type = _get_attribute_type(data, collection, attribute)
            line = if is_vector_attribute(data, collection, attribute)
                index = get_attribute_index(data, collection, attribute)

                if isnothing(index)
                    "$name ::Vector{$type}"
                else
                    "$(name) ::Vector{$type} ← '$index'"
                end
            else
                "$name ::$type"
            end

            push!(lines, line)
        end

        return """
            PSRClasses Collection '$collection' with $(length(attributes)) attributes:
                $(join(lines, "\n    "))
            """
    end
end

function _get_index(data::Data, reference_id::Integer)
    return _get_index(data.data_index, reference_id)
end

function _get_index_by_code(data::Data, collection::String, code::Integer)
    collection_vector = data.raw[collection]

    for (index, element) in enumerate(collection_vector)
        if element["code"] == code
            return index
        end
    end

    return error("Code '$code' not found in collection '$collection'")
end

function _set_index!(data::Data, reference_id::Integer, collection::String, index::Integer)
    _set_index!(data.data_index, reference_id, collection, index)

    return nothing
end

function _build_index!(data::Data)
    for collection in get_collections(data)
        if max_elements(data, collection) == 0
            continue
        end

        for (index, element) in enumerate(_get_elements(data, collection))
            if haskey(element, "reference_id")
                reference_id = element["reference_id"]::Integer

                _set_index!(data, reference_id, collection, index)
            else
                @warn "Missing reference_id for element in collection '$collection' with index '$index'"
            end
        end
    end
    return nothing
end

function _generate_reference_id(data::Data)
    return _generate_reference_id(data.data_index)
end
