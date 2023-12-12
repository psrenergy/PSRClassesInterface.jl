
function create_study(
    ::OpenInterface;
    data_path::AbstractString = pwd(),
    pmd_files::Vector{String} = String[],
    pmds_path::AbstractString = PMD._PMDS_BASE_PATH,
    defaults_path::Union{AbstractString, Nothing} = PSRCLASSES_DEFAULTS_PATH,
    defaults::Union{Dict{String, Any}, Nothing} = _load_defaults!(),
    netplan::Bool = false,
    model_template_path::Union{String, Nothing} = nothing,
    relations_defaults_path = PMD._DEFAULT_RELATIONS_PATH,
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
        merge_defaults!(study_defaults, defaults)
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

    relation_mapper = PMD.RelationMapper()

    PMD.load_relations_struct!(relations_defaults_path, relation_mapper)

    data_struct, model_files_added =
        PMD.load_model(pmds_path, pmd_files, model_template, relation_mapper; verbose)

    stage_type =
        if haskey(study_defaults[study_collection], "Tipo_Etapa")
            StageType(study_defaults[study_collection]["Tipo_Etapa"])
        else
            if verbose
                @warn "Study collection does not have a stage type ('Tipo_Etapa'). Using default value 'STAGE_WEEK'"
            end
            STAGE_WEEK
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
        if stage_type == STAGE_MONTH
            Dates.Date(first_year, 1, 1) + Dates.Month(first_stage - 1)
        else
            Dates.Date(first_year, 1, 1) + Dates.Week(first_stage - 1)
        end

    duration_mode =
        if haskey(study_defaults[study_collection], "HourlyData") &&
           study_defaults[study_collection]["HourlyData"]["BMAP"] in [1, 2]
            HOUR_BLOCK_MAP
        elseif (
            haskey(study_defaults[study_collection], "DurationModel") &&
            haskey(
                study_defaults[study_collection]["DurationModel"],
                "Duracao($number_blocks)",
            )
        )
            VARIABLE_DURATION
        else
            FIXED_DURATION
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

function _create_study_collection(
    data::Data,
    collection::String,
    defaults::Union{Dict{String, Any}, Nothing},
)
    create_element!(data, collection; defaults = defaults)

    return nothing
end

function create_element!(
    data::Data,
    collection::String;
    defaults::Union{Dict{String, Any}, Nothing} = _load_defaults!(),
)
    return create_element!(data, collection, Dict{String, Any}(); defaults = defaults)
end

function create_element!(
    data::Data,
    collection::String,
    ps::Pair{String, <:Any}...;
    defaults::Union{Dict{String, Any}, Nothing} = _load_defaults!(),
)
    attributes = Dict{String, Any}(ps...)

    return create_element!(data, collection, attributes; defaults = defaults)
end

function create_element!(
    data::Data,
    collection::String,
    attributes::Dict{String, Any};
    defaults::Union{Dict{String, Any}, Nothing} = _load_defaults!(),
)
    _validate_collection(data, collection)

    if has_graf_file(data, collection)
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
