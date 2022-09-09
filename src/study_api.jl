const PSRCLASSES_DEFAULTS =
    JSON.parsefile(joinpath(@__DIR__, "json_metadata", "psrclasses.defaults.json"))
const DATE_FORMAT_1 = Dates.DateFormat(raw"yyyy-mm-dd")
const DATE_FORMAT_2 = Dates.DateFormat(raw"dd/mm/yyyy")

function list_attributes(data::Data, collection::String)
    if !haskey(data.data_struct, collection)
        error("PSR Class '$collection' is not available for this study")
    end

    class_struct = data.data_struct[collection]

    attributes = sort(collect(keys(class_struct)))

    return attributes
end

function list_attributes(data::Data, collection::String, index::Int)
    element = _get_element(data, collection, index)

    attributes = sort(collect(keys(element)))

    return attributes
end

function get_indexed_attributes(data::Data, collection::String, index_attr::String)
    if !haskey(data.data_struct, collection)
        error("PSR Class '$collection' is not available for this study")
    end

    class_struct = data.data_struct[collection]

    attributes = []

    for (attribute, attribute_data) in class_struct
        if attribute_data.index == index_attr || attribute == index_attr
            push!(attributes, attribute)
        end
    end

    sort!(attributes)

    return attributes
end

function get_indexed_attributes(
    data::Data,
    collection::String,
    index::Int,
    index_attr::String,
)
    element = _get_element(data, collection, index)

    class_struct = data.data_struct[collection]

    attributes = []

    for (attribute, attribute_data) in class_struct
        if haskey(element, attribute) &&
           (attribute_data.index == index_attr || attribute == index_attr)
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

function _insert_element!(data::Data, collection::String, element::Any)
    raw_data = _raw(data)::Dict{String,<:Any}

    if !haskey(raw_data, collection)
        error("Collection '$collection' is not available for this study")
    end

    objects = raw_data[collection]::Vector

    push!(objects, element)

    return length(objects)
end

function _get_instances(data::Data, collection::String)
    # Retrieves raw JSON-like dict, i.e. `Dict{String, Any}`.
    # `_raw(data)` is a safe interface for `data.raw`.
    # This dictionary was created by reading a JSON file.
    raw_data = _raw(data)::Dict{String,<:Any}

    if !haskey(raw_data, collection)
        error("Collection '$collection' is not available for this study")
    end

    # Gathers a list containing all instances of the class referenced above.
    return raw_data[collection]::Vector
end

"""
    _get_element(
        data::Data,
        collection::String,
        index::Integer,
    )

Low-level call to retrieve an element, that is, an instance of a class in the form of a `Dict{String, <:MainTypes}`.
It performs basic checks for bounds and existence of `index` and `collection` according to `data`.
"""
function _get_element(data::Data, collection::String, index::Integer)
    objects = _get_instances(data, collection)

    if !(1 <= index <= length(objects))
        error("Invalid index '$index' out of bounds [1, $(length(objects))]")
    end

    return objects[index]::Dict{String,<:Any}
end

function _get_attribute_data(data::Data, collection::String, attribute::String)
    if !haskey(data.data_struct, collection)
        error("Collection '$collection' is not available for this study")
    end

    class_struct = data.data_struct[collection]

    if !haskey(class_struct, attribute)
        error("Collection '$collection' has no attribute '$attribute'")
    end

    return class_struct[attribute]::Attribute
end

function set_parm!(
    data::Data,
    collection::String,
    attribute::String,
    index::Int,
    value::T,
) where {T<:MainTypes}
    attribute_data = _get_attribute_data(data, collection, attribute)

    if attribute_data.is_vector
        error(
            """
            Attribute '$attribute' from collection '$collection' is a vector, not a scalar parameter.
            Consider using `PSRI.set_vector!` instead
            """,
        )
    end

    # This is assumed to be a mutable dictionary.
    element = _get_element(data, collection, index)

    # In fact, all attributes must be set beforehand.
    # Schema validation would be useful here, since there would be no need
    #   to check for existing keys and `get_element` could handle all necessary
    #   consistency-related work.
    # This could even be done at loading time or if something is modified by
    #   methods like `set_parm!`.
    if !haskey(element, attribute)
        error("Invalid attribute '$attribute' for object from collection '$collection'")
    end

    element[attribute] = _cast(attribute_data.type, value)

    return nothing
end

function _get_vector_ref(data::Data, collection::String, index::Int, attribute::String)
    attribute_data = _get_attribute_data(data, collection, attribute)

    if !attribute_data.is_vector
        error(
            """
            Attribute '$attribute' from collection '$collection' is a scalar parameter, not a vector.
            Consider using `PSRI.set_parm!` instead
            """,
        )
    end

    element = _get_element(data, collection, index)

    if !haskey(element, attribute)
        error("Invalid attribute '$attribute' for object of type '$collection'")
    end

    return element[attribute]::Vector
end

function get_attribute_type(data::Data, collection::String, attribute::String)
    attribute_data = _get_attribute_data(data, collection, attribute)

    return attribute_data.type::Type{<:MainTypes}
