function rm_bin_hdr(file::String)
    rm(file * ".bin")
    rm(file * ".hdr")
end

function test_convert_twice()

    BLOCKS = 3
    SCENARIOS = 10
    STAGES = 12

    FILE_PATH = joinpath(".", "example_convert_1")
    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        FILE_PATH,
        blocks = BLOCKS,
        scenarios = SCENARIOS,
        stages = STAGES,
        agents = ["X", "Y", "Z"],
        unit = "MW",
        # optional:
        initial_stage = 1,
        initial_year = 2006,
    )

    for estagio = 1:STAGES, serie = 1:SCENARIOS, bloco = 1:BLOCKS
        X = estagio + serie + 0.
        Y = serie - estagio + 0.
        Z = estagio + serie + bloco * 100.
        PSRI.write_registry(
            iow,
            [X, Y, Z],
            estagio,
            serie,
            bloco
        )
    end

    # Finaliza gravacao
    PSRI.close(iow)

    PSRI.convert_file(
        PSRI.OpenBinary.Reader,
        PSRI.OpenCSV.Writer,
        FILE_PATH,
    )

    ior = PSRI.open(
        PSRI.OpenCSV.Reader,
        FILE_PATH,
        use_header = false
    )

    @test PSRI.max_stages(ior) == STAGES
    @test PSRI.max_scenarios(ior) == SCENARIOS
    @test PSRI.max_blocks(ior) == BLOCKS
    @test PSRI.stage_type(ior) == PSRI.STAGE_MONTH
    @test PSRI.initial_stage(ior) == 1
    @test PSRI.initial_year(ior) == 2006
    @test PSRI.data_unit(ior) == "MW"

    # obtem número de colunas
    @test PSRI.agent_names(ior) == ["X", "Y", "Z"]

    for estagio = 1:STAGES
        for serie = 1:SCENARIOS
            for bloco = 1:BLOCKS
                @test PSRI.current_stage(ior) == estagio
                @test PSRI.current_scenario(ior) == serie
                @test PSRI.current_block(ior) == bloco
                
                X = estagio + serie
                Y = serie - estagio
                Z = estagio + serie + bloco * 100
                ref = [X, Y, Z]
                
                for agent in 1:3
                    @test ior[agent] == ref[agent]
                end
                PSRI.next_registry(ior)
            end
        end
    end

    PSRI.close(ior)
    ior = nothing

    FILE_PATH_2 = joinpath(".", "example_convert_2")

    PSRI.convert_file(
        PSRI.OpenCSV.Reader,
        PSRI.OpenBinary.Writer,
        FILE_PATH,
        path_to = FILE_PATH_2,
    )

    ior = PSRI.open(
        PSRI.OpenBinary.Reader,
        FILE_PATH_2,
        use_header = false
    )

    @test PSRI.max_stages(ior) == STAGES
    @test PSRI.max_scenarios(ior) == SCENARIOS
    @test PSRI.max_blocks(ior) == BLOCKS
    @test PSRI.stage_type(ior) == PSRI.STAGE_MONTH
    @test PSRI.initial_stage(ior) == 1
    @test PSRI.initial_year(ior) == 2006
    @test PSRI.data_unit(ior) == "MW"

    # obtem número de colunas
    @test PSRI.agent_names(ior) == ["X", "Y", "Z"]

    for estagio = 1:STAGES
        for serie = 1:SCENARIOS
            for bloco = 1:BLOCKS
                @test PSRI.current_stage(ior) == estagio
                @test PSRI.current_scenario(ior) == serie
                @test PSRI.current_block(ior) == bloco
                X = estagio + serie
                Y = serie - estagio
                Z = estagio + serie + bloco * 100
                ref = [X, Y, Z]
                for agent in 1:3
                    @test ior[agent] == ref[agent]
                end
                PSRI.next_registry(ior)
            end
        end
    end

    PSRI.close(ior)

    rm_bin_hdr(FILE_PATH)
    rm_bin_hdr(FILE_PATH_2)
    try
        rm(FILE_PATH * ".csv")
    catch
        println("Failed to remove $(FILE_PATH).csv")
    end

    return
end

test_convert_twice()

