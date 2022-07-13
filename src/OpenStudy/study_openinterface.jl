struct OpenInterface <: AbstractStudyInterface end

struct Attribute
    name::String
    is_vector::Bool
    type::DataType
    dim::Int
    index::String
    # interval::String
end

mutable struct VectorCache{T}
    dim1_str::String
    dim2_str::String
    dim1::Int
    dim2::Int
    index_str::String
    stage::Int
    vector::Vector{T}
    # date::Vector{Int32}
    # current_date::Int32
end

# TODO: rebuild "raw" stabilizing data types
# TODO fuel consumption updater

Base.@kwdef mutable struct Data{T} <: AbstractData
    raw::T
    stage_type::StageType

    data_path::String

    duration_mode::BlockDurationMode = FIXED_DURATION
    number_blocks::Int = 1

    # for variable duration and for hour block map
    variable_duration::Union{Nothing, OpenBinary.Reader} = nothing
    hour_to_block::Union{Nothing, OpenBinary.Reader} = nothing

    first_year::Int
    first_stage::Int #maybe week or month, day...
    first_date::Dates.Date

    data_struct::Dict{String, Dict{String, Attribute}}
    model_files_added::Set{String}

    log_file::Union{IOStream, Nothing}
    verbose::Bool

    # main time controller
    controller_stage::Int = 1
    controller_stage_changed::Bool = false
    controller_date::Dates.Date
    controller_dim::Dict{String, Int} = Dict{String, Int}()

    # cache to only in data reference once (per element)
    map_cache_data_idx::Dict{String, Dict{String, Vector{Int32}}} =
        Dict{String, Dict{String, Vector{Int32}}}()
    # vectors returned to user
    map_cache_real::Dict{String, Dict{String, VectorCache{Float64}}} =
        Dict{String, Dict{String, VectorCache{Float64}}}()
    map_cache_integer::Dict{String, Dict{String, VectorCache{Int32}}} =
        Dict{String, Dict{String, VectorCache{Int32}}}()
    map_cache_date::Dict{String, Dict{String, VectorCache{Dates.Date}}} =
        Dict{String, Dict{String, VectorCache{Dates.Date}}}()

    map_filter_real::Dict{String, Vector{Tuple{String, String}}} =
        Dict{String, Vector{Tuple{String, String}}}()
    map_filter_integer::Dict{String, Vector{Tuple{String, String}}} =
        Dict{String, Vector{Tuple{String, String}}}()

    extra_config::Dict{String, Any} = Dict{String, Any}()

    # TODO: cache importante data
end

_raw(data::Data) = data.raw

function _simple_date(str::String)

    # possible formats
    # "31/12/1900" # DD/MM/AAAA
    # "1900-12-31" # AAAA/MM/DD
    if length(str) != 10
        error("Baddly defined date, should have 10 digitis got" * str)
    end

    third_digit = str[3]
    if isnumeric(third_digit) # "1900-12-31" # AAAA/MM/DD
        day   = parse(Int, str[9:10])
        month = parse(Int, str[6:7])
        year  = parse(Int, str[1:4])
        return Dates.Date(year, month, day)
    end
    # "31/12/1900" # DD/MM/AAAA
    day   = parse(Int, str[1:2])
    month = parse(Int, str[4:5])
    year  = parse(Int, str[7:10])
    return Dates.Date(year, month, day)
end

function _date_from_stage(data::Data, t::Int)
    return _date_from_stage(t, data.stage_type, data.first_date)
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

