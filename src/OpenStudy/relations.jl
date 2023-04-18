"""
    is_vector_relation(relation::PMD.RelationType)

Returns true is `relation` is a vector relation.
"""
function is_vector_relation(relation::PMD.RelationType)
    return relation == PMD.RELATION_1_TO_N || relation == PMD.RELATION_BACKED
end

"""
    _has_relation_attribute(relations::Vector{PMD.Relation}, relation_attribute::String)

    Returns true if there is a relation with attribute 'relation_attribute' in a 'Vector{PMD.Relation}'
"""
function _has_relation_attribute(relations::Vector{PMD.Relation}, relation_attribute::String)
    has_relation_attribute = false
    for relation in relations
        if relation.attribute == relation_attribute
            has_relation_attribute = true
        end
    end
    return has_relation_attribute
end

"""
    _has_relation_type(relations::Vector{PMD.Relation}, relation_type::PMD.RelationType)

    Returns true if there is a relation with type 'relation_type' in a 'Vector{PMD.Relation}'
"""
function _has_relation_type(relations::Vector{PMD.Relation}, relation_type::PMD.RelationType)
    has_relation_type = false
    for relation in relations
        if relation.type == relation_type
            has_relation_type = true
        end
    end
    return has_relation_type
end

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
    validate_relation(data::Data, source::String)

    if !haskey(data.relation_mapper[source], target)
        if !haskey(data.relation_mapper, target) || !haskey(data.relation_mapper[target], source)
            error("No relation from $source to $target.")
        end
        if haskey(data.relation_mapper, target) && haskey(data.relation_mapper[target], source)
            error(
                "No relation from $source to $target." *
                "There is a reverse relation from $target to $source."
            )
        end
    end
end

"""
    validate_relation(data::Data, source::String, target::String, relation_type::PMD.RelationType)

    Returns an error message if there is no relation between collections 'source' and 'target' with type 'relation_type'
"""
function validate_relation(data::Data, source::String, target::String, relation_type::PMD.RelationType)
    validate_relation(data, source, target)

    if !_has_relation_type(data.relation_mapper[source][target], relation_type)
        if haskey(data.relation_mapper,target) && haskey(data.relation_mapper[target], source)
            if _has_relation_type(data.relation_mapper[target][source], relation_type)
                error(
                    "No relation from $(source) to $(target) with type $(relation_type)." *
                    " The there is a reverse relation from $(target) to " *
                    "$(source)  with type $(relation_type)."
                )
            end
        end
        error("There is no relation with type $(relation_type) between collections $(source) and $(target)")
    end
end

"""
    validate_relation(data::Data, source::String, target::String, relation_attribute::String)

    Returns an error message if there is no relation between collections 'source' and 'target' with attribute 'relation_attribute'
"""
function validate_relation(data::Data, source::String, target::String, relation_attribute::String)
    validate_relation(data, source, target)

    if !_has_relation_attribute(data.relation_mapper[source][target], relation_attribute)
        if haskey(data.relation_mapper,target) && haskey(data.relation_mapper[target], source)
            if _has_relation_attribute(data.relation_mapper[target][source], relation_attribute)
                error(
                    "No relation from $(source) to $(target) with attribute $(relation_attribute)." *
                    " The there is a reverse relation from $(target) to " *
                    "$(source)  with attribute $(relation_attribute)."
                )
            end
        end
        error("There is no relation with attribute $(relation_attribute) between collections $(source) and $(target)")
    end
end

"""
    _get_relation_attribute(data::Data, source::String, target::String, relation_type::PMD.RelationType)
    
    Returns the attribute that represents a relation between elements from collections 'source' and 'target'
"""
function _get_relation_attribute(data::Data, source::String, target::String, relation_type::PMD.RelationType)
    
    validate_relation(data, source, target, relation_type)

    relations = data.relation_mapper[source][target]
    attribute = ""

    for relation in relations
        if relation.type == relation_type
            attribute = relation.attribute
            break
        end
    end

    return attribute
end

"""
    _get_target_index_from_relation(
        data::Data,
        source::String,
        source_index::Integer,
        relation_attribute::String,
    )
    
    Returns the 'target' element's index stored in 'source' element in the attribute 'relation_attribute'
"""
function _get_target_index_from_relation(
    data::Data,
    source::String,
    source_index::Integer,
    relation_attribute::String,
)
    source_element = data.raw[source][source_index]
    target_reference_id = source_element[relation_attribute]
    target_indices = Vector{Int}()

    if isa(target_reference_id, Vector{Int})
        for id in target_reference_id
            _, target_index = _get_index(data.data_index, id)
            push!(target_indices, target_index)
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

    
    relations_as_source = Dict{String, Dict{String,Vector{Int}}}() # Dict{target_collection, Dict{attribute, Vector{target_index}}}
    relations_as_target = Dict{String, Dict{String,Vector{Int}}}() # Dict{source_collection, Dict{attribute, Vector{source_index}}}

    # Relations where the element is source
    if haskey(data.relation_mapper, collection)
        for (target, relations_vector) in data.relation_mapper[collection]
            relations_as_source[target] = Dict{String, Vector{Int}}()
            for relation in relations_vector
                if haskey(element, relation.attribute) # has a relation as source
                    target_indices =
                        _get_target_index_from_relation(data, collection, index, relation.attribute)
                    if !isempty(target_indices)
                        relations_as_source[target][relation.attribute] = Vector{Int}()
                        append!(relations_as_source[target][relation.attribute],target_indices)
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
        for (target, relations) in related
            if haskey(data.raw, source) && target == collection
                relations_as_target[source] = Dict{String, Vector{Int}}()
                for relation in relations
                    source_indices = _get_sources_indices_from_relations(
                        data,
                        source,
                        collection,
                        element["reference_id"],
                        relation.attribute
                    )
                    if !isempty(source_indices)
                        relations_as_target[source][relation.attribute] = Vector{Int}()
                        append!(relations_as_target[source][relation.attribute], source_indices)
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

