
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
        raw_data[collection] = Dict{String, Any}[]
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
    PSRI._check_element_range(data, collection, index)

    elements = _get_elements(data, collection)

    return elements[index]
end

function get_element(data::Data, reference_id::Integer)
    collection, index = _get_index(data, reference_id)
    return _get_element(data, collection, index)
end

function get_element(data::Data, collection::String, code::Integer)
    _validate_collection(data, collection)
    collection_struct = data.data_struct[collection]
    index = 0
    if haskey(collection_struct, "code")
        index = _get_index_by_code(data, collection, code)
    else
        error("Collection '$collection' does not have a code attribute")
    end

    return _get_element(data, collection, index)
end

function _get_attribute_key(
    attribute::String,
    dim::Integer,
    fix::Pair{<:Integer, <:Union{Integer, Nothing}}...,
)
    if dim == 0 # Attribute has no dimensions
        return attribute
    else
        # Fill extra indices with ones
        indices = ones(Int, dim)

        for (i, k) in fix
            # Discard indices out of range / empty
            if i > dim || isnothing(k)
                continue
            end

            indices[i] = k
        end

        raw_indices = join(indices, ",")

        return "$attribute($raw_indices)"
    end
end

function _get_element_axis_dim(
    element,
    attribute::String,
    dim::Integer,
    axis::Integer;
    lower_bound::Int = 1,
    upper_bound::Int = 100,
)
    i = lower_bound # Here, we assume that the first index is
    j = upper_bound #   within bounds but the second one is not.

    # Binary search
    while i < j - 1
        k = (i + j) ÷ 2

        key = _get_attribute_key(attribute, dim, axis => k)

        if haskey(element, key)
            i = k
        else
            j = k
        end
    end

    return i # The last index within bounds
end

function _get_attribute_axis_dim(
    data::Data,
    collection::String,
    attribute::String,
    axis::Integer,
    index::Integer = 1;
    lower_bound::Int = 1,
    upper_bound::Int = 100,
)
    attribute_struct = PSRI.get_attribute_struct(data, collection, attribute)

    dim = PSRI.get_attribute_dim(attribute_struct)

    if dim == 0
        error("Attribute '$attribute' from collection '$collection' has no dimensions")
    end

    PSRI._check_element_range(data, collection, index)

    element = _get_element(data, collection, index)

    return _get_element_axis_dim(
        element,
        attribute,
        dim,
        axis;
        lower_bound = lower_bound,
        upper_bound = upper_bound,
    )
end

function _get_index(data_index::DataIndex, reference_id::Integer)
    if !haskey(data_index.index, reference_id)
        error("Invalid reference_id '$reference_id'")
    end

    return data_index.index[reference_id]
end

function _raw_stage_duration(data::Data, date::Dates.Date)::Int
    if data.stage_type == PSRI.STAGE_WEEK
        return 168.0
    elseif data.stage_type == PSRI.STAGE_DAY
        return 24.0
    end
    return PSRI.DAYS_IN_MONTH[Dates.month(date)] * 24.0
end

function _raw_stage_duration(data::Data, t::Int)::Int
    if data.stage_type == PSRI.STAGE_WEEK
        return 168.0
    elseif data.stage_type == PSRI.STAGE_DAY
        return 24.0
    end
    return PSRI.DAYS_IN_MONTH[Dates.month(
        PSRI._date_from_stage(t, data.stage_type, data.first_date))] * 24.0
end

function _variable_stage_duration(data::Data, t::Int)
    val = 0.0
    PSRI.goto(data.variable_duration, t)
    for b in 1:data.number_blocks
        val += data.variable_duration[b]
    end
    return val
end

function _variable_stage_duration(data::Data, t::Int, b::Int)
    val = 0.0
    PSRI.goto(data.variable_duration, t)
    return data.variable_duration[b]
end

# Graf

function _get_graf_filename(data::Data, collection::String, attribute::String)
    if !PSRI.has_graf_file(data, collection, attribute)
        error("Collection '$collection' does not have a Graf file for '$attribute'.")
    end

    for graf in data.raw["GrafScenarios"]
        if graf["classname"] == collection
            if graf["vector"] == attribute
                return first(splitext(first(graf["binary"])))
            end
        end
    end
    return
end

function _get_graf_agents(graf_file::String)
    ior = PSRI.open(PSRI.OpenBinary.Reader, graf_file; use_header = false)
    return ior.agent_names
end

# Mapped vector

function _get_cache(data, ::Type{Float64})
    return data.map_cache_real
end

function _get_cache(data, ::Type{Int32})
    return data.map_cache_integer
end

function _get_cache(data, ::Type{Dates.Date})
    return data.map_cache_date
end

function _build_name(name, cache)
    if !isempty(cache.dim1_str)
        if !isempty(cache.dim2_str)
            return string(name, '(', cache.dim1, ',', cache.dim2, ')')
        else
            return string(name, '(', cache.dim1, ')')
        end
    else
        return name
    end
end

# Relations