function initialize_study(
    ::OpenInterface;
    data_path = "",
    files = String[],
    path_pmds = PMD._PMDS_BASE_PATH,
    log_file = "",
    verbose = true,
    extra_config_file::String = "",
)
    if !isdir(data_path)
        error("$data_path is not a valid directory")
    end
    PATH_JSON = joinpath(data_path, "psrclasses.json")
    if !isfile(PATH_JSON)
        error("$PATH_JSON not found")
    end

    file = if !isempty(log_file)
        open(file, "w")
    else
        nothing
    end

    raw = JSON.parsefile(PATH_JSON)

    study_data = raw["PSRStudy"][1]

    stage_type = StageType(study_data["Tipo_Etapa"])
    first_year = study_data["Ano_inicial"]
    first_stage = study_data["Etapa_inicial"]
    first_date = Dates.Date(first_year, 1, 1) +
            ifelse(stage_type == STAGE_MONTH,
                Dates.Month(first_stage-1), Dates.Week(first_stage-1))
    # TODO daily study

    data_struct = Dict{String, Dict{String, Attribute}}()
    model_files_added = Set{String}()
    _load_mask_or_model(path_pmds, data_struct, files, model_files_added)
    if isempty(model_files_added)
        error("No Model definition (.pmd) file found")
    end

    number_blocks = study_data["NumeroBlocosDemanda"]
    @assert number_blocks == study_data["NumberBlocks"]

    duration_mode = if haskey(study_data, "HourlyData") && study_data["HourlyData"]["BMAP"] in [1, 2]
        HOUR_BLOCK_MAP
    elseif (
            haskey(study_data, "DurationModel") &&
            haskey(study_data["DurationModel"], "Duracao($number_blocks)")
        )
        VARIABLE_DURATION
    else
        FIXED_DURATION
    end

    data = Data(
        raw = raw,
        data_path = data_path,
        data_struct = data_struct,
        model_files_added = model_files_added,
        stage_type = stage_type,
        first_year = first_year,
        first_stage = first_stage,
        first_date = first_date,
        controller_date = first_date,

        duration_mode = duration_mode,
        number_blocks = number_blocks,

        log_file = file,
        verbose = verbose,
    )

    if duration_mode == VARIABLE_DURATION
        _variable_duration_to_file!(data)
    elseif duration_mode == HOUR_BLOCK_MAP
        _hour_block_map_to_file!(data)
    end

    if !isempty(extra_config_file)
        if isfile(extra_config_file)
            data.extra_config = TOML.parsefile(extra_config_file)
        else
            error("Files $extra_config_file not found")
        end
    end

    return data
end

function _collection(
    data::Data,
    str::String,
    remove_redundant = true,
    sort_on = "",
    query = "",
)
    if sort_on != ""
        error("sort_on is not valid for the JSON reader")
    end
    if query != ""
        error("query is not valid for the JSON reader")
    end

    # if haskey(data.collections, str)
    #     return data.collections[str]
    # else
    #     col = _collection(data, Symbol(str), remove_redundant, sort_on, query)
    #     data.collections[str] = col
    #     @show str, col
    #     return col
    # end
    error("method not implmented")
end

function max_elements(data::Data, str::String)
    raw = _raw(data)
    if haskey(raw, str)
        return length(raw[str])
    end
    return 0
end

_default_value(::Type{T}) where T = zero(T)
_default_value(::Type{String}) = ""
_default_value(::Type{Dates.Date}) = Dates.Date(1900, 1, 1)

function _check_type(attr_struct, T, col, name)
    if attr_struct.type != T
        error("Attribute $name of collection $col is a of type $(attr_struct.type) not $T.")
    end
    return
end
function _check_parm(attr_struct, col, name)
    if attr_struct.is_vector
        error("Attribute $name of collection $col is a of type vector.")
    end
    return
end
function _check_vector(attr_struct, col, name)
    if !attr_struct.is_vector
        error("Attribute $name of collection $col is a of type parm.")
    end
    return
