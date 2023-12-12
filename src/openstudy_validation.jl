function _check_collection_in_study(data::Data, collection::String)
    data_struct = get_data_struct(data)

    if !haskey(data_struct, collection)
        error("Collection '$collection' is not available for this study")
    end

    return nothing
end

function _validate_collection(data::Data, collection::String)
    data_struct = get_data_struct(data)

    if !haskey(data_struct, collection)
        error("Collection '$collection' is not available for this study")
    end

    return nothing
end

function _validate_attribute(::Data, ::String, attribute::String, ::T) where {T}
    return error("Invalid type '$T' assigned to attribute '$attribute'")
end

function _validate_attribute(
    data::Data,
    collection::String,
    attribute::String,
    value::Vector{T},
) where {T <: MainTypes}
    attribute_struct = get_attribute_struct(data, collection, attribute)

    if !attribute_struct.is_vector
        error("Vectorial value '$value' assigned to scalar attribute '$attribute'")
    end

    _, dim = _trim_multidimensional_attribute(attribute)

    if !isnothing(dim)
        # Check for dim size
        if length(dim) != attribute_struct.dim
            error(
                """
          Dimension '$(length(dim))' is not valid for attribute '$(attribute_struct.name)' with dimension '$(attribute_struct.dim)'
          """,
            )
        end
    elseif attribute_struct.dim > 0
        error(
            """
          Dimension '$(0)' is not valid for attribute '$(attribute_struct.name)' with dimension '$(attribute_struct.dim)'
          """,
        )
    end

    if !(T <: attribute_struct.type)
        error(
            "Invalid element type '$T' for attribute '$attribute' of type '$(attribute_struct.type)'",
        )
    end

    return nothing
end

function _validate_attribute(
    data::Data,
    collection::String,
    attribute::String,
    value::T,
) where {T <: MainTypes}
    attribute_struct = get_attribute_struct(data, collection, attribute)

    if attribute_struct.is_vector
        error("Scalar value '$value' assigned to vector attribute '$attribute'")
    end

    _, dim = _trim_multidimensional_attribute(attribute)

    if !isnothing(dim)
        # Check for dim size
        if length(dim) != attribute_struct.dim
            error(
                """
              Dimension '$(length(dim))' is not valid for attribute '$(attribute_struct.name)' with dimension '$(attribute_struct.dim)'
              """,
            )
        end
    elseif attribute_struct.dim > 0
        error(
            """
          Dimension '$(0)' is not valid for attribute '$(attr_struct.name)' with dimension '$(attribute_struct.dim)'
          """,
        )
    end

    if !(T <: attribute_struct.type)
        error(
            "Invalid type '$T' for attribute '$attribute' of type '$(attribute_struct.type)'",
        )
    end

    return nothing
end

function _validate_element(data::Data, collection::String, element::Dict{String, Any})
    data_struct = get_data_struct(data)

    collection_struct = data_struct[collection]
    collection_keys = Set{String}(keys(collection_struct))

    element_keys = Set{String}(keys(element))
    missing_keys = setdiff(collection_keys, element_keys)
    invalid_keys = setdiff(element_keys, collection_keys)

    for key in invalid_keys
        attr, dim = _trim_multidimensional_attribute(key)
        if attr in collection_keys
            pop!(invalid_keys, key)
        end
        if attr in missing_keys
            pop!(missing_keys, attr)
        end
    end

    if !isempty(missing_keys)
        error("""
              Missing attributes for collection '$collection':
                  $(_list_attributes_and_types(data, collection, missing_keys))
              """)
    end

    if !isempty(invalid_keys)
        error("""
              Invalid attributes for collection '$collection':
                  $(join(invalid_keys, "\n    "))
              """)
    end

    for (attribute, value) in element
        _validate_attribute(data, collection, attribute, value)
    end

    return nothing
end
