function _insert_element!(data::Data, collection::String, element::Any)
    _check_collection_in_study(data, collection)

    elements = _get_elements!(data, collection)

    push!(elements, element)

    return length(elements)
end

function PSRI.set_parm!(
    data::Data,
    collection::String,
    attribute::String,
    index::Int,
    value::T;
    validate::Bool = true,
) where {T <: PSRI.MainTypes}
    if validate
        PSRI._check_type_attribute(data, collection, attribute, T)
    end

    element = _get_element(data, collection, index)

    element[attribute] = value

    return nothing
end

function PSRI.set_vector!(
    data::Data,
    collection::String,
    attribute::String,
    index::Int,
    buffer::Vector{T};
    validate::Bool = true,
) where {T <: PSRI.MainTypes}
    if validate
        PSRI._check_type_attribute(data, collection, attribute, T)
    end
    element = _get_element(data, collection, index)
    vector = element[attribute]::Vector

    if length(buffer) != length(vector)
        error(
            """
            Vector length change from $(length(vector)) to $(length(buffer)) is not allowed.
            Use `PSRI.set_series!` to modity the length of the currect vector and all vector associated witht the same index.
            """,
        )
    end

    for i in eachindex(vector)
        vector[i] = buffer[i]
    end

    return nothing
end

function PSRI.set_series!(
    data::Data,
    collection::String,
    indexing_attribute::String,
    index::Int,
    buffer::Dict{String, Vector},
)
    series = PSRI.SeriesTable(buffer)

    return PSRI.set_series!(data, collection, indexing_attribute, index, series)
end

function PSRI.set_series!(
    data::Data,
    collection::String,
    indexing_attribute::String,
    index::Int,
    series::PSRI.SeriesTable;
    check_type::Bool = true,
)
    attributes = _get_indexed_attributes(data, collection, index, indexing_attribute)

    valid = true

    if length(series) != length(attributes)
        valid = false
    end

    for attribute in attributes
        if !haskey(series, attribute)
            valid = false
            break
        end
    end

    if !valid
        missing_attrs = setdiff(attributes, keys(series))

        for attribute in missing_attrs
            @error "Missing attribute '$(attribute)'"
        end

        invalid_attrs = setdiff(keys(series), attributes)

        for attribute in invalid_attrs
            @error "Invalid attribute '$(attribute)'"
        end

        error("Invalid attributes for series indexed by $(indexing_attribute)")
    end

    new_length = nothing

    for vector in values(series)
        if isnothing(new_length)
            new_length = length(vector)
        end

        if length(vector) != new_length
            error("All vectors must be of the same length in a series")
        end
    end

    element = _get_element(data, collection, index)

    # validate types
    if check_type
        for attribute in keys(series)
            attribute_struct =
                PSRI.get_attribute_struct(data, collection, String(attribute))
            PSRI._check_type(
                attribute_struct,
                eltype(series[attribute]),
                collection,
                String(attribute),
            )
        end
    end

    for attribute in keys(series)
        # protect user's data
        element[String(attribute)] = deepcopy(series[attribute])
    end

    return nothing
end

function PSRI.set_vector_related!(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    target_indices::Vector{T},
    relation_type::PSRI.PMD.RelationType = PSRI.PMD.RELATION_1_TO_N,
) where {T <: Integer}
    check_relation_vector(relation_type)
    validate_relation(data, source, target, relation_type)
    source_element = _get_element(data, source, source_index)
    relation_field = _get_relation_attribute(data, source, target, relation_type)

    source_element[relation_field] = Int[]
    for target_index in target_indices
        target_element = _get_element(data, target, target_index)
        push!(source_element[relation_field], target_element["reference_id"])
    end

    return nothing
end

function PSRI.set_related!(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    target_index::Integer;
    relation_type::PSRI.PMD.RelationType = PSRI.PMD.RELATION_1_TO_1,
)
    check_relation_scalar(relation_type)
    validate_relation(data, source, target, relation_type)
    relation_field = _get_relation_attribute(data, source, target, relation_type)
    source_element = _get_element(data, source, source_index)
    target_element = _get_element(data, target, target_index)

    source_element[relation_field] = target_element["reference_id"]

    return nothing
end

function PSRI.set_related_by_code!(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    target_code::Integer;
    relation_type::PSRI.PMD.RelationType = PSRI.PMD.RELATION_1_TO_1,
)
    target_index = _get_index_by_code(data, target, target_code)
    return PSRI.set_related!(
        data,
        source,
        target,
        source_index,
        target_index;
        relation_type = relation_type,
    )
end
