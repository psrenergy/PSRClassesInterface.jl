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
            "Data"     => Dict{String,Vector}(
            "GerMin"   => Float64[0.0, 1.0],
            "GerMax"   => Float64[888.0, 777.0],
            "O&MCost"  => Float64[0.0, 1.0],
            "IH"       => Float64[0.0, 0.0],
            "ICP"      => Float64[0.0, 0.0],
            "Data"     => Dates.Date.(["1900-01-01", "1900-01-02"]),
            "CoefE"    => Float64[1.0, 2.0],
            "CTransp"  => Float64[0.0, 1.0],
            "PotInst"  => Float64[888.0, 777.0],
            "Existing" => Int32[0, 0],
            "sfal"     => Int32[0, 1],
            "NGas"     => Int32[0, 0],
            "NAdF"     => Int32[0, 0],
            "Unidades" => Int32[1, 1],
            "StartUp"  => Float64[0.0, 2.0],
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
            new_value_st = PSRI.SeriesTable(new_value)
            old_value_st = PSRI.get_series(src_data, collection, attribute, 1) # return SeriesTable
            @test old_value_st != new_value_st
            PSRI.set_series!(src_data, collection, attribute, 1, new_value_st)
            value_set = PSRI.get_series(src_data, collection, attribute, 1)
            @test new_value_st == value_set
            @test PSRI.Tables.getcolumn(new_value_st, 1) == PSRI.Tables.getcolumn(value_set, 1)
            @test PSRI.Tables.getcolumn(new_value_st, keys(new_value_st)[1]) == PSRI.Tables.getcolumn(value_set, keys(value_set)[1])
            @test PSRI.Tables.columnnames(new_value_st) == PSRI.Tables.columnnames(value_set)
        end
    end
end


function test_api2() # Tests creating study and element
    temp_path = joinpath(tempdir(), "PSRI_2")
    json_path = joinpath(temp_path, "psrclasses.json")

    mkpath(temp_path)

    data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)

    index = PSRI.create_element!(data,"PSRThermalPlant","ShutDownCost"=>1.0)

    PSRI.write_data(data)

    parm =  PSRI.get_parm(data, "PSRThermalPlant", "ShutDownCost", 1, Float64)
    summary = PSRI.summary(data)
    @test index isa Integer
    @test parm isa Float64
    @test ! isempty(summary)

end

function test_api3() # Tests creating study and wrong collection
    temp_path = joinpath(tempdir(), "PSRI_3")
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
    temp_path = joinpath(tempdir(), "PSRI_4")
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
        @test typeof(error) == ErrorException
    end

    PSRI.set_related!(data, "PSRThermalPlant", "PSRSystem", index1, index3, relation_type = PSRI.RELATION_1_TO_1)
    map = PSRI.get_map(data, "PSRThermalPlant", "PSRSystem")
    @test map == [1,0]

    PSRI.set_vector_related!(data, "PSRThermalPlant", "PSRFuel", index1, [index4,index5,index6])
    map_vec = PSRI.get_vector_map(data,"PSRThermalPlant", "PSRFuel")
    @test map_vec == [[1,2,3],[]]


    PSRI.write_data(data)


    data_copy = PSRI.initialize_study(PSRI.OpenInterface(), data_path = temp_path)

    map_copy = PSRI.get_map(data_copy, "PSRThermalPlant", "PSRSystem")
    @test map_copy == map

    map_vec_copy = PSRI.get_vector_map(data_copy,"PSRThermalPlant", "PSRFuel")
    @test map_vec_copy == map_vec

end

function test_api5() #tests get_element and _get_index_by_code for code
    temp_path = joinpath(tempdir(), "PSRI_5")
    json_path = joinpath(temp_path, "psrclasses.json")

    mkpath(temp_path)

    data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)

    index = PSRI.create_element!(data,"PSRBus","code"=> Int32(5))

    retrieved_index = PSRI._get_index_by_code(data,"PSRBus", 5)

    @test (index == retrieved_index)

    element = PSRI.get_element(data,"PSRBus", 5)

    @test element["code"] == 5
    
end

function test_api6() #tests set_related_by_code!
    temp_path = joinpath(tempdir(), "PSRI_6")
    json_path = joinpath(temp_path, "psrclasses.json")

    mkpath(temp_path)

    data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)

    index1 = PSRI.create_element!(data,"PSRBus","code"=> Int32(5))
    index2 = PSRI.create_element!(data,"PSRBus","code"=> Int32(6))
    index3 = PSRI.create_element!(data,"PSRLinkDC")

    PSRI.set_related_by_code!(data, "PSRLinkDC", "PSRBus", index3, 5, relation_type =  PSRI.RELATION_TO)
    PSRI.set_related_by_code!(data, "PSRLinkDC", "PSRBus", index3, 6, relation_type =  PSRI.RELATION_FROM)

    element = data.raw["PSRLinkDC"][index3]

    @test element["no1"] == 3
    @test element["no2"] == 2
    
