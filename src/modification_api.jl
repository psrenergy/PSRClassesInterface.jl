const _CUSTOM_COLLECTION = Dict{String,Any}()

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
    data_struct = get_data_struct(data)

    if !haskey(data_struct, collection)
        error("Collection '$collection' is not available for this study")
    end

    return nothing
end

function _insert_element!(data::Data, collection::String, element::Any)
    _check_collection_in_study(data, collection)

    elements = _get_elements!(data, collection)

    push!(elements, element)

    return length(elements)
end

"""
    _get_elements(data::Data, collection::String)

Gathers a list containing all instances of the referenced collection.
"""
function _get_elements(data::Data, collection::String)
    _check_collection_in_study(data, collection)

    raw_data = _raw(data)

    return raw_data[collection]::Vector
end

"""
    _get_elements!(data::Data, collection::String)

Gathers a list containing all instances of the referenced collection.

!!! info
    If the instance vector is not present but the collection is still expected, an entry for it will be created.
"""
function _get_elements!(data::Data, collection::String)
    _check_collection_in_study(data, collection)

    raw_data = _raw(data)

    if !haskey(raw_data, collection)
        raw_data[collection] = Dict{String,Any}[]
    end

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
    _check_element_range(data, collection, index)

    elements = _get_elements(data, collection)

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

    buffer = Dict{String,Vector}()

    for attribute in attributes
        buffer[attribute] = get_vector(
            data,
            collection,
            attribute,
            index,
            get_attribute_type(data, collection, attribute),
        )
    end

    return SeriesTable(buffer)
end

# Get GrafTable stored in a graf file for a collection
function get_graf_series(data::Data, collection::String, attribute::String; kws...)
    if !has_graf_file(data, collection)
        error("No time series file for collection '$collection'")
    end

    graf_files = Vector{String}()

    for graf in data.raw["GrafScenarios"]
        if graf["classname"] == collection && graf["vector"] == attribute 
            append!(graf_files, graf["binary"])
        end
    end

    graf_file = first(graf_files)
    graf_path = joinpath(data.data_path, first(splitext(graf_file)))

    graf_table = GrafTable{Float64}(graf_path; kws...)

    return graf_table
end

function set_series!(
    data::Data,
    collection::String,
    indexing_attribute::String,
    index::Int,
    buffer::Dict{String,Vector},
)
    series = SeriesTable(buffer)

    set_series!(data, collection, indexing_attribute, index, series)
end

function set_series!(
    data::Data,
    collection::String,
    indexing_attribute::String,
    index::Int,
    series::SeriesTable,
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
    for attribute in keys(series)
        attribute_struct = get_attribute_struct(data, collection, String(attribute))
        _check_type(attribute_struct, eltype(series[attribute]), collection, String(attribute))
    end

    for attribute in keys(series)
        # protect user's data
        element[String(attribute)] = deepcopy(series[attribute])
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

function set_related_by_code!(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    target_code::Integer;
    relation_type::RelationType = RELATION_1_TO_1,
)
    target_index = _get_index_by_code(data, target, target_code)
    return set_related!(data, source, target, source_index, target_index, relation_type = relation_type)
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

function delete_relation!(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    target_index::Integer
)


    source_relations = _get_element_related(data, source, source_index)
    if haskey(source_relations, (source,target,source_index,target_index))
        relation_attribute = source_relations[(source,target,source_index,target_index)]
        source_element  = _get_element(data, source, source_index)

        target_indices = _get_target_index_from_relation(data, source, source_index, relation_attribute)
        if length(target_indices) > 1
            deleteat!(source_element[relation_attribute], target_indices .== target_index)
        else
            delete!(source_element, relation_attribute)
        end
    else
        error("Relation '$source'(Source) with '$target'(Target) does not exist")
    end

    return nothing
end

function delete_vector_relation!(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    target_indices::Vector{Int}
)
    source_relations = _get_element_related(data, source, source_index)

    relation_attribute = source_relations[(source,target,source_index,target_indices[1])]

    source_element  = _get_element(data, source, source_index)

    delete!(source_element, relation_attribute)

    return nothing
end

function Base.show(io::IO, data::Data)
    return summary(io, data)
end

function create_study(
    ::OpenInterface;
    data_path::AbstractString = pwd(),
    pmd_files::Vector{String} = String[],
    pmds_path::AbstractString = PMD._PMDS_BASE_PATH,
    defaults_path::Union{AbstractString,Nothing} = PSRCLASSES_DEFAULTS_PATH,
    defaults::Union{Dict{String,Any},Nothing} = _load_defaults!(),
    netplan::Bool = false,
    model_template_path::Union{String,Nothing} = nothing,
    study_collection::String = "PSRStudy",
)
    if !isdir(data_path)
        error("data_path = '$data_path' must be a directory")
    end

    if isnothing(defaults)
        defaults = Dict{String,Any}()
    end

    if !isnothing(defaults_path)
        merge!(defaults, JSON.parsefile(defaults_path))
    end

    # Select mapping
    model_template = PMD.ModelTemplate()

    if isnothing(model_template_path)
        if netplan
            PMD.load_model_template!(
                joinpath(JSON_METADATA_PATH, "modeltemplates.netplan.json"),
                model_template,
            )
        else
            PMD.load_model_template!(
                joinpath(JSON_METADATA_PATH, "modeltemplates.sddp.json"),
                model_template,
            )
        end
    else 
        PMD.load_model_template!(model_template_path, model_template)
    end
 
    data_struct, model_files_added = PMD.load_model(pmds_path, pmd_files, model_template)

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
        model_template = model_template
    )

    _create_study_collection(data, study_collection, defaults)

    return data
