"""
    is_vector_relation(relation::RelationType)

Returns true is `relation` is a vector relation.
"""

function is_vector_relation(relation)
    return relation == RELATION_1_TO_N || relation == RELATION_BACKED
end

const _INNER_KEY = Tuple{String, RelationType}
const _INNER_DICT = Dict{_INNER_KEY, String}
const _RELATIONS = Dict{String, _INNER_DICT}(
    "PSRThermalPlant" => _INNER_DICT(
        ("PSRFuel", RELATION_1_TO_N) => "fuels",
        ("PSRSystem", RELATION_1_TO_1) => "system",
    ),
    "PSRFuelConsumption" => _INNER_DICT(
        ("PSRFuel", RELATION_1_TO_1) => "fuel",
        ("PSRThermalPlant", RELATION_1_TO_1) => "plant",
    ),
    "PSRHydroPlant" => _INNER_DICT(
        ("PSRGaugingStation", RELATION_1_TO_1) => "station",
        ("PSRSystem", RELATION_1_TO_1) => "system",
        ("PSRHydroPlant", RELATION_TURBINE_TO) => "turbinning",
        ("PSRHydroPlant", RELATION_SPILL_TO) => "spilling",
        ("PSRHydroPlant", RELATION_INFILTRATE_TO) => "filtration",
        ("PSRHydroPlant", RELATION_STORED_ENERGY_DONWSTREAM) => "storedenergy",
    ),
    "PSRGndPlant" => _INNER_DICT(
        ("PSRGndGaugingStation", RELATION_1_TO_1) => "station",
        ("PSRSystem", RELATION_1_TO_1) => "system",
    ),
    "PSRGaugingStation" => _INNER_DICT(
        ("PSRGaugingStation", RELATION_1_TO_1) => "downstream",
    ),
    "PSRBattery" => _INNER_DICT(
        ("PSRBus", RELATION_1_TO_1) => "bus",
        ("PSRSystem", RELATION_1_TO_1) => "system",
    ),
    "PSRGenerator" => _INNER_DICT(
        ("PSRBus", RELATION_1_TO_1) => "bus",
        ("PSRThermalPlant", RELATION_1_TO_1) => "plant",
        ("PSRHydroPlant", RELATION_1_TO_1) => "plant",
        ("PSRGndPlant", RELATION_1_TO_1) => "plant",
    ),
    # "PSRFuel" => _INNER_DICT(
    #     "PSRSystem", RELATION_1_TO_1) => "system",
    # ),
    "PSRDemandSegment" => _INNER_DICT(
        ("PSRDemand", RELATION_1_TO_1) => "demand",
        ("PSRSystem", RELATION_1_TO_1) => "system",
    ),
    "PSRDemand" => _INNER_DICT(
        ("PSRSystem", RELATION_1_TO_1) => "system",
    ),
    "PSRLoad" => _INNER_DICT(
        ("PSRBus", RELATION_1_TO_1) => "bus",
        ("PSRDemand", RELATION_1_TO_1) => "demand",
    ),
    "PSRInterconnection" => _INNER_DICT(
        ("PSRSystem", RELATION_FROM) => "no1",
        ("PSRSystem", RELATION_TO) => "no2",
    ),
    # TODO:
    # merge series an trafos
    "PSRLinkDC" => _INNER_DICT(
        ("PSRBus", RELATION_FROM) => "no1",
        ("PSRBus", RELATION_TO) => "no2",
    ),
    "PSRSerie" => _INNER_DICT(
        ("PSRBus", RELATION_FROM) => "no1",
        ("PSRBus", RELATION_TO) => "no2",
    ),
    "PSRTransformer" => _INNER_DICT(
        ("PSRBus", RELATION_FROM) => "no1",
        ("PSRBus", RELATION_TO) => "no2",
    ),
    "PSRBus" => _INNER_DICT(
        ("PSRArea", RELATION_1_TO_1) => "area",
        ("PSRSystem", RELATION_1_TO_1) => "system",
    ),
    # TODO maybe rename?
    "PSRGenerationConstraintData" => _INNER_DICT(
        ("PSRSystem", RELATION_1_TO_1) => "system",
        ("PSRThermalPlant", RELATION_1_TO_N) => "usinas",
        ("PSRHydroPlant", RELATION_1_TO_N) => "usinas",
        ("PSRGndPlant", RELATION_1_TO_N) => "usinas",
        ("PSRBattery", RELATION_1_TO_N) => "batteries",
    ),
    # TODO maybe rename?
    "PSRInterconnectionSumData" => _INNER_DICT(
        ("PSRInterconnection", RELATION_1_TO_N) => "elements",
    ),
    # TODO maybe rename?
    "PSRMaintenanceData" => _INNER_DICT(
        ("PSRSystem", RELATION_1_TO_1) => "system",
        ("PSRThermalPlant", RELATION_1_TO_1) => "plant",
        ("PSRHydroPlant", RELATION_1_TO_1) => "plant",
        ("PSRGndPlant", RELATION_1_TO_1) => "plant",
    ),
    # TODO maybe rename?
    "PSRReserveGenerationConstraintData" => _INNER_DICT(
        ("PSRSystem", RELATION_1_TO_1) => "system",
        ("PSRThermalPlant", RELATION_1_TO_N) => "usinas",
        ("PSRHydroPlant", RELATION_1_TO_N) => "usinas",
        ("PSRGndPlant", RELATION_1_TO_N) => "usinas",
        ("PSRBattery", RELATION_1_TO_N) => "batteries",
        ("PSRThermalPlant", RELATION_BACKED) => "backed",
        ("PSRHydroPlant", RELATION_BACKED) => "backed",
        ("PSRGndPlant", RELATION_BACKED) => "backed",
    ),
    # TODO maybe rename?
    "PSRReservoirSet" => _INNER_DICT(
        ("PSRHydroPlant", RELATION_1_TO_N) => "reservoirs",
    ),
)