end
function _check_dim(attr_struct, col, name, dim1, dim2)
    dim = attr_struct.dim
    @assert dim1 >= 0
    @assert dim2 >= 0
    if dim2 > 0 && dim1 == 0
        error("Getting attribute $name of collection $col, got dim2 = $dims2 and dim1 = 0")
    end
    if dim == 0 && dim1 > 0
        error("Attribute $name of collection $col, has 0 dims but got dim1 = $dim1")
    end
    if dim == 0 && dim2 > 0
        error("Attribute $name of collection $col, has 0 dims but got dim2 = $dim2")
    end
    if dim == 1 && dim1 == 0
        error("Attribute $name of collection $col, has 1 dim but got dim1 = 0")
    end
    if dim == 1 && dim2 > 0
        error("Attribute $name of collection $col, has 1 dim but got dim2 = $dim2")
    end
    if dim == 2 && dim1 == 0
        error("Attribute $name of collection $col, has 2 dims but got dim1 = 0")
    end
    if dim == 2 && dim2 == 0
        error("Attribute $name of collection $col, has 2 dims but got dim2 = 0")
    end
    return
end

function get_parm(
    data::Data,
    col::String,
    name::String,
    index::Integer,
    ::Type{T};
    default::T = _default_value(T),
    dim1::Integer = 0,
    dim2::Integer = 0,
) where T

    attr_struct = get_attribute_struct(data, col, name)

    @assert dim1 >= 0
    @assert dim2 >= 0

    if dim2 > 0 && dim1 == 0
        error("Getting attribute $name of collection $col, got dim2 = $dims2 and dim1 = 0")
    end

    dim = attr_struct.dim

    _check_dim(attr_struct, col, name, dim1, dim2)
    _check_type(attr_struct, T, col, name)
    _check_parm(attr_struct, col, name)

    query_name = if dim == 0
        name
    elseif dim == 1
        name * "($dim1)"
    elseif dim == 2
        name * "($dim1,$dim2)"
    end

    n = max_elements(data, col)
    if n == 0
        return default
    end

    @assert 1 <= index <= n

    raw = _raw(data)

    element = raw[col][index]

    if haskey(element, query_name)
        return _cast(T, element[query_name], default)
    end
    return default
end

function get_parm_1d(
    data::Data,
    col::String,
    name::String,
    index::Integer,
    ::Type{T};
    default::T = _default_value(T),
) where T

    attr_struct = get_attribute_struct(data, col, name)

    @assert attr_struct.dim == 1

    _check_type(attr_struct, T, col, name)
    _check_parm(attr_struct, col, name)

    n_dim1 = get_attribute_dim1(data, col, name, index)

    n = max_elements(data, col)
    if n == 0
        error("Collection $col is empty")
    end
    @assert 1 <= index <= n

    raw = _raw(data)
    
    element = raw[col][index]

    out = Vector{T}(undef, n_dim1)

    for i in 1:n_dim1
        query_name = name * "($i)"
        if haskey(element, query_name)
            out[i] = _cast(T, element[query_name], default)
        else
            out[i] = default
        end
    end

    return out
end

function get_parm_2d(
    data::Data,
    col::String,
    name::String,
    index::Integer,
    ::Type{T};
    default::T = _default_value(T),
) where T

    attr_struct = get_attribute_struct(data, col, name)

    @assert attr_struct.dim == 2

    _check_type(attr_struct, T, col, name)
    _check_parm(attr_struct, col, name)

    n_dim1 = get_attribute_dim1(data, col, name, index)
    n_dim2 = get_attribute_dim2(data, col, name, index)

    n = max_elements(data, col)
    if n == 0
        error("Collection $col is empty")
    end
    @assert 1 <= index <= n

    raw = _raw(data)
    
    element = raw[col][index]

    out = Matrix{T}(undef, n_dim1, n_dim2)

    for i in 1:n_dim1, j in 1:n_dim2
        query_name = name * "($i,$j)"
        if haskey(element, query_name)
            out[i, j] = _cast(T, element[query_name], default)
        else
            out[i, j] = default
        end
    end

    return out
end