"""
    has_relations(data::Data, collection::String)

    Returns true if collection 'collection' has any defined relation
"""
function has_relations(data::Data, collection::String)
    if !haskey(data.relation_mapper, collection)
        return false
    end
    return true
end

"""
    has_relations(data::Data, collection::String, index::Integer)

    Returns true if element of index 'index' from collection 'collection' has any defined relation
"""
function has_relations(data::Data, collection::String, index::Int)
    if !haskey(data.relation_mapper, collection)
        return false
    end

    relations_as_source, relations_as_target = _get_element_related(data, collection, index)

    if !isempty(relations_as_source) || !isempty(relations_as_target)
        return true
    end

    return false
end

"""
    relations_summary(data::Data, collection::String, index::Integer)

    Displays all current relations of the element in the following way:

    attribute_name: collection_name[element_index] → collection_name[element_index]

    (The arrow always points from the source to target)
"""
function relations_summary(data::Data, collection::String, index::Integer)
    if !has_relations(data, collection, index)
        println("This element does not have any relations")
        return
    end

    relations_as_source, relations_as_target = _get_element_related(data, collection, index)

    for (target, value) in relations_as_source
        for (attribute, target_index) in value
            println(
                "$attribute: $collection[$index] → $target$target_index",
            )
        end
    end

    for (source, value) in relations_as_target
        for (attribute, source_index) in value
            println(
                "$attribute: $source[$source_index] ← $collection[$index]",
            )
        end
    end
    
    return
end


"""
    check_relation_scalar(relation_type::PMD.RelationType)

    Returns an error message if relation_type is not a scalar
"""
function check_relation_scalar(relation_type::PMD.RelationType)
    if is_vector_relation(relation_type)
        error("Relation of type $relation_type is of type vector, not the expected scalar.")
    end
    return nothing
end

"""
    check_relation_vector(relation_type::PMD.RelationType)

    Returns an error message if relation_type is not a vector
"""
function check_relation_vector(relation_type::PMD.RelationType)
    if !is_vector_relation(relation_type)
        error("Relation of type $relation_type is of type scalar, not the expected vector.")
    end
    return nothing
end

function get_reverse_map(
    data::AbstractData,
    lst_from::String,
    lst_to::String;
    allow_empty::Bool = true,
    original_relation_type::PMD.RelationType = PMD.RELATION_1_TO_1, # type of the direct relation
)
    n_to = max_elements(data, lst_to)
    if n_to == 0
        # TODO warn no field
        return zeros(Int32, 0)
    end
    out = zeros(Int32, n_to)
    if is_vector_relation(original_relation_type)
        vector_map = get_vector_map(
            data,
            lst_from,
            lst_to;
            allow_empty = allow_empty,
            relation_type = original_relation_type,
        )
        for (f, vector_to) in enumerate(vector_map)
            for t in vector_to
                if out[t] == 0
                    out[t] = f
                else
                    error(
                        "The element $t maps to two elements ($(out[t]) and $f), use get_reverse_vector_map instead.",
                    )
                end
            end
        end
    end
    map = get_map(
        data,
        lst_from,
        lst_to;
        allow_empty = allow_empty,
        relation_type = original_relation_type,
    )
    for (f, t) in enumerate(map)
        if t == 0
            continue
        end
        if out[t] == 0
            out[t] = f
        else
            error(
                "The element $t maps to two elements ($(out[t]) and $f), use get_reverse_vector_map instead.",
            )
        end
    end
    return out
end

function get_reverse_vector_map(
    data::AbstractData,
    lst_from::String,
    lst_to::String;
    allow_empty::Bool = true,
    original_relation_type::PMD.RelationType = RELATION_1_TO_N,
)
    n_to = max_elements(data, lst_to)
    if n_to == 0
        # TODO warn no field
        return Vector{Int32}[]
    end
    out = Vector{Int32}[zeros(Int32, 0) for _ in 1:n_to]
    if is_vector_relation(original_relation_type)
        vector_map = get_vector_map(
            data,
            lst_from,
            lst_to;
            allow_empty = allow_empty,
            relation_type = original_relation_type,
        )
        for (f, vector_to) in enumerate(vector_map)
            for t in vector_to
                push!(out[t], f)
            end
        end
    end
    map = get_map(
        data,
        lst_from,
        lst_to;
        allow_empty = allow_empty,
        relation_type = original_relation_type,
    )
    for (f, t) in enumerate(map)
        if t == 0
            continue
        end
        push!(out[t], f)
    end
    return out
