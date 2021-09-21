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

Base.@kwdef mutable struct Data{T}
    raw::T
    stage_type::StageType

    first_year::Int
    first_stage::Int #maybe week or month
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
    # vectors returned tu user
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

# Parse pmd accoring to OpenInterface structs

function _parse_pmd!(data_struct, FILE)
    # PSRThermalPlant => GerMax => Attr
    @assert FILE[end-3:end] == ".pmd"
    if !isfile(FILE)
        error("File not found: $FILE")
    end
    inside_model = false
    current_class = ""
    for line in readlines(FILE)
        clean_line = strip(replace(line, '\t' => ' '))
        if startswith(clean_line ,"//") || isempty(clean_line)
            continue
        end
        if inside_model
            if startswith(clean_line ,"END_MODEL")
                inside_model = false
                current_class = ""
                continue
            end
            words = split(clean_line)
            if length(words) >= 3
                if words[1] == "PARM" || words[1] == "VECTOR" || words[1] == "VETOR"
                    # _is_vector(words[1])
                    # _get_type(words[2])
                    name = words[3]
                    dim = 0
                    index = ""
                    interval = "" # TODO: parse "INTERVAL"
                    if length(words) >= 4
                        if startswith(words[4], "DIM") # assume no space inside DIM
                            dim = length(split(words[4], ','))
                        end
                        if startswith(words[4], "INDEX")
                            if length(words) >= 5
                                index = words[5]
                            else
                                error("no index after INDEX key at $name in $current_class")
                            end
                        end
                    end
                    if length(words) >= 5
                        if startswith(words[5], "INDEX")
                            if length(words) >= 6
                                index = words[6]
                            else
                                error("no index after INDEX key at $name in $current_class")
                            end
                        end
                    end
                    data_struct[current_class][name] = Attribute(
                        name,
                        PMD._is_vector(words[1]),
                        PMD._get_type(words[2]),
                        dim,
                        index,
                        # interval,
                    )
                end
            end
        else
            BEGIN = "DEFINE_MODEL MODL:"
            if startswith(clean_line, BEGIN)
                clean_line
                model_name = strip(clean_line[(length(BEGIN)+1):end])
                if haskey(PMD._MODEL_TO_CLASS, model_name)
                    current_class = PMD._MODEL_TO_CLASS[model_name]
                    inside_model = true
                    data_struct[current_class] = Dict{String, Attribute}()
                    continue
                end
            end
        end
    end
    return data_struct
end

function _load_mask_or_model(path_pmds, data_struct, files, FILES_ADDED)
    str = "Model"
    ext = "pmd"
    if !isempty(files)
        for file in files
            if !isfile(file)
                error("$str $file not found")
            end
            name = basename(file)
            if splitext(name)[2] != ".$ext"
                error("$str $file should contain a .$ext extension")
            end
            if !in(name, FILES_ADDED)
                _parse_pmd!(data_struct, file)
                push!(FILES_ADDED, name)
            end
        end
    else
        names = readdir(path_pmds)
        # names should be basename'd
        for name in names
            if splitext(name)[2] == ".$ext"
                if !in(name, FILES_ADDED)
                    file = joinpath(path_pmds, name)
                    _parse_pmd!(data_struct, file)
                    push!(FILES_ADDED, name)
                end
            end
        end
    end
    return nothing
end

_raw(data::Data) = data.raw

function _simple_data(str::String)

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
    if date < _simple_data(vec[1])
        # error("date before first element")
        return 1
    end
    for i in 1:(length(vec)-1)
        if _simple_data(vec[i]) <= date < _simple_data(vec[i+1])
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

    data_struct = Dict{String, Dict{String, Attribute}}()
    model_files_added = Set{String}()
    _load_mask_or_model(path_pmds, data_struct, files, model_files_added)
    if isempty(model_files_added)
        error("No Model definition (.pmd) file found")
    end

    data = Data(
        raw = raw,
        data_struct = data_struct,
        model_files_added = model_files_added,
        stage_type = stage_type,
        first_year = first_year,
        first_stage = first_stage,
        first_date = first_date,
        controller_date = first_date,

        log_file = file,
        verbose = verbose,
    )

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
    else
        return 0
    end
end

