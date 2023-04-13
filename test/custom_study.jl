function test_custom()
    path = joinpath(@__DIR__, "data", "custom_study")

    data = PSRI.create_study(
        PSRI.OpenInterface();
        data_path = path,
        pmds_path = path,
        model_template_path = joinpath(path, "modeltemplates.json"),
        study_collection = "CustomStudy",
        defaults = Dict{String, Any}(
            "CustomStudy" => Dict{String, Any}(
                "AVId" => "id",
                "name" => "Study",
                "code" => 0,
                "Tipo_Etapa" => 1,
                "Ano_inicial" => 2022,
                "Etapa_inicial" => 1,
            ),
        ),
    )

    PSRI.create_element!(data, "ThermalPlants",
        "Capacity" => 1.0,
        "SpecificConsumptionDate" =>
            [Dates.Date(2022, 1, 1), Dates.Date(2022, 1, 8), Dates.Date(2022, 1, 15)],
        "SpecificConsumption(1)" => [11.0, 12.0, 13.0],
        "SpecificConsumption(2)" => [21.0, 22.0, 23.0],
        "SpecificConsumption(3)" => [31.0, 32.0, 33.0],
        "StartUpColdCost" => 0.0,
        "code" => Int32(2),
        "name" => "Thermal1",
        "AVId" => "id1",
        "DimensionedAttr(1)" => 1.0,
        "DimensionedAttr(2)" => 2.0,
        "DimensionedAttr(3)" => 3.0)

    PSRI.create_element!(data, "ThermalPlants",
        "Capacity" => 1.0,
        "SpecificConsumptionDate" =>
            [Dates.Date(2022, 1, 1), Dates.Date(2022, 1, 8), Dates.Date(2022, 1, 15)],
        "SpecificConsumption(1)" => [111.0, 112.0, 113.0],
        "SpecificConsumption(2)" => [221.0, 222.0, 223.0],
        "SpecificConsumption(3)" => [331.0, 332.0, 333.0],
        "StartUpColdCost" => 0.0,
        "code" => Int32(4),
        "name" => "Thermal1",
        "AVId" => "id2",
        "DimensionedAttr(1)" => 11.0,
        "DimensionedAttr(2)" => 22.0,
        "DimensionedAttr(3)" => 33.0,
    )

    vec1 =
        PSRI.mapped_vector(data, "ThermalPlants", "SpecificConsumption", Float64, "segment")
    vec2 = PSRI.get_parm_1d(data, "ThermalPlants", "DimensionedAttr", 1, Float64)
    vec3 = PSRI.get_parm_1d(data, "ThermalPlants", "DimensionedAttr", 2, Float64)

    @test vec1 == [11.0, 111.0]
    @test vec2 == [1.0, 2.0, 3.0]
    @test vec3 == [11.0, 22.0, 33.0]

    PSRI.go_to_dimension(data, "segment", 2)
    PSRI.update_vectors!(data)

    @test vec1 == [21.0, 221.0]

    PSRI.go_to_stage(data, 2)
    PSRI.update_vectors!(data)

    @test vec1 == [22.0, 222.0]

    PSRI.go_to_stage(data, 3)
    PSRI.go_to_dimension(data, "segment", 3)
    PSRI.update_vectors!(data)

    @test vec1 == [33.0, 333.0]
end

test_custom()