"""
    _get_relation_attribute(data::Data, source::String, target::String, relation_type::PSRI.PMD.RelationType)

    Returns the attribute that represents a relation between elements from collections 'source' and 'target'
"""
function _get_relation_attribute(
    data::Data,
    source::String,
    target::String,
    relation_type::PSRI.PMD.RelationType,
)
    validate_relation(data, source, target, relation_type)

    relations = data.relation_mapper[source][target]

    for relation in values(relations)
        if relation.type == relation_type
            return relation.attribute
        end
    end

    return ""
end

"""
    _get_relation_type(data::Data, source::String, target::String, attribute::string)

    Returns the RelationType for a relation between elements from collections 'source' and 'target', for a given relation attribute
"""
function _get_relation_type(
    data::Data,
    source::String,
    target::String,
    attribute::String,
)
    validate_relation(data, source, target, attribute)

    relation = data.relation_mapper[source][target][attribute]

    return relation.type
end

"""
    _get_target_indices_from_relation(
        data::Data,
        source::String,
        source_index::Integer,
        target::String,
        relation_attribute::String,
    )

    Returns the 'target' element's index stored in 'source' element in the attribute 'relation_attribute'
"""
function _get_target_indices_from_relation(
    data::Data,
    source::String,
    source_index::Integer,
    target::String,
    relation_attribute::String,
)
    source_element = data.raw[source][source_index]
    target_reference_id = source_element[relation_attribute]
    target_indices = Vector{Int}()

    if !isa(target_reference_id, Int)
        for id in target_reference_id
            collection, target_index = _get_index(data.data_index, id)
            if collection == target
                push!(target_indices, target_index)
            end
        end
    else
        _, target_index = _get_index(data.data_index, target_reference_id)
        push!(target_indices, target_index)
    end
    return target_indices
end

"""
    _get_sources_indices_from_relations(
        data::Data,
        source::String,
        target_id::Integer,
        relation_attribute::String,
    )

    Returns indices of all elements from collection 'source' that have an attribute 'relation_attribute' that stores the given 'target_id'
"""
function _get_sources_indices_from_relations(
    data::Data,
    source::String,
    target::String,
    target_id::Integer,
    relation_attribute::String,
)
    if target != first(_get_index(data.data_index, target_id))
        error("Reference id $(target_id) is not for an element from collection $target")
    end
    validate_relation(data, source, target, relation_attribute)

    if !haskey(data.raw, source)
        return Vector{Int32}()
    end
    if !haskey(data.raw, target)
        return Vector{Int32}()
    end

    possible_elements = data.raw[source]

    indices = Vector{Int32}()
    for (index, element) in enumerate(possible_elements)
        if haskey(element, relation_attribute)
            if target_id in element[relation_attribute]
                push!(indices, index)
            end
        end
    end
    return indices
end

"""
    _get_element_related(data::Data, collection::String, index::Integer)

    Returns two dictionaries:
    - Dict{target_collection, Dict{attribute, Vector{target_index}}}
    - Dict{source_collection, Dict{attribute, Vector{source_index}}}

    The first contains information about the relations that the element has with the role of source in a study.
    The second, information about the relations that the element has with the role of target in a study.
"""
function _get_element_related(data::Data, collection::String, index::Integer)
    element = _get_element(data, collection, index)

    relations_as_source = Dict{String, Dict{String, Vector{Int}}}() # Dict{target_collection, Dict{attribute, Vector{target_index}}}
    relations_as_target = Dict{String, Dict{String, Vector{Int}}}() # Dict{source_collection, Dict{attribute, Vector{source_index}}}

    # Relations where the element is source
    if haskey(data.relation_mapper, collection)
        for (target, relations_dict) in data.relation_mapper[collection]
            relations_as_source[target] = Dict{String, Vector{Int}}()
            for relation in values(relations_dict)
                if haskey(element, relation.attribute) # has a relation as source
                    target_indices =
                        _get_target_indices_from_relation(
                            data,
                            collection,
                            index,
                            target,
                            relation.attribute,
                        )
                    if !isempty(target_indices)
                        relations_as_source[target][relation.attribute] = Vector{Int}()
                        append!(
                            relations_as_source[target][relation.attribute],
                            target_indices,
                        )
                    end
                end
            end
            if isempty(relations_as_source[target])
                delete!(relations_as_source, target)
            end
        end
    end

    # Relations where the element is target
    for (source, related) in data.relation_mapper
        for (target, relations_dict) in related
            if haskey(data.raw, source) && target == collection
                relations_as_target[source] = Dict{String, Vector{Int}}()
                for relation in values(relations_dict)
                    source_indices = _get_sources_indices_from_relations(
                        data,
                        source,
                        collection,
                        element["reference_id"],
                        relation.attribute,
                    )
                    if !isempty(source_indices)
                        relations_as_target[source][relation.attribute] = Vector{Int}()
                        append!(
                            relations_as_target[source][relation.attribute],
                            source_indices,
                        )
                    end
                end
                if isempty(relations_as_target[source])
                    delete!(relations_as_target, source)
                end
            end
        end
    end

    return relations_as_source, relations_as_target
end
