function PSRI.create_study(
    ::OpenInterface;
    data_path::AbstractString = pwd(),
    pmd_files::Vector{String} = String[],
    pmds_path::AbstractString = PSRI.PMD._PMDS_BASE_PATH,
    defaults_path::Union{AbstractString, Nothing} = PSRI.PSRCLASSES_DEFAULTS_PATH,
    defaults::Union{Dict{String, Any}, Nothing} = PSRI._load_defaults!(),
    netplan::Bool = false,
    model_template_path::Union{String, Nothing} = nothing,
    relations_defaults_path = PSRI.PMD._DEFAULT_RELATIONS_PATH,
    study_collection::String = "PSRStudy",
    verbose::Bool = false,
)
    if !isdir(data_path)
        error("data_path = '$data_path' must be a directory")
    end

    if isnothing(defaults)
        defaults = Dict{String, Any}()
    end

    study_defaults = Dict{String, Any}()

    if !isnothing(defaults_path)
        merge!(study_defaults, JSON.parsefile(defaults_path))
        PSRI.merge_defaults!(study_defaults, defaults)
    end

    # Select mapping
    model_template = PSRI.PMD.ModelTemplate()

    if isnothing(model_template_path)
        if netplan
            PSRI.PMD.load_model_template!(
                joinpath(PSRI.JSON_METADATA_PATH, "modeltemplates.netplan.json"),
                model_template,
            )
        else
            PSRI.PMD.load_model_template!(
                joinpath(PSRI.JSON_METADATA_PATH, "modeltemplates.sddp.json"),
                model_template,
            )
        end
    else
        PSRI.PMD.load_model_template!(model_template_path, model_template)
    end

    relation_mapper = PSRI.PMD.RelationMapper()

    PSRI.PMD.load_relations_struct!(relations_defaults_path, relation_mapper)

    data_struct, model_files_added =
        PSRI.PMD.load_model(pmds_path, pmd_files, model_template, relation_mapper; verbose)

    stage_type =
        if haskey(study_defaults[study_collection], "Tipo_Etapa")
            PSRI.StageType(study_defaults[study_collection]["Tipo_Etapa"])
        else
            if verbose
                @warn "Study collection does not have a stage type ('Tipo_Etapa'). Using default value 'PSRI.STAGE_WEEK'"
            end
            PSRI.STAGE_WEEK
        end

    first_year =
        if haskey(study_defaults[study_collection], "Ano_inicial")
            study_defaults[study_collection]["Ano_inicial"]
        else
            if verbose
                @warn "Study collection does not have an inital year ('Ano_inicial'). Using default value '2023'"
            end
            2023
        end

    first_stage = if haskey(study_defaults[study_collection], "Etapa_inicial")
        study_defaults[study_collection]["Etapa_inicial"]
    else
        if verbose
            @warn "Study collection does not have a first stage ('Etapa_inicial'). Using default value '1'"
        end
        1
    end

    first_date =
        if stage_type == PSRI.STAGE_MONTH
            Dates.Date(first_year, 1, 1) + Dates.Month(first_stage - 1)
        else
            Dates.Date(first_year, 1, 1) + Dates.Week(first_stage - 1)
        end

    duration_mode =
        if haskey(study_defaults[study_collection], "HourlyData") &&
           study_defaults[study_collection]["HourlyData"]["BMAP"] in [1, 2]
            PSRI.HOUR_BLOCK_MAP
        elseif (
            haskey(study_defaults[study_collection], "DurationModel") &&
            haskey(
                study_defaults[study_collection]["DurationModel"],
                "Duracao($number_blocks)",
            )
        )
            PSRI.VARIABLE_DURATION
        else
            PSRI.FIXED_DURATION
        end

    data = Data(;
        raw = Dict{String, Any}(),
        data_path = data_path,
        data_struct = data_struct,
        validate_attributes = false,
        model_files_added = model_files_added,
        stage_type = stage_type,
        first_year = first_year,
        first_stage = first_stage,
        first_date = first_date,
        controller_date = first_date,
        duration_mode = duration_mode,
        number_blocks = 1,
        log_file = nothing,
        verbose = true,
        model_template = model_template,
        relation_mapper = relation_mapper,
    )

    _create_study_collection(data, study_collection, study_defaults)

    return data
end