function _get_relation(source::String, target::String, relation_type::RelationType)
    return _RELATIONS[source][(target, relation_type)]
end

function _get_target_index_from_relation(data::Data, source::String, target::String, source_index::Integer, relation_attribute::String)
    source_element = data.raw[source][source_index]
    target_index = _get_index(data.data_index,source_element[relation_attribute])
    return target_index[2]
end

function _get_sources_indices_from_relations(data::Data, source::String, target::String, target_id::Integer, relation_attribute::String,)
    possible_elements = data.raw[source]

    indices = Vector{Int32}()
    for (index,element) in enumerate(possible_elements)
        if haskey(element, relation_attribute)
            if element[relation_attribute] == target_id
                push!(indices, index)
            end
        end
    end
    return indices
end


function _get_element_related(data::Data, collection::String, index::Integer)
    element = data.raw[collection][index]

    # source_collection, target_collection, source_index, target_index
    relations = Dict{Tuple{String, String, Int, Int}, String}()
    

    # Relations where the element is source
    for ((target, relation), attribute) in _RELATIONS[collection]
        if haskey(element,attribute) # has a relation as source
            target_index = _get_target_index_from_relation(data,collection, target, index, attribute)
            
            relations[(collection, target, index, target_index)] = attribute
        end
    end


    # Relations where the element is target
    for (source, _) in _RELATIONS
        for ((target, relation), attribute) in _RELATIONS[source]
            if haskey(data.raw, source)
                if target == collection
                    sources_indices = _get_sources_indices_from_relations(data, source, target, element["reference_id"], attribute)
                    if ! isempty(sources_indices)
                        for source_index in sources_indices
                            relations[(source, collection, source_index, index)] = attribute
                        end
                    end
                end
            end
        end
    end
    return relations
end

function has_relations(data::Data, collection:: String, index::Integer)

    relations = _get_element_related(data, collection, index)

    if ! isempty(relations)
        return true
    end

    return false
end


function check_relation_scalar(relation_type)
    if is_vector_relation(relation_type)
        error("Relation of type $relation_type is of type vector, not the expected scalar.")
    end
    return nothing
end

function check_relation_vector(relation_type)
    if !is_vector_relation(relation_type)
        error("Relation of type $relation_type is of type scalar, not the expected vector.")
    end
    return nothing
end

