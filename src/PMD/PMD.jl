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

const DataStruct = Dict{String, Dict{String, Attribute}}

include("model_template.jl")
include("relation_mapper.jl")

const _PMDS_BASE_PATH = joinpath(@__DIR__(), "pmds")

const PMD_MODEL_TEMPLATES_PATH =
    joinpath(@__DIR__(), "..", "json_metadata", "modeltemplates.sddp.json")

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

include("parser/parser.jl")

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
        parse!(filepath, data_struct, model_template)

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

function load_model(
    path_pmds::AbstractString,
    files::Vector{String},
    model_template::ModelTemplate,
)
    data_struct = DataStruct()
    loaded_files = Set{String}()

    _load_model!(data_struct, path_pmds, files, loaded_files, model_template)

    return data_struct, loaded_files
end

end