function PSRI.load_study(
    ::OpenInterface;
    data_path = "",
    pmd_files = String[],
    path_pmds = PSRI.PMD._PMDS_BASE_PATH,
    rectify_json_data::Bool = false,
    log_file::Union{AbstractString, Nothing} = nothing,
    verbose = true,
    extra_config_file::String = "",
    validate_attributes::Bool = true,
    _netplan_database::Bool = false,
    model_template_path::Union{String, Nothing} = nothing,
    relations_defaults_path = PSRI.PMD._DEFAULT_RELATIONS_PATH,
    #merge collections
    add_transformers_to_series::Bool = true,
    #json api 
    json_struct_path::Union{Nothing, Vector{String}, String} = nothing,
    # Alternative Study Collection
    study_collection::String = "PSRStudy",
)
    if !isdir(data_path)
        error("$data_path is not a valid directory")
    end

    PATH_JSON = joinpath(data_path, "psrclasses.json")

    if !isfile(PATH_JSON)
        error("$PATH_JSON not found")
    end

    if !isnothing(log_file)
        log_file = Base.open(log_file, "w")
    end

    model_template = PSRI.PMD.ModelTemplate()

    if isnothing(model_template_path)
        if _netplan_database
            PSRI.PMD.load_model_template!(
                joinpath(PSRI.JSON_METADATA_PATH, "modeltemplates.netplan.json"),
                model_template,
            )
        else
            PSRI.PMD.load_model_template!(
                joinpath(PSRI.JSON_METADATA_PATH, "modeltemplates.sddp.json"),
                model_template,
            )
        end
    else
        PSRI.PMD.load_model_template!(model_template_path, model_template)
    end

    relation_mapper = PSRI.PMD.RelationMapper()

    PSRI.PMD.load_relations_struct!(relations_defaults_path, relation_mapper)

    data_struct, model_files_added =
        PSRI.PMD.load_model(path_pmds, pmd_files, model_template, relation_mapper)

    if isempty(model_files_added)
        error("No Model definition (.pmd) file found")
    end

    raw_data = JSON.parsefile(PATH_JSON)

    if !haskey(raw_data, study_collection)
        error("Study collection '$study_collection' is missing")
    end

    study_data = raw_data[study_collection][begin]

    if study_collection == "PSRStudy"
        stage_type = PSRI.StageType(study_data["Tipo_Etapa"])
        first_year = study_data["Ano_inicial"]
        first_stage = study_data["Etapa_inicial"]
        first_date = if stage_type == PSRI.STAGE_MONTH
            Dates.Date(first_year, 1, 1) + Dates.Month(first_stage - 1)
        else
            Dates.Date(first_year, 1, 1) + Dates.Week(first_stage - 1)
        end

        # TODO: daily study

        number_blocks = study_data["NumeroBlocosDemanda"]

        @assert number_blocks == study_data["NumberBlocks"]

        if haskey(study_data, "HourlyData") && study_data["HourlyData"]["BMAP"] in [1, 2]
            duration_mode = PSRI.HOUR_BLOCK_MAP
        elseif (
            haskey(study_data, "DurationModel") &&
            haskey(study_data["DurationModel"], "Duracao($number_blocks)")
        )
            duration_mode = PSRI.VARIABLE_DURATION
        else
            duration_mode = PSRI.FIXED_DURATION
        end
    else
        stage_type = PSRI.STAGE_WEEK
        first_year = 2023
        first_stage = 1
        first_date = Dates.Date(2023, 1, 1)
        number_blocks = 1
        duration_mode = PSRI.FIXED_DURATION
    end

    data = Data(;
        raw = raw_data,
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
        log_file = log_file,
        verbose = verbose,
        model_template = model_template,
        relation_mapper = relation_mapper,
    )

    if rectify_json_data
        _rectify_study_data!(data)
    end

    if add_transformers_to_series
        _merge_psr_transformer_and_psr_serie!(data)
    end

    if duration_mode == PSRI.VARIABLE_DURATION
        _variable_duration_to_file!(data)
    elseif duration_mode == PSRI.HOUR_BLOCK_MAP
        _hour_block_map_to_file!(data)
    end

    if !isempty(extra_config_file)
        if isfile(extra_config_file)
            data.extra_config = TOML.parsefile(extra_config_file)
        else
            error("Files $extra_config_file not found")
        end
    end

    load_json_struct!(data, json_struct_path)

    # Assigns to every `reference_id` the corresponding instance index
    # as a pair (collection, index)
    _build_index!(data)

    return data
end

# Read

function PSRI.get_parm(
    data::Data,
    collection::String,
    attribute::String,
    index::Integer,
    ::Type{T};
    default::T = PSRI._default_value(T),
    dim1::Union{Integer, Nothing} = nothing,
    dim2::Union{Integer, Nothing} = nothing,
    validate::Bool = true,
)::T where {T}
    # Basic checks
    if validate
        attribute_struct = PSRI.get_attribute_struct(data, collection, attribute)
        PSRI._check_dim(attribute_struct, collection, attribute, dim1, dim2)
        PSRI._check_type(attribute_struct, T, collection, attribute)
        PSRI._check_parm(attribute_struct, collection, attribute)
        dim = PSRI.get_attribute_dim(attribute_struct)
    else
        if dim2 !== nothing && dim2 > 0
            dim = 2
        elseif dim1 !== nothing && dim1 > 0
            dim = 1
        else
            dim = 0
        end
    end
    _check_element_range(data, collection, index)

    # This is assumed to be a mutable dictionary
    element = _get_element(data, collection, index)

    # Format according to dimension
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

function PSRI.get_parm_1d(
    data::Data,
    collection::String,
    attribute::String,
    index::Integer,
    ::Type{T};
    default::T = PSRI._default_value(T),
    validate::Bool = true,
)::Vector{T} where {T}
    if validate
        attribute_struct = PSRI.get_attribute_struct(data, collection, attribute)
        dim = PSRI.get_attribute_dim(attribute_struct)
        if dim != 1
            if dim == 0
                error(
                    """
                  Attribute '$attribute' from collection '$colllection' has no dimensions.
                  Consider using `get_parm` instead.
                  """,
                )
            else
                error(
                    """
                    Attribute '$attribute' from collection '$colllection' has $(attribute_struct.dim) dimensions.
                    Consider using `get_parm_$(attribute_struct.dim)d` instead.
                    """,
                )
            end
        end
        PSRI._check_type(attribute_struct, T, collection, attribute)
        PSRI._check_parm(attribute_struct, collection, attribute)
        _check_element_range(data, collection, index)
    end

    dim1 = PSRI.get_attribute_dim1(data, collection, attribute, index)

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

