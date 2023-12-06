function create_case_1()
    case_path = joinpath(@__DIR__, "data", "case_1")
    if isfile(joinpath(case_path, "psrclasses.sqlite"))
        rm(joinpath(case_path, "psrclasses.sqlite"))
    end

    db = PSRI.create_study(
        PSRI.SQLInterface();
        data_path = case_path,
        schema = "toy_schema",
        study_collection = "Configuration",
        id = "Toy Case",
        value1 = 1.0,
    )

    @test PSRI.get_parm(db, "Configuration", "id", "Toy Case") == "Toy Case"
    @test PSRI.get_parm(db, "Configuration", "value1", "Toy Case") == 1.0
    @test PSRI.get_parm(db, "Configuration", "enum1", "Toy Case") == "A"

    PSRI.create_element!(
        db,
        "Plant";
        id = "Plant 1",
        capacity = 50.0,
    )

    PSRI.create_element!(
        db,
        "Plant";
        id = "Plant 2",
    )

    @test PSRI.get_parm(db, "Plant", "id", "Plant 1") == "Plant 1"
    @test PSRI.get_parm(db, "Plant", "capacity", "Plant 1") == 50.0
    @test PSRI.get_parm(db, "Plant", "id", "Plant 2") == "Plant 2"
    @test PSRI.get_parm(db, "Plant", "capacity", "Plant 2") == 0.0

    PSRI.set_parm!(
        db,
        "Plant",
        "capacity",
        "Plant 2",
        100.0,
    )

    @test PSRI.get_parm(db, "Plant", "capacity", "Plant 2") == 100.0

    PSRI.create_element!(
        db,
        "Resource";
        id = "R1",
        type = "E",
        some_value = [1.0, 2.0, 3.0],
    )

    PSRI.create_element!(
        db,
        "Resource";
        id = "R2",
        type = "F",
        some_value = [4.0, 5.0, 6.0],
    )

    @test PSRI.get_vector(
        db,
        "Resource",
        "some_value",
        "R1",
    ) == [1.0, 2.0, 3.0]

    @test PSRI.get_vector(
        db,
        "Resource",
        "some_value",
        "R2",
    ) == [4.0, 5.0, 6.0]

    PSRI.set_vector!(
        db,
        "Resource",
        "some_value",
        "R1",
        [7.0, 8.0, 9.0],
    )

    @test PSRI.get_vectors(
        db,
        "Resource",
        "some_value",
    ) == [[7.0, 8.0, 9.0], [4.0, 5.0, 6.0]]

    PSRI.set_related!(
        db,
        "Plant",
        "Resource",
        "Plant 1",
        "R1",
        "id",
    )
    PSRI.set_related!(
        db,
        "Plant",
        "Resource",
        "Plant 2",
        "R2",
        "id",
    )

    @test PSRI.get_related(
        db,
        "Plant",
        "Resource",
        "Plant 1",
        "id",
    ) == "R1"

    @test PSRI.get_parm(db, "Plant", "resource_id", "Plant 1") == "R1"

    PSRI.delete_relation!(
        db,
        "Plant",
        "Resource",
        "Plant 1",
        "R1",
    )

    @test PSRI.get_parm(db, "Plant", "resource_id", "Plant 1") == ""

    @test PSRI.max_elements(db, "Plant") == 2
    @test PSRI.max_elements(db, "Resource") == 2

    PSRI.OpenSQL.close(db)

    db = PSRI.load_study(
        PSRI.SQLInterface();
        data_path = joinpath(case_path, "psrclasses.sqlite"),
    )

    PSRI.delete_element!(db, "Plant", "Plant 1")
    PSRI.delete_element!(db, "Resource", "R1")

    @test PSRI.max_elements(db, "Plant") == 1
    @test PSRI.max_elements(db, "Resource") == 1

    @test PSRI.get_attributes(db, "Resource") == ["id", "type", "some_value"]

    @test PSRI.get_attributes(db, "Plant") ==
          [
        "id",
        "capacity",
        "resource_id",
        "plant_turbine_to",
        "plant_spill_to",
        "generation",
        "cost",
    ]

    PSRI.OpenSQL.close(db)

    return rm(joinpath(case_path, "psrclasses.sqlite"))
end

function create_case_relations()
    case_path = joinpath(@__DIR__, "data", "case_1")
    if isfile(joinpath(case_path, "psrclasses.sqlite"))
        rm(joinpath(case_path, "psrclasses.sqlite"))
    end

    db = PSRI.create_study(
        PSRI.SQLInterface();
        data_path = case_path,
        schema = "toy_schema",
        study_collection = "Configuration",
        id = "Toy Case",
        value1 = 1.0,
    )

    PSRI.create_element!(
        db,
        "Plant";
        id = "Plant 1",
        capacity = 50.0,
    )

    PSRI.create_element!(
        db,
        "Plant";
        id = "Plant 2",
    )

    PSRI.create_element!(
        db,
        "Cost";
        id = "Cost 1",
        value = 30.0,
    )

    PSRI.create_element!(
        db,
        "Cost";
        id = "Cost 2",
        value = 40.0,
    )

    PSRI.set_vector_related!(
        db,
        "Plant",
        "Cost",
        "Plant 1",
        "Cost 1",
        "sometype",
    )

    PSRI.set_vector_related!(
        db,
        "Plant",
        "Cost",
        "Plant 1",
        "Cost 2",
        "sometype2",
    )

    PSRI.set_vector_related!(
        db,
        "Plant",
        "Cost",
        "Plant 2",
        "Cost 1",
        "sometype",
    )

    @test PSRI.get_vector_related(
        db,
        "Plant",
        "Plant 1",
        "sometype",
    ) == ["Cost 1"]

    @test PSRI.get_vector_related(
        db,
        "Plant",
        "Plant 1",
        "sometype2",
    ) == ["Cost 2"]

    # @test PSRI.get_vector_related(
    #     db,
    #     "Plant",
    #     "Plant 2",
    #     "sometype"
    # ) == ["Cost 1"]

    PSRI.OpenSQL.close(db)

    return rm(joinpath(case_path, "psrclasses.sqlite"))
end

create_case_1()
create_case_relations()
