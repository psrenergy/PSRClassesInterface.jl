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

    rm(FILE_PATH * ".bin")
    rm(FILE_PATH * ".hdr")
    rm(FILE_PATH_2 * ".bin")
    rm(FILE_PATH_2 * ".hdr")
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
        FILE_PATH,
    )

    @test data == PSRI.file_to_array(
        PSRI.OpenBinary.Reader,
        FILE_PATH,
    )

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

    rm(FILE_PATH * ".bin")
    rm(FILE_PATH * ".hdr")
    try
        rm(FILE_PATH * ".csv")
    catch
        println("Failed to remove $(FILE_PATH).csv")
    end

    return
end

test_file_to_array()