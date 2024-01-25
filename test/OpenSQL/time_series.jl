function test_time_series()
    case_path = joinpath(@__DIR__, "data", "case_2")
    if isfile(joinpath(case_path, "simplecase.sqlite"))
        rm(joinpath(case_path, "simplecase.sqlite"))
    end

    db = PSRI.create_study(
        PSRI.OpenSQLInterface(),
        joinpath(case_path, "simplecase.sqlite"),
        joinpath(case_path, "simple_schema.sql");
        val1 = 1,
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
        agents = PSRI.get_parms(db, "Plant", "label"),
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
        agents = PSRI.get_parms(db, "Plant", "label"),
        unit = "USD",
    )

    for t in 1:12, s in 1:2, b in 1:3
        PSRI.write_registry(iow, [(t + s + b) * 500.0, (t + s + b) * 400.0], t, s, b)
    end

    PSRI.close(iow)

    PSRI.link_series_to_file(
        db,
        "Plant";
        generation = "generation",
        cost = "cost",
    )

    PSRI.OpenSQL.close(db)

    return rm(joinpath(case_path, "simplecase.sqlite"))
end

test_time_series()
