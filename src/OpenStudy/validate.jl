function _check_collection_in_study(data::Data, collection::String)
    data_struct = PSRI.get_data_struct(data)

    if !haskey(data_struct, collection)
        error("Collection '$collection' is not available for this study")
    end

    return nothing
end

function _validate_collection(data::Data, collection::String)
    data_struct = PSRI.get_data_struct(data)

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
) where {T <: PSRI.MainTypes}
    attribute_struct = PSRI.get_attribute_struct(data, collection, attribute)

    if !attribute_struct.is_vector
        error("Vectorial value '$value' assigned to scalar attribute '$attribute'")
    end

    _, dim = PSRI._trim_multidimensional_attribute(attribute)

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
) where {T <: PSRI.MainTypes}
    attribute_struct = PSRI.get_attribute_struct(data, collection, attribute)

    if attribute_struct.is_vector
        error("Scalar value '$value' assigned to vector attribute '$attribute'")
    end

    _, dim = PSRI._trim_multidimensional_attribute(attribute)

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
    data_struct = PSRI.get_data_struct(data)

    collection_struct = data_struct[collection]
    collection_keys = Set{String}(keys(collection_struct))

    element_keys = Set{String}(keys(element))
    missing_keys = setdiff(collection_keys, element_keys)
    invalid_keys = setdiff(element_keys, collection_keys)

    for key in invalid_keys
        attr, dim = PSRI._trim_multidimensional_attribute(key)
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

function PSRI._check_type(
    attribute_struct::Attribute,
    ::Type{T},
    collection::String,
    attribute::String,
) where {T}
    if attribute_struct.type !== T
        error(
            "Attribute '$attribute' of collection '$collection' is of type '$(attribute_struct.type)', not '$T'",
        )
    end

    return nothing
end

function PSRI._check_parm(
    attribute_struct::Attribute,
    collection::String,
    attribute::String,
)
    if attribute_struct.is_vector
        error(
            "Attribute '$attribute' of collection '$collection' is a vector, not a parameter",
        )
    end

    return nothing
end

function PSRI._check_vector(
    attribute_struct::Attribute,
    collection::String,
    attribute::String,
)
    if !attribute_struct.is_vector
        error("Attribute '$attribute' of collection '$collection' isn't a vector")
    end

    return nothing
end

# make backwards compatible by adding `iszero` and `isempty`
_isvalid_dim(axis::Nothing) = false
_isvalid_dim(axis::Integer) = !iszero(axis)
_isvalid_dim(axis::String) = !isempty(axis)

function _check_dim(
    attribute_struct::Attribute,
    collection::String,
    attribute::String,
    dim1::Union{T, Nothing} = nothing,
    dim2::Union{T, Nothing} = nothing,
) where {T <: Union{String, Integer}}
    # ~*~ Retrieve Information & validate input ~*~ #
    dim = PSRI.get_attribute_dim(attribute_struct)
    dim1_valid = _isvalid_dim(dim1)
    dim2_valid = _isvalid_dim(dim2)

    # ~*~ Run semantic checks ~*~ #
    if dim == 0
        if dim1_valid || dim2_valid
            error("Attribute '$attribute' from collection '$collection' has no dimensions.")
        end
    elseif dim == 1
        if !dim1_valid
            error(
                "Attribute '$attribute' from collection '$collection' has one dimension, which is missing",
            )
        end

        if dim2_valid
            error(
                "Attribute '$attribute' from collection '$collection' has only one dimension but a second one was provided",
            )
        end
    elseif dim == 2
        if !dim1_valid
            error(
                "Attribute '$attribute' from collection '$collection' has two dimensions but dimension 1 is missing",
            )
        end

        if !dim2_valid
            error(
                "Attribute '$attribute' from collection '$collection' has two dimensions but dimension 2 is missing",
            )
        end
    end

    return nothing
end

function _check_element_range(data::Data, collection::String, index::Integer)
    n = PSRI.max_elements(data, collection)

    if n == 0
        error("Collection '$collection' is empty")
    end

    if !(1 <= index <= n)
        error("Index '$index' is out of bounds '[1, $n]' for collection '$collection'")
    end

    return nothing
end