end

function _create_study_collection(data::Data, collection::String, defaults::Union{Dict{String,Any},Nothing})
    create_element!(data, collection; defaults = defaults)

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

function _cast_element!(data::Data, collection::String, element::Dict{String,Any})
    for (attribute, value) in element
        T = get_attribute_type(data, collection, attribute)

        if is_vector_attribute(data, collection, attribute)
            element[attribute] = _cast_vector(T, value)
        else
            element[attribute] = _cast(T, value)
        end
    end

    return nothing
end


function create_attribute!(
    data::Data, 
    collection::String, 
    attribute::String, 
    is_vector::Bool, 
    ::Type{T}, 
    dimension::Int,
    has_default::Bool = true,
    default::T = _default_value(T)
    ) where {T<:MainTypes}
    _validate_collection(data, collection)

    data.data_struct[collection][attribute] = Attribute(attribute, is_vector, T, dimension, "")

    if !haskey(_CUSTOM_COLLECTION, collection)
        _CUSTOM_COLLECTION[collection] = Dict{String,Any}()
    end
    if has_default
        push!(_CUSTOM_COLLECTION[collection], (attribute => default))
    end

    return nothing
end

function create_collection!(
    data::Data,
    collection::String
    )
    if haskey(data.data_struct, collection)
        error("Collection '$collection' is already part of this study")
    end
    
    data.data_struct[collection] = Dict{String,Attribute}()

    return nothing
end

function create_element!(
    data::Data,
    collection::String;
    defaults::Union{Dict{String,Any},Nothing} = _load_defaults!(),
)
    return create_element!(data, collection, Dict{String,Any}(); defaults=defaults)
end

function create_element!(
    data::Data,
    collection::String,
    ps::Pair{String,<:Any}...;
    defaults::Union{Dict{String,Any},Nothing} = _load_defaults!(),
)
    attributes = Dict{String,Any}(ps...)

    return create_element!(data, collection, attributes; defaults=defaults)
end

function create_element!(
    data::Data,
    collection::String,
    attributes::Dict{String,Any};
    defaults::Union{Dict{String,Any},Nothing} = _load_defaults!(),
)
    _validate_collection(data, collection)

    # TODO: handle case when collection has a  graf file
    if has_graf_file(data, collection) 
        error("Cannot create element for a collection with a Graf file")
    end

    element = if isnothing(defaults)
        Dict{String,Any}()
    elseif haskey(defaults, collection)
        deepcopy(defaults[collection])
    else 

        @warn "No default initialization values for collection '$collection'"
        
        Dict{String,Any}()
    end

    # Cast values from json default 
    _cast_element!(data, collection, element)

    # Default attributes are overriden by the provided ones
    merge!(element, attributes)

    _validate_element(data, collection, element)

    # If not reference_id is assigned to the element, a new one is created
    if !haskey(element, "reference_id")
        reference_id = _generate_reference_id(data)

        element["reference_id"] = reference_id
    end

    index = _insert_element!(data, collection, element)

    # Assigns to the given (collection, index) pair its own reference_id
    _set_index!(data, reference_id, collection, index)

    return index
end

function delete_element!(data::Data, collection::String, index::Int)
    if !has_relations(data, collection, index)
        elements = _get_elements(data, collection)

        element_id = elements[index]["reference_id"]

        # Remove element reference from data_index by its id
        delete!(data.data_index.index, element_id)

        # Remove element from collection vector by its index
        deleteat!(elements, index)
    else
        error("Element $collection cannot be deleted because it has relations with other elements")
    end
    return nothing
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

function _get_index(data::Data, reference_id::Integer)
    return _get_index(data.data_index, reference_id)
end

function _get_index_by_code(data:: Data, collection::String, code::Integer)
    collection_vector = data.raw[collection]

    for (index,element) in enumerate(collection_vector)
        if element["code"] == code
            return index
        end
    end
    
    error("Code '$code' not found in collection '$collection'")
end

function get_element(data::Data, reference_id::Integer)
    collection, index = _get_index(data, reference_id)
    return _get_element(data, collection, index)
end

function get_element(data::Data, collection::String, code::Integer)
    _validate_collection(data, collection)
    collection_struct = data.data_struct[collection]
    index = 0
    if haskey(collection_struct,"code")
        index = _get_index_by_code(data, collection, code)
    else
        error("Collection '$collection' does not have a code attribute")
    end

    return _get_element(data, collection, index)
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