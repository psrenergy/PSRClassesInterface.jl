module PMD

import Dates
import JSON

"""
```
struct Attribute
    name::String
    is_vector::Bool
    type::DataType
    dim::Int
    index::String
end
```
"""
struct Attribute
    name::String
    is_vector::Bool
    type::DataType
    dim::Int
    index::String
    # interval::String
end

const DataStruct = Dict{String,Dict{String,Attribute}}

include("model_template.jl")

const _PMDS_BASE_PATH = joinpath(@__DIR__(), "pmds")

const PMD_MODEL_TEMPLATES_PATH = joinpath(@__DIR__(), "..", "json_metadata", "modeltemplates.sddp.json")

const _MODEL_TO_CLASS_SDDP = Dict(
    "SDDP_V10.2_ConfiguracaoEstudo" => "PSRStudy",
    "SDDP_V10.2_Sistema" => "PSRSystem",
    "SDDP_V10.2_Area" => "PSRArea",
    "SDDP_V10.2_CargaBarra" => "PSRLoad",
    "SDDP_V10.2_Demanda" => "PSRDemand",
    "SDDP_V10.2_SegmentoDemanda" => "PSRDemandSegment",
    "SDDP_V10.2_Interconnection" => "PSRInterconnection",
    "SDDP_V10.2_Bus" => "PSRBus",
    "SDDP_V10.2_Circuito" => "PSRSerie",
    "SDDP_Transformador" => "PSRTransformer",
    "SDDP_V10.2_Termica" => "PSRThermalPlant",
    "SDDP_V10.2_Hidro" => "PSRHydroPlant",
    "SDDP_V10.2_Gnd" => "PSRGndPlant",
    "SDDP_PostoMedicaoGnd" => "PSRGndGaugingStation",
    "SDDP_Csp" => "PSRCspPlant",
    "SDDP_V10.2_Combustivel" => "PSRFuel",
    "SDDP_V10.2_Manutencao" => "PSRMaintenanceData",
    "SDDP_V10.2_RestricaoGeracao" => "PSRGenerationConstraintData",
    "SDDP_V10.2_ReservaGeracao" => "PSRReserveGenerationConstraintData",
    "SDDP_V10.2_ConexaoHidreletrica" => "PSRHydrologicalPlantConnection",
    "SDDP_V10.2_PostoHidrologico" => "PSRGaugingStation",
    "SDDP_V10.2_DCLink" => "PSRLinkDC",
    "SDDP_V10.2_NoGas" => "PSRGasNode",
    "SDDP_V10.2_Gasoduto" => "PSRGasPipeline",
    "SDDP_V10.2_Bateria" => "PSRBattery",
    "SDDP_ConsumoCombustivel" => "PSRFuelConsumption",
    "SDDP_V10.2_InjecaoPotencia" => "PSRPowerInjection",
    "SDDP_ContratoCombustivel" => "PSRFuelContract",
    "SDDP_ReservatorioCombustivel" => "PSRFuelReservoir",
    "SDDP_RestricaoSomaInterconexao" => "PSRInterconnectionSumData",
    "SDDP_RestricaoSomaCircuito" => "PSRCircuitSumData",
    "SDDP_CicloCombinadoTermica" => "PSRThermalCombinedCycle",
    "SDDP_EmissaoGas" => "PSRGasEmission",
    "SDDP_ConjuntoReservatorios" => "PSRReservoirSet",
    "SDDP_V10.2_Currency" => "PSRCurrency",
    "SDDP_V10.2_Restricao" => "_PSRConstraintData",
    "SDDP_V10.2_RestricaoSoma" => "_PSRSumConstraintData",
)

