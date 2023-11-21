function incomplete_file()
    temp_path = joinpath(tempdir(), "openbin")
    bin_path = joinpath(temp_path, "binfile")

    mkpath(temp_path)

    n_stages = 4
    n_scenarios = 3
    n_blocks = 2

    agents = ["X", "Y", "Z"]

    unit = ""

    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        bin_path;
        is_hourly = false,
        scenarios = n_scenarios,
        stages = n_stages,
        blocks = n_blocks,
        agents = agents,
        unit = unit,
        initial_stage = 1,
        initial_year = 2000,
        stage_type = PSRI.STAGE_MONTH,
        single_binary = false,
    )

    PSRI.write_registry(
        iow,
        [1.0, 2.0, 3.0],
        1,
        1,
        1,
    )

    PSRI.write_registry(
        iow,
        [3.0, 2.0, 1.0],
        1,
        1,
        2,
    )

    PSRI.close(iow)

    ior = PSRI.open(
        PSRI.OpenBinary.Reader,
        bin_path;
        header = agents,
    )

    @test ior.data == [1.0, 2.0, 3.0]

    PSRI.next_registry(ior)

    @test ior.data == [3.0, 2.0, 1.0]

    PSRI.next_registry(ior)

    @test ior.data == [0.0, 0.0, 0.0]

    return PSRI.close(ior)
end

incomplete_file()
