# Stage monthly
FILE_PATH = joinpath(".", "example_2")
iow = PSRI.write(
    OpenCSV(),
    FILE_PATH,
    blocks = 3,
    scenarios = 10,
    stages = 12,
    agents = ["X", "Y", "Z"],
    unit = "MW",
    # optional:
    initial_stage = 1,
    initial_year = 2006,
)

# ---------------------------------------------
# Parte 3 - Gravacao dos registros do resultado
# ---------------------------------------------

# Loop de gravacao
for estagio = 1:12, serie = 1:10, bloco = 1:3
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

ior = PSRI.read(
    OpenCSV(),
    FILE_PATH
)

@test max_stages(ior) == 12
@test max_scenarios(ior) == 10
@test max_blocks(ior) == 3
@test stage_type(ior) == STAGE_MONTH
@test initial_stage(ior) == 1
@test initial_year(ior) == 2006
@test data_unit(ior) == "MW"

# obtem número de colunas
@test agent_names(ior) == ["X", "Y", "Z"]

for estagio = 1:12
    for serie = 1:10
        for bloco = 1:3
            @test current_stage(ior) == estagio
            @test current_scenario(ior) == serie
            @test current_block(ior) == bloco
            
            X = estagio + serie
            Y = serie - estagio
            Z = estagio + serie + bloco * 100
            ref = [X, Y, Z]
            
            for agent in 1:3
                @test ior[agent] == ref[agent]
            end
            next_registry(ior)
        end
    end
end

PSRI.close(ior)
ior = nothing
GC.gc();GC.gc()

rm(FILE_PATH * ".csv")