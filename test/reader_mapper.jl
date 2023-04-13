function reader_mapper_test()
    FILE1_PATH = joinpath(".", "example_map_h")
    FILE2_PATH = joinpath(".", "example_map_t")

    AGENTS = ["X", "Y", "Z"]
    STAGES = 12
    SCENARIOS = 10
    BLOCKS = 3

    ioh = PSRI.open(
        PSRI.OpenBinary.Writer,
        FILE1_PATH;
        blocks = BLOCKS,
        scenarios = SCENARIOS,
        stages = STAGES,
        agents = AGENTS,
        unit = "MW",
        initial_stage = 1,
        initial_year = 2006,
    )
    iot = PSRI.open(
        PSRI.OpenBinary.Writer,
        FILE2_PATH;
        blocks = BLOCKS,
        scenarios = SCENARIOS,
        stages = STAGES,
        agents = AGENTS,
        unit = "MW",
        initial_stage = 1,
        initial_year = 2006,
    )

    # ---------------------------------------------
    # Parte 3 - Gravacao dos registros do resultado
    # ---------------------------------------------

    # Loop de gravacao
    for estagio in 1:STAGES, serie in 1:SCENARIOS, bloco in 1:BLOCKS
        X = estagio + serie + 0.0
        Y = serie - estagio + 0.0
        Z = estagio + serie + bloco * 100.0
        PSRI.write_registry(
            ioh,
            [X, Y, Z],
            estagio,
            serie,
            bloco,
        )
        PSRI.write_registry(
            iot,
            [X, Y, Z] .+ 1,
            estagio,
            serie,
            bloco,
        )
    end

    # Finaliza gravacao
    PSRI.close(ioh)
    PSRI.close(iot)

    mapper = PSRI.ReaderMapper(PSRI.OpenBinary.Reader, PSRI.Dates.Date(2006, 1))

    gerter_vec = PSRI.add_reader!(
        mapper,
        FILE1_PATH,
        AGENTS,
    )

    PSRI.add_reader!(
        mapper,
        FILE2_PATH,
        AGENTS,
        ["hid_only"];
        name = "hid",
    )

    for t in 1:STAGES, s in 1:SCENARIOS, b in 1:BLOCKS
        PSRI.goto(mapper, t, s, b)
        X = t + s + 0.0
        Y = s - t + 0.0
        Z = t + s + b * 100.0
        ref = [X, Y, Z]
        @test gerter_vec == ref
        @test mapper["hid"] == ref .+ 1
    end
    for t in 1:(STAGES-1), s in 1:SCENARIOS, b in 1:BLOCKS
        if iseven(b)
            PSRI.goto(mapper, "hid_only", t, s, b)
        else
            PSRI.goto(mapper, "hid", t, s, b)
        end
        X = t + s + 0.0
        Y = s - t + 0.0
        Z = t + s + b * 100.0
        ref = [X, Y, Z]
        @test gerter_vec != ref
        @test mapper["hid"] == ref .+ 1
    end

    PSRI.close(mapper)

    rm(FILE1_PATH * ".hdr")
    rm(FILE1_PATH * ".bin")
    rm(FILE2_PATH * ".hdr")
    return rm(FILE2_PATH * ".bin")
end
reader_mapper_test()
