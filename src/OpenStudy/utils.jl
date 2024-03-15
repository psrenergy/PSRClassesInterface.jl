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

function _get_attribute_type(data::Data, collection::String, attribute::String)
    attribute_data = PSRI.get_attribute_struct(data, collection, attribute)
    return attribute_data.type::Type{<:PSRI.MainTypes}
end

function Base.show(io::IO, data::Data)
    return summary(io, data)
end

function _list_attributes_and_types(data::Data, collection::String, attributes::Set{String})
    items = String[]

    for attr in sort(collect(attributes))
        attr_struct = PSRI.get_attribute_struct(data, collection, attr)

        type = if attr_struct.is_vector
            "Vector{$(attr_struct.type)}"
        else
            "$(attr_struct.type)"
        end

        push!(items, "$attr :: $type")
    end

    return join(items, "\n    ")
end

function _cast_element!(data::Data, collection::String, element::Dict{String, Any})
    for (attribute, value) in element
        if _has_relation_attribute(data.relation_mapper, collection, attribute) ||
           attribute == "reference_id"
            continue
        end
        T = _get_attribute_type(data, collection, attribute)

        if is_vector_attribute(data, collection, attribute)
            element[attribute] = _cast_vector(T, value)
        else
            element[attribute] = _cast(T, value)
        end
    end

    return nothing
end

function _rectify_study_data!(data::Data)
    for (collection, elements) in data.raw
        for element in 1:length(elements)
            _cast_element!(data, collection, data.raw[collection][element])
        end
    end
end

function is_vector_attribute(data::Data, collection::String, attribute::String)
    return PSRI.get_attribute_struct(data, collection, attribute).is_vector
end

function get_attribute_index(data::Data, collection::String, attribute::String)
    index = PSRI.get_attribute_struct(data, collection, attribute).index

    if isnothing(index) || isempty(index)
        return nothing
    else
        return index
    end
end

function _get_index(data::Data, reference_id::Integer)
    return _get_index(data.data_index, reference_id)
end

function _get_index_by_code(data::Data, collection::String, code::Integer)
    collection_vector = data.raw[collection]

    for (index, element) in enumerate(collection_vector)
        if element["code"] == code
            return index
        end
    end

    return error("Code '$code' not found in collection '$collection'")
end

function _set_index!(data::Data, reference_id::Integer, collection::String, index::Integer)
    _set_index!(data.data_index, reference_id, collection, index)

    return nothing
end

function _build_index!(data::Data)
    for collection in PSRI.get_collections(data)
        if PSRI.max_elements(data, collection) == 0
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

const _GET_DICT = Dict{String, Any}()

"""
    _cast(::Type{T}, val, default::T = PSRI._default_value(T))

Converts `val` to type `T`, if possible.
"""
_cast(::Type{T}, val::T, default::T = PSRI._default_value(T)) where {T} = val
_cast(::Type{String}, val::String, default::String = PSRI._default_value(String)) = val
_cast(::Type{Int32}, val::Integer, default::Int32 = PSRI._default_value(Int32)) = Int32(val)
_cast(::Type{Float64}, val::Real, default::Float64 = PSRI._default_value(Float64)) = val
_cast(::Type{T}, val::Nothing, default::T = PSRI._default_value(T)) where {T} = default

function _cast(
    ::Type{Dates.Date},
    val::Dates.Date,
    default::Dates.Date = PSRI._default_value(Dates.Date),
)
    return val
end

function _cast(::Type{T}, val::String, default::T = PSRI._default_value(T)) where {T}
    return parse(T, val)
end

function _cast(
    ::Type{Dates.Date},
    val::String,
    default::Dates.Date = _default_value(Dates.Date),
)
    return _simple_date(val)
end

"""
    _cast_vector(::Type{T}, vector, default::T = PSRI._default_value(T))

Converts `vector` to vector of type `T`, if possible.
"""
function _cast_vector(
    ::Type{T},
    vector::Vector{<:Any},
    default::T = PSRI._default_value(T),
) where {T}
    out = Vector{T}(undef, length(vector))

    for i in eachindex(vector)
        out[i] = _cast(T, vector[i], default)
    end

    return out
end

function _cast_vector(
    ::Type{T},
    vector::Vector{T},
    default::T = PSRI._default_value(T),
) where {T}
    return deepcopy(vector)
end

_raw(data::Data) = data.raw

function _simple_date(date::Dates.Date)
    return date
end

function _simple_date(str::String)

    # possible formats
    # "31/12/1900" # DD/MM/AAAA
    # "1900-12-31" # AAAA/MM/DD
    if length(str) != 10
        error("Baddly defined date, should have 10 digitis got" * str)
    end

    third_digit = str[3]
    if isnumeric(third_digit) # "1900-12-31" # AAAA/MM/DD
        day = parse(Int, str[9:10])
        month = parse(Int, str[6:7])
        year = parse(Int, str[1:4])
        return Dates.Date(year, month, day)
    end
    # "31/12/1900" # DD/MM/AAAA
    day = parse(Int, str[1:2])
    month = parse(Int, str[4:5])
    year = parse(Int, str[7:10])
    return Dates.Date(year, month, day)
