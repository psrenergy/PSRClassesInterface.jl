function test_pmd_parser()
    test_pmd_source_0()
    test_pmd_source_1()
    test_pmd_source_2()
    test_pmd_source_3()
    test_pmd_source_3_relations()

    return nothing
end

function test_pmd_source_0()
    model_template = PSRI.PMD.load_model_template(
        joinpath(PSRI.JSON_METADATA_PATH, "modeltemplates.sddp.json"),
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

    return nothing
end

function test_pmd_source_1()
    model_template = PSRI.PMD.load_model_template(
        joinpath(PSRI.JSON_METADATA_PATH, "modeltemplates.sddp.json"),
    )

    @testset "source1.pmd" begin
        path = joinpath(@__DIR__, "data", "pmd", "source1.pmd")
        data = PSRI.PMD.parse(path, model_template; verbose = true)

        @test haskey(data["PSRHydroPlant"], "Included")

        @test data == Dict{String, Dict{String, PSRI.PMD.Attribute}}(
            "PSRHydroPlant" => Dict(
                "AVId" =>
                    PSRI.PMD.Attribute("AVId", false, String, 0, ""),
                "name" =>
                    PSRI.PMD.Attribute("name", false, String, 0, ""),
                "code" =>
                    PSRI.PMD.Attribute("code", false, Int32, 0, ""),
                "test" =>
                    PSRI.PMD.Attribute("test", false, Int32, 0, ""),
                "DataSensib" =>
                    PSRI.PMD.Attribute("DataSensib", true, Dates.Date, 0, ""),
                "MinCOD" =>
                    PSRI.PMD.Attribute("MinCOD", false, Dates.Date, 0, ""),
                "SensibPotInst" =>
                    PSRI.PMD.Attribute("SensibPotInst", true, Float64, 0, "DataSensib"),
                "Included" =>
                    PSRI.PMD.Attribute("Included", false, Int32, 0, ""),
                "Percentage" =>
                    PSRI.PMD.Attribute("Percentage", false, Float64, 0, ""),
            ),
            "Contract_Forward" => Dict(
                "AVId" =>
                    PSRI.PMD.Attribute("AVId", false, String, 0, ""),
                "name" =>
                    PSRI.PMD.Attribute("name", false, String, 0, ""),
                "SpreadUnit" => PSRI.PMD.Attribute(
                    "SpreadUnit",
                    false,
                    Int32,
                    0,
                    "",
                ),
                "Spread" =>
                    PSRI.PMD.Attribute("Spread", false, Float64, 0, ""),
                "code" =>
                    PSRI.PMD.Attribute("code", false, Int32, 0, ""),
            ),
            "PSRGeneratorUnit" => Dict(
                "AVId" =>
                    PSRI.PMD.Attribute("AVId", false, String, 0, ""),
                "name" =>
                    PSRI.PMD.Attribute("name", false, String, 0, ""),
                "FixedOEM" => PSRI.PMD.Attribute(
                    "FixedOEM",
                    true,
                    Float64,
                    0,
                    "DataOptfolio",
                ),
                "Code" =>
                    PSRI.PMD.Attribute("Code", false, Int32, 0, ""),
                "code" =>
                    PSRI.PMD.Attribute("code", false, Int32, 0, ""),
                "NumberUnits" => PSRI.PMD.Attribute(
                    "NumberUnits",
                    false,
                    Int32,
                    0,
                    "",
                ),
            ),
            "MODELX" => Dict(
                "DataHP" => PSRI.PMD.Attribute(
                    "DataHP",
                    true,
                    Dates.Date,
                    0,
                    "",
                ),
                "code" =>
                    PSRI.PMD.Attribute("code", false, Int32, 0, ""),
                "DataN" =>
                    PSRI.PMD.Attribute("DataN", false, String, 0, ""),
                "DataDP" => PSRI.PMD.Attribute(
                    "DataDP",
                    true,
                    Dates.Date,
                    0,
                    "",
                ),
                "AVId" =>
                    PSRI.PMD.Attribute("AVId", false, String, 0, ""),
                "name" =>
                    PSRI.PMD.Attribute("name", false, String, 0, ""),
                "DataD" => PSRI.PMD.Attribute(
                    "DataD",
                    false,
                    Dates.Date,
                    0,
                    "",
                ),
                "DataPTS" => PSRI.PMD.Attribute(
                    "DataPTS",
                    true,
                    Float64,
                    1,
                    "DataP",
                ),
                "DataP" =>
                    PSRI.PMD.Attribute("DataP", false, Float64, 0, ""),
                "DataU" =>
                    PSRI.PMD.Attribute("DataU", false, Int32, 0, ""),
                "DataPHTS" => PSRI.PMD.Attribute(
                    "DataPHTS",
                    true,
                    Float64,
                    0,
                    "DataHP",
                ),
            ),
        )
    end

    return nothing
end

function test_pmd_source_2()
    model_template = PSRI.PMD.load_model_template(
        joinpath(PSRI.JSON_METADATA_PATH, "modeltemplates.sddp.json"),
    )

    @testset "source2.pmd" begin
        path = joinpath(@__DIR__, "data", "pmd", "source2.pmd")
        data = PSRI.PMD.parse(path, model_template; verbose = true)

        @test data == Dict{String, Dict{String, PSRI.PMD.Attribute}}(
            "PSRLoad" => Dict(
                "AVId" => PSRI.PMD.Attribute("AVId", false, String, 0, ""),
                "name" => PSRI.PMD.Attribute("name", false, String, 0, ""),
                "P" => PSRI.PMD.Attribute("P", true, Float64, 1, "Data"),
                "PerF" => PSRI.PMD.Attribute("PerF", true, Float64, 1, "Data"),
                "Data" => PSRI.PMD.Attribute("Data", true, Dates.Date, 0, ""),
                "Pind" => PSRI.PMD.Attribute("Pind", true, Float64, 1, "Data"),
                "code" => PSRI.PMD.Attribute("code", false, Int32, 0, ""),
                "icca" => PSRI.PMD.Attribute("icca", true, Int32, 0, ""),
            ),
        )
    end

    return nothing
end

function test_pmd_source_3()
    model_template = PSRI.PMD.load_model_template(
        joinpath(PSRI.JSON_METADATA_PATH, "modeltemplates.sddp.json"),
    )

    @testset "source3.pmd" begin
        path = joinpath(@__DIR__, "data", "pmd", "source3.pmd")
        data = PSRI.PMD.parse(path, model_template; verbose = true)

        @test data == Dict{String, Dict{String, PSRI.PMD.Attribute}}(
            "PSRElement" => Dict(
                "AVId" =>
                    PSRI.PMD.Attribute("AVId", false, String, 0, ""),
                "name" =>
                    PSRI.PMD.Attribute("name", false, String, 0, ""),
                "Code" =>
                    PSRI.PMD.Attribute("Code", false, Int32, 0, ""),
                "code" =>
                    PSRI.PMD.Attribute("code", false, Int32, 0, ""),
                "NumberUnits" => PSRI.PMD.Attribute(
                    "NumberUnits",
                    false,
                    Int32,
                    0,
                    "",
                ),
            ),
            "PSRBus" => Dict(
                "AVId" =>
                    PSRI.PMD.Attribute("AVId", false, String, 0, ""),
                "name" =>
                    PSRI.PMD.Attribute("name", false, String, 0, ""),
                "Code" =>
                    PSRI.PMD.Attribute("Code", false, Int32, 0, ""),
                "code" =>
                    PSRI.PMD.Attribute("code", false, Int32, 0, ""),
                "NumberUnits" => PSRI.PMD.Attribute(
                    "NumberUnits",
                    false,
                    Int32,
                    0,
                    "",
                ),
            ),
            "PSRTest" => Dict(
                "AVId" =>
                    PSRI.PMD.Attribute("AVId", false, String, 0, ""),
                "name" =>
                    PSRI.PMD.Attribute("name", false, String, 0, ""),
                "Code" =>
                    PSRI.PMD.Attribute("Code", false, Int32, 0, ""),
                "code" =>
                    PSRI.PMD.Attribute("code", false, Int32, 0, ""),
                "NumberUnits" => PSRI.PMD.Attribute(
                    "NumberUnits",
                    false,
                    Int32,
                    0,
                    "",
                ),
            ),
            "PSRGeneratorUnit" => Dict(
                "AVId" =>
                    PSRI.PMD.Attribute("AVId", false, String, 0, ""),
                "name" =>
                    PSRI.PMD.Attribute("name", false, String, 0, ""),
                "Code" =>
                    PSRI.PMD.Attribute("Code", false, Int32, 0, ""),
                "Date" =>
                    PSRI.PMD.Attribute("Date", true, Dates.Date, 0, ""),
                "code" =>
                    PSRI.PMD.Attribute("code", false, Int32, 0, ""),
                "NumberUnits" => PSRI.PMD.Attribute(
                    "NumberUnits",
                    false,
                    Int32,
                    0,
                    "",
                ),
            ),
            "Custom_StudyConfig" => Dict(
                "AVId" =>
                    PSRI.PMD.Attribute("AVId", false, String, 0, ""),
                "name" =>
                    PSRI.PMD.Attribute("name", false, String, 0, ""),
                "Ano_inicial" => PSRI.PMD.Attribute(
                    "Ano_inicial",
                    false,
                    Int32,
                    0,
                    "",
                ),
                "Tipo_Etapa" => PSRI.PMD.Attribute(
                    "Tipo_Etapa",
                    false,
                    Int32,
                    0,
                    "",
                ),
                "code" =>
                    PSRI.PMD.Attribute("code", false, Int32, 0, ""),
                "Etapa_inicial" => PSRI.PMD.Attribute(
                    "Etapa_inicial",
                    false,
                    Int32,
                    0,
                    "",
                ),
            ),
        )
    end

    return nothing
end

function test_pmd_source_3_relations()
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