_default_value(::Type{T}) where T = zero(T)
_default_value(::Type{String}) = ""
_default_value(::Type{Dates.Date}) = Dates.Date(1900, 1, 1)
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
    raw = _raw(data)

    n = max_elements(data, col)
    if n == 0
        return T[]
    end

    if check_type
        if name == "name" || name == "AVId" # TODO? protect spelling
            @assert String == T
        elseif name == "code"
            @assert Int32 == T
        else
            @assert !data.data_struct[col][name].type == T
        end
    end
    if check_parm && !(name in ["name", "code", "AVId"])
        @assert !data.data_struct[col][name].is_vector
    end

    out = T[default for _ in 1:n]

    for (idx, el) in enumerate(raw[col])
        if !haskey(el, name)
            error("Attribute $name not found in collection $col")
        end
        out[idx] = el[name] #::T # assert type
    end

    return out
end

function get_code(
    data::Data,
    col::String
)
    get_parms(data, col, "code", Int32)
end
function get_name(
    data::Data,
    col::String;
    strlen = 12
)
    get_parms(data, col, "name", String)
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
    data.stage_type == STAGE_MONTH ? 12 : 52
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

# TODO CEsp: many time does nto have the second dim

function mapped_vector(
    data::Data,
    col::String,
    name::String,
    ::Type{T},
    dim1::String="",
    dim2::String="";
    ignore::Bool=false,
    map_key = col, # reference for PSRMap pointer, if empty use class name
    filters = String[], # for calling just within a subset instead of the full call
) where T #<: Union{Float64, Int32}

    raw = _raw(data)

    n = max_elements(data, col)
    if n == 0
        return T[]
    end

    collection_struct = data.data_struct[col]

    # check attribute existence
    if !haskey(collection_struct, name)
        error("Attribute $name not found in collection $col")
    end
    attr_data = collection_struct[name]

    # validate type and shape
    @assert attr_data.type == T
    @assert attr_data.is_vector

    # validate dimensions
    dim = attr_data.dim
    if isempty(dim1) && !isempty(dim2)
        error("Got dim1 empty, but dim2 = $dim2")
    end
    if dim == 0 && !isempty(dim1)
        error("Got dim1 = $dim1 but attribute $name is no dimensioned")
    end
    if dim >= 1 && isempty(dim1)
        error("Got dim1 empty but attribute $name has $dim dimension(s)")
    end
    if dim == 1 && !isempty(dim2)
        error("Got dim2 = $dim2 but attribute $name has a single dimension")
    end

    dim1_val = _add_get_dim_val(data, dim1)
    dim2_val = _add_get_dim_val(data, dim2)

    total_dim = dim1_val + dim2_val
    if total_dim != dim
        error("Dimension mismatch, data structure should have $(total_dim) but has $dim in the data file")
    end

    index = attr_data.index
    stage = data.controller_stage

    cache = _get_cache(data, T)

    col_cache = get!(cache, col, Dict{String, VectorCache{T}}())

    if haskey(col_cache, name)
        error("Attribute $name was already mapped.")
    end

    out = T[_default_value(T) for _ in 1:n] #zeros(T, n)
    
    date_cache = get!(data.map_cache_data_idx, col, Dict{String, Vector{Int32}}())
    
    need_up_dates = false
    if isempty(index)
        error("Vector Attribute is not indexed, cannot be mapped")
    end
    date_ref = if haskey(date_cache, index)
        need_up_dates = false
        date_cache[index]
    else
        need_up_dates = true
        vec = zeros(Int32, n)
        date_cache[index] = vec
        vec
    end

    vec_cache = VectorCache(
        dim1, dim2, dim1_val, dim2_val, index, stage, out)#, date_ref)
    col_cache[name] = vec_cache

    if need_up_dates
        _update_dates!(data, raw[col], date_ref, index)
    end
    _update_vector!(data, raw[col], date_ref, vec_cache, name)

    _add_filter(data, map_key, col, name, T)
    for f in filters
        _add_filter(data, f, col, name, T)
    end

    return out
end

function _update_dates!(data::Data, collection, date_ref::Vector{Int32}, index::String)
    current = data.controller_date
    for (idx, el) in enumerate(collection)
        date_ref[idx] = _findfirst_date(current, el[index])
    end
    return nothing
end