function get_parms(
    data::Data,
    col::String,
    name::String,
    ::Type{T};
    check_type::Bool = true,
    check_parm::Bool = true,
    ignore::Bool = false,
    default::T = _default_value(T),
) where T

    attr_struct = get_attribute_struct(data, col, name)
    if check_type
        _check_type(attr_struct, T, col, name)
    end
    if check_parm
        _check_parm(attr_struct, col, name)
    end

    n = max_elements(data, col)
    out = T[]
    sizehint!(out, n)
    for i in 1:n
        push!(out, get_parm(data, col, name, i, T; default = default))
    end
    return out
end

function get_parms_1d(
    data::Data,
    col::String,
    name::String,
    ::Type{T};
    check_type::Bool = true,
    check_parm::Bool = true,
    ignore::Bool = false,
    default::T = _default_value(T),
) where T

    attr_struct = get_attribute_struct(data, col, name)
    if check_type
        _check_type(attr_struct, T, col, name)
    end
    if check_parm
        _check_parm(attr_struct, col, name)
    end

    n = max_elements(data, col)
    out = Vector{T}[]
    sizehint!(out, n)
    for i in 1:n
        push!(out, get_parm_1d(data, col, name, i, T; default = default))
    end
    return out
end

function get_parms_2d(
    data::Data,
    col::String,
    name::String,
    ::Type{T};
    check_type::Bool = true,
    check_parm::Bool = true,
    ignore::Bool = false,
    default::T = _default_value(T),
) where T

    attr_struct = get_attribute_struct(data, col, name)
    if check_type
        _check_type(attr_struct, T, col, name)
    end
    if check_parm
        _check_parm(attr_struct, col, name)
    end

    n = max_elements(data, col)
    out = Matrix{T}[]
    sizehint!(out, n)
    for i in 1:n
        push!(out, get_parm_2d(data, col, name, i, T; default = default))
    end
    return out
end

function get_attribute_struct(data::Data, collection::String, attribute::String)
    collection_struct = data.data_struct[collection]
    # check attribute existence
    if !haskey(collection_struct, attribute)
        error("Attribute $attribute not found in collection $collection")
    end
    return collection_struct[attribute]
end

function get_attribute_dim1(
    data::Data,
    col::String,
    attribute::String,
    index::Integer;
    max_check::Integer = 100,
)
    attr_struct = get_attribute_struct(data, col, attribute)
    dim = attr_struct.dim
    if dim == 0
        error("Attribute $attribute from collection $col has no extra dimensions")
    end

    n = max_elements(data, col)
    @assert 1 <= index <= n

    raw = _raw(data)

    element = raw[col][index]

    for i in 1:max_check
        query_name = if dim == 1
            attribute * "($i)"
        elseif dim == 2
            attribute * "($i,1)"
        end
        if !haskey(element, query_name)
            return i - 1
        end
    end
    error("Attribute $attribute from collection $col has dim1 larger than $max_check")
    return 999
end

function get_attribute_dim2(
    data::Data,
    col::String,
    attribute::String,
    index::Integer;
    max_check::Integer = 100,
)
    attr_struct = get_attribute_struct(data, col, attribute)
    if attr_struct.dim < 2
        error("Attribute $attribute from collection $col has $(attr_struct.dim) < 2 dimensions")
    end

    n = max_elements(data, col)
    @assert 1 <= index <= n

    raw = _raw(data)

    element = raw[col][index]

    for i in 1:max_check
        query_name =  attribute * "(1,$i)"
        if !haskey(element, query_name)
            return i - 1
        end
    end
    error("Attribute $attribute from collection $col has dim2 larger than $max_check")
    return 999
end

function get_attributes(data::Data, collection::String)
    return sort(collect(keys(data.data_struct[collection])))
end

function get_collections(data::Data)
    return sort(collect(keys(data.data_struct)))
end

function get_relations(data::Data, collection::String)
    if haskey(_RELATIONS, collection)
        return keys(_RELATIONS[collection])
    end
    return Tuple{String, RelationType}[]
end

function get_code(
    data::Data,
    col::String
)
    return get_parms(data, col, "code", Int32)
end
function get_name(
    data::Data,
    col::String
)
    return get_parms(data, col, "name", String)
