function test_pmd_parser()
    model_template = PSRI.PMD.load_model_template(
        joinpath(@__DIR__, "..", "src", "json_metadata", "modeltemplates.sddp.json"),
    )

    @testset "source0.pmd" begin
        path = joinpath(@__DIR__, "data", "pmd", "source0.pmd")
        data = PSRI.PMD.parse(path, model_template; verbose = true)

        @test data == PSRI.DataStruct(
            "PSRThermalPlant" => Dict(
                "AVId" =>
                    PSRI.PMD.Attribute("AVId", false, String, 0, ""),
                "name" =>
                    PSRI.PMD.Attribute("name", false, String, 0, ""),
                "code" =>
                    PSRI.PMD.Attribute("code", false, Int32, 0, ""),
                "CEsp" => PSRI.PMD.Attribute(
                    "CEsp",
                    true,
                    Float64,
                    2,
                    "DataCesp",
                ),
                "DataCesp" => PSRI.PMD.Attribute(
                    "DataCesp",
                    true,
                    Dates.Date,
                    0,
                    "",
                ),
            ),
            "PSRBattery" => Dict(
                "AVId" =>
                    PSRI.PMD.Attribute("AVId", false, String, 0, ""),
                "name" =>
                    PSRI.PMD.Attribute("name", false, String, 0, ""),
                "code" =>
                    PSRI.PMD.Attribute("code", false, Int32, 0, ""),
            ),
            "PSRTransformer" => Dict(
                "AVId" =>
                    PSRI.PMD.Attribute("AVId", false, String, 0, ""),
                "name" =>
                    PSRI.PMD.Attribute("name", false, String, 0, ""),
                "EndDateMaintenance" => PSRI.PMD.Attribute(
                    "EndDateMaintenance",
                    true,
                    Dates.Date,
                    0,
                    "",
                ),
                "InitialDateMaintenance" => PSRI.PMD.Attribute(
                    "InitialDateMaintenance",
                    true,
                    Dates.Date,
                    0,
                    "",
                ),
                "code" =>
                    PSRI.PMD.Attribute("code", false, Int32, 0, ""),
            ),
            "PSRInterconnection" => Dict(
                "Currency" => PSRI.PMD.Attribute(
                    "Currency",
                    false,
                    String,
                    0,
                    "",
                ),
                "LossFactor->" => PSRI.PMD.Attribute(
                    "LossFactor->",
                    true,
                    Float64,
                    0,
                    "Data",
                ),
                "LossFactor<-" => PSRI.PMD.Attribute(
                    "LossFactor<-",
                    true,
                    Float64,
                    0,
                    "Data",
                ),
                "code" =>
                    PSRI.PMD.Attribute("code", false, Int32, 0, ""),
                "AVId" =>
                    PSRI.PMD.Attribute("AVId", false, String, 0, ""),
                "name" =>
                    PSRI.PMD.Attribute("name", false, String, 0, ""),
                "Cost<-" => PSRI.PMD.Attribute(
                    "Cost<-",
                    true,
                    Float64,
                    1,
                    "DataCost<-",
                ),
                "DataCost<-" => PSRI.PMD.Attribute(
                    "DataCost<-",
                    true,
                    Dates.Date,
                    0,
                    "",
                ),
                "Capacity<-" => PSRI.PMD.Attribute(
                    "Capacity<-",
                    true,
                    Float64,
                    1,
                    "Data",
                ),
                "DataCost->" => PSRI.PMD.Attribute(
                    "DataCost->",
                    true,
                    Dates.Date,
                    0,
                    "",
                ),
                "Capacity->" => PSRI.PMD.Attribute(
                    "Capacity->",
                    true,
                    Float64,
                    1,
                    "Data",
                ),
                "Data" => PSRI.PMD.Attribute(
                    "Data",
                    true,
                    Dates.Date,
                    0,
                    "",
                ),
                "Existing" => PSRI.PMD.Attribute(
                    "Existing",
                    true,
                    Int32,
                    0,
                    "Data",
                ),
                "Cost->" => PSRI.PMD.Attribute(
                    "Cost->",
                    true,
                    Float64,
                    1,
                    "DataCost->",
                ),
            ),
            "PSRCurrency" => Dict(
                "AVId" =>
                    PSRI.PMD.Attribute("AVId", false, String, 0, ""),
                "name" =>
                    PSRI.PMD.Attribute("name", false, String, 0, ""),
                "Currency" => PSRI.PMD.Attribute(
                    "Currency",
                    false,
                    String,
                    0,
                    "",
                ),
                "code" =>
                    PSRI.PMD.Attribute("code", false, Int32, 0, ""),
            ),
            "PSRSerie" => Dict(
                "AVId" =>
                    PSRI.PMD.Attribute("AVId", false, String, 0, ""),
                "name" =>
                    PSRI.PMD.Attribute("name", false, String, 0, ""),
                "EndDateMaintenance" => PSRI.PMD.Attribute(
                    "EndDateMaintenance",
                    true,
                    Dates.Date,
                    0,
                    "",
                ),
                "InitialDateMaintenance" => PSRI.PMD.Attribute(
                    "InitialDateMaintenance",
                    true,
                    Dates.Date,
                    0,
                    "",
                ),
                "code" =>
                    PSRI.PMD.Attribute("code", false, Int32, 0, ""),
            ),
        )
    end
end

function test_pmd_parser_2()
    model_template = PSRI.PMD.load_model_template(
        joinpath(@__DIR__, "data", "model_template_test", "modeltemplates.source3.json"),
    )
    pmds_path = [joinpath(@__DIR__, "data", "pmd", "source3.pmd")]

    @testset "source3.pmd" begin
        relation_mapper = PSRI.PMD.RelationMapper()
        PSRI.PMD.load_model(
            "",
            pmds_path,
            model_template,
            relation_mapper,
        )
        @test relation_mapper == PSRI.PMD.RelationMapper(
            Dict(
                "PSRGeneratorUnit" =>
                    Dict(
                        "PSRBus" =>
                            Dict{String, PSRI.PMD.Relation}(
                                "Bus" => PSRI.PMD.Relation(
                                    PSRI.PMD.RELATION_1_TO_1,
                                    "Bus",
                                ),
                                "Buses" => PSRI.PMD.Relation(
                                    PSRI.PMD.RELATION_1_TO_N,
                                    "Buses",
                                ),
                            ),
                        "PSRElement" =>
                            Dict{String, PSRI.PMD.Relation}(
                                "Element" => PSRI.PMD.Relation(
                                    PSRI.PMD.RELATION_1_TO_N,
                                    "Element",
                                ),
                            ),
                    ),
                "PSRTest" =>
                    Dict(
                        "PSRBus" =>
                            Dict{String, PSRI.PMD.Relation}(
                                "Bus3" => PSRI.PMD.Relation(
                                    PSRI.PMD.RELATION_1_TO_1,
                                    "Bus3",
                                ),
                            ),
                    ),
            ),
        )
    end
end

test_pmd_parser()
test_pmd_parser_2()