function PSRI.get_parm_2d(
    data::Data,
    collection::String,
    attribute::String,
    index::Integer,
    ::Type{T};
    default::T = PSRI._default_value(T),
    validate::Bool = true,
)::Matrix{T} where {T}
    if validate
        attribute_struct = PSRI.get_attribute_struct(data, collection, attribute)
        dim = PSRI.get_attribute_dim(attribute_struct)
        if dim != 2
            if dim == 0
                error(
                    """
                  Attribute '$attribute' from collection '$colllection' has no dimensions.
                  Consider using `get_parm` instead.
                  """,
                )
            else
                error(
                    """
                    Attribute '$attribute' from collection '$colllection' has $(dim) dimensions.
                    Consider using `get_parm_$(dim)d` instead.
                    """,
                )
            end
        end
        PSRI._check_type(attribute_struct, T, collection, attribute)
        PSRI._check_parm(attribute_struct, collection, attribute)
        _check_element_range(data, collection, index)
    end

    dim1 = PSRI.get_attribute_dim1(data, collection, attribute, index)
    dim2 = PSRI.get_attribute_dim2(data, collection, attribute, index)

    element = _get_element(data, collection, index)

    out = Matrix{T}(undef, dim1, dim2)

    for i in 1:dim1, j in 1:dim2
        key = _get_attribute_key(attribute, 2, 1 => i, 2 => j)

        out[i, j] = if haskey(element, key)
            _cast(T, element[key], default)
        else
            default
        end
    end

    return out
end

function PSRI.get_nonempty_vector(data::Data, collection::String, attribute::String)
    n = PSRI.max_elements(data, collection)

    if n == 0
        return Bool[]
    end

    out = zeros(Bool, n)

    attr_data = PSRI.get_attribute_struct(data, collection, attribute)

    PSRI._check_vector(attr_data, collection, attribute)

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

function PSRI.get_vector(
    data::Data,
    collection::String,
    attribute::String,
    index::Integer,
    ::Type{T};
    dim1::Union{Integer, Nothing} = nothing,
    dim2::Union{Integer, Nothing} = nothing,
    default::T = PSRI._default_value(T),
    validate::Bool = true,
) where {T}
    attribute_struct = PSRI.get_attribute_struct(data, collection, attribute)

    if validate
        PSRI._check_dim(attribute_struct, collection, attribute, dim1, dim2)
        PSRI._check_type(attribute_struct, T, collection, attribute)
        PSRI._check_vector(attribute_struct, collection, attribute)
    end
    _check_element_range(data, collection, index)

    dim = PSRI.get_attribute_dim(attribute_struct)
    key = _get_attribute_key(attribute, dim, 1 => dim1, 2 => dim2)

    element = _get_element(data, collection, index)

    if haskey(element, key)
        return _cast_vector(T, element[key], default)
    else
        return T[]
    end
end

function PSRI.get_vector_1d(
    data::Data,
    collection::String,
    attribute::String,
    index::Integer,
    ::Type{T};
    default::T = PSRI._default_value(T),
    validate::Bool = true,
) where {T}
    if validate
        attribute_struct = PSRI.get_attribute_struct(data, collection, attribute)
        dim = PSRI.get_attribute_dim(attribute_struct)
        if dim != 1
            if dim == 0
                error(
                    """
                  Attribute '$attribute' from collection '$colllection' has no dimensions.
                  Consider using `get_parm` instead.
                  """,
                )
            else
                error(
                    """
                    Attribute '$attribute' from collection '$colllection' has $(dim) dimensions.
                    Consider using `get_parm_$(dim)d` instead.
                    """,
                )
            end
        end
        PSRI._check_type(attribute_struct, T, collection, attribute)
        PSRI._check_vector(attribute_struct, collection, attribute)
        _check_element_range(data, collection, index)
    end

    dim1 = PSRI.get_attribute_dim1(data, collection, attribute, index)

    element = _get_element(data, collection, index)

    out = Vector{Vector{T}}(undef, dim1)

    for i in 1:dim1
        key = _get_attribute_key(attribute, 1, 1 => i)

        out[i] = if haskey(element, key)
            _cast_vector(T, element[key], default)
        else
            T[]
        end
    end

    return out
end

function PSRI.get_vector_2d(
    data::Data,
    collection::String,
    attribute::String,
    index::Integer,
    ::Type{T};
    default::T = PSRI._default_value(T),
    validate::Bool = true,
) where {T}
    if validate
        attribute_struct = PSRI.get_attribute_struct(data, collection, attribute)
        dim = PSRI.get_attribute_dim(attribute_struct)
        if dim != 2
            if dim == 0
                error(
                    """
                  Attribute '$attribute' from collection '$colllection' has no dimensions.
                  Consider using `get_parm` instead.
                  """,
                )
            else
                error(
                    """
                    Attribute '$attribute' from collection '$collection' has $(dim) dimensions.
                    Consider using `get_parm_$(dim)d` instead.
                    """,
                )
            end
        end
        PSRI._check_type(attribute_struct, T, collection, attribute)
        PSRI._check_vector(attribute_struct, collection, attribute)
    end
    _check_element_range(data, collection, index)

    dim1 = PSRI.get_attribute_dim1(data, collection, attribute, index)
    dim2 = PSRI.get_attribute_dim2(data, collection, attribute, index)

    element = _get_element(data, collection, index)

    out = Matrix{Vector{T}}(undef, dim1, dim2)

    for i in 1:dim1, j in 1:dim2
        key = _get_attribute_key(attribute, 2, 1 => i, 2 => j)

        out[i, j] = if haskey(element, key)
            _cast_vector(T, element[key], default)
        else
            T[]
        end
    end

    return out
