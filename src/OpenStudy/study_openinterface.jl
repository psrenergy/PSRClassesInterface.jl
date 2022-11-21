"""
    OpenInterface <: AbstractStudyInterface
"""
struct OpenInterface <: AbstractStudyInterface end

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
    default::T

    function VectorCache(
        dim1_str::Union{String,Nothing},
        dim2_str::Union{String,Nothing},
        dim1::Union{Integer,Nothing},
        dim2::Union{Integer,Nothing},
        index_str::String,
        stage::Integer,
        vector::Vector{T},
        default::T
    ) where {T}
        return new{T}(
            isnothing(dim1_str) ? "" : dim1_str,
            isnothing(dim2_str) ? "" : dim2_str,
            isnothing(dim1) ? 0 : dim1,
            isnothing(dim2) ? 0 : dim2,
            index_str,
            stage,
            vector,
            default,
        )
    end
end

# TODO: rebuild "raw" stabilizing data types
# TODO fuel consumption updater

mutable struct DataIndex
    # `index` takes a `reference_id` as key and returns a pair
    # containing the collection from which the referenced item
    # belongs but also its index in the vector of instances of
    # the collection.
    index::Dict{Int,Tuple{String,Int}}

    # This should be equal to `Set{Int}(keys(data_index.index))`
    key_set::Set{Int}    

    # This is defined as the greatest `reference_id` indexed so
    # far, that is, `maximum(data_index.key_set)`.
    max_id::Int

    function DataIndex()
        new(
            Dict{Int,Tuple{String,Int}}(),
            Set{Int}(),
            0,
        )
    end
end

function _get_index(data_index::DataIndex, reference_id::Integer)
    if !haskey(data_index.index, reference_id)
        error("Invalid reference_id '$reference_id'")
    end

    return data_index.index[reference_id]
end

function _set_index!(data_index::DataIndex, reference_id::Integer, collection::String, index::Integer)
    if reference_id ∈ data_index.key_set
        previous_collection, _ = _get_index(data_index, reference_id)

        @warn """
        Replacing reference_id = '$reference_id' from '$previous_collection' to '$collection'
        """
    else
        data_index.max_id = max(data_index.max_id, reference_id)
        push!(data_index.key_set, reference_id)
    end

    data_index.index[reference_id] = (collection, index)

    return nothing
end

function _generate_reference_id(data_index::DataIndex)
    @assert data_index.max_id < typemax(Int)

    return data_index.max_id + 1
end

Base.@kwdef mutable struct Data{T} <: AbstractData
    raw::T
    stage_type::StageType

    data_path::String

    duration_mode::BlockDurationMode = FIXED_DURATION
    number_blocks::Int = 1

    # for variable duration and for hour block map
    variable_duration::Union{Nothing,OpenBinary.Reader} = nothing
    hour_to_block::Union{Nothing,OpenBinary.Reader} = nothing

    first_year::Int
    first_stage::Int #maybe week or month, day...
    first_date::Dates.Date

    data_struct::Dict{String,Dict{String,Attribute}}
    validate_attributes::Bool
    model_files_added::Set{String}

    log_file::Union{IOStream,Nothing}
    verbose::Bool

    # main time controller
    controller_stage::Int = 1
    controller_stage_changed::Bool = false
    controller_date::Dates.Date
    controller_dim::Dict{String,Int} = Dict{String,Int}()

    # cache to only in data reference once (per element)
    map_cache_data_idx::Dict{String,Dict{String,Vector{Int32}}} =
        Dict{String,Dict{String,Vector{Int32}}}()
    # vectors returned to user
    map_cache_real::Dict{String,Dict{String,VectorCache{Float64}}} =
        Dict{String,Dict{String,VectorCache{Float64}}}()
    map_cache_integer::Dict{String,Dict{String,VectorCache{Int32}}} =
        Dict{String,Dict{String,VectorCache{Int32}}}()
    map_cache_date::Dict{String,Dict{String,VectorCache{Dates.Date}}} =
        Dict{String,Dict{String,VectorCache{Dates.Date}}}()

    map_filter_real::Dict{String,Vector{Tuple{String,String}}} =
        Dict{String,Vector{Tuple{String,String}}}()
    map_filter_integer::Dict{String,Vector{Tuple{String,String}}} =
        Dict{String,Vector{Tuple{String,String}}}()

    extra_config::Dict{String,Any} = Dict{String,Any}()

    # TODO: cache importante data

    # Reference Indexing
    data_index::DataIndex = DataIndex()
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

