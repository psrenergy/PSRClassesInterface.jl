function test_time_series()
    case_path = joinpath(@__DIR__, "data", "case_2")
    if isfile(joinpath(case_path, "psrclasses.sqlite"))
        rm(joinpath(case_path, "psrclasses.sqlite"))
    end

    db = PSRI.create_study(
        PSRI.SQLInterface();
        data_path = case_path,
        schema = "simple_schema",
        study_collection = "Study",
        id = "Toy Case",
    )

    PSRI.create_element!(
        db,
        "Plant";
        id = "Plant 1",
    )

    PSRI.create_element!(
        db,
        "Plant";
        id = "Plant 2",
    )

    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        joinpath(case_path, "generation");
        blocks = 3,
        scenarios = 2,
        stages = 12,
        agents = ["Plant 1", "Plant 2"],
        unit = "MW",
    )

    for t in 1:12, s in 1:2, b in 1:3
        PSRI.write_registry(iow, [(t + s + b) * 100.0, (t + s + b) * 300.0], t, s, b)
    end

    PSRI.close(iow)

    PSRI.link_series_to_file(
        db,
        "Plant",
        "generation_file",
        joinpath(case_path, "generation"),
    )

    ior = PSRI.mapped_vector(db, "Plant", "generation_file")

    for t in 1:12, s in 1:2, b in 1:3
        @test ior.data == [(t + s + b) * 100.0, (t + s + b) * 300.0]
        PSRI.next_registry(ior)
    end

    PSRI.close(ior)

    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        joinpath(case_path, "cost");
        blocks = 3,
        scenarios = 2,
        stages = 12,
        agents = ["Plant 1", "Plant 2"],
        unit = "USD",
    )

    for t in 1:12, s in 1:2, b in 1:3
        PSRI.write_registry(iow, [(t + s + b) * 500.0, (t + s + b) * 400.0], t, s, b)
    end

    PSRI.close(iow)

    PSRI.link_series_to_file(db, "Plant", "cost_file", joinpath(case_path, "cost"))

    ior = PSRI.mapped_vector(db, "Plant", "cost_file")

    for t in 1:12, s in 1:2, b in 1:3
        @test ior.data == [(t + s + b) * 500.0, (t + s + b) * 400.0]
        PSRI.next_registry(ior)
    end

    PSRI.close(ior)

    PSRI.OpenSQL.close(db)

    return rm(joinpath(case_path, "psrclasses.sqlite"))
end

function test_time_series_2()
    case_path = joinpath(@__DIR__, "data", "case_2")
    if isfile(joinpath(case_path, "psrclasses.sqlite"))
        rm(joinpath(case_path, "psrclasses.sqlite"))
    end

    db = PSRI.create_study(
        PSRI.SQLInterface();
        data_path = case_path,
        schema = "simple_schema",
        study_collection = "Study",
        id = "Toy Case",
    )

    PSRI.create_element!(
        db,
        "Plant";
        id = "Plant 1",
    )

    PSRI.create_element!(
        db,
        "Plant";
        id = "Plant 2",
    )

    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        joinpath(case_path, "generation");
        blocks = 3,
        scenarios = 2,
        stages = 12,
        agents = ["Plant 1", "Plant 2"],
        unit = "MW",
    )

    for t in 1:12, s in 1:2, b in 1:3
        PSRI.write_registry(iow, [(t + s + b) * 100.0, (t + s + b) * 300.0], t, s, b)
    end

    PSRI.close(iow)

    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        joinpath(case_path, "cost");
        blocks = 3,
        scenarios = 2,
        stages = 12,
        agents = ["Plant 1", "Plant 2"],
        unit = "USD",
    )

    for t in 1:12, s in 1:2, b in 1:3
        PSRI.write_registry(iow, [(t + s + b) * 500.0, (t + s + b) * 400.0], t, s, b)
    end

    PSRI.close(iow)

    PSRI.link_series_to_files(
        db,
        "Plant";
        generation_file = joinpath(case_path, "generation"),
        cost_file = joinpath(case_path, "cost"),
    )

    ior = PSRI.mapped_vector(db, "Plant", "generation_file")

    for t in 1:12, s in 1:2, b in 1:3
        @test ior.data == [(t + s + b) * 100.0, (t + s + b) * 300.0]
        PSRI.next_registry(ior)
    end

    PSRI.close(ior)

    ior = PSRI.mapped_vector(db, "Plant", "cost_file")

    for t in 1:12, s in 1:2, b in 1:3
        @test ior.data == [(t + s + b) * 500.0, (t + s + b) * 400.0]
        PSRI.next_registry(ior)
    end

    PSRI.close(ior)

    PSRI.OpenSQL.close(db)

    return rm(joinpath(case_path, "psrclasses.sqlite"))
end

test_time_series()
test_time_series_2()
