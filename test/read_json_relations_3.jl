data = PSRI.initialize_study(
    PSRI.OpenInterface(),
    data_path = joinpath(".", "data", "caso2")
)

@test PSRI.get_map(data, "PSRGaugingStation", "PSRGaugingStation") == Int32[0, 1]

@test PSRI.get_map(data, "PSRHydroPlant", "PSRHydroPlant", relation_type = PSRI.RELATION_TURBINE_TO) == Int32[2, 0]
@test PSRI.get_map(data, "PSRHydroPlant", "PSRHydroPlant", relation_type = PSRI.RELATION_SPILL_TO) == Int32[2, 0]
@test PSRI.get_map(data, "PSRHydroPlant", "PSRHydroPlant", relation_type = PSRI.RELATION_INFILTRATE_TO) == Int32[2, 0]
@test PSRI.get_map(data, "PSRHydroPlant", "PSRHydroPlant", relation_type = PSRI.RELATION_STORED_ENERGY_DONWSTREAM) == Int32[2, 0]

@test PSRI.get_map(data, "PSRInterconnection", "PSRSystem", relation_type = PSRI.RELATION_FROM) == Int32[1]
@test PSRI.get_map(data, "PSRInterconnection", "PSRSystem", relation_type = PSRI.RELATION_TO) == Int32[2]

@test PSRI.get_vector_map(data, "PSRInterconnectionSumData", "PSRInterconnection") == Vector{Int32}[[1]]

@test PSRI.get_vector_map(data, "PSRGenerationConstraintData", "PSRThermalPlant") == Vector{Int32}[[1, 3]]
@test PSRI.get_vector_map(data, "PSRGenerationConstraintData", "PSRHydroPlant") == Vector{Int32}[[2]]
@test PSRI.get_vector_map(data, "PSRGenerationConstraintData", "PSRGndPlant") == Vector{Int32}[[]]
@test PSRI.get_vector_map(data, "PSRGenerationConstraintData", "PSRBattery") == Vector{Int32}[[]]

@test PSRI.get_map(data, "PSRMaintenanceData", "PSRSystem") == Int32[1]
@test PSRI.get_map(data, "PSRMaintenanceData", "PSRThermalPlant") == Int32[0]
@test PSRI.get_map(data, "PSRMaintenanceData", "PSRHydroPlant") == Int32[1]
@test PSRI.get_map(data, "PSRMaintenanceData", "PSRGndPlant") == Int32[0]

@test PSRI.get_vector_map(data, "PSRReserveGenerationConstraintData", "PSRThermalPlant") == Vector{Int32}[[1, 2]]
@test PSRI.get_vector_map(data, "PSRReserveGenerationConstraintData", "PSRHydroPlant") == Vector{Int32}[[1]]
@test PSRI.get_vector_map(data, "PSRReserveGenerationConstraintData", "PSRGndPlant") == Vector{Int32}[[]]
@test PSRI.get_vector_map(data, "PSRReserveGenerationConstraintData", "PSRBattery") == Vector{Int32}[[]]

@test PSRI.get_vector_map(data, "PSRReserveGenerationConstraintData", "PSRThermalPlant", relation_type = PSRI.RELATION_BACKED) == Vector{Int32}[[]]
@test PSRI.get_vector_map(data, "PSRReserveGenerationConstraintData", "PSRHydroPlant", relation_type = PSRI.RELATION_BACKED) == Vector{Int32}[[]]
@test PSRI.get_vector_map(data, "PSRReserveGenerationConstraintData", "PSRGndPlant", relation_type = PSRI.RELATION_BACKED) == Vector{Int32}[[]]

@test PSRI.get_vector_map(data, "PSRReservoirSet", "PSRHydroPlant") == Vector{Int32}[[1, 2]]