function _merge_psr_transformer_and_psr_serie!(data::Data)
    raw = _raw(data)

    if haskey(raw, "PSRSerie") && haskey(raw, "PSRTransformer")
        append!(raw["PSRSerie"], raw["PSRTransformer"])
        delete!(raw, "PSRTransformer")
    elseif haskey(raw, "PSRTransformer")
        raw["PSRSerie"] = raw["PSRTransformer"]
        delete!(raw, "PSRTransformer")
    end
    
    return nothing
end

function initialize_study(
    ::OpenInterface;
    data_path = "",
    pmd_files = String[],
    path_pmds = PMD._PMDS_BASE_PATH,
    log_file = "",
    verbose = true,
    extra_config_file::String = "",
    validate_attributes::Bool = true,
    _netplan_database::Bool = false,
    model_class_map = PMD._MODEL_TO_CLASS_SDDP,
    #merge collections
    add_transformers_to_series::Bool = true,
)
    if !isdir(data_path)
        error("$data_path is not a valid directory")
    end
    PATH_JSON = joinpath(data_path, "psrclasses.json")
    if !isfile(PATH_JSON)
        error("$PATH_JSON not found")
    end

    file = if !isempty(log_file)
        Base.open(file, "w")
    else
        nothing
    end

    raw = JSON.parsefile(PATH_JSON)

    study_data = raw["PSRStudy"][1]

    stage_type = StageType(study_data["Tipo_Etapa"])
    first_year = study_data["Ano_inicial"]
    first_stage = study_data["Etapa_inicial"]
    first_date =
        Dates.Date(first_year, 1, 1) + ifelse(
            stage_type == STAGE_MONTH,
            Dates.Month(first_stage - 1),
            Dates.Week(first_stage - 1),
        )
    # TODO daily study

    if _netplan_database
        model_class_map = PMD._MODEL_TO_CLASS_NETPLAN
    end
    data_struct, model_files_added = PMD.load_model(path_pmds, pmd_files, model_class_map)
    if isempty(model_files_added)
        error("No Model definition (.pmd) file found")
    end

    number_blocks = study_data["NumeroBlocosDemanda"]
    @assert number_blocks == study_data["NumberBlocks"]

    duration_mode =
        if haskey(study_data, "HourlyData") && study_data["HourlyData"]["BMAP"] in [1, 2]
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
        validate_attributes = validate_attributes,
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
    if add_transformers_to_series
        _merge_psr_transformer_and_psr_serie!(data)
    end

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

    # Assigns to every `reference_id` the corresponding instance index
    # as a pair (collection, index)
    _build_index!(data)

    return data
end

function max_elements(data::Data, collection::String)
    raw = _raw(data)
    
    if haskey(raw, collection)
        return length(raw[collection])
    else
        return 0
    end
end

_default_value(::Type{T}) where {T<:Number} = zero(T)
_default_value(::Type{String}) = ""
_default_value(::Type{Dates.Date}) = Dates.Date(1900, 1, 1)

function get_attribute_dim(attribute_struct::Attribute)
    return attribute_struct.dim
end