const _MODEL_TO_CLASS_NETPLAN = Dict(
    #
    # NETPLAN
    #
    # ? sub model X merge model ?
    "NETPLAN_V2.6_Configuration" => "PSRStudy",
    # "NETPLAN_ConfigurationIncremental" => "PSRStudy",
    "NETPLAN_V2.6_Sistema" => "PSRSystem",
    # "NETPLAN_V2.6_DuracaoVariavel" => "",
    # "NETPLAN_V2.6_Constantes" => "",
    "NETPLAN_V2.6_Area" => "PSRArea",
    "NETPLAN_V2.6_Bus" => "PSRBus",
    "NETPLAN_V2.6_Generation" => "PSRGenerator",
    # "NETPLAN_V2.6_BusShunt" => "PSRCapacitor",
    # "NETPLAN_V2.6_BusShunt" => "PSRReactor", # yes both are valid
    "NETPLAN_V2.6_SyncronousCompensator" => "PSRSynchronousCompensator",
    "NETPLAN_V2.6_Circuit" => "PSRSerie",
    "NETPLAN_V2.6_Trafo" => "PSRTransformer",
    "NETPLAN_Transformer3Winding" => "PSRTransformer3Winding",
    "NETPLAN_V2.6_LineReactor" => "PSRLineReactor",
    "NETPLAN_V2.6_SerieCapacitor" => "PSRSerieCapacitor",
    "NETPLAN_V2.6_FlowController" => "PSRFlowController",
    # "NETPLAN_V2.6_Shunt" => "PSRCapacitor", # generico
    "NETPLAN_V2.6_BusDC" => "PSRBusDC",
    "NETPLAN_V2.6_CircuitDC" => "PSRCircuitDC",
    "NETPLAN_V2.6_CargaBarra" => "PSRLoad",
    "NETPLAN_LinkDC" => "PSRLinkDC",
    "NETPLAN_ConstraintFlow" => "PSRCircuitFlowConstraint",
    "NETPLAN_ConstraintAngle" => "PSRBusAngleConstraint",
    "NETPLAN_ConstraintCorridor" => "PSRCircuitCorridorConstraint",
    "NETPLAN_ConstraintEnviromental" => "PSRCircuitEnviromentalConstraint",
    "NETPLAN_ConstraintBipole" => "PSRBipoleConstraint",
    "NETPLAN_StaticVarCompensator" => "PSRStaticVarCompensator",
    "NETPLAN_Battery" => "PSRBattery",
    "NETPLAN_Injection" => "PSRPowerInjection",
    "NETPLAN_V2.6_ConversorDCAC" => "PSRConverterDCAC",
    # "NETPLAN_V2.6_ConversorDCAC" => "PSRConverterDCAC_LCC",
    "NETPLAN_Conversor_P2P" => "PSRConverterDCAC_P2P",
    "NETPLAN_Conversor_VSC" => "PSRConverterDCAC_VSC",
    #
    "NETPLAN_V3.0_CargaBarra" => "PSRLoad",
    "NETPLAN_V3.0_ConversorDCAC" => "PSRConverterDCAC_LCC",
)

function _is_vector(str)
    if str == "VECTOR" || str == "VETOR" # TODO: comentar no cnaal do classes
        return true
    elseif str == "PARM"
        return false
    else
        error("data type $str not known")
    end
end

function _get_type(str)
    if str == "INTEGER"
        return Int32
    elseif str == "REAL"
        return Float64
    elseif str == "STRING"
        return String
    elseif str == "DATE"
        return Dates.Date
    elseif str == "REFERENCE"
        return Ptr{Nothing}
    else
        error("Type $str no known")
    end
end

const _MAX_MERGE = 10

"""
    _PMD_STATE

Subtypes of `_PMD_STATE` represent the states of the PMD parser.
"""
abstract type _PMD_STATE end

"""
    _PMD_STATE_IDLE

Indicates that the parser is in _idle_ state, that is, it is at the beginning of
the file or has just finished consuming a top-level block.
"""
struct _PMD_STATE_IDLE <: _PMD_STATE end

"""
    _PMD_STATE_MODEL

Indicates that the parser is parsing a _model_ block.
"""
struct _PMD_STATE_MODEL <: _PMD_STATE
    collection::String
    num_merges::Int

    _PMD_STATE_MODEL(collection::String, num_merges::Integer = 0) = new(collection, num_merges)
end

function _parse_pmd(filepath::AbstractString, model_template::ModelTemplate)
    data_struct = DataStruct()

    return _parse_pmd!(data_struct, filepath, model_template)
end

