function test_graf()
    temp_path = joinpath(tempdir(), "PSRI")
    graf_path = joinpath(temp_path,"caso_graf")

    mkpath(temp_path)

    n_blocks = 2
    n_scenarios = 3
    n_stages = 4
    n_agents = 5

    time_series_data = rand(Float64, n_agents, n_blocks, n_scenarios, n_stages)

    PSRI.array_to_file(
        PSRI.OpenBinary.Writer,
        graf_path,
        time_series_data,
        agents = ["Agent 1", "Agent 2", "Agent 3", "Agent 4", "Agent 5"],
        unit = "MW";
        initial_stage = 3,
        initial_year = 2006,
    )

    data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)
    
    PSRI.create_element!(data, "PSRDemandSegment")
    PSRI.create_element!(data, "PSRDemandSegment")
    PSRI.create_element!(data, "PSRDemandSegment")
    PSRI.create_element!(data, "PSRDemandSegment")
    PSRI.create_element!(data, "PSRDemandSegment")

    PSRI.link_series_to_file(
        data, 
        "PSRDemandSegment", 
        "HourDemand", 
        "DataHourDemand",
        joinpath(graf_path)
    )

    PSRI.write_data(data)

    @test PSRI.has_graf_file(data, "PSRDemandSegment")
    @test PSRI.has_graf_file(data, "PSRDemandSegment", "HourDemand")
    @test !(PSRI.has_graf_file(data, "PSRDemandSegment", "Random"))

    graf_table = PSRI.get_series(
        data,
        "PSRDemandSegment",
        "HourDemand";
        use_header = false
    )
 
    column_names = [:stage, :series, :block, Symbol("Agent 2"), Symbol("Agent 1"), Symbol("Agent 3"), Symbol("Agent 4"), Symbol("Agent 5")]

    @test PSRI.Tables.columnnames(graf_table) == column_names
    @test haskey(graf_table, Symbol("Agent 1"))

    data_copy = PSRI.initialize_study(PSRI.OpenInterface(); data_path = temp_path)

    @test PSRI.has_graf_file(data_copy, "PSRDemandSegment")
    @test PSRI.has_graf_file(data_copy, "PSRDemandSegment", "HourDemand")
    @test !(PSRI.has_graf_file(data_copy, "PSRDemandSegment", "Random"))

    graf_table_copy = PSRI.get_series(
        data_copy,
        "PSRDemandSegment",
        "HourDemand";
        use_header = false
    )

    @test graf_table == graf_table_copy
    @test PSRI.Tables.getcolumn(graf_table, "Agent 1") == PSRI.Tables.getcolumn(graf_table_copy, "Agent 1")
    @test PSRI.Tables.getcolumn(graf_table, 2) == PSRI.Tables.getcolumn(graf_table_copy, 2)
    
end



test_graf()