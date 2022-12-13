module PMD

import Dates

"""
    Attribute

struct Attribute
    name::String
    is_vector::Bool
    type::DataType
    dim::Int
    index::String
end
"""
struct Attribute
    name::String
    is_vector::Bool
    type::DataType
    dim::Int
    index::String
    # interval::String
end

const DataStruct = Dict{String, Dict{String, Attribute}}

const _PMDS_BASE_PATH = joinpath(@__DIR__(), "pmds")

const PMD_MODEL_TEMPLATES_PATH = joinpath(@__DIR__(), "modeltemplates.sddp.json")

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
    "SDDP_V10.2_Currency"=>"PSRCurrency",
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
            elseif length(words) >= 2
                if words[1] == "MERGE_MODEL"
                    @assert startswith(words[2], "MODL:")
                    @assert length(words[2]) >= 6
                    total_merges += 1
                    for i in 1:_MAX_MERGE
                        if !haskey(data_struct[current_class], "_MERGE_$i")
                            data_struct[current_class]["_MERGE_$i"] = Attribute(
                                MODEL_CLASS_MAP[words[2][6:end]], false, DataType, 0, "")
                            break
                        end
                        if i == _MAX_MERGE
                            println("Number of merges in class $current_class exceeded the maximum of $(_MAX_MERGE)")
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
                    data_struct[current_class] = Dict{String, Attribute}()
                    # default attributes tha belong to "all classes"
                    data_struct[current_class]["name"] = Attribute(
                        "name", false, String, 0, "")
                    data_struct[current_class]["code"] = Attribute(
                        "code", false, Int32, 0, "")
                    data_struct[current_class]["AVId"] = Attribute(
                        "AVId", false, String, 0, "")
                    if current_class == "PSRSystem"
                        data_struct[current_class]["id"] = Attribute(
                            "id", false, String, 0, "")
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
                    error("Class $class already has attribute $k being merged from $to_merge")
                end
                class[k] = v
            end
        end
    end
    return nothing
end

function _load_model!(
    data_struct,
    path_pmds::AbstractString,
    files::Vector{String},
    FILES_ADDED::Set{String},
    model_class_map,
)
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
                _parse_pmd!(data_struct, file, model_class_map)
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
                    _parse_pmd!(data_struct, file, model_class_map)
                    push!(FILES_ADDED, name)
                end
            end
        end
    end
    return nothing
end

function load_model(
    path_pmds::AbstractString,
    files::Vector{String},
    model_class_map,
)
    data_struct = DataStruct()
    files_added = Set{String}()
    _load_model!(
        data_struct,
        path_pmds,
        files,
        files_added,
        model_class_map,
    )
    return data_struct, files_added
end

end