function test_file_to_array()

    BLOCKS = 3
    SCENARIOS = 10
    STAGES = 12

    FILE_PATH = joinpath(".", "example_array_1")
    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        FILE_PATH,
        blocks = BLOCKS,
        scenarios = SCENARIOS,
        stages = STAGES,
        agents = ["X", "Y", "Z"],
        unit = "MW",
        # optional:
        initial_stage = 1,
        initial_year = 2006,
    )

    for estagio = 1:STAGES, serie = 1:SCENARIOS, bloco = 1:BLOCKS
        X = estagio + serie + 0.
        Y = serie - estagio + 0.
        Z = estagio + serie + bloco * 100.
        PSRI.write_registry(
            iow,
            [X, Y, Z],
            estagio,
            serie,
            bloco
        )
    end

    PSRI.close(iow)

    data, header = PSRI.file_to_array_and_header(
        PSRI.OpenBinary.Reader,
        FILE_PATH;
        use_header=false
    )

    data_order, header_order = PSRI.file_to_array_and_header(
        PSRI.OpenBinary.Reader,
        FILE_PATH;
        use_header=true,
        header=["Y", "Z", "X"]
    )

    @test data == PSRI.file_to_array(
        PSRI.OpenBinary.Reader,
        FILE_PATH;
        use_header=false
    )

    @test data_order == PSRI.file_to_array(
        PSRI.OpenBinary.Reader,
        FILE_PATH;
        use_header=true,
        header=["Y", "Z", "X"]
    )

    @test data_order[1] == data[2] # "Y"
    @test data_order[2] == data[3] # "Z"
    @test data_order[3] == data[1] # "X"

    PSRI.array_to_file(
        PSRI.OpenCSV.Writer,
        FILE_PATH,
        data,
        agents = header,
        unit = "MW",
        initial_year = 2006,
    )

    ior = PSRI.open(
        PSRI.OpenCSV.Reader,
        FILE_PATH,
        use_header = false
    )

    @test PSRI.max_stages(ior) == STAGES
    @test PSRI.max_scenarios(ior) == SCENARIOS
    @test PSRI.max_blocks(ior) == BLOCKS
    @test PSRI.stage_type(ior) == PSRI.STAGE_MONTH
    @test PSRI.initial_stage(ior) == 1
    @test PSRI.initial_year(ior) == 2006
    @test PSRI.data_unit(ior) == "MW"

    # obtem número de colunas
    @test PSRI.agent_names(ior) == ["X", "Y", "Z"]

    for estagio = 1:STAGES
        for serie = 1:SCENARIOS
            for bloco = 1:BLOCKS
                @test PSRI.current_stage(ior) == estagio
                @test PSRI.current_scenario(ior) == serie
                @test PSRI.current_block(ior) == bloco
                
                X = estagio + serie
                Y = serie - estagio
                Z = estagio + serie + bloco * 100
                ref = [X, Y, Z]
                
                for agent in 1:3
                    @test ior[agent] == ref[agent]
                end
                PSRI.next_registry(ior)
            end
        end
    end

    PSRI.close(ior)
    ior = nothing

    rm_bin_hdr(FILE_PATH)
    try
        rm(FILE_PATH * ".csv")
    catch
        println("Failed to remove $(FILE_PATH).csv")
    end

    return
end

test_file_to_array()

function create_time_series(
            filename::String;
            blocks::Int = 3,
            scenarios::Int = 10,
            stages::Int = 12,
            unit::String = "MW",
            initial_stage::Int = 1,
            initial_year::Int = 2006,
            agents::Vector{String} = ["X", "Y", "Z"],
            offset::Real = 0
        )

    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        filename,
        blocks = blocks,
        scenarios = scenarios,
        stages = stages,
        agents = agents,
        unit = unit,
        # optional:
        initial_stage = initial_stage,
        initial_year = initial_year,
    )

    n_agents = length(agents)
    registry_data = collect(1:n_agents) .+ offset

    for estagio = 1:stages, serie = 1:scenarios, bloco = 1:blocks
        PSRI.write_registry(
            iow,
            registry_data,
            estagio,
            serie,
            bloco
        )
    end
    PSRI.close(iow)
    return filename
end