end

function get_map(
    data::Data,
    lst_from::String,
    lst_to::String;
    allow_empty::Bool = true,
    relation_type::PMD.RelationType = PMD.RELATION_1_TO_1, # type of the direct relation
)
    if is_vector_relation(relation_type)
        error("For relation relation_type = $relation_type use get_vector_map")
    end
    validate_relation(data, lst_from, lst_to, relation_type)

    # @assert TYPE == PSR_RELATIONSHIP_1TO1 # TODO I think we don't need that in this interface
    raw = _raw(data)
    n_from = max_elements(data, lst_from)
    if n_from == 0
        return zeros(Int32, 0)
    end
    n_to = max_elements(data, lst_to)
    if n_to == 0
        # TODO warn no field
        return zeros(Int32, n_from)
    end

    raw_field = _get_relation_attribute(data, lst_from, lst_to, relation_type)

    out = zeros(Int32, n_from)

    vec_from = raw[lst_from]
    vec_to = raw[lst_to]

    # TODO improve this quadratic loop
    for (idx_from, el_from) in enumerate(vec_from)

        id_to = get(el_from, raw_field, -1)

        found = false
        for (idx, el) in enumerate(vec_to)
            id = el["reference_id"]
            if id_to == id
                out[idx_from] = idx
                found = true
                break
            end
        end
        if !found && !allow_empty
            error("No $lst_to element matching $lst_from of index $idx_from")
        end

    end
    return out
end

function get_vector_map(
    data::Data,
    lst_from::String,
    lst_to::String;
    allow_empty::Bool = true,
    relation_type::PMD.RelationType = PMD.RELATION_1_TO_N,
)
    if !is_vector_relation(relation_type)
        error("For relation relation_type = $relation_type use get_map")
    end

    validate_relation(data, lst_from, lst_to, relation_type)

    # @assert TYPE == PSR_RELATIONSHIP_1TO1 # TODO I think we don't need that in this interface
    raw = _raw(data)
    n_from = max_elements(data, lst_from)
    if n_from == 0
        return Vector{Int32}[]
    end
    n_to = max_elements(data, lst_to)
    if n_to == 0
        # TODO warn no field
        return Vector{Int32}[Int32[] for _ in 1:n_from]
    end

    raw_field = _get_relation_attribute(data, lst_from, lst_to, relation_type)

    out = Vector{Int32}[Int32[] for _ in 1:n_from]

    vec_from = raw[lst_from]
    vec_to = raw[lst_to]

    # TODO improve this quadratic loop
    for (idx_from, el_from) in enumerate(vec_from)
        vec_id_to = get(el_from, raw_field, Any[])
        for id_to in vec_id_to
            # found = false
            for (idx, el) in enumerate(vec_to)
                id = el["reference_id"]
                if id_to == id
                    push!(out[idx_from], idx)
                    # found = true
                    break
                end
            end
            # if !found && !allow_empty
            #     error("No $lst_to element matching $lst_from of index $idx_from")
            # end
        end
    end
    return out
end

function get_related(
    data::Data,
    source::String,
    target::String,
    source_index::Integer;
    relation_type::PMD.RelationType = PMD.RELATION_1_TO_1,
)
    check_relation_scalar(relation_type)
    validate_relation(data, source, target, relation_type)
    relation_field = _get_relation_attribute(data, source, target, relation_type)
    source_element = _get_element(data, source, source_index)

    if !haskey(source_element, relation_field)
        # low level error
        error(
            "Element '$source_index' from collection '$source' has no field '$relation_field'",
        )
    end

    target_id = source_element[relation_field]

    # TODO: consider caching reference_id's
    for (index, element) in enumerate(_get_elements(data, target))
        if element["reference_id"] == target_id
            return index
        end
    end

    error("No element with id '$target_id' was found in collection '$target'")

    return 0 # for type stability
end

function get_vector_related(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    relation_type::PMD.RelationType = PMD.RELATION_1_TO_N,
)
    check_relation_vector(relation_type)
    validate_relation(data, source, target, relation_type)
    source_element = _get_element(data, source, source_index)
    relation_field = _get_relation_attribute(data, source, target, relation_type)

    if !haskey(source_element, relation_field)
        error(
            "Element '$source_index' from collection '$source' has no field '$relation_field'",
        )
    end

    target_id_set = Set{Int}(source_element[relation_field])

    target_index_list = Int[]

    for (index, element) in enumerate(_get_elements(data, target))
        if element["reference_id"] ∈ target_id_set
            push!(target_index_list, index)
        end
    end

    if isempty(target_index_list)
        error("No elements with id '$target_id' were found in collection '$target'")
    end

    return target_index_list
end