function _get_attribute_key(
    attribute::String,
    dim::Integer,
    fix::Pair{<:Integer,<:Union{Integer,Nothing}}...,
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

function get_parm(
    data::Data,
    collection::String,
    attribute::String,
    index::Integer,
    ::Type{T};
    default::T = _default_value(T),
    dim1::Union{Integer,Nothing} = nothing,
    dim2::Union{Integer,Nothing} = nothing,
) where {T}
    # Retrieve attribute metadata
    attribute_struct = get_attribute_struct(data, collection, attribute)

    # Basic checks
    _check_dim(attribute_struct, collection, attribute, dim1, dim2)
    _check_type(attribute_struct, T, collection, attribute)
    _check_parm(attribute_struct, collection, attribute)
    _check_element_range(data, collection, index)

    # This is assumed to be a mutable dictionary
    element = _get_element(data, collection, index)

    # Format according to dimension
    dim = get_attribute_dim(attribute_struct)
    key = _get_attribute_key(attribute, dim, 1 => dim1, 2 => dim2)

    # Here, a choice is made to return a default
    # value if there is no entry for a given key
    # in the element.
    if haskey(element, key)
        return _cast(T, element[key], default)
    else
        return default
    end
end

function get_parm_1d(
    data::Data,
    collection::String,
    attribute::String,
    index::Integer,
    ::Type{T};
    default::T = _default_value(T),
) where {T}
    attribute_struct = get_attribute_struct(data, collection, attribute)

    dim = get_attribute_dim(attribute_struct)

    if dim != 1
        if dim == 0
            error("""
                  Attribute '$attribute' from collection '$colllection' has no dimensions.
                  Consider using `get_parm` instead.
                  """)
        else
            error(
                """
                Attribute '$attribute' from collection '$colllection' has $(attribute_struct.dim) dimensions.
                Consider using `get_parm_$(attribute_struct.dim)d` instead.
                """,
            )
        end
    end

    _check_type(attribute_struct, T, collection, attribute)
    _check_parm(attribute_struct, collection, attribute)
    _check_element_range(data, collection, index)

    dim1 = get_attribute_dim1(data, collection, attribute, index)

    element = _get_element(data, collection, index)

    out = Vector{T}(undef, dim1)

    for i in 1:dim1
        key = _get_attribute_key(attribute, 1, 1 => i)

        out[i] = if haskey(element, key)
            _cast(T, element[key], default)
        else
            default
        end
    end

    return out
end

function get_parm_2d(
    data::Data,
    collection::String,
    attribute::String,
    index::Integer,
    ::Type{T};
    default::T = _default_value(T),
) where {T}
    attribute_struct = get_attribute_struct(data, collection, attribute)

    dim = get_attribute_dim(attribute_struct)

    if dim != 2
        if dim == 0
            error("""
                  Attribute '$attribute' from collection '$colllection' has no dimensions.
                  Consider using `get_parm` instead.
                  """)
        else
            error(
                """
                Attribute '$attribute' from collection '$colllection' has $(dim) dimensions.
                Consider using `get_parm_$(dim)d` instead.
                """,
            )
        end
    end

    _check_type(attribute_struct, T, collection, attribute)
    _check_parm(attribute_struct, collection, attribute)
    _check_element_range(data, collection, index)

    dim1 = get_attribute_dim1(data, collection, attribute, index)
    dim2 = get_attribute_dim2(data, collection, attribute, index)

    element = _get_element(data, collection, index)

    out = Matrix{T}(undef, dim1, dim2)

    for i in 1:dim1, j in 1:dim2
        key = _get_attribute_key(attribute, dim, 1 => i, 2 => j)

        out[i, j] = if haskey(element, key)
            _cast(T, element[key], default)
        else
            default
        end
    end

    return out
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
    attribute_struct = get_attribute_struct(data, collection, attribute)

    dim = get_attribute_dim(attribute_struct)

    if dim == 0
        error("Attribute '$attribute' from collection '$collection' has no dimensions")
    end

    _check_element_range(data, collection, index)

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

function get_attribute_dim1(
    data::Data,
    collection::String,
    attribute::String,
    index::Integer,
)
    return _get_attribute_axis_dim(data, collection, attribute, 1, index)
end

function get_attribute_dim2(
    data::Data,
    collection::String,
    attribute::String,
    index::Integer,
)
    return _get_attribute_axis_dim(data, collection, attribute, 2, index)
end

function description(::Data)
    return ""
end

function total_stages(data::Data)
    return _raw(data)["PSRStudy"][1]["NumeroEtapas"]
end

function total_scenarios(data::Data)
    # _raw(data)["PSRStudy"][1]["Series_Forward"]
    return _raw(data)["PSRStudy"][1]["NumberSimulations"]
end

function total_openings(data::Data)
    return _raw(data)["PSRStudy"][1]["NumberOpenings"]
end

function total_blocks(data::Data)
    return _raw(data)["PSRStudy"][1]["NumberBlocks"]
end

function total_stages_per_year(data::Data)
    if data.stage_type == STAGE_MONTH
        return 12
    elseif data.stage_type == STAGE_WEEK
        return 52
    else
        error("Stage type '$(data.stage_type)' is not currently supported")
    end
end

# TODO CEsp: many time does nto have the second dim

function get_nonempty_vector(data::Data, collection::String, attribute::String)
    n = max_elements(data, collection)

    if n == 0
        return Bool[]
    end

    out = zeros(Bool, n)

    attr_data = get_attribute_struct(data, collection, attribute)

    _check_vector(attr_data, collection, attribute)

    dim = attr_data.dim
    key = _get_attribute_key(attribute, dim)

    for (idx, el) in enumerate(_get_elements(data, collection))
        if haskey(el, key)
            len = length(el[key])
            if (len == 1 && el[key][] !== nothing) || len > 1
                out[idx] = true
            end
        end
    end

    return out
end

function get_vector(
    data::Data,
    collection::String,
    attribute::String,
    index::Integer,
    ::Type{T};
    dim1::Union{Integer,Nothing} = nothing,
    dim2::Union{Integer,Nothing} = nothing,
    default::T = _default_value(T),
) where {T}
    attribute_struct = get_attribute_struct(data, collection, attribute)

    _check_dim(attribute_struct, collection, attribute, dim1, dim2)
    _check_vector(attribute_struct, collection, attribute)
    _check_type(attribute_struct, T, collection, attribute)
    _check_element_range(data, collection, index)

    dim = get_attribute_dim(attribute_struct)
    key = _get_attribute_key(attribute, dim, 1 => dim1, 2 => dim2)

    element = _get_element(data, collection, index)

    if haskey(element, key)
        return _cast_vector(T, element[key], default)
    else
        return T[]
    end
end

function get_vector_1d(
    data::Data,
    collection::String,
    attribute::String,
    index::Integer,
    ::Type{T};
    default::T = _default_value(T),
) where {T}
    attribute_struct = get_attribute_struct(data, collection, attribute)

    dim = get_attribute_dim(attribute_struct)

    if dim != 1
        if dim == 0
            error("""
                  Attribute '$attribute' from collection '$colllection' has no dimensions.
                  Consider using `get_parm` instead.
                  """)
        else
            error(
                """
                Attribute '$attribute' from collection '$colllection' has $(dim) dimensions.
                Consider using `get_parm_$(dim)d` instead.
                """,
            )
        end
    end

    _check_vector(attribute_struct, collection, attribute)
    _check_type(attribute_struct, T, collection, attribute)
    _check_element_range(data, collection, index)

    dim1 = get_attribute_dim1(data, collection, attribute, index)

    element = _get_element(data, collection, index)

    out = Vector{Vector{T}}(undef, dim1)

    for i in 1:dim1
        key = _get_attribute_key(attribute, dim, 1 => i)

        out[i] = if haskey(element, key)
            _cast_vector(T, element[key], default)
        else
            T[]
        end
    end

    return out
end

function get_vector_2d(
    data::Data,
    collection::String,
    attribute::String,
    index::Integer,
    ::Type{T};
    default::T = _default_value(T),
) where {T}
    attribute_struct = get_attribute_struct(data, collection, attribute)

    dim = get_attribute_dim(attribute_struct)

    if dim != 2
        if dim == 0
            error("""
                  Attribute '$attribute' from collection '$colllection' has no dimensions.
                  Consider using `get_parm` instead.
                  """)
        else
            error(
                """
                Attribute '$attribute' from collection '$collection' has $(dim) dimensions.
                Consider using `get_parm_$(dim)d` instead.
                """,
            )
        end
    end

    _check_vector(attribute_struct, collection, attribute)
    _check_type(attribute_struct, T, collection, attribute)
    _check_element_range(data, collection, index)

    dim1 = get_attribute_dim1(data, collection, attribute, index)
    dim2 = get_attribute_dim2(data, collection, attribute, index)

    element = _get_element(data, collection, index)

    out = Matrix{Vector{T}}(undef, dim1, dim2)

    for i in 1:dim1, j in 1:dim2
        key = _get_attribute_key(attribute, dim, 1 => i, 2 => j)

        out[i, j] = if haskey(element, key)
            _cast_vector(T, element[key], default)
        else
            T[]
        end
    end

    return out
end

const _GET_DICT = Dict{String,Any}()

function configuration_parameter(data::Data, parameter::String, default::Integer)
    return configuration_parameter(data, parameter, Int32(default))
end

function configuration_parameter(
    data::Data,
    parameter::String,
    default::T,
) where {T<:MainTypes}
    if haskey(data.extra_config, parameter)
        return _cast(T, data.extra_config[parameter])
    end

    raw_data = _raw(data)
    study_data = raw_data["PSRStudy"][begin]

    for key in ["ExecutionParameters", "ChronologicalData", "HourlyData"]
        data = get(study_data, key, _GET_DICT)
        if haskey(data, parameter)
            return _cast(T, data[parameter])
        end
    end

    return _cast(T, get(study_data, parameter, default))
end

function configuration_parameter(
    data::Data,
    parameter::String,
    default::Vector{T},
) where {T<:MainTypes}
    if haskey(data.extra_config, parameter)
        return _cast.(T, data.extra_config[parameter])
    end

    raw_data = _raw(data)
    study_data = raw_data["PSRStudy"][begin]

    for key in ["ExecutionParameters", "ChronologicalData", "HourlyData"]
        data = get(study_data, key, _GET_DICT)
        if haskey(data, parameter)
            return _cast.(T, data[parameter])
        end
    end

    return _cast.(T, get(study_data, parameter, default))
end

"""
    _cast(::Type{T}, val, default::T = _default_value(T))

Converts `val` to type `T`, if possible.
"""
_cast(::Type{T}, val::T, default::T = _default_value(T)) where {T} = val
_cast(::Type{String}, val::String, default::String = _default_value(String)) = val
_cast(::Type{Int32}, val::Integer, default::Int32 = _default_value(Int32)) = Int32(val)
_cast(::Type{Float64}, val::Real, default::Float64 = _default_value(Float64)) = val
_cast(::Type{T}, val::Nothing, default::T = _default_value(T)) where {T} = default

function _cast(
    ::Type{Dates.Date},
    val::Dates.Date,
    default::Dates.Date = _default_value(Dates.Date),
)
    return val
end

function _cast(::Type{T}, val::String, default::T = _default_value(T)) where {T}
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
    _cast_vector(::Type{T}, vector, default::T = _default_value(T))

Converts `vector` to vector of type `T`, if possible.
"""
function _cast_vector(
    ::Type{T},
    vector::Vector{<:Any},
    default::T = _default_value(T),
) where {T}
    out = Vector{T}(undef, length(vector))

    for i in eachindex(vector)
        out[i] = _cast(T, vector[i], default)
    end

    return out
end

function _cast_vector(::Type{T}, vector::Vector{T}, default::T = _default_value(T)) where {T}
    return deepcopy(vector)
end