function _update_vector!(
    data::Data,
    collection,
    date_ref::Vector{Int32},
    cache::VectorCache{T},
    attr::String
) where T
    if !isempty(cache.dim1_str)
        cache.dim1 = data.controller_dim[cache.dim1_str]
        if !isempty(cache.dim2_str)
            cache.dim2 = data.controller_dim[cache.dim2_str]
        end
    end
    cache.stage = data.controller_stage
    query_name = _build_name(attr, cache)
    for (idx, el) in enumerate(collection)
        cache.vector[idx] = el[query_name][date_ref[idx]]
    end
    return nothing
end

function _get_cache(data, ::Type{Float64})
    return data.map_cache_real
end
function _get_cache(data, ::Type{Int32})
    return data.map_cache_integer
end
function _get_cache(data, ::Type{Dates.Date})
    return data.map_cache_date
end

function _add_get_dim_val(data, dim1)
    dim1_val = 0
    if !isempty(dim1)
        if !haskey(data.controller_dim, dim1)
            data.controller_dim[dim1] = 1
            dim1_val = 1
        else
            dim1_val = data.controller_dim[dim1]
        end
    end
    return dim1_val
end

function go_to_stage(data::Data, stage::Integer)
    if data.controller_stage != stage
        data.controller_stage_changed = true
    end
    data.controller_stage = stage
    data.controller_date = _date_from_stage(data, stage)
    return nothing
end

function go_to_dimension(data::Data, str::String, val::Integer)
    if haskey(data.controller_dim, str)
        data.controller_dim[str] = val
    else
        error("Dimension $str was not created.")
    end
    return nothing
end

function update_vectors!(data::Data)

    _update_all_dates!(data)

    _update_all_vectors!(data, data.map_cache_real)
    _update_all_vectors!(data, data.map_cache_integer)
    _update_all_vectors!(data, data.map_cache_date)

    return nothing
end

function update_vectors!(data::Data, filter::String)

    # TODO improve this witha a DataCache
    _update_all_dates!(data)

    raw = _raw(data)
    no_attr = false
    if haskey(data.map_filter_real, filter)
        for (col_name, attr) in data.map_filter_real[filter]
            vec_cache = data.map_cache_real[col_name][attr]
            collection = raw[col_name]
            col_dates = data.map_cache_data_idx[col_name]
            if _need_update(data, vec_cache)
                date_ref = col_dates[vec_cache.index_str]
                _update_vector!(data, collection, date_ref, vec_cache, attr)
            end
        end
    else
        no_attr = true
    end
    if haskey(data.map_filter_integer, filter)
        for (col_name, attr) in data.map_filter_integer[filter]
            vec_cache = data.map_cache_integer[col_name][attr]
            collection = raw[col_name]
            col_dates = data.map_cache_data_idx[col_name]
            if _need_update(data, vec_cache)
                date_ref = col_dates[vec_cache.index_str]
                _update_vector!(data, collection, date_ref, vec_cache, attr)
            end
        end
    elseif no_attr
        error("Filter $filter not valid")
    end

    return nothing
end

function update_vectors!(data::Data, filters::Vector{String})
    for f in filters
        update_vectors!(data, f)
    end
    return nothing
end

function _update_all_dates!(data::Data)
    raw = _raw(data)
    # update reference vectors
    if data.controller_stage_changed
        for (col_name, dict) in data.map_cache_data_idx
            collection = raw[col_name]
            for (index, vec) in dict
                _update_dates!(data, collection, vec, index)
            end
        end
    end
    data.controller_stage_changed = false
    return nothing
end

function _update_all_vectors!(data::Data, map_cache)
    raw = _raw(data)
    for (col_name, dict) in map_cache
        collection = raw[col_name]
        col_dates = data.map_cache_data_idx[col_name]
        for (attr, vec_cache) in dict
            if _need_update(data, vec_cache)
                date_ref = col_dates[vec_cache.index_str]
                _update_vector!(data, collection, date_ref, vec_cache, attr)
            end
        end
    end
    return nothing
end
function _build_name(name, cache) where T<:Integer
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

const _get_dict = Dict{String, Any}()
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
    exec = get(study_data, "ExecutionParameters", _get_dict)
    chro = get(study_data, "ChronologicalData", _get_dict)
    hour = get(study_data, "HourlyData", _get_dict)
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

_cast(::Type{T}, val::T) where T = val
function _cast(::Type{T}, val::String) where T
    return parse(T, val)
end
_cast(::Type{Int32}, val::Integer) = Int32(val)