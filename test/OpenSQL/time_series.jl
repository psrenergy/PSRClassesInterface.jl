function test_time_series()
    case_path = joinpath(@__DIR__, "data", "case_2")
    if isfile(joinpath(case_path, "simplecase.sqlite"))
        rm(joinpath(case_path, "simplecase.sqlite"))
    end

    db = PSRI.create_study(
        PSRI.SQLInterface(),
        joinpath(case_path, "simplecase.sqlite"),
        joinpath(case_path, "simple_schema.sql");
        label = "Toy Case",
    )

    PSRI.create_element!(
        db,
        "Plant";
        label = "Plant 1",
    )

    PSRI.create_element!(
        db,
        "Plant";
        label = "Plant 2",
    )

    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        db,
        "Plant",
        "generation",
        joinpath(case_path, "generation");
        blocks = 3,
        scenarios = 2,
        stages = 12,
        unit = "MW",
    )

    for t in 1:12, s in 1:2, b in 1:3
        PSRI.write_registry(iow, [(t + s + b) * 100.0, (t + s + b) * 300.0], t, s, b)
    end

    PSRI.close(iow)

    ior = PSRI.open(PSRI.OpenBinary.Reader, db, "Plant", "generation")

    for t in 1:12, s in 1:2, b in 1:3
        @test ior.data == [(t + s + b) * 100.0, (t + s + b) * 300.0]
        PSRI.next_registry(ior)
    end

    PSRI.close(ior)

    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        db,
        "Plant",
        "cost",
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

    ior = PSRI.open(PSRI.OpenBinary.Reader, db, "Plant", "cost")

    for t in 1:12, s in 1:2, b in 1:3
        @test ior.data == [(t + s + b) * 500.0, (t + s + b) * 400.0]
        PSRI.next_registry(ior)
    end

    PSRI.close(ior)

    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        db,
        "Plant",
        "generation",
        joinpath(case_path, "generation_new");
        blocks = 3,
        scenarios = 2,
        stages = 12,
        unit = "MW",
    )

    for t in 1:12, s in 1:2, b in 1:3
        PSRI.write_registry(iow, [(t + s + b) * 50.0, (t + s + b) * 20.0], t, s, b)
    end

    PSRI.close(iow)

    ior = PSRI.open(PSRI.OpenBinary.Reader, db, "Plant", "generation")

    for t in 1:12, s in 1:2, b in 1:3
        @test ior.data == [(t + s + b) * 50.0, (t + s + b) * 20.0]
        PSRI.next_registry(ior)
    end

    PSRI.close(ior)

    PSRI.OpenSQL.close(db)

    return rm(joinpath(case_path, "simplecase.sqlite"))
end

function test_time_series_2()
    case_path = joinpath(@__DIR__, "data", "case_2")
    if isfile(joinpath(case_path, "simplecase.sqlite"))
        rm(joinpath(case_path, "simplecase.sqlite"))
    end

    db = PSRI.create_study(
        PSRI.SQLInterface(),
        joinpath(case_path, "simplecase.sqlite"),
        joinpath(case_path, "simple_schema.sql");
        label = "Toy Case",
    )

    PSRI.create_element!(
        db,
        "Plant";
        label = "Plant 1",
    )

    PSRI.create_element!(
        db,
        "Plant";
        label = "Plant 2",
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
        generation = "generation",
        cost = "cost",
    )

    ior = PSRI.open(PSRI.OpenBinary.Reader, db, "Plant", "generation")

    for t in 1:12, s in 1:2, b in 1:3
        @test ior.data == [(t + s + b) * 100.0, (t + s + b) * 300.0]
        PSRI.next_registry(ior)
    end

    PSRI.close(ior)

    ior = PSRI.open(PSRI.OpenBinary.Reader, db, "Plant", "cost")

    for t in 1:12, s in 1:2, b in 1:3
        @test ior.data == [(t + s + b) * 500.0, (t + s + b) * 400.0]
        PSRI.next_registry(ior)
    end

    PSRI.close(ior)

    PSRI.OpenSQL.close(db)

    return rm(joinpath(case_path, "simplecase.sqlite"))
end

# test_time_series()
# test_time_series_2()