end

function _date_from_stage(data::Data, t::Int)
    return PSRI._date_from_stage(t, data.stage_type, data.first_date)
end
function _findfirst_date(date::Dates.Date, vec::Vector) # TODO type this vecto whe raw is stabilized
    # vec is assumed sorted
    if length(vec) == 0
        error("empty vector of dates")
        # return 1
    end
    if date < _simple_date(vec[1])
        # error("date before first element")
        return 1
    end
    for i in 1:(length(vec)-1)
        if _simple_date(vec[i]) <= date < _simple_date(vec[i+1])
            return i
        end
    end
    return length(vec)
end
# TODO: preprocess date vectors
# TODO: informs about empty slots (beyond classes)

function _variable_duration_to_file!(data::Data)
    dur_model = _raw(data)["PSRStudy"][1]["DurationModel"]
    # dur_model["modeldimensions"][1]["value"] # max block sim
    dates = dur_model["Data"]
    duration = [dur_model["Duracao($b)"] for b in 1:data.number_blocks]

    FILE_NAME = tempname(data.data_path) * string("_", time_ns(), "_psr_temp")

    STAGES = length(dates)

    _year, _stage = PSRI._year_stage(_simple_date(dates[1]), data.stage_type)

    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        FILE_NAME;
        blocks = 1,
        scenarios = 1,
        stages = STAGES,
        agents = ["$b" for b in 1:data.number_blocks],
        unit = "h",
        # optional:
        initial_stage = _stage,
        initial_year = _year,
        stage_type = data.stage_type,
    )
    # TODO check handle time in negative stages

    cache = zeros(data.number_blocks)

    first_date = _findfirst_date(_date_from_stage(data, 1), dates)

    for t in 1:STAGES
        for b in 1:data.number_blocks
            cache[b] = duration[b][t]
        end
        PSRI.write_registry(iow, cache, t, 1, 1)
    end

    PSRI.close(iow)

    ior = PSRI.open(
        PSRI.OpenBinary.Reader,
        FILE_NAME;
        use_header = false,
        initial_stage = data.first_date,
    )

    data.variable_duration = ior

    return
end

# TODO: handle profile mode
function _hour_block_map_to_file!(data::Data)
    study = _raw(data)["PSRStudy"][1]
    dates = study["DataHourBlock"]
    hbmap = study["HourBlockMap"]

    FILE_NAME_DUR = tempname(data.data_path) * string("_", time_ns(), "_psr_temp")
    FILE_NAME_HBM = tempname(data.data_path) * string("_", time_ns(), "_psr_temp")

    _first = _simple_date(dates[1])
    _last = _simple_date(dates[end])

    STAGES = PSRI._stage_from_date(_last, data.stage_type, _first)

    _year, _stage = PSRI._year_stage(_first, data.stage_type)

    io_dur = PSRI.open(
        PSRI.OpenBinary.Writer,
        FILE_NAME_DUR;
        blocks = 1,
        scenarios = 1,
        stages = STAGES,
        agents = ["$b" for b in 1:data.number_blocks],
        unit = "h",
        # optional:
        initial_stage = _stage,
        initial_year = _year,
        stage_type = data.stage_type,
    )
    # TODO check handle time in negative stages
    io_hbm = PSRI.open(
        PSRI.OpenBinary.Writer,
        FILE_NAME_HBM;
        # blocks = 1,
        is_hourly = true,
        scenarios = 1,
        stages = STAGES,
        agents = ["block"],
        unit = "idx",
        # optional:
        initial_stage = _stage,
        initial_year = _year,
        stage_type = data.stage_type,
    )

    cache = zeros(data.number_blocks)
    cache_hbm = zeros(1)

    hour = 0
    last_str = ""
    current_str = ""

    first_date = _findfirst_date(_date_from_stage(data, 1), dates)

    for t in 1:STAGES
        fill!(cache, 0.0)
        for b in 1:PSRI.blocks_in_stage(io_hbm, t)
            hour += 1
            current_str = dates[hour]
            if b == 1
                @assert current_str != last_str
            else
                @assert current_str == last_str
            end
            last_str = current_str
            cache_hbm[] = hbmap[hour]
            @assert 1 <= cache_hbm[] <= data.number_blocks
            PSRI.write_registry(io_hbm, cache_hbm, t, 1, b)
            cache[Int(cache_hbm[])] += 1
        end
        for b in 1:data.number_blocks
            @assert cache[b] > 0
        end
        PSRI.write_registry(io_dur, cache, t, 1, 1)
    end

    PSRI.close(io_dur)
    PSRI.close(io_hbm)

    ior_dur = PSRI.open(
        PSRI.OpenBinary.Reader,
        FILE_NAME_DUR;
        use_header = false,
        initial_stage = data.first_date,
    )
    ior_hbm = PSRI.open(
        PSRI.OpenBinary.Reader,
        FILE_NAME_HBM;
        use_header = false,
        initial_stage = data.first_date,
    )

    data.variable_duration = ior_dur
    data.hour_to_block = ior_hbm

    return
