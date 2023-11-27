function create_case_1()
    case_path = joinpath(@__DIR__, "data", "case_1")
    if isfile(joinpath(case_path, "psrclasses.sqlite"))
        rm(joinpath(case_path, "psrclasses.sqlite"))
    end

    db = PSRI.create_study(
        PSRI.SQLInterface();
        data_path = case_path,
        schema = "current_schema",
        study_collection = "StudyParameters",
        id = "Toy Case",
        n_periods = 3,
        n_subperiods = 2,
        subperiod_duration = 24.0,
    )

    @test typeof(db) == PSRI.OpenSQL.DB

    PSRI.create_element!(
        db,
        "Resource";
        id = "R1",
        ref_availability = 100.0,
        subperiod_av_type = "PerPeriod",
        subperiod_cost_type = "PerPeriod",
        ref_cost = 1.0,
    )

    PSRI.create_element!(
        db,
        "Resource";
        id = "R2",
        ref_availability = 20.0,
        subperiod_av_type = "PerSubperiodConstant",
        subperiod_cost_type = "PerPeriod",
        ref_cost = 1.0,
    )

    PSRI.create_element!(
        db,
        "Resource";
        id = "R3",
        ref_availability = 100.0,
        subperiod_av_type = "PerPeriod",
        subperiod_cost_type = "PerPeriod",
        ref_cost = 1.0,
    )

    PSRI.create_element!(
        db,
        "PowerAsset";
        id = "Generator 1",
        capacity = 50.0,
        output_cost = 10.0,
        resource_cost_multiplier = 10.0,
        commitment_type = "Linearized",
    )

    PSRI.create_element!(
        db,
        "PowerAsset";
        id = "Generator 2",
        capacity = 100.0,
        output_cost = 12.0,
        resource_cost_multiplier = 12.0,
        commitment_type = "Linearized",
    )

    PSRI.create_element!(
        db,
        "PowerAsset";
        id = "Generator 3",
        capacity = 100.0,
        output_cost = 15.0,
        resource_cost_multiplier = 15.0,
        commitment_type = "Linearized",
    )

    PSRI.create_element!(
        db,
        "PowerAsset";
        id = "Generator 4",
        output_sign = "DemandLike",
        curve_type = "Forced",
        commitment_type = "AlwaysOn",
        capacity = 100.0,
    )

    PSRI.create_element!(
        db,
        "ConversionCurve";
        id = "Conversion curve 1",
        unit = "MW",
        max_capacity_fractions = [0.1, 0.2, 0.3, 0.4],
        conversion_efficiencies = [1.0, 2.0],
    )

    PSRI.create_element!(
        db,
        "ConversionCurve";
        id = "Conversion curve 2",
        unit = "MW",
        max_capacity_fractions = [0.5, 0.3, 0.2, 0.1],
        conversion_efficiencies = [1.0, 2.0, 4.0],
    )

    PSRI.create_element!(
        db,
        "ConversionCurve";
        id = "Conversion curve 3",
        unit = "MW",
    )

    PSRI.set_related!(
        db,
        "PowerAsset",
        "Resource",
        "Generator 1",
        "R1",
    )
    PSRI.set_related!(
        db,
        "PowerAsset",
        "Resource",
        "Generator 2",
        "R2",
    )
    PSRI.set_related!(
        db,
        "PowerAsset",
        "Resource",
        "Generator 3",
        "R3",
    )

    PSRI.OpenSQL.close(db)

    db = PSRI.OpenSQL.load_db(joinpath(case_path, "psrclasses.sqlite"))

    @test PSRI.get_parm(db, "StudyParameters", "id", "Toy Case") == "Toy Case"
    @test PSRI.get_parm(db, "StudyParameters", "n_periods", "Toy Case") == 3
    @test PSRI.get_parm(db, "StudyParameters", "n_subperiods", "Toy Case") == 2
    @test PSRI.get_parm(db, "StudyParameters", "subperiod_duration", "Toy Case") == 24.0

    @test PSRI.get_parms(db, "Resource", "id") == ["R1", "R2", "R3"]
    @test PSRI.get_parms(db, "Resource", "ref_availability") == [100.0, 20.0, 100.0]
    @test PSRI.get_parms(db, "Resource", "subperiod_av_type") ==
          ["PerPeriod", "PerSubperiodConstant", "PerPeriod"]
    @test PSRI.get_parms(db, "Resource", "subperiod_cost_type") ==
          ["PerPeriod", "PerPeriod", "PerPeriod"]
    @test PSRI.get_parms(db, "Resource", "ref_cost") == [1.0, 1.0, 1.0]

    PSRI.set_related!(
        db,
        "PowerAsset",
        "Resource",
        "Generator 1",
        "R1",
    )

    PSRI.set_related!(
        db,
        "PowerAsset",
        "Resource",
        "Generator 2",
        "R2",
    )

    PSRI.set_related!(
        db,
        "PowerAsset",
        "Resource",
        "Generator 3",
        "R3",
    )

    PSRI.OpenSQL.close(db)

    return rm(joinpath(case_path, "psrclasses.sqlite"))
end

create_case_1()
