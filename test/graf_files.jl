function test_graf()
    temp_path = joinpath(tempdir(), "PSRI_graf")
    graf_path = joinpath(temp_path,"caso_graf")

    mkpath(temp_path)

    AGENTS = ["X", "Y", "Z"]
    STAGES = 12
    SCENARIOS = 10
    BLOCKS = 3

    io = PSRI.open(
        PSRI.OpenBinary.Writer,
        graf_path,
        blocks = BLOCKS,
        scenarios = SCENARIOS,
        stages = STAGES,
        agents = AGENTS,
        unit = "MW",
        initial_stage = 1,
        initial_year = 2006,
    )

    for estagio = 1:STAGES, serie = 1:SCENARIOS, bloco = 1:BLOCKS
        X = estagio + serie + 0.
        Y = serie - estagio + 0.
        Z = estagio + serie + bloco * 100.
        PSRI.write_registry(
            io,
            [X, Y, Z] .+ 1,
            estagio,
            serie,
            bloco
        )
    end

    PSRI.close(io)

    data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)
    
    PSRI.create_element!(data, "PSRDemandSegment", "name" => "X")
    PSRI.create_element!(data, "PSRDemandSegment", "name" => "Y")
    PSRI.create_element!(data, "PSRDemandSegment", "name" => "Z")


    PSRI.link_series_to_file(
        data, 
        "PSRDemandSegment", 
        "HourDemand", 
        "name",
        joinpath(graf_path)
    )

    PSRI.write_data(data)

    @test PSRI.has_graf_file(data, "PSRDemandSegment")
    @test PSRI.has_graf_file(data, "PSRDemandSegment", "HourDemand")
    @test !(PSRI.has_graf_file(data, "PSRDemandSegment", "Random"))

    graf_table = PSRI.get_graf_series(
        data,
        "PSRDemandSegment",
        "HourDemand";
        # use_header = false
        header = ["X","Y","Z"]
    )
 
    column_names = [:stage, :series, :block, Symbol("X"), Symbol("Y"), Symbol("Z")]

    @test sort(PSRI.Tables.columnnames(graf_table)) == sort(column_names)
    @test haskey(graf_table, Symbol("X"))

    data_copy = PSRI.initialize_study(PSRI.OpenInterface(); data_path = temp_path)

    @test PSRI.has_graf_file(data_copy, "PSRDemandSegment")
    @test PSRI.has_graf_file(data_copy, "PSRDemandSegment", "HourDemand")
    @test !(PSRI.has_graf_file(data_copy, "PSRDemandSegment", "Random"))

    graf_table_copy = PSRI.get_graf_series(
        data_copy,
        "PSRDemandSegment",
        "HourDemand";
        use_header = false
    )

    @test graf_table == graf_table_copy
    @test PSRI.Tables.getcolumn(graf_table, "X") == PSRI.Tables.getcolumn(graf_table_copy, "X")
    @test PSRI.Tables.getcolumn(graf_table, 2) == PSRI.Tables.getcolumn(graf_table_copy, 2)
    
end


function test_graf2()
    temp_path = joinpath(tempdir(), "PSRI_graf2")
    graf_path = joinpath(temp_path,"caso_graf")

    mkpath(temp_path)

    AGENTS = ["X", "Y", "Z"]
    STAGES = 12
    SCENARIOS = 10
    BLOCKS = 3

    io = PSRI.open(
        PSRI.OpenBinary.Writer,
        graf_path,
        blocks = BLOCKS,
        scenarios = SCENARIOS,
        stages = STAGES,
        agents = AGENTS,
        unit = "MW",
        initial_stage = 1,
        initial_year = 2023,
    )

    for estagio = 1:STAGES, serie = 1:SCENARIOS, bloco = 1:BLOCKS
        X = estagio*5.0
        Y = estagio*3.0
        Z = estagio*7.0
        PSRI.write_registry(
            io,
            [X, Y, Z],
            estagio,
            serie,
            bloco
        )
    end

    PSRI.close(io)

    data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)
    
    @show data.mapper

    PSRI.create_element!(data, "PSRDemandSegment", "name" => "X")
    PSRI.create_element!(data, "PSRDemandSegment", "name" => "Y")
    PSRI.create_element!(data, "PSRDemandSegment", "name" => "Z")


    PSRI.link_series_to_file(
        data, 
        "PSRDemandSegment", 
        "HourDemand", 
        "name",
        joinpath(graf_path)
    )

    PSRI.write_data(data)

    vec1 = PSRI.mapped_vector(
        data, 
        "PSRDemandSegment", 
        "HourDemand",
        Float64
    )

    vec2 = PSRI.mapped_vector(
        data, 
        "PSRDemandSegment", 
        "HourDemand",
        Float64,
        filters = ["test_filter"]
    )

    vec1_cpy = vec1
    @test vec1 == vec2

    PSRI.go_to_block(data, 2)
    PSRI.go_to_stage(data, 3)
    PSRI.go_to_scenario(data, 10)

    @show vec1
    @show vec2
    PSRI.update_vectors!(data, "test_filter")
    
    
    @test vec1 == vec1_cpy
    @test vec1 != vec2
    
    PSRI.update_vectors!(data)

    @test vec1 == vec1_cpy
end



test_graf()
test_graf2()