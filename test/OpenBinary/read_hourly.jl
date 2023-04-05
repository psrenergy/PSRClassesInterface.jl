function read_binary_subhourly()
    STAGES = 2
    SCENARIOS = 2
    AGENTS = ["X", "Y", "Z"]
    UNIT = "MW"

    for stage_type in [PSRI.STAGE_MONTH, PSRI.STAGE_WEEK, PSRI.STAGE_DAY]
        for hour_discretization in [2, 4, 6]
            path = joinpath(".", "data", "case4", "subhourly_$(stage_type)_$(hour_discretization)")

            io = PSRI.open(PSRI.OpenBinary.Reader, path, use_header = false)

            @test PSRI.max_stages(io) == STAGES
            @test PSRI.max_scenarios(io) == SCENARIOS
            @test PSRI.max_blocks(io) == hour_discretization * (stage_type == PSRI.STAGE_MONTH ? 744 : PSRI.HOURS_IN_STAGE[stage_type])
            @test PSRI.stage_type(io) == stage_type
            @test PSRI.initial_stage(io) == 2
            @test PSRI.initial_year(io) == 2006
            @test PSRI.data_unit(io) == UNIT
            @test PSRI.agent_names(io) == AGENTS
            @test PSRI.is_hourly(io) == true
            @test PSRI.hour_discretization(io) == hour_discretization

            for t in 1:STAGES
                for s in 1:SCENARIOS
                    @test PSRI.blocks_in_stage(io, t) <= PSRI.max_blocks(io)
                    for b in 1:PSRI.blocks_in_stage(io, t)
                        @test PSRI.current_stage(io) == t
                        @test PSRI.current_scenario(io) == s
                        @test PSRI.current_block(io) == b
                        X = 10_000.0 * t + 1000.0 * s + b
                        Y = b + 0.0
                        Z = 10.0 * t + s
                        ref = [X, Y, Z]
                        for agent in 1:3
                            @test io[agent] == ref[agent]
                        end
                        PSRI.next_registry(io)
                    end
                end
            end

            PSRI.close(io)
        end
    end
    return
end

read_binary_subhourly()