function _parse_pmd!(
    data_struct::DataStruct,
    filepath::AbstractString,
    model_template::ModelTemplate,
)
    if !isfile(filepath) || !endswith(filepath, ".pmd")
        error("'$filepath' is not a valid .pmd file")
    end

    open(filepath, "r") do fp
        _parse_pmd!(fp, data_struct, model_template)
    end

    return data_struct
end

function _parse_pmd!(io::IO, data_struct::DataStruct, model_template::ModelTemplate)
    state = _PMD_STATE_IDLE()

    for line in strip.(readlines(io))
        if isempty(line) || startswith(line, "//")
            continue # comment or empty line
        end

        state = _parse_pmd_line!(data_struct, model_template, line, state)
    end

    # apply merges
    for collection in keys(data_struct)
        _merge_class(data_struct, collection, String[collection])
    end

    # delete temporary classes (starting with "_")
    for collection in keys(data_struct)
        if startswith(collection, "_")
            delete!(data_struct, collection)
        end
    end

    return data_struct
end

function _parse_pmd_line!(
    data_struct::DataStruct,
    model_template::ModelTemplate,
    line::AbstractString,
    state::_PMD_STATE_IDLE,
)
    m = match(r"DEFINE_MODEL\s+MODL:([\S]+)", line)

    if !isnothing(m)
        model_name = m[1]

        if _hasinv(model_template, model_name)
            collection = model_template.inv[model_name]

            data_struct[collection] = Dict{String,Attribute}()

            # default attributes tha belong to "all collectiones"
            data_struct[collection]["name"] = Attribute("name", false, String, 0, "")
            data_struct[collection]["code"] = Attribute("code", false, Int32, 0, "")
            data_struct[collection]["AVId"] = Attribute("AVId", false, String, 0, "")

            if collection == "PSRSystem"
                data_struct[collection]["id"] = Attribute("id", false, String, 0, "")
            end

            return _PMD_STATE_MODEL(collection)
        end
    end

    return state
end

function _parse_pmd_line!(
    data_struct::DataStruct,
    model_template::ModelTemplate,
    line::AbstractString,
    state::_PMD_STATE_MODEL,
)
    if startswith(line, "END_MODEL")
        return _PMD_STATE_IDLE()
    end

    m = match(r"MERGE_MODEL\s+MODL:([\S]+)", line)

    if !isnothing(m)
        model_name = m[1]

        for i in 1:_MAX_MERGE
            if !haskey(data_struct[state.collection], "_MERGE_$i")
                data_struct[state.collection]["_MERGE_$i"] = Attribute(model_template.inv[model_name], false, DataType, 0, "")
                
                return _PMD_STATE_MODEL(state.collection, state.num_merges + 1)
            end
        end

        @warn "Number of merges in class $(state.collection) exceeded the maximum of $(_MAX_MERGE)"

        return state
    end

    m = match(r"(PARM|VECTOR|VETOR)\s+([\S]+)\s+([\S]+)(\s+DIM\(([\S]+(,[\S]+)*)\))?(\s+INDEX\s+([\S]+))?", line)
    
    # @show m
    if !isnothing(m)
        kind  = m[1]
        type  = m[2]
        name  = m[3]
        dims  = m[5]
        index = m[8]

        # @show dims

        data_struct[state.collection][name] = Attribute(
            name,
            PMD._is_vector(kind),
            PMD._get_type(type),
            isnothing(dims) ? 0 : count(",", dims) + 1,
            something(index, ""),
            # interval,
        )
    end

    return state
end