end

function load_json_struct!(::Data, ::Nothing) end

function load_json_struct!(data::Data, paths::Vector{String})
    for path in paths
        load_json_struct!(data, path)
    end
    return nothing
end

function load_json_struct!(data::Data, path::String)
    if isdir(path)
        for subpath in readdir(path)
            if isfile(subpath) && last(splitext(subpath)) == ".json"
                load_json_struct!(data, subpath)
            end
        end
        return nothing
    end

    if !(isfile(path) && last(splitext(path)) == ".json")
        error("Invalid JSON file path '$path'")
    end

    raw_struct = JSON.parsefile(path)

    for (collection, attr_list) in raw_struct
        if !haskey(data.data_struct, collection)
            data.data_struct[collection] = Dict{String, Attribute}()
        end

        for (attr_name, attr_data) in attr_list
            data.data_struct[collection][attr_name] = Attribute(
                attr_data["name"],
                attr_data["is_vector"],
                _get_json_type(attr_data["type"]),
                attr_data["dim"],
                attr_data["index"],
            )
        end
    end

    return nothing
end

function _get_json_type(type::String)
    if type == "Int32"
        return Int32
    elseif type == "Float64"
        return Float64
    elseif type == "String"
        return String
    elseif type == "Dates.Date"
        return Dates.Date
    elseif type == "Ptr{Nothing}"
        return Ptr{Nothing}
    else
        error("Unknown type '$type'")
    end
end

function dump_json_struct(path::String, data::Data)
    Base.open(path, "w") do io
        return JSON.print(io, data.data_struct)
    end
end

function _generate_reference_id(data_index::DataIndex)
    @assert data_index.max_id < typemax(Int)

    return data_index.max_id + 1
end

# Mapped vector

function _need_update(data::Data, cache)
    if data.controller_stage != cache.stage
        return true
    elseif !isempty(cache.dim1_str)
        if data.controller_dim[cache.dim1_str] != cache.dim1
            return true
        elseif !isempty(cache.dim2_str)
            if data.controller_dim[cache.dim2_str] != cache.dim2
                return true
            else
                return false
            end
        end
    else
        return false
    end
end

function _add_filter(data, filter, collection, attr, ::Type{Int32})
    if haskey(data.map_filter_integer, filter)
        push!(data.map_filter_integer[filter], (collection, attr))
    else
        data.map_filter_integer[filter] = [(collection, attr)]
    end
    return nothing
end
function _add_filter(data, filter, collection, attr, ::Type{Float64})
    if haskey(data.map_filter_real, filter)
        push!(data.map_filter_real[filter], (collection, attr))
    else
        data.map_filter_real[filter] = [(collection, attr)]
    end
    return nothing
end
function _add_filter(data, filter, collection, attr, ::Type{Dates.Date})
    error("TODO")
    if haskey(data.map_filter_date, filter)
        push!(data.map_filter_date[filter], (collection, attr))
    else
        data.map_filter_date[filter] = [(collection, attr)]
    end
    return nothing
end

# Relation

"""
    _has_relation_attribute(relations::Dict{String, PSRI.PMD.Relation}, relation_attribute::String)

    Returns true if there is a relation with attribute 'relation_attribute' in a 'Vector{PMD.Relation}'
"""
function _has_relation_attribute(
    relations::Dict{String, PSRI.PMD.Relation},
    relation_attribute::String,
)
    for relation in values(relations)
        if relation.attribute == relation_attribute
            return true
        end
    end
    return false
end

function _has_relation_attribute(
    relations::Dict{String, Dict{String, PSRI.PMD.Relation}},
    relation_attribute::String,
)
    for (target, relations) in relations
        if _has_relation_attribute(relations, relation_attribute)
            return true
        end
    end
    return false
end

function _has_relation_attribute(
    relations::Dict{String, Dict{String, Dict{String, PSRClassesInterface.PMD.Relation}}},
    source::String,
    relation_attribute::String,
)
    if !haskey(relations, source)
        return false
    end
    for (source, source_relations) in relations[source]
        if _has_relation_attribute(source_relations, relation_attribute)
            return true
        end
    end
    return false
end

"""
    _has_relation_type(relations::Vector{PMD.Relation}, relation_type::PSRI.PMD.RelationType)

    Returns true if there is a relation with type 'relation_type' in a 'Vector{PMD.Relation}'
"""
function _has_relation_type(
    relations::Dict{String, PSRI.PMD.Relation},
    relation_type::PSRI.PMD.RelationType,
)
    has_relation_type = false
    for relation in values(relations)
        if relation.type == relation_type
            has_relation_type = true
        end
    end
    return has_relation_type
end

"""
    relations_summary(data::Data, collection::String, index::Integer)

    Displays all current relations of the element in the following way:

    attribute_name: collection_name[element_index] → collection_name[element_index]

    (The arrow always points from the source to target)
"""
function relations_summary(data::Data, collection::String, index::Integer)
    if !PSRI.has_relations(data, collection, index)
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