end

function set_vector!(
    data::Data,
    collection::String,
    attribute::String,
    index::Int,
    buffer::Vector{T},
) where {T<:MainTypes}
    vector = _get_vector_ref(data, collection, index, attribute)

    if length(buffer) != length(vector)
        error(
            """
            Vector length change from $(length(vector)) to $(length(buffer)) is not allowed.
            Use `PSRI.set_series!` instead.
            """,
        )
    end

    # Validation on `collection` & `attribute` already happened during `_get_vector_ref`
    attribute_type = get_attribute_type(data, collection, attribute)

    # Modify data in-place
    for i in eachindex(vector)
        vector[i] = _cast(attribute_type, buffer[i])
    end

    return nothing
end

function get_series(data::Data, collection::String, index_attr::String, index::Int)
    attributes = get_indexed_attributes(data, collection, index, index_attr)

    series = Dict{String,Vector}()

    sizehint!(series, length(attributes))

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
    index_attr::String,
    index::Int,
    buffer::Dict{String,Vector},
)
    series = get_series(data, collection, index_attr, index)

    valid = true

    if length(buffer) != length(series)
        valid = false
    end

    for attribute in keys(series)
        if !haskey(buffer, attribute)
            valid = false
            break
        end
    end

    if !valid
        missing_attrs = setdiff(keys(series), keys(buffer))

        for attribute in missing_attrs
            @error "Missing attribute '$(attribute)'"
        end

        invalid_attrs = setdiff(keys(buffer), keys(series))

        for attribute in invalid_attrs
            @error "Invalid attribute '$(attribute)'"
        end

        error("Invalid attributes for series indexed by $(index_attr)")
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

    for (attribute, vector) in buffer
        element[attribute] = vector
    end

    return nothing
end

function write_data(data::Data, path::String)
    # Retrieves JSON-like raw data
    raw_data = _raw(data)::Dict{String,<:Any}

    # Writes to file
    Base.open(path, "w") do io
        return JSON.print(io, raw_data)
    end

    return nothing
end

# ~*~ Relations ~*~ #
function _validate_relation(
    source::String,
    target::String,
    relation_type::RelationType,
)
    if !haskey(_RELATIONS, source)
        error("Collection '$source' has no relations at all")
    end

    target_relation = (target, relation_type)
    source_relations = _RELATIONS[source]

    if !haskey(source_relations, target_relation)
        error("Collection '$source' has no relation to '$target' of type '$relation_type'")
    end

    return nothing
end

function _get_relation(source::String, target::String, relation_type::RelationType)
    _validate_relation(source, target, relation_type)
    
    return _RELATIONS[source][(target, relation_type)]
end

function get_related(
    data::Data,
    source::String,
    target::String,
    source_index::Integer;
    relation_type::RelationType = RELATION_1_TO_1,
)
    source_element = _get_element(data, source, source_index)
    relation_field = _get_relation(source, target, relation_type)
    
    if !haskey(source_element, relation_field)
        error("Element '$source_index' from collection '$source' has no field '$relation_field'")
    end

    target_id = source_element[relation_field]
    
    # TODO: make this step a separate function?
    target_index = nothing

    for (index, element) in enumerate(_get_instances(data, target))
        # TODO: perform validation on 'reference_id'
        if element["reference_id"] === target_id
            target_index = index
            break
        end
    end

    if isnothing(target_index)
        error("No element with id '$target_id' was found in collection '$target'")
    end

    return target_index
end

function set_related!(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    target_index::Integer;
    relation_type::RelationType = RELATION_1_TO_1,
)
    source_element = _get_element(data, source, source_index)
    target_element = _get_element(data, target, target_index)
    relation_field = _get_relation(source, target, relation_type)

    # TODO: perform validation on 'reference_id'
    source_element[relation_field] = target_element["reference_id"]

    return nothing
end

function get_vector_related(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    relation_type::RelationType = RELATION_1_TO_N,
)
    source_element = _get_element(data, source, source_index)
    relation_field = _get_relation(source, target, relation_type)
    
    if !haskey(source_element, relation_field)
        error("Element '$source_index' from collection '$source' has no field '$relation_field'")
    end

    target_id_set = Set{Int}(source_element[relation_field])
    
    # TODO: make this step a separate function?
    target_index_list = Int[]

    for (index, element) in enumerate(_get_instances(data, target))
        # TODO: perform validation on 'id'
        if element["reference_id"] ∈ target_id_set
            push!(target_index_list, index)
        end
    end

    if isempty(target_index_list)
        error("No elements with id '$target_id' were found in collection '$target'")
    end

    return target_index_list
end

function set_vector_related!(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    target_indices::Vector{T},
    relation_type::RelationType = RELATION_1_TO_N,
) where {T <:Integer}
    source_element = _get_element(data, source, source_index)
    relation_field = _get_relation(source, target, relation_type)

    for target_index in target_indices
        target_element = _get_element(data, target, target_index)

        # TODO: perform validation on 'reference_id'
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