function test_graf()
    temp_path = joinpath(tempdir(), "PSRI")
    graf_path = joinpath(temp_path,"caso_graf")

    mkpath(temp_path)

    n_blocks = 2
    n_series = 3
    n_stages = 4
    n_agents = 5

    time_series_data = rand(Float64, n_agents, n_blocks, n_series, n_stages)

    PSRI.array_to_file(
        PSRI.OpenBinary.Writer,
        graf_path,
        time_series_data,
        agents = ["Agent X", "Agent Y", "Agent Z", "Agent K", "Agent P"],
        unit = "MW";
        initial_stage = 1,
        initial_year = 2006,
    )

    data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)
    
    PSRI.create_element!(data, "PSRDemandSegment", "name" => "Agent X")
    PSRI.create_element!(data, "PSRDemandSegment", "name" => "Agent Y")
    PSRI.create_element!(data, "PSRDemandSegment", "name" => "Agent Z")
    PSRI.create_element!(data, "PSRDemandSegment", "name" => "Agent K")
    PSRI.create_element!(data, "PSRDemandSegment", "name" => "Agent P")

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
        use_header = false
    )
 
    column_names = [:stage, :series, :block, Symbol("Agent X"), Symbol("Agent Y"), Symbol("Agent Z"), Symbol("Agent K"), Symbol("Agent P")]

    @test sort(PSRI.Tables.columnnames(graf_table)) == sort(column_names)
    @test haskey(graf_table, Symbol("Agent X"))

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
    @test PSRI.Tables.getcolumn(graf_table, "Agent X") == PSRI.Tables.getcolumn(graf_table_copy, "Agent X")
    @test PSRI.Tables.getcolumn(graf_table, 2) == PSRI.Tables.getcolumn(graf_table_copy, 2)
    
end



test_graf()