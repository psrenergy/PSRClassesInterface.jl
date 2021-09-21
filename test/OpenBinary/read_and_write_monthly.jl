# Stage monthly
FILE_PATH = joinpath(".", "example_2")
iow = PSRI.write(
    PSRI.OpenBinary.Writer,
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
    PSRI.OpenBinary.Reader,
    FILE_PATH,
    use_header = false
)

@test PSRI.max_stages(ior) == 12
@test PSRI.max_scenarios(ior) == 10
@test PSRI.max_blocks(ior) == 3
@test PSRI.stage_type(ior) == PSRI.STAGE_MONTH
@test PSRI.initial_stage(ior) == 1
@test PSRI.initial_year(ior) == 2006
@test PSRI.data_unit(ior) == "MW"

# obtem número de colunas
@test PSRI.agent_names(ior) == ["X", "Y", "Z"]

for estagio = 1:12
    for serie = 1:10
        for bloco = 1:3
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