end

function description(data::Data)
    return ""
end
function total_stages(data::Data)
    _raw(data)["PSRStudy"][1]["NumeroEtapas"]
end
function total_scenarios(data::Data)
    # _raw(data)["PSRStudy"][1]["Series_Forward"]
    _raw(data)["PSRStudy"][1]["NumberSimulations"]
end
function total_openings(data::Data)
    _raw(data)["PSRStudy"][1]["NumberOpenings"]
end
function total_blocks(data::Data)
    _raw(data)["PSRStudy"][1]["NumberBlocks"]
end
function total_stages_per_year(data::Data)
    if data.stage_type == STAGE_MONTH
        return 12
    elseif data.stage_type == STAGE_WEEK
        return 52
    else
        error("Stage type $(data.stage_type) not currently supported")
    end
end

# TODO CEsp: many time does nto have the second dim

function get_nonempty_vector(
    data::Data,
    col::String,
    name::String,
)

    n = max_elements(data, col)
    if n == 0
        return Bool[]
    end

    out = zeros(Bool, n)

    attr_data = get_attribute_struct(data, col, name)

    _check_vector(attr_data, col, name)

    dim = attr_data.dim

    query_name = if dim == 0
        name
    elseif dim == 1
        name * "(1)"
    elseif dim == 2
        name * "(1,1)"
    end

    raw = _raw(data)

    for (idx, el) in enumerate(raw[col])
        if haskey(el, query_name)
            len = length(el[query_name])
            if (len == 1 && el[query_name][] !== nothing) || len > 1
                out[idx] = true
            end
        end
    end

    return out
end

function get_vector(
    data::Data,
    col::String,
    name::String,
    index::Integer,
    ::Type{T};
    dim1::Integer = 0,
    dim2::Integer = 0,
    default::T = _default_value(T),
) where T

    attr_struct = get_attribute_struct(data, col, name)

    _check_dim(attr_struct, col, name, dim1, dim2)
    _check_vector(attr_struct, col, name)
    _check_type(attr_struct, T, col, name)

    dim = attr_struct.dim

    query_name = if dim == 0
        name
    elseif dim == 1
        name * "($dim1)"
    elseif dim == 2
        name * "($dim1,$dim2)"
    end

    n = max_elements(data, col)
    if n == 0
        return T[]
    end

    @assert 1 <= index <= n

    raw = _raw(data)

    element = raw[col][index]

    if haskey(element, query_name)
        return _cast_vector(T, element[query_name], default)
    end
    return T[]
end

function get_vector_1d(
    data::Data,
    col::String,
    name::String,
    index::Integer,
    ::Type{T};
    default::T = _default_value(T),
) where T

    attr_struct = get_attribute_struct(data, col, name)

    @assert attr_struct.dim == 1

    _check_vector(attr_struct, col, name)
    _check_type(attr_struct, T, col, name)

    n_dim1 = get_attribute_dim1(data, col, name, index)

    n = max_elements(data, col)
    if n == 0
        error("Collection $col is empty")
    end
    @assert 1 <= index <= n

    raw = _raw(data)

    element = raw[col][index]

    out = Vector{Vector{T}}(undef, n_dim1)

    for i in 1:n_dim1
        query_name = name * "($i)"
        if haskey(element, query_name)
            out[i] = _cast_vector(T, element[query_name], default)
        else
            out[i] = T[]
        end
    end
    return out
end

function get_vector_2d(
    data::Data,
    col::String,
    name::String,
    index::Integer,
    ::Type{T};
    default::T = _default_value(T),
) where T

    attr_struct = get_attribute_struct(data, col, name)

    @assert attr_struct.dim == 2

    _check_vector(attr_struct, col, name)
    _check_type(attr_struct, T, col, name)

    n_dim2 = get_attribute_dim2(data, col, name, index)
    n_dim1 = get_attribute_dim1(data, col, name, index)

    n = max_elements(data, col)
    if n == 0
        error("Collection $col is empty")
    end
    @assert 1 <= index <= n

    raw = _raw(data)

    element = raw[col][index]

    out = Matrix{Vector{T}}(undef, n_dim1, n_dim2)

    for i in 1:n_dim1, j in 1:n_dim2
        query_name = name * "($i,$j)"
        if haskey(element, query_name)
            out[i, j] = _cast_vector(T, element[query_name], default)
        else
            out[i, j] = T[]
        end
    end
    return out