end


function test_api7() #tests delete_element!
    temp_path = joinpath(tempdir(), "PSRI_7")
    json_path = joinpath(temp_path, "psrclasses.json")

    mkpath(temp_path)

    data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)

    index1 = PSRI.create_element!(data,"PSRBus","code"=> Int32(5))
    index2 = PSRI.create_element!(data,"PSRBus","code"=> Int32(6))
    index3 = PSRI.create_element!(data,"PSRBus","code"=> Int32(7))
    index4 = PSRI.create_element!(data,"PSRBus","code"=> Int32(8))

    PSRI.write_data(data)

    PSRI.delete_element!(data, "PSRBus", 3)
    PSRI.write_data(data)

    data_copy = PSRI.initialize_study(PSRI.OpenInterface(); data_path = temp_path)

    @test data_copy.raw["PSRBus"][3]["code"] == 8
    @test length(data_copy.raw["PSRBus"]) == 3
    @test !haskey(data_copy.data_index.index, 4)
    
end

function test_api8() #tests delete_relation!
    temp_path = joinpath(tempdir(), "PSRI_8")
    json_path = joinpath(temp_path, "psrclasses.json")

    mkpath(temp_path)

    data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)
   
    index1 = PSRI.create_element!(data,"PSRBus")
    index2 = PSRI.create_element!(data,"PSRBus")

    index3 = PSRI.create_element!(data,"PSRSerie")
    
    PSRI.set_related!(data, "PSRSerie", "PSRBus", index3, index1, relation_type = PSRI.RELATION_TO)
    PSRI.set_related!(data, "PSRSerie", "PSRBus", index3, index2, relation_type = PSRI.RELATION_FROM)
    
    PSRI.write_data(data)
    
    @test PSRI.has_relations(data, "PSRBus", index1)
    @test PSRI.has_relations(data, "PSRBus", index2)
    @test PSRI.has_relations(data, "PSRSerie", index3)

    @test PSRI.get_map(data, "PSRSerie", "PSRBus", relation_type = PSRI.RELATION_FROM) == [2]
    @test PSRI.get_map(data, "PSRSerie", "PSRBus", relation_type = PSRI.RELATION_TO) == [1]

    PSRI.delete_relation!(data, "PSRSerie", "PSRBus", index3, index1)
    PSRI.delete_relation!(data, "PSRSerie", "PSRBus", index3, index2)
    
    PSRI.write_data(data)
    
    data_copy = PSRI.initialize_study(PSRI.OpenInterface(); data_path = temp_path)

    @test !PSRI.has_relations(data_copy, "PSRBus", index1)
    @test !PSRI.has_relations(data_copy, "PSRBus", index2)
    @test !PSRI.has_relations(data_copy, "PSRSerie", index3)
    
    @test PSRI.get_map(data_copy, "PSRSerie", "PSRBus", relation_type = PSRI.RELATION_FROM) == [0]
    @test PSRI.get_map(data_copy, "PSRSerie", "PSRBus", relation_type = PSRI.RELATION_TO) == [0]
end

function test_api9() #tests delete_vector_relation!
    temp_path = joinpath(tempdir(), "PSRI_9")
    json_path = joinpath(temp_path, "psrclasses.json")

    mkpath(temp_path)

    data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)
   
    index1 = PSRI.create_element!(data,"PSRThermalPlant","ShutDownCost"=>1.0)
    index2 = PSRI.create_element!(data,"PSRFuel")
    index3 = PSRI.create_element!(data,"PSRFuel")
    index4 = PSRI.create_element!(data,"PSRFuel")

    PSRI.set_vector_related!(data, "PSRThermalPlant", "PSRFuel", index1, [index2,index3,index4])
    map_vec = PSRI.get_vector_map(data,"PSRThermalPlant", "PSRFuel")
    @test map_vec == Vector{Int32}[[1,2,3]]
    PSRI.write_data(data)

    PSRI.delete_vector_relation!(data, "PSRThermalPlant", "PSRFuel", index1, [index2,index3,index4])
    
    PSRI.write_data(data)

    data_copy = PSRI.initialize_study(PSRI.OpenInterface(); data_path = temp_path)
    
    map_vec_copy = PSRI.get_vector_map(data_copy,"PSRThermalPlant", "PSRFuel")
    @test map_vec_copy == Vector{Int32}[[]]
    

end

test_api(PATH_CASE_0)
test_api2() 
test_api3()
test_api4()
test_api5()
test_api6()
test_api7()
test_api8()
test_api9()