end

function PSRI.configuration_parameter(data::Data, parameter::String, default::Integer)
    return PSRI.configuration_parameter(data, parameter, Int32(default))
end

function PSRI.configuration_parameter(
    data::Data,
    parameter::String,
    default::T,
) where {T <: PSRI.MainTypes}
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

function PSRI.configuration_parameter(
    data::Data,
    parameter::String,
    default::Vector{T},
) where {T <: PSRI.MainTypes}
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

function PSRI.get_attribute_dim(attribute_struct::Attribute)
    return attribute_struct.dim
end

function PSRI.get_attribute_dim1(
    data::Data,
    collection::String,
    attribute::String,
    index::Integer,
)
    return _get_attribute_axis_dim(data, collection, attribute, 1, index)
end

function PSRI.get_attribute_dim2(
    data::Data,
    collection::String,
    attribute::String,
    index::Integer,
)
    return _get_attribute_axis_dim(data, collection, attribute, 2, index)
end

function PSRI.max_elements(data::Data, collection::String)
    raw = _raw(data)

    if haskey(raw, collection)
        return length(raw[collection])
    else
        return 0
    end
end

function PSRI.stage_duration(data::Data, date::Dates.Date)
    if data.duration_mode != PSRI.VARIABLE_DURATION
        return _raw_stage_duration(data, date)
    end
    t = PSRI._stage_from_date(date, data.stage_type, data.first_date)
    return _variable_stage_duration(data, t)
end

function PSRI.stage_duration(data::Data, t::Int = data.controller_stage)
    if data.duration_mode != PSRI.VARIABLE_DURATION
        return _raw_stage_duration(data, t)
    end
    return _variable_stage_duration(data, t)
end

function PSRI.block_duration(data::Data, date::Dates.Date, b::Int)
    if !(1 <= b <= data.number_blocks)
        error(
            "Blocks is expected to be larger than 1 and smaller than the number of blocks in the study $(data.number_blocks)",
        )
    end
    if data.duration_mode == PSRI.FIXED_DURATION
        raw = _raw(data)
        percent = raw["PSRStudy"][1]["Duracao($b)"] / 100.0
        return percent * _raw_stage_duration(data, date)
    end# elseif data.duration_mode == PSRI.VARIABLE_DURATION # OR PSRI.HOUR_BLOCK_MAP
    t = PSRI._stage_from_date(date, data.stage_type, data.first_date)
    return _variable_stage_duration(data, t, b)
end

function PSRI.block_duration(data::Data, b::Int)
    return PSRI.block_duration(data, data.controller_stage, b)
end

function PSRI.block_duration(data::Data, t::Int, b::Int)
    if !(1 <= b <= data.number_blocks)
        error(
            "Blocks is expected to be larger than 1 and smaller than the number of blocks in the study $(data.number_blocks)",
        )
    end
    if data.duration_mode == PSRI.FIXED_DURATION
        raw = _raw(data)
        percent = raw["PSRStudy"][1]["Duracao($b)"] / 100.0
        return percent * _raw_stage_duration(data, t)
    end# elseif data.duration_mode == PSRI.VARIABLE_DURATION # OR PSRI.HOUR_BLOCK_MAP
    return _variable_stage_duration(data, t, b)
end

function PSRI.block_from_stage_hour(data::Data, t::Int, h::Int)
    if data.duration_mode != PSRI.HOUR_BLOCK_MAP
        error("Cannot query block from study with duration mode: $(data.duration_mode)")
    end
    PSRI.goto(data.hour_to_block, t, 1, h)
    return data.hour_to_block[]
end

function PSRI.block_from_stage_hour(data::Data, date::Dates.Date, h::Int)
    t = PSRI._stage_from_date(date, data.stage_type, data.first_date)
    return PSRI.block_from_stage_hour(data, t, h)
end

function PSRI.get_series(
    data::Data,
    collection::String,
    indexing_attribute::String,
    index::Int,
)
    # TODO: review this. The element should always have all attributes even if
    # they need to be empty. the element creator should assure the data is
    # is complete. or this `get_series` should check existence and the return
    # empty if needed.
    attributes = _get_indexed_attributes(data, collection, index, indexing_attribute)

    buffer = Dict{String, Vector}()

    for attribute in attributes
        buffer[attribute] = PSRI.get_vector(
            data,
            collection,
            attribute,
            index,
            _get_attribute_type(data, collection, attribute),
        )
    end

    return PSRI.SeriesTable(buffer)
end

function PSRI.get_graf_series(data::Data, collection::String, attribute::String; kws...)
    if !PSRI.has_graf_file(data, collection)
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

    graf_table = PSRI.GrafTable{Float64}(graf_path; kws...)

    return graf_table