function test_is_equal()
    # Case of equal time series
    file_1 = create_time_series(joinpath(".", "test_isequal_1"))
    file_2 = create_time_series(joinpath(".", "test_isequal_2"))
    ior1 = PSRI.open(PSRI.OpenBinary.Reader, file_1, use_header = false)
    ior2 = PSRI.open(PSRI.OpenBinary.Reader, file_2, use_header = false)
    @test PSRI.is_equal(ior1, ior2)
    PSRI.close(ior1)
    PSRI.close(ior2)
    rm_bin_hdr(file_1)
    rm_bin_hdr(file_2)

    # Cases with different sizes
    file_1 = create_time_series(joinpath(".", "test_isequal_1"); stages = 10)
    file_2 = create_time_series(joinpath(".", "test_isequal_2"); stages = 9)
    ior1 = PSRI.open(PSRI.OpenBinary.Reader, file_1, use_header = false)
    ior2 = PSRI.open(PSRI.OpenBinary.Reader, file_2, use_header = false)
    @test_throws ErrorException PSRI.is_equal(ior1, ior2)
    PSRI.close(ior1)
    PSRI.close(ior2)
    rm_bin_hdr(file_1)
    rm_bin_hdr(file_2)

    file_1 = create_time_series(joinpath(".", "test_isequal_1"); blocks = 3)
    file_2 = create_time_series(joinpath(".", "test_isequal_2"); blocks = 5)
    ior1 = PSRI.open(PSRI.OpenBinary.Reader, file_1, use_header = false)
    ior2 = PSRI.open(PSRI.OpenBinary.Reader, file_2, use_header = false)
    @test_throws ErrorException PSRI.is_equal(ior1, ior2)
    PSRI.close(ior1)
    PSRI.close(ior2)
    rm_bin_hdr(file_1)
    rm_bin_hdr(file_2)

    # Case with different units
    file_1 = create_time_series(joinpath(".", "test_isequal_1"); unit = "MW")
    file_2 = create_time_series(joinpath(".", "test_isequal_2"); unit = "MWm")
    ior1 = PSRI.open(PSRI.OpenBinary.Reader, file_1, use_header = false)
    ior2 = PSRI.open(PSRI.OpenBinary.Reader, file_2, use_header = false)
    @test_throws ErrorException PSRI.is_equal(ior1, ior2)
    PSRI.close(ior1)
    PSRI.close(ior2)
    rm_bin_hdr(file_1)
    rm_bin_hdr(file_2)

    # Case with different agents
    file_1 = create_time_series(joinpath(".", "test_isequal_1"); agents = ["W", "X", "Y", "Z"])
    file_2 = create_time_series(joinpath(".", "test_isequal_2"))
    ior1 = PSRI.open(PSRI.OpenBinary.Reader, file_1, use_header = false)
    ior2 = PSRI.open(PSRI.OpenBinary.Reader, file_2, use_header = false)
    @test_throws ErrorException PSRI.is_equal(ior1, ior2)
    PSRI.close(ior1)
    PSRI.close(ior2)
    rm_bin_hdr(file_1)
    rm_bin_hdr(file_2)

    # Case with different initial stages
    file_1 = create_time_series(joinpath(".", "test_isequal_1"); initial_stage = 1)
    file_2 = create_time_series(joinpath(".", "test_isequal_2"); initial_stage = 2)
    ior1 = PSRI.open(PSRI.OpenBinary.Reader, file_1, use_header = false)
    ior2 = PSRI.open(PSRI.OpenBinary.Reader, file_2, use_header = false)
    @test_throws ErrorException PSRI.is_equal(ior1, ior2)
    PSRI.close(ior1)
    PSRI.close(ior2)
    rm_bin_hdr(file_1)
    rm_bin_hdr(file_2)
 
    # Case with different initial years
    file_1 = create_time_series(joinpath(".", "test_isequal_1"); initial_stage = 1)
    file_2 = create_time_series(joinpath(".", "test_isequal_2"); initial_stage = 2)
    ior1 = PSRI.open(PSRI.OpenBinary.Reader, file_1, use_header = false)
    ior2 = PSRI.open(PSRI.OpenBinary.Reader, file_2, use_header = false)
    @test_throws ErrorException PSRI.is_equal(ior1, ior2)
    PSRI.close(ior1)
    PSRI.close(ior2)
    rm_bin_hdr(file_1)
    rm_bin_hdr(file_2)

    # Case with different data
    file_1 = create_time_series(joinpath(".", "test_isequal_1"); offset = 0)
    file_2 = create_time_series(joinpath(".", "test_isequal_2"); offset = 1)
    ior1 = PSRI.open(PSRI.OpenBinary.Reader, file_1, use_header = false)
    ior2 = PSRI.open(PSRI.OpenBinary.Reader, file_2, use_header = false)
    @test_throws ErrorException PSRI.is_equal(ior1, ior2)
    PSRI.close(ior1)
    PSRI.close(ior2)
    rm_bin_hdr(file_1)
    rm_bin_hdr(file_2)
end

test_is_equal()

function test_non_unique_agents()
    FILE_PATH = joinpath(".", "example_non_unique_agents")
    @test_throws ErrorException iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        FILE_PATH,
        blocks = BLOCKS,
        scenarios = SCENARIOS,
        stages = STAGES,
        agents = ["X", "Y", "X"],
        unit = "MW",
        # optional:
        initial_stage = 1,
        initial_year = 2006,
    )
    @test_throws ErrorException iow = PSRI.open(
        PSRI.OpenCSV.Writer,
        FILE_PATH,
        blocks = BLOCKS,
        scenarios = SCENARIOS,
        stages = STAGES,
        agents = ["X", "Y", "X"],
        unit = "MW",
        # optional:
        initial_stage = 1,
        initial_year = 2006,
    )
end