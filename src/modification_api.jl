const PSRCLASSES_DEFAULT =
    JSON.parsefile(joinpath(@__DIR__, "json_metadata", "psrclasses.default.json"))
# const PSRCLASSES_SCHEMAS =
#     JSON.parsefile(joinpath(@__DIR__, "json_metadata", "psrclasses.schema.json"))

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

function _check_collection_in_study(data::Data, collection::String)
    raw_data = _raw(data)

    if !haskey(raw_data, collection)
        error("Collection '$collection' is not available for this study")
    end

    return nothing
end

function _insert_element!(data::Data, collection::String, element::Any)
    _check_collection_in_study(data, collection)

    raw_data = _raw(data)

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

function write_data(data::Data, path::Union{AbstractString,Nothing} = nothing)
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
) where {T<:Integer}
    check_relation_vector(relation_type)
    validate_relation(source, target, relation_type)
    source_element = _get_element(data, source, source_index)
    relation_field = _get_relation(source, target, relation_type)

    source_element[relation_field] = Int[]
    for target_index in target_indices
        target_element = _get_element(data, target, target_index)
        push!(source_element[relation_field], target_element["reference_id"])
    end

    return nothing
end

function Base.show(io::IO, data::Data)
    summary(io, data)
end

function create_study(
    ::OpenInterface;
    data_path::AbstractString = pwd(),
    pmd_files::Vector{String} = String[],
    pmds_path::AbstractString = PMD._PMDS_BASE_PATH,
    netplan::Bool = false,
    kws...,
)
    if !isdir(data_path)
        error("data_path = '$data_path' must be a directory")
    end

    json_path = joinpath(data_path, "psrclasses.json")

    # Select mapping
    model_class_map = if netplan
        PMD._MODEL_TO_CLASS_NETPLAN
    else
        PMD._MODEL_TO_CLASS_SDDP
    end

    data_struct, model_files_added = PMD.load_model(pmds_path, pmd_files, model_class_map)

    data = Data(
        raw = Dict{String,Any}(),
        data_path = data_path,
        data_struct = data_struct,
        validate_attributes = false,
        model_files_added = model_files_added,
        stage_type = STAGE_WEEK,
        first_year = 2023,
        first_stage = 1,
        first_date = Dates.Date(2023, 1, 1),
        controller_date = Dates.Date(2023, 1, 1),
        duration_mode = FIXED_DURATION,
        number_blocks = 1,
        log_file = nothing,
        verbose = true,
    )

    create_element!(data, "PSRStudy")

    return data
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
) where {T<:MainTypes}
    attribute_struct = get_attribute_struct(data, collection, attribute)

    if !attribute_struct.is_vector
        error("Vectorial value '$value' assigned to scalar attribute '$attribute'")
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
) where {T<:MainTypes}
    attribute_struct = get_attribute_struct(data, collection, attribute)

    if attribute_struct.is_vector
        error("Scalar value '$value' assigned to vector attribute '$attribute'")
    end

    if !(T <: attribute_struct.type)
        error(
            "Invalid type '$T' for attribute '$attribute' of type '$(attribute_struct.type)'",
        )
    end

    return nothing
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

function _validate_element(data::Data, collection::String, element::Dict{String,Any})
    data_struct = get_data_struct(data)

    collection_struct = data_struct[collection]
    collection_keys = Set{String}(keys(collection_struct))

    element_keys = Set{String}(keys(element))
    missing_keys = setdiff(collection_keys, element_keys)
    invalid_keys = setdiff(element_keys, collection_keys)

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

function create_element!(data::Data, collection::String, ps::Pair{String,<:Any}...)
    attributes = Dict{String,Any}(ps...)

    return create_element!(data, collection, attributes)
end

function create_element!(data::Data, collection::String, attributes::Dict{String,Any})
    _validate_collection(data, collection)

    if haskey(PSRCLASSES_DEFAULT, collection)
        element = deepcopy(PSRCLASSES_DEFAULT[collection])
    else
        @warn "No default initialization values for collection '$collection'"
        element = Dict{String,Any}()
    end

    # Default attributes are overriden
    merge!(element, attributes)

    _validate_element(data, collection, element)

    raw_data = _raw(data)

    # Create instance list if not exists
    if !haskey(raw_data, collection)
        raw_data[collection] = []
    end

    index = _insert_element!(data, collection, element)

    return index
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
            type = get_attribute_type(data, collection, attribute)
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