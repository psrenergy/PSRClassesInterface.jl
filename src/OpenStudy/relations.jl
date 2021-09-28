
@enum RelationType begin
    RELATION_1_TO_1
    RELATION_1_TO_N
    RELATION_FROM
    RELATION_TO
    RELATION_TURBINE_TO
    RELATION_SPILL_TO
    RELATION_INFILTRATE_TO
    RELATION_STORED_ENERGY_DONWSTREAM
    RELATION_BACKED
end

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

function validate_reation(lst_from::String, lst_to::String, type::RelationType)
    if haskey(_RELATIONS, lst_from)
        if !haskey(_RELATIONS[lst_from], (lst_to, type))
            error("No relation from $lst_from to $lst_to with type $type \n" *
                  "Available relations from $lst_from are: \n" *
                  "$(keys(_RELATIONS[lst_from]))")
        end
    else
        error("No relations from $lst_from available")
    end
    return nothing
end

function get_reverse_map(
    data::Data,
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
    data::Data,
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
    validate_reation(lst_from, lst_to, relation_type)

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

    raw_field = _RELATIONS[lst_from][(lst_to, relation_type)]

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
    validate_reation(lst_from, lst_to, relation_type)

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

    raw_field = _RELATIONS[lst_from][(lst_to, relation_type)]

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
