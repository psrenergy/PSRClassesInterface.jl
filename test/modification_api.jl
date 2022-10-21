function test_api(data_path::String)
    temp_path = joinpath(tempdir(), "PSRCI")
    json_path = joinpath(temp_path, "psrclasses.json")

    mkpath(temp_path)

    src_data = PSRI.initialize_study(PSRI.OpenInterface(); data_path = data_path)
    raw_data = PSRI._raw(src_data)

    PSRI.write_data(src_data, json_path)

    dest_data = PSRI.initialize_study(PSRI.OpenInterface(); data_path = temp_path)

    @test PSRI._raw(dest_data) == raw_data

    # set_parm!
    parm_data = Dict(
        "PSRThermalPlant" => ["ComT" => Int32(33)],
        # TODO: Add more test cases later, as in:
        #   "PSRClass" => ["attribute" => value...]
    )

    for (collection, parm_list) in parm_data
        for (attribute, new_value) in parm_list
            old_value = PSRI.get_parm(src_data, collection, attribute, 1, Int32)
            @test old_value != new_value
            PSRI.set_parm!(src_data, collection, attribute, 1, new_value)
            value_set = PSRI.get_parm(src_data, collection, attribute, 1, Int32)
            @test new_value == value_set
        end
    end

    # set_vector!
    vector_data = Dict(
        "PSRThermalPlant" => ["Data" => Dates.Date.(["1900-01-02"])],
        # TODO: Add more test cases later, as in:
        #   "PSRClass" => ["attribute" => [value...]...]
    )

    for (collection, vector_list) in vector_data
        for (attribute, new_value) in vector_list
            old_value = PSRI.get_vector(src_data, collection, attribute, 1, Dates.Date)
            @test old_value != new_value
            PSRI.set_vector!(src_data, collection, attribute, 1, new_value)
            value_set = PSRI.get_vector(src_data, collection, attribute, 1, Dates.Date)
            @test new_value == value_set
        end
    end

    # set_series!
    series_data = Dict(
        "PSRThermalPlant" => [
            "Data" => Dict{String,Vector}(
                "GerMin" => [0.0, 1.0],
                "GerMax" => [888.0, 777.0],
                "O&MCost" => [0.0, 1.0],
                "IH" => [0.0, 0.0],
                "ICP" => [0.0, 0.0],
                "Data" => Dates.Date.(["1900-01-01", "1900-01-02"]),
                "CoefE" => [1.0, 2.0],
                "CTransp" => [0.0, 1.0],
                "PotInst" => [888.0, 777.0],
                "Existing" => Int32[0, 0],
                "sfal" => Int32[0, 1],
                "NGas" => Int32[0, 0],
                "NAdF" => Int32[0, 0],
                "Unidades" => Int32[1, 1],
                "StartUp" => [0.0, 2.0],
            ),
        ],
        # TODO: Add more test cases later, as in:
        #   "PSRClass" => [
        #       "index_attr" => Dict{String, Vector}(
        #           "attribute" => [value...]...
        #       )...
        #   ]
    )

    for (collection, series_list) in series_data
        for (attribute, new_value) in series_list
            old_value = PSRI.get_series(src_data, collection, attribute, 1)
            @test old_value != new_value
            PSRI.set_series!(src_data, collection, attribute, 1, new_value)
            value_set = PSRI.get_series(src_data, collection, attribute, 1)
            @test new_value == value_set
        end
    end
end


function test_api2() # Tests creating study
    temp_path = joinpath(tempdir(), "PSRI")
    json_path = joinpath(temp_path, "psrclasses.json")

    mkpath(temp_path)

    data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)

    index = PSRI.create_element!(data,"PSRThermalPlant")
    index = PSRI.create_element!(data,"PSRBus")
    index = PSRI.create_element!(data,"PSRSerie")
    index = PSRI.create_element!(data,"PSRSystem")
    index = PSRI.create_element!(data,"PSRArea")
    index = PSRI.create_element!(data,"PSRLoad")
    index = PSRI.create_element!(data,"PSRFuelConsumption")
    index = PSRI.create_element!(data,"PSRGndGaugingStation")
    index = PSRI.create_element!(data,"PSRHydroPlant")
    index = PSRI.create_element!(data,"PSRGndPlant")
    index = PSRI.create_element!(data,"PSRInterconnection")
    index = PSRI.create_element!(data,"PSRGaugingStation")
    index = PSRI.create_element!(data,"PSRDemand")
    
    # index = PSRI.create_element!(data,"PSRHydrologicalPlantConnection")
    # index = PSRI.create_element!(data,"PSRFuel")
    # index = PSRI.create_element!(data,"PSRGenerator")
    # index = PSRI.create_element!(data,"PSRNetworkDC")
    # index = PSRI.create_element!(data,"PSRReservoirSet")
    # index = PSRI.create_element!(data,"PSRBattery")
    # index = PSRI.create_element!(data,"PSRTransformer")
    # index = PSRI.create_element!(data,"PSRGasEmission")
    # index = PSRI.create_element!(data,"PSRGenerationConstraintData")
    # index = PSRI.create_element!(data,"PSRHydrologicalPlantNetwork")
    # index = PSRI.create_element!(data,"PSRInterconnectionSumData")
    # index = PSRI.create_element!(data,"PSRHydrologicalNetwork")
    # index = PSRI.create_element!(data,"PSRNetwork")
    # index = PSRI.create_element!(data,"PSRElectrificationNetwork")
    # index = PSRI.create_element!(data,"PSRDemandSegment")
    # index = PSRI.create_element!(data,"PSRInterconnectionNetwork")
    # index = PSRI.create_element!(data,"PSRGasNetwork")
    # index = PSRI.create_element!(data,"PSRReserveGenerationConstraintData")



    PSRI.write_data(data)

    @test index isa Integer

end

test_api(PATH_CASE_0)
test_api2() 
