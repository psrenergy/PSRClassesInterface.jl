function read_write_binary_hourly()
    FILE_GERTER = joinpath(".", "gerter")

    STAGES = 2
    SCENARIOS = 2
    AGENTS = ["X", "Y", "Z"]
    UNIT = "MW"

    for stage_type in [PSRI.STAGE_MONTH, PSRI.STAGE_WEEK, PSRI.STAGE_DAY]

        gerter = PSRI.open(
            PSRI.OpenBinary.Writer,
            FILE_GERTER,
            is_hourly = true,
            scenarios = SCENARIOS,
            stages = STAGES,
            agents = AGENTS,
            unit = UNIT,
            # optional:
            initial_stage = 2,
            initial_year = 2006,
            stage_type = stage_type
        )

        for t = 1:STAGES, s = 1:SCENARIOS
            for b in 1:PSRI.blocks_in_stage(gerter, t)
                X = 10_000. * t + 1000. * s + b
                Y = b + 0.
                Z = 10. * t + s
                PSRI.write_registry(
                    gerter,
                    [X, Y, Z],
                    t,
                    s,
                    b
                )
            end
        end

        PSRI.close(gerter)

        ior = PSRI.open(
            PSRI.OpenBinary.Reader,
            FILE_GERTER,
            use_header = false,
        )

        @test PSRI.max_stages(ior) == STAGES
        @test PSRI.max_scenarios(ior) == SCENARIOS
        @test PSRI.max_blocks(ior) == (stage_type == PSRI.STAGE_MONTH ? 744 : PSRI.HOURS_IN_STAGE[stage_type])
        @test PSRI.stage_type(ior) == stage_type
        @test PSRI.initial_stage(ior) == 2
        @test PSRI.initial_year(ior) == 2006
        @test PSRI.data_unit(ior) == "MW"
        @test PSRI.agent_names(ior) == ["X", "Y", "Z"]
        @test PSRI.is_hourly(ior) == true
        @test PSRI.hour_discretization(ior) == 1

        for t = 1:1, s = 1:1
            @test PSRI.blocks_in_stage(ior, t) <= PSRI.max_blocks(ior)
            for b = 1:PSRI.blocks_in_stage(ior, t)
                @test PSRI.current_stage(ior) == t
                @test PSRI.current_scenario(ior) == s
                @test PSRI.current_block(ior) == b
                X = 10_000. * t + 1000. * s + b
                Y = b + 0.
                Z = 10. * t + s
                ref = [X, Y, Z]
                for agent in 1:3
                    @test ior[agent] == ref[agent]
                end
                PSRI.next_registry(ior)
            end
        end

        PSRI.close(ior)
        ior = nothing

    end

    rm(FILE_GERTER * ".bin")
    rm(FILE_GERTER * ".hdr")
    return
end

function read_write_binary_subhourly()
    FILE_GERTER = joinpath(".", "gerter")

    STAGES = 2
    SCENARIOS = 2
    AGENTS = ["X", "Y", "Z"]
    UNIT = "MW"

    for stage_type in [PSRI.STAGE_MONTH, PSRI.STAGE_WEEK, PSRI.STAGE_DAY]
        for hour_discretization in [2, 3, 4, 6, 12]
            gerter = PSRI.open(
                PSRI.OpenBinary.Writer,
                FILE_GERTER,
                is_hourly = true,
                hour_discretization = hour_discretization,
                scenarios = SCENARIOS,
                stages = STAGES,
                agents = AGENTS,
                unit = UNIT,
                # optional:
                initial_stage = 2,
                initial_year = 2006,
                stage_type = stage_type,
            )

            for t in 1:STAGES, s in 1:SCENARIOS
                for b in 1:PSRI.blocks_in_stage(gerter, t)
                    X = 10_000.0 * t + 1000.0 * s + b
                    Y = b + 0.0
                    Z = 10.0 * t + s
                    PSRI.write_registry(gerter, [X, Y, Z], t, s, b)
                end
            end

            PSRI.close(gerter)

            ior = PSRI.open(PSRI.OpenBinary.Reader, FILE_GERTER, use_header = false)

            @test PSRI.max_stages(ior) == STAGES
            @test PSRI.max_scenarios(ior) == SCENARIOS
            @test PSRI.max_blocks(ior) == hour_discretization * (stage_type == PSRI.STAGE_MONTH ? 744 : PSRI.HOURS_IN_STAGE[stage_type])
            @test PSRI.stage_type(ior) == stage_type
            @test PSRI.initial_stage(ior) == 2
            @test PSRI.initial_year(ior) == 2006
            @test PSRI.data_unit(ior) == "MW"
            @test PSRI.agent_names(ior) == ["X", "Y", "Z"]
            @test PSRI.is_hourly(ior) == true
            @test PSRI.hour_discretization(ior) == hour_discretization

            for t in 1:1, s in 1:1
                @test PSRI.blocks_in_stage(ior, t) <= PSRI.max_blocks(ior)
                for b in 1:PSRI.blocks_in_stage(ior, t)
                    @test PSRI.current_stage(ior) == t
                    @test PSRI.current_scenario(ior) == s
                    @test PSRI.current_block(ior) == b
                    X = 10_000.0 * t + 1000.0 * s + b
                    Y = b + 0.0
                    Z = 10.0 * t + s
                    ref = [X, Y, Z]
                    for agent in 1:3
                        @test ior[agent] == ref[agent]
                    end
                    PSRI.next_registry(ior)
                end
            end

            PSRI.close(ior)
            ior = nothing
        end
    end

    rm(FILE_GERTER * ".bin")
    rm(FILE_GERTER * ".hdr")
    return
