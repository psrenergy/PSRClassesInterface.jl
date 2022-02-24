function read_write_binary_block()
    BLOCKS = 3
    SCENARIOS = 5
    STAGES = 12
    INITIAL_STAGE = 4

    FILE_PATH = joinpath(".", "example_21")

    for _stage_type in [PSRI.STAGE_MONTH, PSRI.STAGE_WEEK, PSRI.STAGE_DAY]

        iow = PSRClassesInterface.open(
            PSRClassesInterface.OpenBinary.Writer,
            FILE_PATH,
            blocks = BLOCKS,
            scenarios = SCENARIOS,
            stages = STAGES,
            agents = ["X", "Y", "Z"],
            unit = "MW",
            # optional:
            initial_stage = INITIAL_STAGE,
            initial_year = 2006,
            stage_type = _stage_type
        )

        for t = 1:STAGES, s = 1:SCENARIOS, b = 1:BLOCKS
            X = t + s + 0.
            Y = s - t + 0.
            Z = t + s + b * 100.
            PSRClassesInterface.write_registry(iow, [X, Y, Z], t, s, b)
        end

        # Finaliza gravacao
        PSRClassesInterface.close(iow)

        ior = PSRI.open(
            PSRI.OpenBinary.Reader,
            FILE_PATH,
            use_header = false
        )

        @test PSRI.max_stages(ior) == STAGES
        @test PSRI.max_scenarios(ior) == SCENARIOS
        @test PSRI.max_blocks(ior) == BLOCKS
        @test PSRI.stage_type(ior) == _stage_type
        @test PSRI.initial_stage(ior) == INITIAL_STAGE
        @test PSRI.initial_year(ior) == 2006
        @test PSRI.data_unit(ior) == "MW"

        # obtem número de colunas
        @test PSRI.agent_names(ior) == ["X", "Y", "Z"]

        for t = 1:STAGES, s = 1:SCENARIOS, b = 1:BLOCKS
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

read_write_binary_block()

function read_write_binary_block_single_binary()
    BLOCKS = 3
    SCENARIOS = 5
    STAGES = 12
    INITIAL_STAGE = 4

    FILE_PATH = joinpath(".", "example_2")

    for _stage_type in [PSRI.STAGE_MONTH, PSRI.STAGE_WEEK, PSRI.STAGE_DAY]

        iow = PSRClassesInterface.open(
            PSRClassesInterface.OpenBinary.Writer,
            FILE_PATH,
            blocks = BLOCKS,
            scenarios = SCENARIOS,
            stages = STAGES,
            agents = ["X", "Y", "Z"],
            unit = "MW",
            # optional:
            initial_stage = INITIAL_STAGE,
            initial_year = 2006,
            stage_type = _stage_type,
            single_binary = true
        )

        for t = 1:STAGES, s = 1:SCENARIOS, b = 1:BLOCKS
            X = t + s + 0.
            Y = s - t + 0.
            Z = t + s + b * 100.
            PSRClassesInterface.write_registry(iow, [X, Y, Z], t, s, b)
        end

        # Finaliza gravacao
        PSRClassesInterface.close(iow)

        ior = PSRClassesInterface.open(
            PSRClassesInterface.OpenBinary.Reader,
            FILE_PATH,
            use_header = false,
            single_binary = true
        )

        @test PSRI.max_stages(ior) == STAGES
        @test PSRI.max_scenarios(ior) == SCENARIOS
        @test PSRI.max_blocks(ior) == BLOCKS
        @test PSRI.stage_type(ior) == _stage_type
        @test PSRI.initial_stage(ior) == INITIAL_STAGE
        @test PSRI.initial_year(ior) == 2006
        @test PSRI.data_unit(ior) == "MW"

        # obtem número de colunas
        @test PSRI.agent_names(ior) == ["X", "Y", "Z"]

        for t = 1:STAGES, s = 1:SCENARIOS, b = 1:BLOCKS
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

    rm(FILE_PATH * ".dat")

    return
end

read_write_binary_block_single_binary()