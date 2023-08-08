function read_write_binary_block()
    BLOCKS = 3
    SCENARIOS = 5
    STAGES = 12
    INITIAL_STAGE = 4

    FILE_PATH = joinpath(".", "example_21")

    for stage_type in [PSRI.STAGE_MONTH, PSRI.STAGE_WEEK, PSRI.STAGE_DAY]
        iow = PSRClassesInterface.open(
            PSRClassesInterface.OpenBinary.Writer,
            FILE_PATH;
            blocks = BLOCKS,
            scenarios = SCENARIOS,
            stages = STAGES,
            agents = ["X", "Y", "Z"],
            unit = "MW",
            # optional:
            initial_stage = INITIAL_STAGE,
            initial_year = 2006,
            stage_type = stage_type,
        )

        for t in 1:STAGES, s in 1:SCENARIOS, b in 1:BLOCKS
            X = t + s + 0.0
            Y = s - t + 0.0
            Z = t + s + b * 100.0
            PSRClassesInterface.write_registry(iow, [X, Y, Z], t, s, b)
        end

        # Finaliza gravacao
        PSRClassesInterface.close(iow)

        ior = PSRI.open(
            PSRI.OpenBinary.Reader,
            FILE_PATH;
            use_header = false,
        )

        @test PSRI.max_stages(ior) == STAGES
        @test PSRI.max_scenarios(ior) == SCENARIOS
        @test PSRI.max_blocks(ior) == BLOCKS
        @test PSRI.stage_type(ior) == stage_type
        @test PSRI.initial_stage(ior) == INITIAL_STAGE
        @test PSRI.initial_year(ior) == 2006
        @test PSRI.data_unit(ior) == "MW"
        @test PSRI.is_hourly(ior) == false

        # obtem número de colunas
        @test PSRI.agent_names(ior) == ["X", "Y", "Z"]

        for t in 1:STAGES, s in 1:SCENARIOS, b in 1:BLOCKS
            @test PSRI.current_stage(ior) == t
            @test PSRI.current_scenario(ior) == s
            @test PSRI.current_block(ior) == b
            X = t + s
            Y = s - t
            Z = t + s + b * 100
            ref = [X, Y, Z]
            for agent in 1:3
                @test ior[agent] == ref[agent]
            end
            PSRI.next_registry(ior)
        end

        PSRI.close(ior)
        ior = nothing

        @test_throws ErrorException PSRI.convert_file(
            PSRI.OpenBinary.Reader,
            PSRI.OpenBinary.Writer,
            FILE_PATH,
        )
    end

    rm(FILE_PATH * ".bin")
    rm(FILE_PATH * ".hdr")

    return
end

function read_write_binary_block_single_binary()
    BLOCKS = 3
    SCENARIOS = 5
    STAGES = 12
    INITIAL_STAGE = 4

    FILE_PATH = joinpath(".", "example_2")

    for stage_type in [PSRI.STAGE_MONTH, PSRI.STAGE_WEEK, PSRI.STAGE_DAY]
        iow = PSRClassesInterface.open(
            PSRClassesInterface.OpenBinary.Writer,
            FILE_PATH;
            blocks = BLOCKS,
            scenarios = SCENARIOS,
            stages = STAGES,
            agents = ["X", "Y", "Z"],
            unit = "MW",
            # optional:
            initial_stage = INITIAL_STAGE,
            initial_year = 2006,
            stage_type = stage_type,
            single_binary = true,
        )
        @test first(splitext(PSRI.file_path(iow))) == FILE_PATH

        for t in 1:STAGES, s in 1:SCENARIOS, b in 1:BLOCKS
            X = t + s + 0.0
            Y = s - t + 0.0
            Z = t + s + b * 100.0
            PSRClassesInterface.write_registry(iow, [X, Y, Z], t, s, b)
        end

        # Finaliza gravacao
        PSRClassesInterface.close(iow)

        ior = PSRClassesInterface.open(
            PSRClassesInterface.OpenBinary.Reader,
            FILE_PATH;
            use_header = false,
            single_binary = true,
            verbose_header = true,
        )
        @test first(splitext(PSRI.file_path(ior))) == FILE_PATH

        @test PSRI.max_stages(ior)    == STAGES
        @test PSRI.max_scenarios(ior) == SCENARIOS
        @test PSRI.max_blocks(ior)    == BLOCKS
        @test PSRI.stage_type(ior)    == stage_type
        @test PSRI.initial_stage(ior) == INITIAL_STAGE
        @test PSRI.initial_year(ior)  == 2006
        @test PSRI.data_unit(ior)     == "MW"
        @test PSRI.is_hourly(ior)     == false

        # obtem número de colunas
        @test PSRI.agent_names(ior) == ["X", "Y", "Z"]

        for t in 1:STAGES, s in 1:SCENARIOS, b in 1:BLOCKS
            @test PSRI.current_stage(ior) == t
            @test PSRI.current_scenario(ior) == s
            @test PSRI.current_block(ior) == b
            X = t + s
            Y = s - t
            Z = t + s + b * 100
            ref = [X, Y, Z]
            for agent in 1:3
                @test ior[agent] == ref[agent]

                ior[agent] != ref[agent] && error("($t, $s, $b)")
            end
            PSRI.next_registry(ior)
        end

        PSRI.close(ior)
        ior = nothing

        @test_throws ErrorException PSRI.convert_file(
            PSRI.OpenBinary.Reader,
            PSRI.OpenBinary.Writer,
            FILE_PATH,
        )
    end

    rm(FILE_PATH * ".dat")

    return
end

read_write_binary_block()
read_write_binary_block_single_binary()