end

function read_write_binary_hourly_single_binary()
    FILE_GERTER = joinpath(".", "gerter")

    STAGES = 2
    SCENARIOS = 2
    AGENTS = ["X", "Y", "Z"]
    UNIT = "MW"

    for stage_type in [PSRI.STAGE_MONTH, PSRI.STAGE_WEEK, PSRI.STAGE_DAY]

        gerter = PSRI.open(
            PSRI.OpenBinary.Writer,
            FILE_GERTER,
            is_hourly = true,
            scenarios = SCENARIOS,
            stages = STAGES,
            agents = AGENTS,
            unit = UNIT,
            # optional:
            initial_stage = 2,
            initial_year = 2006,
            stage_type = stage_type,
            single_binary = true
        )

        for t = 1:STAGES, s = 1:SCENARIOS
            for b in 1:PSRI.blocks_in_stage(gerter, t)
                X = 10_000. * t + 1000. * s + b
                Y = b + 0.
                Z = 10. * t + s
                PSRI.write_registry(
                    gerter,
                    [X, Y, Z],
                    t,
                    s,
                    b
                )
            end
        end

        PSRI.close(gerter)

        ior = PSRI.open(
            PSRI.OpenBinary.Reader,
            FILE_GERTER,
            use_header = false,
            single_binary = true
        )

        @test PSRI.max_stages(ior) == STAGES
        @test PSRI.max_scenarios(ior) == SCENARIOS
        @test PSRI.max_blocks(ior) == (stage_type == PSRI.STAGE_MONTH ? 744 : PSRI.HOURS_IN_STAGE[stage_type])
        @test PSRI.stage_type(ior) == stage_type
        @test PSRI.initial_stage(ior) == 2
        @test PSRI.initial_year(ior) == 2006
        @test PSRI.data_unit(ior) == "MW"
        @test PSRI.agent_names(ior) == ["X", "Y", "Z"]
        @test PSRI.is_hourly(ior) == true
        @test PSRI.hour_discretization(ior) == 1

        for t = 1:1, s = 1:1
            @test PSRI.blocks_in_stage(ior, t) <= PSRI.max_blocks(ior)
            for b = 1:PSRI.blocks_in_stage(ior, t)
                @test PSRI.current_stage(ior) == t
                @test PSRI.current_scenario(ior) == s
                @test PSRI.current_block(ior) == b
                X = 10_000. * t + 1000. * s + b
                Y = b + 0.
                Z = 10. * t + s
                ref = [X, Y, Z]
                for agent in 1:3
                    @test ior[agent] == ref[agent]
                end
                PSRI.next_registry(ior)
            end
        end

        PSRI.close(ior)
        ior = nothing

    end

    rm(FILE_GERTER * ".dat")
    return
end

read_write_binary_hourly()
read_write_binary_subhourly()
read_write_binary_hourly_single_binary()
