module PMD

import Dates

const _PMDS_BASE_PATH = joinpath(@__DIR__(), "pmds")

const _MODEL_TO_CLASS = Dict(
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

end
