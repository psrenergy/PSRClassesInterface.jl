function use_header()
    file_path = joinpath(".", "data")

    STAGES = 2
    SCENARIOS = 2
    AGENTS = ["X", "Y", "Z"]
    UNIT = "MW"

    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        file_path;
        is_hourly = true,
        scenarios = SCENARIOS,
        stages = STAGES,
        agents = AGENTS,
        unit = UNIT,
        # optional:
        initial_stage = 2,
        initial_year = 2006,
        stage_type = PSRI.STAGE_MONTH,
    )

    for t in 1:STAGES, s in 1:SCENARIOS
        for b in 1:PSRI.blocks_in_stage(iow, t)
            X = 10_000.0 * t + 1000.0 * s + b
            Y = b + 0.0
            Z = 10.0 * t + s
            PSRI.write_registry(
                iow,
                [X, Y, Z],
                t,
                s,
                b,
            )
        end
    end

    PSRI.close(iow)

    # All agents

    ior = PSRI.open(
        PSRI.OpenBinary.Reader,
        file_path;
        use_header = true,
        header = ["X", "Y", "Z"],
    )

    @test PSRI.agent_names(ior) == ["X", "Y", "Z"]

    for t in 1:1, s in 1:1
        for b in 1:PSRI.blocks_in_stage(ior, t)
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

    # # Only X

    ior = PSRI.open(
        PSRI.OpenBinary.Reader,
        file_path;
        use_header = true,
        header = ["X"],
    )

    @test PSRI.agent_names(ior) == ["X"]

    for t in 1:1, s in 1:1
        for b in 1:PSRI.blocks_in_stage(ior, t)
            X = 10_000.0 * t + 1000.0 * s + b
            ref = [X]
            @test ior[1] == ref[1]
            PSRI.next_registry(ior)
        end
    end

    PSRI.close(ior)
    ior = nothing

    # Only Y

    ior = PSRI.open(
        PSRI.OpenBinary.Reader,
        file_path;
        use_header = true,
        header = ["Y"],
    )

    @test PSRI.agent_names(ior) == ["Y"]

    for t in 1:1, s in 1:1
        for b in 1:PSRI.blocks_in_stage(ior, t)
            Y = b + 0.0
            ref = [Y]
            @test ior[1] == ref[1]
            PSRI.next_registry(ior)
        end
    end

    PSRI.close(ior)
    ior = nothing

    # All agents reverse

    ior = PSRI.open(
        PSRI.OpenBinary.Reader,
        file_path;
        use_header = true,
        header = ["Z", "Y", "X"],
    )

    @test PSRI.agent_names(ior) == ["Z", "Y", "X"]

    for t in 1:1, s in 1:1
        for b in 1:PSRI.blocks_in_stage(ior, t)
            X = 10_000.0 * t + 1000.0 * s + b
            Y = b + 0.0
            Z = 10.0 * t + s
            ref = [Z, Y, X]
            for agent in 1:3
                @test ior[agent] == ref[agent]
            end
            PSRI.next_registry(ior)
        end
    end

    PSRI.close(ior)
    ior = nothing

    rm(file_path * ".bin")
    rm(file_path * ".hdr")
    return
end

use_header()