end

const _GET_DICT = Dict{String, Any}()
configuration_parameter(data::Data, name::String, default::Integer) =
    configuration_parameter(data, name, Int32(default))
function configuration_parameter(
    data::Data,
    name::String,
    default::T
) where T <: MainTypes
    if haskey(data.extra_config, name)
        val = dict[name]
        return _cast(T, val)
    end
    raw = _raw(data)
    study_data = raw["PSRStudy"][1]
    exec = get(study_data, "ExecutionParameters", _GET_DICT)
    chro = get(study_data, "ChronologicalData", _GET_DICT)
    hour = get(study_data, "HourlyData", _GET_DICT)
    if haskey(exec, name)
        pre_out = exec[name]
        return _cast(T, pre_out)
    elseif haskey(chro, name)
        pre_out = chro[name]
        return _cast(T, pre_out)
    elseif haskey(hour, name)
        pre_out = hour[name]
        return _cast(T, pre_out)
    end
    pre_out = get(study_data, name, default)
    out = _cast(T, pre_out)
    return out
end

function configuration_parameter(
    data::Data,
    name::String,
    default::Vector{T}
) where T <: MainTypes
    if haskey(data.extra_config, name)
        val = dict[name]
        return _cast.(T, val)
    end
    raw = _raw(data)
    study_data = raw["PSRStudy"][1]
    exec = get(study_data, "ExecutionParameters", _GET_DICT)
    chro = get(study_data, "ChronologicalData", _GET_DICT)
    hour = get(study_data, "HourlyData", _GET_DICT)
    if haskey(exec, name)
        pre_out = exec[name]
        return _cast.(T, pre_out)
    elseif haskey(chro, name)
        pre_out = chro[name]
        return _cast.(T, pre_out)
    elseif haskey(hour, name)
        pre_out = hour[name]
        return _cast.(T, pre_out)
    end
    pre_out = get(study_data, name, default)
    out = _cast.(T, pre_out)
    return out
end

"""
    _cast(::Type{T}, val, default::T = _default_value(T))

Converts `val` to type `T`, if possible.
"""
_cast(::Type{T}, val::T, default::T = _default_value(T)) where T = val
_cast(::Type{String}, val::String, default::String = _default_value(String)) = val
_cast(::Type{Int32}, val::Integer, default::Int32 = _default_value(Int32)) = Int32(val)
_cast(::Type{Float64}, val::Float64, default::Float64 = _default_value(Float64)) = val
_cast(::Type{Dates.Date}, val::Dates.Date, default::Dates.Date = _default_value(Dates.Date)) = val
function _cast(::Type{T}, val::String, default::T = _default_value(T)) where T
    return parse(T, val)
end
_cast(::Type{Int32}, val::Integer, default::Int32 = _default_value(Int32)) = Int32(val)
_cast(::Type{Dates.Date}, val::String, default::Dates.Date = _default_value(Dates.Date)) = _simple_date(val)

_cast(::Type{T}, val::Nothing, default::T = _default_value(T)) where T = default

"""
    _cast_vector(::Type{T}, vector, default::T = _default_value(T))

Converts `vector` to vector of type `T`, if possible.
"""
function _cast_vector(::Type{T}, vec::Vector{Any}, default::T = _default_value(T)) where T
    out = T[]
    for val in vec
        push!(out, _cast(T, val, default))
    end
    return out
end
_cast_vector(::Type{T}, vec::Vector{T}, default::T = _default_value(T)) where T = deepcopy(vec)