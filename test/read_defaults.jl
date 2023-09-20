function test_read_defaults()
    case_path = raw"./data/case_read_defaults/"

    data = PSRI.load_study(
        PSRI.OpenInterface();
        data_path = case_path,
        use_defaults = true,
        rectify_json_data = true,
    )

    bus_collection = data.raw["PSRBus"]
    gaugin_collection = data.raw["PSRGaugingStation"]
    study_collection = data.raw["PSRStudy"]

    @test bus_collection[1]["AVId"] == "string"
    @test bus_collection[1]["name"] == "string"
    @test bus_collection[1]["Kv"] == 0.0
    @test bus_collection[1]["reference_id"] == 2
    @test bus_collection[1]["code"] == 0
    @test bus_collection[1]["icca"] == 0

    @test bus_collection[2]["AVId"] == "string"
    @test bus_collection[2]["name"] == "string"
    @test bus_collection[2]["Kv"] == 0.0
    @test bus_collection[2]["reference_id"] == 3
    @test bus_collection[2]["code"] == 0
    @test bus_collection[2]["icca"] == 0

    @test gaugin_collection[1]["Teta"] == [
        0.0,
    ]
    @test gaugin_collection[1]["code"] == 0
    @test gaugin_collection[1]["Sd"] == [
        0.0,
    ]
    @test gaugin_collection[1]["Fi(1)"] == [
        0.0,
    ]
    @test gaugin_collection[1]["AVId"] == "string"
    @test gaugin_collection[1]["name"] == "string"
    @test gaugin_collection[1]["reference_id"] == 4
    @test gaugin_collection[1]["Ordem"] == [
        0,
    ]
    @test gaugin_collection[1]["Av"] == [
        0.0,
    ]
    @test gaugin_collection[1]["Vazao"] == [
        0.0,
    ]
    @test gaugin_collection[1]["Data"] == [
        Dates.Date(1900, 1, 1),
    ]

    @test gaugin_collection[2]["Teta"] == [
        0.0,
    ]
    @test gaugin_collection[2]["code"] == 0
    @test gaugin_collection[2]["Sd"] == [
        0.0,
    ]
    @test gaugin_collection[2]["Fi(1)"] == [
        0.0,
    ]
    @test gaugin_collection[2]["AVId"] == "string"
    @test gaugin_collection[2]["name"] == "string"
    @test gaugin_collection[2]["reference_id"] == 5
    @test gaugin_collection[2]["Ordem"] == [
        0,
    ]
    @test gaugin_collection[2]["Av"] == [
        0.0,
    ]
    @test gaugin_collection[2]["Vazao"] == [
        0.0,
    ]
    @test gaugin_collection[2]["Data"] == [
        Dates.Date(1900, 1, 1),
    ]

    @test study_collection[1]["DateChroDeficitCost"] == [
        Dates.Date(1900, 1, 1),
    ]
    @test study_collection[1]["FutureCostStage"] == 0
    @test study_collection[1]["NumberOpenings"] == 0
    @test study_collection[1]["Series_Backward"] == 0
    @test study_collection[1]["VersionRenewableBlockProfile"] == 0
    @test study_collection[1]["DeficitCost"] == [0.0]
    @test study_collection[1]["DataHourBlock"] == [
        Dates.Date(1900, 1, 1),
    ]
    @test study_collection[1]["Vazoes"] == 0
    @test study_collection[1]["VersaoInfoCargaBarra"] == "string"
    @test study_collection[1]["Ano_inicial"] == 0
    @test study_collection[1]["AVId"] == "string"
    @test study_collection[1]["Configuracao"] == 0
    @test study_collection[1]["Horizonte"] == 0
    @test study_collection[1]["MinSpillageUnit"] == 0
    @test study_collection[1]["DeficitSegment"] == [
        0.0,
    ]
    @test study_collection[1]["Etapa_inicial"] == 0
    @test study_collection[1]["NumeroAnosAdicionaisParm2"] == 0
    @test study_collection[1]["Mes_Inicial_Hidro"] == 0
    @test study_collection[1]["FlagCreateFutureCost"] == 0
    @test study_collection[1]["SubHourlyScenario"] == [
        0,
    ]
    @test study_collection[1]["Perdas"] == 0
    @test study_collection[1]["SubHourlyDiscretization"] == 0
    @test study_collection[1]["FutureCostEntryFileName"] == "string"
    @test study_collection[1]["CodigoSistemas"] == [
        0,
    ]
    @test study_collection[1]["MinOutflowPenalty"] == 0.0
    @test study_collection[1]["NumeroSistemas"] == 0
    @test study_collection[1]["CurrencyFactor"] == [
        0.0,
    ]
    @test study_collection[1]["Objetivo"] == 0
    @test study_collection[1]["Idioma"] == 0
    @test study_collection[1]["Currency"] == [
        "string",
    ]
    @test study_collection[1]["NumeroBlocosDemanda"] == 0
    @test study_collection[1]["ChroDeficitCost(1)"] == [
        0.0,
    ]
    @test study_collection[1]["NumberSimulations"] == 0
    @test study_collection[1]["code"] == 0
    @test study_collection[1]["FutureCostReadFileName"] == "string"
    @test study_collection[1]["SpillagePenalty"] == 0.0
    @test study_collection[1]["TaxaDesconto"] == 0.0
    @test study_collection[1]["FlagReadFutureCost"] == 0
    @test study_collection[1]["name"] == "string"
    @test study_collection[1]["Rede"] == 0
    @test study_collection[1]["FutureCostYear"] == 0
    @test study_collection[1]["HourBlockMap"] == [
        0,
    ]
    @test study_collection[1]["Series_Forward"] == 0
    @test study_collection[1]["NumeroAnosAdicionais"] == 0
    @test study_collection[1]["Ano_Inicial_Hidro"] == 0
    @test study_collection[1]["NumeroEtapas"] == 0
    @test study_collection[1]["SubHourlyStage"] == [Dates.Date(1900, 1, 1)]
    @test study_collection[1]["Tipo_Etapa"] == 0
    @test study_collection[1]["Series_Simular"] == 0
    @test study_collection[1]["NumeroAnosAdicionaisParm3"] == 0
    @test study_collection[1]["reference_id"] == 1
    @test study_collection[1]["InitialStageFutureCost"] == 0
    @test study_collection[1]["CriterioConvergencia"] == 0.0
    @test study_collection[1]["NivelInformes"] == 0
    @test study_collection[1]["FinalStageFutureCost"] == 0
    @test study_collection[1]["MaximoIteracoes"] == 0
    @test study_collection[1]["NumberBlocks"] == 0
    @test study_collection[1]["IndexSeriesSimulacao"] == [0]
    @test study_collection[1]["CurrencyReference"] == "string"
    @test study_collection[1]["Manutencao"] == 0
    @test study_collection[1]["FlagUseHotStart"] == 0
    @test study_collection[1]["SubHourlyDays"] == [0]
    @test study_collection[1]["Opcao"] == 0
    @test study_collection[1]["NumeroBlocosDemandaParm2"] == 0
end

test_read_defaults()
