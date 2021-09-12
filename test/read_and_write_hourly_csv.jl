FILE_GERTER = joinpath(".", "gerter")

STAGES = 3
SCENARIOS = 2
AGENTS = ["X", "Y", "Z"]
UNIT = "MW"

gerter = PSRI.write(
    PSRI.OpenCSV(),
    FILE_GERTER,
    is_hourly = true,
    scenarios = SCENARIOS,
    stages = STAGES,
    agents = AGENTS,
    unit = UNIT,
    # optional:
    initial_stage = 2,
    initial_year = 2006,
)

# Loop de gravacao
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

# Finaliza gravacao
PSRI.close(gerter)

ior = PSRI.read(
    PSRI.OpenCSV(),
    FILE_GERTER,
    is_hourly = true
)

@test PSRI.max_stages(ior) == STAGES
@test PSRI.max_scenarios(ior) == SCENARIOS
@test PSRI.max_blocks(ior) == 744
@test PSRI.stage_type(ior) == PSRI.STAGE_MONTH
@test PSRI.initial_stage(ior) == 2
@test PSRI.initial_year(ior) == 2006
@test PSRI.data_unit(ior) == "MW"
@test PSRI.agent_names(ior) == ["X", "Y", "Z"]

for t = 1:1
    for s = 1:1
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
end

PSRI.close(ior)
ior = nothing
GC.gc();GC.gc()

rm(FILE_GERTER * ".csv")