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


function test_api2() # Tests creating study and element
    temp_path = joinpath(tempdir(), "PSRI")
    json_path = joinpath(temp_path, "psrclasses.json")

    mkpath(temp_path)

    data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)

    index = PSRI.create_element!(data,"PSRThermalPlant","ShutDownCost"=>1.0)

    PSRI.write_data(data)

    parm =  PSRI.get_parm(data, "PSRThermalPlant", "ShutDownCost", 1, Float64)
    @test index isa Integer
    @test parm isa Float64

end

function test_api3() # Tests creating study and wrong collection
    temp_path = joinpath(tempdir(), "PSRI")
    json_path = joinpath(temp_path, "psrclasses.json")

    mkpath(temp_path)

    data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)

    try
        PSRI.create_element!(data,"RandomCollection123","ShutDownCost"=>1.0)
    catch error
        buf = IOBuffer()
        showerror(buf, error)
        message = String(take!(buf))
        @test message == "Collection 'RandomCollection123' is not available for this study"
    end

end

function test_api4() # Tests set_related!() and set_vector_related!() methods
    temp_path = joinpath(tempdir(), "PSRI")
    json_path = joinpath(temp_path, "psrclasses.json")

    mkpath(temp_path)

    data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)

    index1 = PSRI.create_element!(data,"PSRThermalPlant","ShutDownCost"=>1.0)
    index2 = PSRI.create_element!(data,"PSRThermalPlant","ShutDownCost"=>2.0)
    index3 = PSRI.create_element!(data,"PSRSystem")
    index4 = PSRI.create_element!(data,"PSRFuel")
    index5 = PSRI.create_element!(data,"PSRFuel")
    index6 = PSRI.create_element!(data,"PSRFuel")

    try
        PSRI.set_related!(data, "PSRThermalPlant", "PSRThermalPlant", index1, index2)
    catch error
        buf = IOBuffer()
        showerror(buf, error)
        message = String(take!(buf))
        @test message == "No relation from PSRThermalPlant to PSRThermalPlant with type RELATION_1_TO_1 \nAvailable relations from PSRThermalPlant are: \nTuple{String, PSRClassesInterface.RelationType}[(\"PSRSystem\", PSRClassesInterface.RELATION_1_TO_1), (\"PSRFuel\", PSRClassesInterface.RELATION_1_TO_N)]"
    end

    PSRI.set_related!(data, "PSRThermalPlant", "PSRSystem", index1, index3, relation_type = PSRI.RELATION_1_TO_1)
    map = PSRI.get_map(data, "PSRThermalPlant", "PSRSystem")
    @test map == [1,0]

    PSRI.set_vector_related!(data, "PSRThermalPlant", "PSRFuel", index1, [index4,index5,index6])
    map_vec = PSRI.get_vector_map(data,"PSRThermalPlant", "PSRFuel")
    @test map_vec == [[1,2,3],[]]


    PSRI.write_data(data)
end

test_api(PATH_CASE_0)
test_api2() 
test_api3()
test_api4()
