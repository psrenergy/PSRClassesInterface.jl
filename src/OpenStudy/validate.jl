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

# Relations

"""
    _check_relation(data::Data, source::String)

    Returns an error message if there is no relation where collection 'source' is the source element
"""
function validate_relation(data::Data, source::String)
    if !haskey(data.relation_mapper, source)
        error("Collection $(source) is not the source for any relation in this study")
    end
end

"""
    validate_relation(data::Data, source::String, target::String)

    Returns an error message if there is no relation between collections 'source' and 'target'
"""
function validate_relation(data::Data, source::String, target::String)
    validate_relation(data, source)

    if !haskey(data.relation_mapper[source], target)
        if !haskey(data.relation_mapper, target) ||
           !haskey(data.relation_mapper[target], source)
            error("No relation from $source to $target.")
        end
        if haskey(data.relation_mapper, target) &&
           haskey(data.relation_mapper[target], source)
            error(
                "No relation from $source to $target." *
                "There is a reverse relation from $target to $source.",
            )
        end
    end
end

"""
    validate_relation(data::Data, source::String, target::String, relation_type::PSRI.PMD.RelationType)

    Returns an error message if there is no relation between collections 'source' and 'target' with type 'relation_type'
"""
function validate_relation(
    data::Data,
    source::String,
    target::String,
    relation_type::PSRI.PMD.RelationType,
)
    validate_relation(data, source, target)

    if !_has_relation_type(data.relation_mapper[source][target], relation_type)
        if haskey(data.relation_mapper, target) &&
           haskey(data.relation_mapper[target], source)
            if _has_relation_type(data.relation_mapper[target][source], relation_type)
                error(
                    "No relation from $(source) to $(target) with type $(relation_type)." *
                    " The there is a reverse relation from $(target) to " *
                    "$(source)  with type $(relation_type).",
                )
            end
        end
        error(
            "There is no relation with type $(relation_type) between collections $(source) and $(target)",
        )
    end
end

"""
    validate_relation(data::Data, source::String, target::String, relation_attribute::String)

    Returns an error message if there is no relation between collections 'source' and 'target' with attribute 'relation_attribute'
"""
function validate_relation(
    data::Data,
    source::String,
    target::String,
    relation_attribute::String,
)
    validate_relation(data, source, target)

    if !_has_relation_attribute(data.relation_mapper[source][target], relation_attribute)
        if haskey(data.relation_mapper, target) &&
           haskey(data.relation_mapper[target], source)
            if _has_relation_attribute(
                data.relation_mapper[target][source],
                relation_attribute,
            )
                error(
                    "No relation from $(source) to $(target) with attribute $(relation_attribute)." *
                    " The there is a reverse relation from $(target) to " *
                    "$(source)  with attribute $(relation_attribute).",
                )
            end
        end
        error(
            "There is no relation with attribute $(relation_attribute) between collections $(source) and $(target)",
        )
    end
end

"""
    check_relation_scalar(relation_type::PSRI.PMD.RelationType)

    Returns an error message if relation_type is not a scalar
"""
function check_relation_scalar(relation_type::PSRI.PMD.RelationType)
    if is_vector_relation(relation_type)
        error("Relation of type $relation_type is of type vector, not the expected scalar.")
    end
    return nothing
end

"""
    check_relation_vector(relation_type::PSRI.PMD.RelationType)

    Returns an error message if relation_type is not a vector
"""
function check_relation_vector(relation_type::PSRI.PMD.RelationType)
    if !is_vector_relation(relation_type)
        error("Relation of type $relation_type is of type scalar, not the expected vector.")
    end
    return nothing
end

# Graf

# Checks if names for Agents in Study are equal to the ones in Graf file
function _validate_json_graf(
    agent_attribute::String,
    elements::Vector{Dict{String, Any}},
    graf_file::String,
)
    ior = PSRI.open(PSRI.OpenBinary.Reader, graf_file; use_header = false)

    agents_json = Vector{String}()
    for element in elements
        push!(agents_json, element[agent_attribute])
    end

    if sort(agents_json) != sort(ior.agent_names)
        error("Agent names from your Study are different from the ones in Graf file")
    end

    return
end
