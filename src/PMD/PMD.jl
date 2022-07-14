module PMD

import Dates

"""
    Attribute
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

const _MODEL_TO_CLASS = Dict(
    "SDDP_V10.2_ConfiguracaoEstudo" => "PSRStudy",
    "SDDP_V10.2_Sistema" => "PSRSystem",
    "SDDP_V10.2_Area" => "PSRArea",
    "SDDP_V10.2_CargaBarra" => "PSRLoad",
    "SDDP_V10.2_Demanda" => "PSRDemand",
    "SDDP_V10.2_SegmentoDemanda" => "PSRDemandSegment",
    "SDDP_V10.2_Interconnection" => "PSRInterconnection",
    "SDDP_V10.2_Bus" => "PSRBus",
    "SDDP_V10.2_Circuito" => "PSRSerie",
    # "SDDP_V10.SDDP_Transformador" => "PSRSerie",
    "SDDP_V10.2_Termica" => "PSRThermalPlant",
    "SDDP_V10.2_Hidro" => "PSRHydroPlant",
    "SDDP_V10.2_Gnd" => "PSRGndPlant",
    # "SDDP_PostoMedicaoGnd" => "PSRGndGaugingStation",
    # "SDDP_Csp" => "PSRCsp",
    "SDDP_V10.2_Combustivel" => "PSRFuel",
    # "SDDP_V10.2_Manutencao" => "PSRMaintenanceData",
    # "SDDP_V10.2_RestricaoGeracao" => "PSRGenerationConstraintData",
    # "SDDP_V10.2_ReservaGeracao" => "PSRReserveGenerationConstraintData",
    # "SDDP_V10.2_ConexaoHidreletrica" => "PSRHydrologicalNetwork",
    "SDDP_V10.2_PostoHidrologico" => "PSRGaugingStation",
    "SDDP_V10.2_DCLink" => "PSRLinkDC",
    # "SDDP_V10.2_NoGas" => "PSRGasNode",
    # "SDDP_V10.2_Gasoduto" => "PSRGasPipeline",
    "SDDP_V10.2_Bateria" => "PSRBattery",
    "SDDP_ConsumoCombustivel" => "PSRFuelConsumption",
    "SDDP_V10.2_InjecaoPotencia" => "PSRPowerInjection",
    "SDDP_ContratoCombustivel" => "PSRFuelContract",
    "SDDP_ReservatorioCombustivel" => "PSRFuelReservoir",
    "SDDP_RestricaoSomaInterconexao" => "PSRInterconnectionSumData",
    "SDDP_RestricaoSomaCircuito" => "PSRCircuitSumData",
    "SDDP_CicloCombinadoTermica" => "PSRThermalCombinedCycle",
    "SDDP_EmissaoGas" => "PSRGasEmission",
    # "SDDP_ConjuntoReservatorios" => "??",
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
    else
        error("Type $str no known")
    end
end

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
                    # default attributes tha belong to "all classes"
                    data_struct[current_class]["name"] = Attribute(
                        "name", false, String, 0, "")
                    data_struct[current_class]["code"] = Attribute(
                        "code", false, Int32, 0, "")
                    data_struct[current_class]["AVId"] = Attribute(
                        "code", false, String, 0, "")
                    continue
                end
            end
        end
    end
    return data_struct
end

function _load_model!(
    data_struct,
    path_pmds::AbstractString,
    files::Vector{String},
    FILES_ADDED::Set{String},
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

function load_model(path_pmds::AbstractString, files::Vector{String})
    data_struct = DataStruct()
    files_added = Set{String}()
    _load_model!(
        data_struct,
        path_pmds,
        files,
        files_added,
    )
    return data_struct, files_added
end

end
