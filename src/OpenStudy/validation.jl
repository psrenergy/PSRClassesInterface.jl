function _check_type(
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

function _check_parm(attribute_struct::Attribute, collection::String, attribute::String)
    if attribute_struct.is_vector
        error(
            "Attribute '$attribute' of collection '$collection' is a vector, not a parameter",
        )
    end

    return nothing
end

function _check_vector(attribute_struct::Attribute, collection::String, attribute::String)
    if !attribute_struct.is_vector
        error("Attribute '$attribute' of collection '$collection' isn't a vector")
    end

    return nothing
end

# ~ make backwards compatible by adding `iszero` and `isempty`
_isvalid_dim(axis::Nothing) = false
_isvalid_dim(axis::Integer) = !iszero(axis)
_isvalid_dim(axis::String) = !isempty(axis)

function _check_dim(
    attribute_struct::Attribute,
    collection::String,
    attribute::String,
    dim1::Union{T,Nothing} = nothing,
    dim2::Union{T,Nothing} = nothing,
) where {T<:Union{String,Integer}}
    # ~*~ Retrieve Information & validate input ~*~ #
    dim = get_attribute_dim(attribute_struct)
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

function _check_element_range(data::AbstractData, collection::String, index::Integer)
    n = max_elements(data, collection)

    if n == 0
        error("Collection '$collection' is empty")
    end

    if !(1 <= index <= n)
        error("Index '$index' is out of bounds '[1, $n]' for collection '$collection'")
    end

    return nothing
end