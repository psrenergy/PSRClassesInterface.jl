const PSRCLASSES_DEFAULTS =
    JSON.parsefile(joinpath(@__DIR__, "json_metadata", "psrclasses.defaults.json"))

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

function create_element!(data::Data, collection::String)
    if !haskey(PSRCLASSES_DEFAULTS, collection)
        error("Unknown PSR Class '$collection'")
    end

    element = deepcopy(PSRCLASSES_DEFAULTS[collection])

    index = _insert_element!(data, collection, element)

    return index
end

function _check_collection_in_study(data::Data, collection::String)
    raw_data = _raw(data)
    if !haskey(raw_data, collection)
        error("Collection '$collection' is not available for this study")
    end
    return nothing
end

function _insert_element!(data::Data, collection::String, element::Any)
    raw_data = _raw(data)

    _check_collection_in_study(raw_data, collection)

    objects = raw_data[collection]::Vector

    push!(objects, element)

    return length(objects)
end

function _get_collection(data::Data, collection::String)
    _check_collection_in_study(data, collection)
    raw_data = _raw(data)
    # Gathers a list containing all elements of the class referenced above.
    return raw_data[collection]::Vector
end

"""
    _get_element(
        data::Data,
        collection::String,
        index::Integer,
    )

Low-level call to retrieve an element, that is, an instance of a class in the
form of a `Dict{String, <:MainTypes}`. It performs basic checks for bounds and
existence of `index` and `collection` according to `data`.
"""
function _get_element(data::Data, collection::String, index::Integer)
    elements = _get_collection(data, collection)
    _check_element_range(data, collection, index)
    return elements[index]
end

function set_parm!(
    data::Data,
    collection::String,
    attribute::String,
    index::Int,
    value::T,
) where {T<:MainTypes}
    attribute_struct = get_attribute_struct(data, collection, attribute)
    _check_parm(attribute_struct, collection, attribute)
    _check_type(attribute_struct, T, collection, attribute)
    element = _get_element(data, collection, index)
    element[attribute] = value
    return nothing
end

function get_attribute_type(data::Data, collection::String, attribute::String)
    attribute_data = get_attribute_struct(data, collection, attribute)
    return attribute_data.type::Type{<:MainTypes}
end

function set_vector!(
    data::Data,
    collection::String,
    attribute::String,
    index::Int,
    buffer::Vector{T},
) where {T<:MainTypes}
    attribute_struct = get_attribute_struct(data, collection, attribute)
    _check_vector(attribute_struct, collection, attribute)
    _check_type(attribute_struct, T, collection, attribute)

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

function get_series(data::Data, collection::String, indexing_attribute::String, index::Int)
    # TODO: review this. The element should always have all attributes even if
    # they need to be empty. the element creator should assure the data is
    # is complete. or this `get_series` should check existence and the return
    # empty if needed.
    attributes = _get_indexed_attributes(data, collection, index, indexing_attribute)

    series = Dict{String,Vector}()

    for attribute in attributes
        series[attribute] = get_vector(
            data,
            collection,
            attribute,
            index,
            get_attribute_type(data, collection, attribute),
        )
    end

    return series
end

function set_series!(
    data::Data,
    collection::String,
    indexing_attribute::String,
    index::Int,
    buffer::Dict{String,Vector},
)
    attributes = _get_indexed_attributes(data, collection, index, indexing_attribute)

    valid = true

    if length(buffer) != length(attributes)
        valid = false
    end

    for attribute in attributes
        if !haskey(buffer, attribute)
            valid = false
            break
        end
    end

    if !valid
        missing_attrs = setdiff(attributes, keys(buffer))

        for attribute in missing_attrs
            @error "Missing attribute '$(attribute)'"
        end

        invalid_attrs = setdiff(keys(buffer), attributes)

        for attribute in invalid_attrs
            @error "Invalid attribute '$(attribute)'"
        end

        error("Invalid attributes for series indexed by $(indexing_attribute)")
    end

    new_length = nothing

    for vector in values(buffer)
        if isnothing(new_length)
            new_length = length(vector)
        end

        if length(vector) != new_length
            error("All vectors must be of the same length in a series")
        end
    end

    element = _get_element(data, collection, index)

    # validate types
    for (attribute, vector) in buffer
        attribute_struct = get_attribute_struct(data, collection, attribute)
        _check_type(attribute_struct, eltype(vector), collection, attribute)
    end

    for (attribute, vector) in buffer
        # protect user's data
        element[attribute] = deepcopy(vector)
    end

    return nothing
end

function write_data(data::Data, path::String)
    # Retrieves JSON-like raw data
    raw_data = _raw(data)

    # Writes to file
    Base.open(path, "w") do io
        return JSON.print(io, raw_data)
    end

    return nothing
end

function set_related!(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    target_index::Integer;
    relation_type::RelationType = RELATION_1_TO_1,
)
    check_relation_scalar(relation_type)
    validate_relation(source, target, relation_type)
    relation_field = _get_relation(source, target, relation_type)
    source_element = _get_element(data, source, source_index)
    target_element = _get_element(data, target, target_index)

    source_element[relation_field] = target_element["reference_id"]

    return nothing
end

function set_vector_related!(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    target_indices::Vector{T},
    relation_type::RelationType = RELATION_1_TO_N,
) where {T <:Integer}
    check_relation_vector(relation_type)
    validate_relation(source, target, relation_type)
    source_element = _get_element(data, source, source_index)
    relation_field = _get_relation(source, target, relation_type)

    source_element[relation_field] = Int[]
    for target_index in target_indices
        target_element = _get_element(data, target, target_index)
        push!(
            source_element[relation_field],
            target_element["reference_id"],
        )
    end

    return nothing
end

function Base.show(io::IO, data::Data)
    collections = get_collections(data)

    print(
        io,
        """
        PSRClasses Interface Data with $(length(collections)) collections:
            $(join(collections, "\n    "))
        """
    )
end