end

function PSRI.get_reverse_map(
    data::Data,
    source::String,
    target::String,
    attribute::String;
    allow_empty::Bool = true,
)
    validate_relation(data, source, target, attribute)

    relation_type = _get_relation_type(data, source, target, attribute)

    if is_vector_relation(relation_type)
        error("For relation relation_type = '$relation_type' use get_reverse_vector_map")
    end

    if !haskey(data.raw, target)
        return zeros(Int32, 0)
    end

    raw = _raw(data)

    out_vec = Vector{Int}()

    for target_element in raw[target]
        target_id = target_element["reference_id"]
        source_indices =
            _get_sources_indices_from_relations(data, source, target, target_id, attribute)
        if !isempty(source_indices)
            append!(out_vec, [source_indices][1])
        else
            append!(out_vec, 0)
        end
    end

    return out_vec
end

function PSRI.get_reverse_map(
    data::Data,
    lst_from::String,
    lst_to::String;
    allow_empty::Bool = true,
    original_relation_type::PSRI.PMD.RelationType = PSRI.PMD.RELATION_1_TO_1, # type of the direct relation
)
    n_to = PSRI.max_elements(data, lst_to)
    if n_to == 0
        # TODO warn no field
        return zeros(Int32, 0)
    end
    out = zeros(Int32, n_to)
    if is_vector_relation(original_relation_type)
        vector_map = PSRI.get_vector_map(
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
    map = PSRI.get_map(
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

function PSRI.get_reverse_vector_map(
    data::Data,
    source::String,
    target::String,
    attribute::String;
    allow_empty::Bool = true,
)
    validate_relation(data, source, target, attribute)

    if !haskey(data.raw, target)
        return Vector{Int32}[]
    end

    raw = _raw(data)

    out_vec = Vector{Vector{Int32}}()

    for target_element in raw[target]
        target_id = target_element["reference_id"]
        source_indices =
            _get_sources_indices_from_relations(data, source, target, target_id, attribute)
        append!(out_vec, [source_indices])
    end

    return out_vec
end

function PSRI.get_reverse_vector_map(
    data::Data,
    lst_from::String,
    lst_to::String;
    allow_empty::Bool = true,
    original_relation_type::PSRI.PMD.RelationType = PSRI.PMD.RELATION_1_TO_N,
)
    n_to = PSRI.max_elements(data, lst_to)
    if n_to == 0
        # TODO warn no field
        return Vector{Int32}[]
    end
    out = Vector{Int32}[zeros(Int32, 0) for _ in 1:n_to]
    if is_vector_relation(original_relation_type)
        vector_map = PSRI.get_vector_map(
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
    map = PSRI.get_map(
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

function PSRI.get_map(
    data::Data,
    source::String,
    target::String,
    attribute::String;
    allow_empty::Bool = true,
)
    if !haskey(data.relation_mapper, source) ||
       !haskey(data.relation_mapper[source], target)
        error("There is no relation between '$source' and '$target'")
    end

    relations = data.relation_mapper[source][target]

    if !haskey(relations, attribute)
        error("No relation '$attribute' between '$source' and '$target'")
    end

    relation = relations[attribute]

    validate_relation(data, source, target, relation.type)

    if is_vector_relation(relation.type)
        error("For relation relation_type = '$(relation.type)' use get_vector_map")
    end

    src_size = PSRI.max_elements(data, source)

    if src_size == 0
        return zeros(Int32, 0)
    end

    dst_size = PSRI.max_elements(data, target)

    if dst_size == 0 # TODO warn no field
        return zeros(Int32, src_size)
    end

    raw = _raw(data)

    out_vec = zeros(Int32, src_size)
    src_vec = raw[source]
    dst_vec = raw[target]

    # TODO improve this quadratic loop

    for (src_index, src_element) in enumerate(src_vec)
        dst_index = get(src_element, attribute, -1)

        found = false

        for (index, element) in enumerate(dst_vec)
            if dst_index == element["reference_id"]
                out_vec[src_index] = index

                found = true
                break
            end
        end

        if !found && !allow_empty
            error("No '$target' element matching '$source' of index '$src_index'")
        end
    end

    return out_vec
end

function PSRI.get_map(
    data::Data,
    source::String,
    target::String;
    allow_empty::Bool = true,
    relation_type::PSRI.PMD.RelationType = PSRI.PMD.RELATION_1_TO_1, # type of the direct relation
)
    attribute = _get_relation_attribute(data, source, target, relation_type)

    return PSRI.get_map(data, source, target, attribute; allow_empty)
end

function PSRI.get_vector_map(
    data::Data,
    source::String,
    target::String,
    attribute::String;
    allow_empty::Bool = true,
)
    validate_relation(data, source, target, attribute)

    relation_type = _get_relation_type(data, source, target, attribute)

    if !is_vector_relation(relation_type)
        error("For relation relation_type = '$relation_type' use get_map")
    end

    src_size = PSRI.max_elements(data, source)

    target_size = PSRI.max_elements(data, target)

    if src_size == 0
        @warn "No '$source' elements in this study"
        return Vector{Int32}[]
    end

    if target_size == 0
        @warn "No '$target' elements in this study"
        return Vector{Int32}[zeros(Int32, 0) for _ in 1:src_size]
    end

    raw = _raw(data)

    out_vec = Vector{Vector{Int}}()

    for src_i in keys(raw[source])
        target_indices =
            _get_target_indices_from_relation(data, source, src_i, target, attribute)
        append!(out_vec, [target_indices])
    end

    return out_vec
end

function PSRI.get_vector_map(
    data::Data,
    lst_from::String,
    lst_to::String;
    allow_empty::Bool = true,
    relation_type::PSRI.PMD.RelationType = PSRI.PMD.RELATION_1_TO_N,
)
    if !is_vector_relation(relation_type)
        error("For relation relation_type = $relation_type use get_map")
    end

    validate_relation(data, lst_from, lst_to, relation_type)

    # @assert TYPE == PSR_RELATIONSHIP_1TO1 # TODO I think we don't need that in this interface
    raw = _raw(data)
    n_from = PSRI.max_elements(data, lst_from)
    if n_from == 0
        return Vector{Int32}[]
    end
    n_to = PSRI.max_elements(data, lst_to)
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

function PSRI.get_related(
    data::Data,
    source::String,
    target::String,
    source_index::Integer;
    relation_type::PSRI.PMD.RelationType = PSRI.PMD.RELATION_1_TO_1,
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

function PSRI.get_vector_related(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    relation_type::PSRI.PMD.RelationType = PSRI.PMD.RELATION_1_TO_N,
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

function PSRI.total_stages(data::Data)
    return _raw(data)["PSRStudy"][1]["NumeroEtapas"]
end

function PSRI.total_scenarios(data::Data)
    # _raw(data)["PSRStudy"][1]["Series_Forward"]
    return _raw(data)["PSRStudy"][1]["NumberSimulations"]
end

function PSRI.total_openings(data::Data)
    return _raw(data)["PSRStudy"][1]["NumberOpenings"]
end

function PSRI.total_blocks(data::Data)
    return _raw(data)["PSRStudy"][1]["NumberBlocks"]
end

function PSRI.total_stages_per_year(data::Data)
    if data.stage_type == PSRI.STAGE_MONTH
        return 12
    elseif data.stage_type == PSRI.STAGE_WEEK
        return 52
    else
        error("Stage type '$(data.stage_type)' is not currently supported")
    end
end

function PSRI.mapped_vector(
    data::Data,
    collection::String,
    attribute::String,
    ::Type{T},
    dim1::Union{String, Nothing} = nothing,
    dim2::Union{String, Nothing} = nothing;
    ignore::Bool = false,
    map_key = collection, # reference for PSRMap pointer, if empty use class name
    filters = String[], # for calling just within a subset instead of the full call
    default = PSRI._default_value(T),
    validate::Bool = true,
) where {T} #<: Union{Float64, Int32}
    if PSRI.has_graf_file(data, collection, attribute)
        if isnothing(data.mapper)
            data.mapper = PSRI.ReaderMapper(PSRI.OpenBinary.Reader, data.controller_date)
        end
        graf_file = _get_graf_filename(data, collection, attribute)
        header = _get_graf_agents(graf_file)
        return PSRI.add_reader!(data.mapper, graf_file, header, filters)
    end

    raw = _raw(data)

    n = PSRI.max_elements(data, collection)

    if n == 0
        return T[]
    end

    attribute_struct = PSRI.get_attribute_struct(data, collection, attribute)

    if validate
        PSRI._check_type(attribute_struct, T, collection, attribute)
        PSRI._check_vector(attribute_struct, collection, attribute)
    end
    PSRI._check_dim(attribute_struct, collection, attribute, dim1, dim2)

    dim = PSRI.get_attribute_dim(attribute_struct)

    dim1_val = _add_get_dim_val(data, dim1)
    dim2_val = _add_get_dim_val(data, dim2)

    index = attribute_struct.index
    stage = data.controller_stage

    cache = _get_cache(data, T)

    collection_cache = get!(cache, collection, Dict{String, VectorCache{T}}())

    if haskey(collection_cache, attribute)
        error("Attribute $attribute was already mapped.")
    end

    out = T[default for _ in 1:n] #zeros(T, n)

    date_cache = get!(data.map_cache_data_idx, collection, Dict{String, Vector{Int32}}())

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

    vector_cache = VectorCache(
        dim1, dim2, dim1_val, dim2_val, index, stage, out, default)#, date_ref)
    collection_cache[attribute] = vector_cache

    if need_up_dates
        _update_dates!(data, raw[collection], date_ref, index)
    end
    _update_vector!(data, raw[collection], date_ref, vector_cache, attribute)

    _add_filter(data, map_key, collection, attribute, T)
    for f in filters
        _add_filter(data, f, collection, attribute, T)
    end

    return out
end

# Modification

function PSRI.set_parm!(
    data::Data,
    collection::String,
    attribute::String,
    index::Int,
    value::T;
    validate::Bool = true,
) where {T <: PSRI.MainTypes}
    if validate
        PSRI._check_type_attribute(data, collection, attribute, T)
    end

    element = _get_element(data, collection, index)

    element[attribute] = value

    return nothing
end

function PSRI.set_vector!(
    data::Data,
    collection::String,
    attribute::String,
    index::Int,
    buffer::Vector{T};
    validate::Bool = true,
) where {T <: PSRI.MainTypes}
    if validate
        PSRI._check_type_attribute(data, collection, attribute, T)
    end
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

function PSRI.set_series!(
    data::Data,
    collection::String,
    indexing_attribute::String,
    index::Int,
    buffer::Dict{String, Vector},
)
    series = PSRI.SeriesTable(buffer)

    return PSRI.set_series!(data, collection, indexing_attribute, index, series)
end

function PSRI.set_series!(
    data::Data,
    collection::String,
    indexing_attribute::String,
    index::Int,
    series::PSRI.SeriesTable;
    check_type::Bool = true,
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
    if check_type
        for attribute in keys(series)
            attribute_struct =
                PSRI.get_attribute_struct(data, collection, String(attribute))
            PSRI._check_type(
                attribute_struct,
                eltype(series[attribute]),
                collection,
                String(attribute),
            )
        end
    end

    for attribute in keys(series)
        # protect user's data
        element[String(attribute)] = deepcopy(series[attribute])
    end

    return nothing
end

function PSRI.set_vector_related!(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    target_indices::Vector{T},
    relation_type::PSRI.PMD.RelationType = PSRI.PMD.RELATION_1_TO_N,
) where {T <: Integer}
    check_relation_vector(relation_type)
    validate_relation(data, source, target, relation_type)
    source_element = _get_element(data, source, source_index)
    relation_field = _get_relation_attribute(data, source, target, relation_type)

    source_element[relation_field] = Int[]
    for target_index in target_indices
        target_element = _get_element(data, target, target_index)
        push!(source_element[relation_field], target_element["reference_id"])
    end

    return nothing
end

function PSRI.set_related!(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    target_index::Integer;
    relation_type::PSRI.PMD.RelationType = PSRI.PMD.RELATION_1_TO_1,
)
    check_relation_scalar(relation_type)
    validate_relation(data, source, target, relation_type)
    relation_field = _get_relation_attribute(data, source, target, relation_type)
    source_element = _get_element(data, source, source_index)
    target_element = _get_element(data, target, target_index)

    source_element[relation_field] = target_element["reference_id"]

    return nothing
end

function PSRI.set_related_by_code!(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    target_code::Integer;
    relation_type::PSRI.PMD.RelationType = PSRI.PMD.RELATION_1_TO_1,
)
    target_index = _get_index_by_code(data, target, target_code)
    return PSRI.set_related!(
        data,
        source,
        target,
        source_index,
        target_index;
        relation_type = relation_type,
    )
end

function PSRI.create_element!(
    data::Data,
    collection::String;
    defaults::Union{Dict{String, Any}, Nothing} = PSRI._load_defaults!(),
)
    return PSRI.create_element!(data, collection, Dict{String, Any}(); defaults = defaults)
end

function PSRI.create_element!(
    data::Data,
    collection::String,
    ps::Pair{String, <:Any}...;
    defaults::Union{Dict{String, Any}, Nothing} = PSRI._load_defaults!(),
)
    attributes = Dict{String, Any}(ps...)

    return PSRI.create_element!(data, collection, attributes; defaults = defaults)
end

function PSRI.create_element!(
    data::Data,
    collection::String,
    attributes::Dict{String, Any};
    defaults::Union{Dict{String, Any}, Nothing} = PSRI._load_defaults!(),
)
    _validate_collection(data, collection)

    if PSRI.has_graf_file(data, collection)
        error("Cannot create element for a collection with a Graf file")
    end

    element = if isnothing(defaults)
        Dict{String, Any}()
    elseif haskey(defaults, collection)
        deepcopy(defaults[collection])
    else
        @warn "No default initialization values for collection '$collection'"

        Dict{String, Any}()
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

function PSRI.delete_relation!(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    target_index::Integer,
)
    relations_as_source, _ = _get_element_related(data, source, source_index)

    source_element = _get_element(data, source, source_index)
    target_element = _get_element(data, target, target_index)

    if haskey(relations_as_source, target)
        for (relation_attribute, _) in relations_as_source[target]
            if source_element[relation_attribute] == target_element["reference_id"]
                delete!(source_element, relation_attribute)
            end
        end
    else
        error(
            "Relation between element from '$source'(Source) with element from '$target'(Target) does not exist",
        )
    end

    return nothing
end

function PSRI.delete_vector_relation!(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    target_indices::Vector{Int},
)
    relations_as_source, _ = _get_element_related(data, source, source_index)

    source_element = _get_element(data, source, source_index)
    targets_ref_id = [
        _get_element(data, target, target_index)["reference_id"] for
        target_index in target_indices
    ]

    if haskey(relations_as_source, target)
        for (relation_attribute, _) in relations_as_source[target]
            if sort(source_element[relation_attribute]) == sort(targets_ref_id)
                delete!(source_element, relation_attribute)
            end
        end
    else
        error(
            "Relation between element from '$source'(Source) with element from '$target'(Target) does not exist",
        )
    end

    return nothing
end

function PSRI.delete_element!(data::Data, collection::String, index::Int)
    if !PSRI.has_relations(data, collection, index)
        elements = _get_elements(data, collection)

        element_id = elements[index]["reference_id"]

        # Remove element reference from data_index by its id
        delete!(data.data_index.index, element_id)

        # Remove element from collection vector by its index
        deleteat!(elements, index)
    else
        error(
            "Element $collection cannot be deleted because it has relations with other elements",
        )
    end
    return nothing
end

# Graf files

function PSRI.link_series_to_file(
    data::Data,
    collection::String,
    attribute::String,
    agent_attribute::String,
    file_name::String,
)
    if !haskey(data.raw, "GrafScenarios")
        data.raw["GrafScenarios"] = Vector{Dict{String, Any}}()
    end

    if _get_attribute_type(data, collection, agent_attribute) != String
        error("Attribute '$agent_attribute' can only be an Attribute of type String")
    end

    collection_elements = data.raw[collection]

    _validate_json_graf(agent_attribute, collection_elements, file_name)

    for element in collection_elements
        if haskey(element, attribute)
            pop!(element, attribute)
        end
    end

    graf_dict = Dict{String, Any}(
        "classname" => collection,
        "parmid" => agent_attribute,
        "vector" => attribute,
        "binary" => [file_name * ".bin", file_name * ".hdr"],
    )

    push!(data.raw["GrafScenarios"], graf_dict)

    PSRI.write_data(data)
    return
end

# Mapped vector utils

function PSRI.go_to_stage(data::Data, stage::Integer)
    if data.controller_stage != stage
        data.controller_stage_changed = true
    end
    data.controller_stage = stage
    data.controller_date = _date_from_stage(data, stage)
    return nothing
end

function PSRI.go_to_dimension(data::Data, str::String, val::Integer)
    if haskey(data.controller_dim, str)
        data.controller_dim[str] = val
    else
        error("Dimension $str was not created.")
    end
    return nothing
end

function PSRI.go_to_scenario(data::Data, scenario::Integer)
    data.controller_scenario = scenario
    return nothing
end

function PSRI.go_to_block(data::Data, block::Integer)
    data.controller_block = block
    return nothing
end

function PSRI.update_vectors!(data::Data)
    _update_all_dates!(data)

    _update_all_vectors!(data, data.map_cache_real)
    _update_all_vectors!(data, data.map_cache_integer)
    _update_all_vectors!(data, data.map_cache_date)
    if !isnothing(data.mapper)
        _update_graf_vectors!(data)
    end

    return nothing
end

function PSRI.update_vectors!(data::Data, filter::String)

    # TODO improve this with a DataCache
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
    elseif !isnothing(data.mapper)
        if haskey(data.mapper.dict, filter)
            _update_graf_vectors!(data, filter)
        end
    elseif no_attr
        error("Filter $filter not valid")
    end

    return nothing
end

function PSRI.update_vectors!(data::Data, filters::Vector{String})
    for f in filters
        PSRI.update_vectors!(data, f)
    end
    return nothing
end

# Utils

function PSRI.has_relations(data::Data, collection::String)
    return haskey(data.relation_mapper, collection)
end

function PSRI.has_relations(data::Data, collection::String, index::Int)
    if !haskey(data.relation_mapper, collection)
        return false
    end

    relations_as_source, relations_as_target = _get_element_related(data, collection, index)

    if !isempty(relations_as_source) || !isempty(relations_as_target)
        return true
    end

    return false
end

function PSRI.has_graf_file(
    data::Data,
    collection::String,
    attribute::Union{String, Nothing} = nothing,
)
    _check_collection_in_study(data, collection)

    if !haskey(data.raw, collection)
        return false
    end

    if !haskey(data.raw, "GrafScenarios")
        return false
    end

    for graf in data.raw["GrafScenarios"]
        if graf["classname"] == collection
            if isnothing(attribute)
                return true
            end
            if graf["vector"] == attribute
                return true
            end
        end
    end

    return false
end

function PSRI.description(::Data)
    return ""
end

function PSRI.write_data(data::Data, path::Union{AbstractString, Nothing} = nothing)
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

PSRI.summary(io::IO, args...) = print(io, PSRI.summary(args...))

function PSRI.summary(data::Data)
    collections = PSRI.get_collections(data)

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

function PSRI.summary(data::Data, collection::String)
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
            type = _get_attribute_type(data, collection, attribute)
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

PSRI._default_value(::Type{T}) where {T <: Number} = zero(T)
PSRI._default_value(::Type{String}) = ""
PSRI._default_value(::Type{Dates.Date}) = Dates.Date(1900, 1, 1)

function PSRI._check_type(
    attribute_struct::Attribute,
    ::Type{T},
    collection::String,
    attribute::String,
) where {T}
    if attribute_struct.type !== T
        error(
            "Attribute '$attribute' of collection '$collection' is of type '$(attribute_struct.type)', not '$T'",
        )
    end

    return nothing
end

function PSRI._check_parm(
    attribute_struct::Attribute,
    collection::String,
    attribute::String,
)
    if attribute_struct.is_vector
        error(
            "Attribute '$attribute' of collection '$collection' is a vector, not a parameter",
        )
    end

    return nothing
end

function PSRI._check_vector(
    attribute_struct::Attribute,
    collection::String,
    attribute::String,
)
    if !attribute_struct.is_vector
        error("Attribute '$attribute' of collection '$collection' isn't a vector")
    end

    return nothing
end

function PSRI.PMD.dump_model_template(path::String, data::Data)
    PSRI.PMD.dump_model_template(path, data.model_template)

    return nothing
end

function PSRI.PMD.load_model_template!(path::String, data::Data)
    PSRI.PMD.load_model_template!(path, data.model_template)

    return nothing
end