function validate_relation(lst_from::String, lst_to::String, type::RelationType)

    direct = false
    reverse = false
    reverse_type = nothing
    if haskey(_RELATIONS, lst_from)
        direct = true # there are relations from lst_from
        if haskey(_RELATIONS[lst_from], (lst_to, type))
            return nothing # valid relation found
        end
    end
    if haskey(_RELATIONS, lst_to)
        for (k, v) in _RELATIONS[lst_to]
            if k[1] == lst_from
                reverse = true # a reverse relation was found
                reverse_type = k[2]
                break
            end
        end
    end
    if reverse
        error("No relation from $lst_from to $lst_to with type $type." *
            " The there is a reverse relation from $lst_to to " * 
            "$lst_from  with type $type.\n" *
            "Try: PSRI.get_reverse_vector_map(data, \"$lst_to\", " *
            "\"$lst_from\"; original_relation_type = $(reverse_type))")
    elseif direct
        error("No relation from $lst_from to $lst_to with type $type \n" *
            "Available relations from $lst_from are: \n" *
            "$(keys(_RELATIONS[lst_from]))")
    else
        error("No relations from $lst_from available")
    end
    return nothing
end

function get_reverse_map(
    data::AbstractData,
    lst_from::String,
    lst_to::String;
    allow_empty::Bool = true,
    original_relation_type::RelationType = RELATION_1_TO_1, # type of the direct relation
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
            lst_to,
            allow_empty = allow_empty,
            relation_type = original_relation_type
        )
        for (f,vector_to) in enumerate(vector_map)
            for t in vector_to
                if out[t] == 0
                    out[t] = f
                else
                    error("The element $t maps to two elements ($(out[t]) and $f), use get_reverse_vector_map instead.")
                end
            end
        end
    end
    map = get_map(
        data,
        lst_from,
        lst_to,
        allow_empty = allow_empty,
        relation_type = original_relation_type
    )
    for (f,t) in enumerate(map)
        if t == 0
            continue
        end
        if out[t] == 0
            out[t] = f
        else
            error("The element $t maps to two elements ($(out[t]) and $f), use get_reverse_vector_map instead.")
        end
    end
    return out
end

function get_reverse_vector_map(
    data::AbstractData,
    lst_from::String,
    lst_to::String;
    allow_empty::Bool = true,
    original_relation_type::RelationType = RELATION_1_TO_N,
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
            lst_to,
            allow_empty = allow_empty,
            relation_type = original_relation_type
        )
        for (f,vector_to) in enumerate(vector_map)
            for t in vector_to
                push!(out[t], f)
            end
        end
    end
    map = get_map(
        data,
        lst_from,
        lst_to,
        allow_empty = allow_empty,
        relation_type = original_relation_type
    )
    for (f,t) in enumerate(map)
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
    relation_type::RelationType = RELATION_1_TO_1, # type of the direct relation
)

    if is_vector_relation(relation_type)
        error("For relation relation_type = $relation_type use get_vector_map")
    end
    validate_relation(lst_from, lst_to, relation_type)

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

    raw_field = _get_relation(lst_from, lst_to, relation_type)

    out = zeros(Int32, n_from)

    vec_from = raw[lst_from]
    vec_to = raw[lst_to]

    # TODO improve this quadratic loop
    for (idx_from, el_from) in enumerate(vec_from)
        id_to = get(el_from, raw_field, -1)

        found = false
        for (idx,el) in enumerate(vec_to)
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
    relation_type::RelationType = RELATION_1_TO_N,
)

    if !is_vector_relation(relation_type)
        error("For relation relation_type = $relation_type use get_map")
    end

    validate_relation(lst_from, lst_to, relation_type)

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

    raw_field = _get_relation(lst_from, lst_to, relation_type)

    out = Vector{Int32}[Int32[] for _ in 1:n_from]

    vec_from = raw[lst_from]
    vec_to = raw[lst_to]

    # TODO improve this quadratic loop
    for (idx_from, el_from) in enumerate(vec_from)
        vec_id_to = get(el_from, raw_field, Any[])
        for id_to in vec_id_to
            # found = false
            for (idx,el) in enumerate(vec_to)
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
    relation_type::RelationType = RELATION_1_TO_1,
)
    check_relation_scalar(relation_type)
    validate_relation(source, target, relation_type)
    relation_field = _get_relation(source, target, relation_type)
    source_element = _get_element(data, source, source_index)

    if !haskey(source_element, relation_field)
        # low level error
        error("Element '$source_index' from collection '$source' has no field '$relation_field'")
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
    relation_type::RelationType = RELATION_1_TO_N,
)
    check_relation_vector(relation_type)
    validate_relation(source, target, relation_type)
    source_element = _get_element(data, source, source_index)
    relation_field = _get_relation(source, target, relation_type)

    if !haskey(source_element, relation_field)
        error("Element '$source_index' from collection '$source' has no field '$relation_field'")
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