function _parse_pmd!(data_struct, FILE, MODEL_CLASS_MAP)
    # PSRThermalPlant => GerMax => Attr
    @assert FILE[end-3:end] == ".pmd"
    if !isfile(FILE)
        error("File not found: $FILE")
    end
    inside_model = false
    current_class = ""
    total_merges = 0
    for line in readlines(FILE)
        clean_line = strip(replace(line, '\t' => ' '))
        if startswith(clean_line, "//") || isempty(clean_line)
            continue
        end
        if inside_model
            if startswith(clean_line, "END_MODEL")
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
            elseif length(words) >= 2
                if words[1] == "MERGE_MODEL"
                    @assert startswith(words[2], "MODL:")
                    @assert length(words[2]) >= 6
                    total_merges += 1
                    for i in 1:_MAX_MERGE
                        if !haskey(data_struct[current_class], "_MERGE_$i")
                            data_struct[current_class]["_MERGE_$i"] = Attribute(
                                MODEL_CLASS_MAP[words[2][6:end]],
                                false,
                                DataType,
                                0,
                                "",
                            )
                            break
                        end
                        if i == _MAX_MERGE
                            println(
                                "Number of merges in class $current_class exceeded the maximum of $(_MAX_MERGE)",
                            )
                        end
                    end
                end
            end
        else
            BEGIN = "DEFINE_MODEL MODL:"
            if startswith(clean_line, BEGIN)
                clean_line
                model_name = strip(clean_line[(length(BEGIN)+1):end])
                if haskey(MODEL_CLASS_MAP, model_name)
                    current_class = MODEL_CLASS_MAP[model_name]
                    inside_model = true
                    data_struct[current_class] = Dict{String,Attribute}()
                    # default attributes tha belong to "all classes"
                    data_struct[current_class]["name"] =
                        Attribute("name", false, String, 0, "")
                    data_struct[current_class]["code"] =
                        Attribute("code", false, Int32, 0, "")
                    data_struct[current_class]["AVId"] =
                        Attribute("AVId", false, String, 0, "")
                    if current_class == "PSRSystem"
                        data_struct[current_class]["id"] =
                            Attribute("id", false, String, 0, "")
                    end
                    continue
                end
            end
        end
    end
    # apply merges
    for class_name in keys(data_struct)
        _merge_class(data_struct, class_name, String[class_name])
    end
    # delete temporary classes (starting with "_")
    for class_name in keys(data_struct)
        if startswith(class_name, "_")
            delete!(data_struct, class_name)
        end
    end
    return data_struct
end

function _merge_class(data_struct, class_name, merge_path)
    class = data_struct[class_name]
    for i in 1:_MAX_MERGE
        if haskey(class, "_MERGE_$i")
            to_merge = class["_MERGE_$i"].name
            if to_merge in merge_path
                error("merge cycle found")
            end
            _merge_path = deepcopy(merge_path)
            push!(_merge_path, to_merge)
            _merge_class(data_struct, to_merge, _merge_path)
            delete!(class, "_MERGE_$i")
            for (k, v) in data_struct[to_merge]
                if k in ["name", "code", "AVId"] # because we are forcing all these
                    continue
                end
                if haskey(class, k)
                    error(
                        "Class $class already has attribute $k being merged from $to_merge",
                    )
                end
                class[k] = v
            end
        end
    end
    return nothing
end

function _load_model!(
    data_struct::DataStruct,
    filepath::AbstractString,
    loaded_files::Set{String},
    model_template::ModelTemplate,
)
    if !isfile(filepath)
        error("'$filepath' is not a valid file")
    end

    if last(splitext(filepath)) != ".pmd"
        error("'$filepath' should contain a .pmd extension")
    end

    filename = basename(filepath)

    if !in(filename, loaded_files)
        _parse_pmd!(data_struct, filepath, model_template)

        push!(loaded_files, filename)
    end

    return nothing
end

function _load_model!(
    data_struct::DataStruct,
    path_pmds::AbstractString,
    files::Vector{String},
    loaded_files::Set{String},
    model_template::ModelTemplate,
)
    if !isempty(files)
        for filepath in files
            _load_model!(data_struct, filepath, loaded_files, model_template)
        end
    else
        if !isdir(path_pmds)
            error("'$path_pmds' is not a valid directory")
        end

        for filepath in readdir(path_pmds; join = true)
            if isfile(filepath) && last(splitext(filepath)) == ".pmd"
                _load_model!(data_struct, filepath, loaded_files, model_template)
            end
        end
    end

    return nothing
end

function load_model(path_pmds::AbstractString, files::Vector{String}, model_template::ModelTemplate)
    data_struct = DataStruct()
    loaded_files = Set{String}()

    _load_model!(data_struct, path_pmds, files, loaded_files, model_template)

    return data_struct, loaded_files
end

end
