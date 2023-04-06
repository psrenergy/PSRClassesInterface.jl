data = PSRI.initialize_study(
    PSRI.OpenInterface(),
    data_path = joinpath(".", "data", "case2")
)

@test 1 == PSRI.configuration_parameter(data, "BMAP", 2)
@test 1 == PSRI.configuration_parameter(data, "VALE", 1)
@test 0 == PSRI.configuration_parameter(data, "MNIT", 1)

@test PSRI.get_map(data, "PSRGaugingStation", "PSRGaugingStation") == Int32[0, 1]

@test PSRI.get_map(data, "PSRHydroPlant", "PSRHydroPlant", relation_type = PSRI.RELATION_TURBINE_TO) == Int32[2, 0]
@test PSRI.get_map(data, "PSRHydroPlant", "PSRHydroPlant", relation_type = PSRI.RELATION_SPILL_TO) == Int32[2, 0]
@test PSRI.get_map(data, "PSRHydroPlant", "PSRHydroPlant", relation_type = PSRI.RELATION_INFILTRATE_TO) == Int32[2, 0]
@test PSRI.get_map(data, "PSRHydroPlant", "PSRHydroPlant", relation_type = PSRI.RELATION_STORED_ENERGY_DONWSTREAM) == Int32[2, 0]

@test PSRI.get_map(data, "PSRInterconnection", "PSRSystem", relation_type = PSRI.RELATION_FROM) == Int32[1]
@test PSRI.get_map(data, "PSRInterconnection", "PSRSystem", relation_type = PSRI.RELATION_TO) == Int32[2]
@test_throws ErrorException PSRI.get_vector_map(data,"PSRThermalPlant", "PSRFuelConsumption"; relation_type = PSRI.RELATION_1_TO_N)

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


# reverse relations

# upstream turbining hydros
@test PSRI.get_reverse_vector_map(data, "PSRHydroPlant", "PSRHydroPlant", original_relation_type = PSRI.RELATION_TURBINE_TO) == Vector{Int32}[[], [1]]

# for each hydro - return its maintenance data
# both work for this one
@test PSRI.get_reverse_map(data, "PSRMaintenanceData", "PSRHydroPlant") == Int32[1, 0]
@test PSRI.get_reverse_vector_map(data, "PSRMaintenanceData", "PSRHydroPlant", original_relation_type = PSRI.RELATION_1_TO_1) == Vector{Int32}[[1], []]

# for each thermal - return all Gen Ctr it belongs
# might be many so it fails (in this case)
@test_throws ErrorException PSRI.get_map(data, "PSRGenerationConstraintData", "PSRThermalPlant")
