PATH_CASE_0 = joinpath(@__DIR__, "data", "case0")

function read_json_1()
    data = PSRI.load_study(
        PSRI.OpenInterface();
        data_path = PATH_CASE_0,
    )

    @test 0.0 == PSRI.configuration_parameter(data, "TaxaDesconto", 0.0)
    @test 10 == PSRI.configuration_parameter(data, "MaximoIteracoes", 0)
    @test 10 == PSRI.configuration_parameter(data, "MaximoIteracoes", 0)
    @test 5000.0 == PSRI.configuration_parameter(data, "MinOutflowPenalty", 0.0)
    @test [500.0] == PSRI.configuration_parameter(data, "DeficitCost", [0.0])
    @test [100.0] == PSRI.configuration_parameter(data, "DeficitSegment", [0.0])

    #       --------------------------------------------
    #       Parte 3 - Obtem lista de entidades desejadas
    #       --------------------------------------------

    #       Obtem total de sistemas e usinas associadas
    #       -------------------------------------------
    nsys = PSRI.max_elements(data, "PSRSystem")
    nhydro = PSRI.max_elements(data, "PSRHydroPlant")
    nthermal = PSRI.max_elements(data, "PSRThermalPlant")
    @test nsys == 1
    @test nhydro == 1
    @test nthermal == 3

    #       -----------------------------------------
    #       Parte 4 - Obtem informacoes do PSRCLASSES
    #       -----------------------------------------

    ipthermsys = PSRI.get_map(data, "PSRThermalPlant", "PSRSystem")
    iphydrosys = PSRI.get_map(data, "PSRHydroPlant", "PSRSystem")

    sys_names = PSRI.get_name(data, "PSRSystem")
    @test sys_names == ["System 1"]
    systemCode = PSRI.get_code(data, "PSRSystem")

    thermName = PSRI.get_name(data, "PSRThermalPlant")
    thermCode = PSRI.get_code(data, "PSRThermalPlant")
    @test thermCode == [1, 2, 3]
    thermFut = PSRI.mapped_vector(data, "PSRThermalPlant", "Existing", Int32) # remove list?
    thermCap = PSRI.mapped_vector(data, "PSRThermalPlant", "PotInst", Float64) # remove list?
    @test thermCap == [10.0, 5.0, 20.0]
    thermCVaria =
        PSRI.mapped_vector(data, "PSRThermalPlant", "CEsp", Float64, "segment", "block") # remove list?
    @test thermCVaria == [10, 15, 12.5]

    #       Posiciona controlador de tempo no primeiro estagio do estudo
    #       ------------------------------------------------------------
    PSRI.go_to_stage(data, 1)

    #       Posiciona os vetores com as dimens�es informadas
    #       Vetores que foram mapeados com a dimens�o "segment" ser�o posicionados em segment=1
    #       Vetores que foram mapeados com a dimens�o "block" ser�o posicionados em block=1
    #       -----------------------------------------------------------------------------------
    PSRI.go_to_dimension(data, "segment", 1)
    PSRI.go_to_dimension(data, "block", 1)

    PSRI.update_vectors!(data)
    # update_vectors!(data, filter = ["", ""])

    #       --------------------------------------------------
    #       Parte 5 - Exibe um sumario das informacoes do caso
    #       --------------------------------------------------
    println(string("Descricao do caso: ", PSRI.description(data)))

    println(string("Total de estagios: ", PSRI.total_stages(data)))
    println(string("Total de cenarios: ", PSRI.total_scenarios(data)))
    println(string("Total de blocos: ", PSRI.total_blocks(data)))

    println(string("Total de sistemas do caso: ", nsys))
    println(string("Total de hydros do caso: ", nhydro))
    println(string("Total de termicas do caso: ", nthermal))

    println("Overview das Termicas:")

    #       Obtem par�metros de interesse do estudo
    #       ---------------------------------------
    number_stages = PSRI.total_stages(data)
    number_blocks = PSRI.total_blocks(data)

    @test number_stages == 2
    @test number_blocks == 1
    #       Loops de configura��es (percorrer todos os est�gios e blocos)
    #       -------------------------------------------------------------
    for stage in 1:5, block in 1:number_blocks
        println(string("Configuracao: ", stage, " bloco: ", block))
        println("Stage duration: ", PSRI.stage_duration(data, stage))
        println("Block duration: ", PSRI.block_duration(data, stage, block))

        #       Seta o estagio
        #       --------------
        PSRI.go_to_stage(data, stage)

        #       Seta o bloco atual pelo time controller
        #       ---------------------------------------------------
        PSRI.go_to_dimension(data, "block", block)

        #       Refaz o pull para a memoria dos atributos
        #       atualizando os vetores JULIA para a fotografia atual
        #       ---------------------------------------------------
        PSRI.update_vectors!(data)

        #       Mostra na tela as informacoes mapeadas das termicas
        #       ---------------------------------------------------
        println(string("Exibindo atributos para estagio: ", stage, " bloco: ", block))

        for iterm in 1:nthermal
            println(
                string(
                    thermCode[iterm], " ",
                    thermName[iterm], " ",
                    "SISTEMA: ",
                    systemCode[ipthermsys[iterm]], " ",
                    sys_names[ipthermsys[iterm]], " ",
                    thermFut[iterm], " ",
                    thermCap[iterm], " ",
                    # thermCost[iterm], " ",
                    thermCVaria[iterm], " ",
                    # thermCTransp[iterm]
                ),
            )
        end
    end

    @test PSRI.get_nonempty_vector(data, "PSRThermalPlant", "ChroGerMin") == Bool[0, 0, 0]
    @test PSRI.get_nonempty_vector(data, "PSRThermalPlant", "SpinningReserve") ==
          Bool[0, 0, 0]

    vazao = PSRI.get_vector(data, "PSRGaugingStation", "Vazao", 1, Float64)
    @test vazao[2] == 35.01

    vazao = PSRI.get_vectors(data, "PSRGaugingStation", "Vazao", Float64)
    @test vazao[1][2] == 35.01
    @test vazao[2][2] == 0.0

    fi_6 = PSRI.get_vector(data, "PSRGaugingStation", "Fi", 2, Float64; dim1 = 6)
    @test length(fi_6) == 12
    @test sum(fi_6) == 0

    fi = PSRI.get_vector_1d(data, "PSRGaugingStation", "Fi", 2, Float64)
    @test length(fi[6]) == 12
    @test sum(fi[6]) == 0

    fi = PSRI.get_vectors_1d(data, "PSRGaugingStation", "Fi", Float64)
    @test length(fi[2][6]) == 12
    @test sum(fi[2][6]) == 0
    @test length(fi[1][6]) == 12
    @test sum(abs.(fi[1][6])) == 0
    @test sum(abs.(fi[1][1])) > 0

    cesp = PSRI.get_vector_2d(data, "PSRThermalPlant", "CEsp", 3, Float64)
    @test cesp[1, 1][1] == 12.5
    @test cesp[2, 1][1] == 0.0
    @test cesp[3, 1][1] == 0.0

    cesp = PSRI.get_vectors_2d(data, "PSRThermalPlant", "CEsp", Float64)
    @test cesp[3][1, 1][1] == 12.5
    @test cesp[3][2, 1][1] == 0.0
    @test cesp[3][3, 1][1] == 0.0
    @test cesp[2][1, 1][1] == 15.0
    @test cesp[2][2, 1][1] == 0.0
    @test cesp[2][3, 1][1] == 0.0

    @test PSRI.get_parm(data, "PSRThermalPlant", "ComT", 2, Int32) == 0
    @test PSRI.get_parm(data, "PSRThermalPlant", "RampUp", 2, Float64; default = 3.6) == 3.6

    @test PSRI.get_parms(data, "PSRThermalPlant", "ComT", Int32) == zeros(Int32, 3)

    @test PSRI.get_parm_1d(data, "PSRHydroPlant", "FP", 1, Float64) ==
          [0.0, 0.0, 0.0, 0.0, 0.0]
    @test PSRI.get_parm_1d(data, "PSRHydroPlant", "FP.VOL", 1, Float64) ==
          [0.0, 0.0, 0.0, 0.0, 0.0]

    @test PSRI.get_parms_1d(data, "PSRHydroPlant", "FP", Float64) ==
          [[0.0, 0.0, 0.0, 0.0, 0.0]]
end

function read_json_2()
    data = PSRI.load_study(
        PSRI.OpenInterface();
        data_path = joinpath(".", "data", "case1"),
    )

    @test_throws ErrorException PSRI.mapped_vector(data, "PSRBattery", "Einic", Float64)
    @test_throws ErrorException PSRI.mapped_vector(data, "PSRBattery", "Einic", Int32)
    @test_throws ErrorException PSRI.get_parms(data, "PSRBattery", "Einic", Int32)

    @test PSRI.get_parms(data, "PSRBattery", "Einic", Float64) == Float64[0, 0, 0]
    @test PSRI.get_parms(data, "PSRBattery", "ChargeRamp", Float64) == Float64[-1, -1, -1]
    @test PSRI.get_parms(data, "PSRBattery", "DischargeRamp", Float64) ==
          Float64[-1, -1, -1]

    PSRI.get_parms(data, "PSRBattery", "Einic", Float64)
    PSRI.get_parms(data, "PSRBattery", "ChargeRamp", Float64)
    PSRI.get_parms(data, "PSRBattery", "DischargeRamp", Float64)

    status = PSRI.mapped_vector(data, "PSRThermalPlant", "Existing", Int32)
    @test status == Int32[0, 0, 0, 0, 0]
    capacity = PSRI.mapped_vector(data, "PSRThermalPlant", "PotInst", Float64)
    @test capacity == [888.0, 0.1, 0.5, 1.0, 2.0]

    # calling again is not valid
    @test_throws ErrorException capfail =
        PSRI.mapped_vector(data, "PSRThermalPlant", "PotInst", Float64)

    @test ter2sys =
        PSRI.get_map(data, "PSRThermalPlant", "PSRSystem") == Int32[1, 1, 1, 1, 1]
    @test fcs2ter =
        PSRI.get_map(data, "PSRFuelConsumption", "PSRThermalPlant") == Int32[1, 2, 3, 4, 5]
    @test bat2sys = PSRI.get_map(data, "PSRBattery", "PSRSystem") == Int32[1, 1, 1]
    @test bat2bus = PSRI.get_map(data, "PSRBattery", "PSRBus") == Int32[125, 13, 60]

    @test ger2ter =
        PSRI.get_map(data, "PSRGenerator", "PSRThermalPlant") ==
        Int32[0, 2, 4, 5, 0, 3, 0, 0, 1]
    @test ger2bat =
        PSRI.get_map(data, "PSRGenerator", "PSRGndPlant") ==
        Int32[1, 0, 0, 0, 2, 0, 3, 4, 0]
    @test ger2bus =
        PSRI.get_map(data, "PSRGenerator", "PSRBus") ==
        Int32[20, 33, 39, 51, 71, 86, 93, 109, 117]

    @test busFcur =
        PSRI.get_map(data, "PSRSerie", "PSRBus"; relation_type = PSRI.PMD.RELATION_FROM) ==
        Int32[
            1,
            1,
            1,
            3,
            3,
            5,
            7,
            8,
            8,
            8,
            9,
            13,
            13,
            14,
            14,
            15,
            15,
            18,
            18,
            19,
            21,
            21,
            23,
            23,
            25,
            25,
            26,
            26,
            27,
            28,
            29,
            30,
            31,
            34,
            35,
            35,
            36,
            36,
            38,
            40,
            40,
            42,
            42,
            44,
            44,
            45,
            47,
            47,
            49,
            50,
            51,
            52,
            53,
            54,
            54,
            55,
            57,
            57,
            58,
            60,
            60,
            62,
            63,
            64,
            65,
            67,
            67,
            67,
            68,
            69,
            70,
            72,
            72,
            73,
            74,
            76,
            76,
            77,
            78,
            78,
            80,
            81,
            81,
            82,
            84,
            86,
            87,
            87,
            89,
            89,
            91,
            91,
            93,
            93,
            95,
            97,
            98,
            99,
            100,
            101,
            101,
            102,
            103,
            105,
            105,
            106,
            108,
            108,
            109,
            110,
            110,
            112,
            113,
            115,
            116,
            119,
            120,
            122,
            9,
            25,
            120,
            13,
            18,
            60,
            97,
            123,
            127,
            54,
            118,
            125,
            117,
            61,
            61,
            117,
        ]
    @test busTcir =
        PSRI.get_map(data, "PSRSerie", "PSRBus"; relation_type = PSRI.PMD.RELATION_TO) ==
        Int32[
            2,
            3,
            7,
            4,
            5,
            6,
            8,
            12,
            9,
            13,
            14,
            34,
            18,
            11,
            10,
            16,
            17,
            19,
            21,
            20,
            22,
            23,
            24,
            25,
            26,
            28,
            27,
            31,
            33,
            29,
            30,
            123,
            32,
            15,
            36,
            40,
            37,
            38,
            39,
            41,
            42,
            43,
            44,
            45,
            47,
            46,
            48,
            49,
            50,
            51,
            118,
            53,
            54,
            55,
            57,
            56,
            58,
            60,
            59,
            61,
            62,
            63,
            64,
            65,
            66,
            68,
            72,
            97,
            69,
            70,
            71,
            73,
            76,
            74,
            75,
            77,
            86,
            78,
            79,
            80,
            81,
            82,
            84,
            83,
            85,
            87,
            88,
            89,
            90,
            91,
            92,
            93,
            94,
            95,
            96,
            98,
            99,
            100,
            127,
            102,
            105,
            103,
            104,
            106,
            108,
            107,
            109,
            125,
            110,
            111,
            112,
            113,
            114,
            35,
            1,
            52,
            67,
            101,
            14,
            26,
            67,
            119,
            115,
            120,
            122,
            124,
            128,
            94,
            125,
            126,
            116,
            129,
            129,
            116,
        ]

    @test fcs2fue =
        PSRI.get_map(data, "PSRFuelConsumption", "PSRFuel") == Int32[1, 2, 3, 4, 5]
    @test_throws ErrorException PSRI.get_map(data, "PSRThermalPlant", "PSRFuel")
    @test ter2fue =
        PSRI.get_vector_map(data, "PSRThermalPlant", "PSRFuel") ==
        Vector{Int32}[[1], [2], [3], [4], [5]]

    #=
        reverse relations
    =#

    # for each thermal, return its generator
    @test PSRI.get_reverse_map(data, "PSRGenerator", "PSRThermalPlant") ==
          Int32[9, 2, 6, 3, 4]

    # same for gnd
    @test PSRI.get_reverse_map(data, "PSRGenerator", "PSRGndPlant") == Int32[1, 5, 7, 8]

    # for each bus, return all generators there
    @test PSRI.get_reverse_vector_map(
        data,
        "PSRGenerator",
        "PSRBus";
        original_relation_type = PSRI.PMD.RELATION_1_TO_1,
    ) == Vector{Int32}[
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [1],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [2],
        [],
        [],
        [],
        [],
        [],
        [3],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [4],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [5],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [6],
        [],
        [],
        [],
        [],
        [],
        [],
        [7],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [8],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [9],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
        [],
    ]
end

function read_json_3()
    data = PSRI.load_study(
        PSRI.OpenInterface();
        data_path = joinpath(".", "data", "case2"),
    )

    @test 1 == PSRI.configuration_parameter(data, "BMAP", 2)
    @test 1 == PSRI.configuration_parameter(data, "VALE", 1)
    @test 0 == PSRI.configuration_parameter(data, "MNIT", 1)

    @test PSRI.get_map(data, "PSRGaugingStation", "PSRGaugingStation") == Int32[0, 1]

    @test PSRI.get_map(
        data,
        "PSRHydroPlant",
        "PSRHydroPlant";
        relation_type = PSRI.PMD.RELATION_TURBINE_TO,
    ) == Int32[2, 0]
    @test PSRI.get_map(
        data,
        "PSRHydroPlant",
        "PSRHydroPlant";
        relation_type = PSRI.PMD.RELATION_SPILL_TO,
    ) == Int32[2, 0]
    @test PSRI.get_map(
        data,
        "PSRHydroPlant",
        "PSRHydroPlant";
        relation_type = PSRI.PMD.RELATION_INFILTRATE_TO,
    ) == Int32[2, 0]
    @test PSRI.get_map(
        data,
        "PSRHydroPlant",
        "PSRHydroPlant";
        relation_type = PSRI.PMD.RELATION_STORED_ENERGY_DONWSTREAM,
    ) == Int32[2, 0]

    @test PSRI.get_map(
        data,
        "PSRInterconnection",
        "PSRSystem";
        relation_type = PSRI.PMD.RELATION_FROM,
    ) == Int32[1]
    @test PSRI.get_map(
        data,
        "PSRInterconnection",
        "PSRSystem";
        relation_type = PSRI.PMD.RELATION_TO,
    ) == Int32[2]
    @test_throws ErrorException PSRI.get_vector_map(
        data,
        "PSRThermalPlant",
        "PSRFuelConsumption";
        relation_type = PSRI.PMD.RELATION_1_TO_N,
    )

    @test PSRI.get_vector_map(data, "PSRInterconnectionSumData", "PSRInterconnection") ==
          Vector{Int32}[[1]]
    attr1 = PSRI._get_relation_attribute(
        data,
        "PSRInterconnectionSumData",
        "PSRInterconnection",
        PSRI.PMD.RELATION_1_TO_N,
    )
    @test PSRI.get_vector_map(
        data,
        "PSRInterconnectionSumData",
        "PSRInterconnection",
        attr1,
    ) ==
          Vector{Int32}[[1]]

    @test PSRI.get_vector_map(data, "PSRGenerationConstraintData", "PSRThermalPlant") ==
          Vector{Int32}[[1, 3]]
    attr2 = PSRI._get_relation_attribute(
        data,
        "PSRGenerationConstraintData",
        "PSRThermalPlant",
        PSRI.PMD.RELATION_1_TO_N,
    )
    @test PSRI.get_vector_map(
        data,
        "PSRGenerationConstraintData",
        "PSRThermalPlant",
        attr2,
    ) ==
          Vector{Int32}[[1, 3]]

    @test PSRI.get_vector_map(data, "PSRGenerationConstraintData", "PSRHydroPlant") ==
          Vector{Int32}[[2]]
    attr3 = PSRI._get_relation_attribute(
        data,
        "PSRGenerationConstraintData",
        "PSRHydroPlant",
        PSRI.PMD.RELATION_1_TO_N,
    )
    @test PSRI.get_vector_map(
        data,
        "PSRGenerationConstraintData",
        "PSRHydroPlant",
        attr3,
    ) ==
          Vector{Int32}[[2]]

    @test PSRI.get_vector_map(data, "PSRGenerationConstraintData", "PSRGndPlant") ==
          Vector{Int32}[[]]
    attr4 = PSRI._get_relation_attribute(
        data,
        "PSRGenerationConstraintData",
        "PSRGndPlant",
        PSRI.PMD.RELATION_1_TO_N,
    )
    @test PSRI.get_vector_map(data, "PSRGenerationConstraintData", "PSRGndPlant", attr4) ==
          Vector{Int32}[[]]

    @test PSRI.get_vector_map(data, "PSRGenerationConstraintData", "PSRBattery") ==
          Vector{Int32}[[]]
    attr5 = PSRI._get_relation_attribute(
        data,
        "PSRGenerationConstraintData",
        "PSRBattery",
        PSRI.PMD.RELATION_1_TO_N,
    )
    @test PSRI.get_vector_map(data, "PSRGenerationConstraintData", "PSRBattery", attr5) ==
          Vector{Int32}[[]]

    @test PSRI.get_map(data, "PSRMaintenanceData", "PSRSystem") == Int32[1]
    @test PSRI.get_map(data, "PSRMaintenanceData", "PSRThermalPlant") == Int32[0]
    @test PSRI.get_map(data, "PSRMaintenanceData", "PSRHydroPlant") == Int32[1]
    @test PSRI.get_map(data, "PSRMaintenanceData", "PSRGndPlant") == Int32[0]

    @test PSRI.get_vector_map(
        data,
        "PSRReserveGenerationConstraintData",
        "PSRThermalPlant",
    ) ==
          Vector{Int32}[[1, 2]]
    @test PSRI.get_vector_map(
        data,
        "PSRReserveGenerationConstraintData",
        "PSRHydroPlant",
    ) ==
          Vector{Int32}[[1]]
    @test PSRI.get_vector_map(data, "PSRReserveGenerationConstraintData", "PSRGndPlant") ==
          Vector{Int32}[[]]
    @test PSRI.get_vector_map(data, "PSRReserveGenerationConstraintData", "PSRBattery") ==
          Vector{Int32}[[]]

    @test PSRI.get_vector_map(
        data,
        "PSRReserveGenerationConstraintData",
        "PSRThermalPlant";
        relation_type = PSRI.PMD.RELATION_BACKED,
    ) == Vector{Int32}[[]]
    @test PSRI.get_vector_map(
        data,
        "PSRReserveGenerationConstraintData",
        "PSRHydroPlant";
        relation_type = PSRI.PMD.RELATION_BACKED,
    ) == Vector{Int32}[[]]
    @test PSRI.get_vector_map(
        data,
        "PSRReserveGenerationConstraintData",
        "PSRGndPlant";
        relation_type = PSRI.PMD.RELATION_BACKED,
    ) == Vector{Int32}[[]]

    @test PSRI.get_vector_map(data, "PSRReservoirSet", "PSRHydroPlant") ==
          Vector{Int32}[[1, 2]]

    # reverse relations

    # upstream turbining hydros
    @test PSRI.get_reverse_vector_map(
        data,
        "PSRHydroPlant",
        "PSRHydroPlant";
        original_relation_type = PSRI.PMD.RELATION_TURBINE_TO,
    ) == Vector{Int32}[[], [1]]
    @test PSRI.get_reverse_vector_map(
        data,
        "PSRHydroPlant",
        "PSRHydroPlant",
        "turbinning",
    ) == Vector{Int32}[[], [1]]

    # for each hydro - return its maintenance data
    # both work for this one
    @test PSRI.get_reverse_map(data, "PSRMaintenanceData", "PSRHydroPlant") == Int32[1, 0]
    @test PSRI.get_reverse_vector_map(
        data,
        "PSRMaintenanceData",
        "PSRHydroPlant";
        original_relation_type = PSRI.PMD.RELATION_1_TO_1,
    ) == Vector{Int32}[[1], []]
    attr = PSRI._get_relation_attribute(
        data,
        "PSRMaintenanceData",
        "PSRHydroPlant",
        PSRI.PMD.RELATION_1_TO_1,
    )
    @test PSRI.get_reverse_map(data, "PSRMaintenanceData", "PSRHydroPlant", attr) ==
          Int32[1, 0]
    @test PSRI.get_reverse_vector_map(
        data,
        "PSRMaintenanceData",
        "PSRHydroPlant",
        attr,
    ) == Vector{Int32}[[1], []]

    # for each thermal - return all Gen Ctr it belongs
    # might be many so it fails (in this case)
    @test_throws ErrorException PSRI.get_map(
        data,
        "PSRGenerationConstraintData",
        "PSRThermalPlant",
    )
end

function read_json_4()
    temp_path = joinpath(tempdir(), "rectify_json")
    mkpath(temp_path)
    data = PSRI.create_study(
        PSRI.OpenInterface();
        data_path = temp_path,
    )

    PSRI.create_element!(data, "PSRReserveGenerationConstraintData")
    PSRI.create_element!(data, "PSRThermalPlant")
    PSRI.create_element!(data, "PSRThermalPlant")
    PSRI.create_element!(data, "PSRThermalPlant")
    PSRI.create_element!(data, "PSRThermalPlant")

    PSRI.set_vector_related!(
        data,
        "PSRReserveGenerationConstraintData",
        "PSRThermalPlant",
        1,
        [1, 2],
    )
    PSRI.set_vector_related!(
        data,
        "PSRReserveGenerationConstraintData",
        "PSRThermalPlant",
        1,
        [3, 4],
        PSRI.PMD.RELATION_BACKED,
    )

    PSRI.write_data(data)

    data_read = PSRI.load_study(
        PSRI.OpenInterface();
        data_path = temp_path,
        rectify_json_data = true,
    )

    @test PSRI.get_vector_related(
        data_read,
        "PSRReserveGenerationConstraintData",
        "PSRThermalPlant",
        1,
    ) == [1, 2]

    @test PSRI.get_vector(
        data_read,
        "PSRThermalPlant",
        "DataChroGerMin",
        Int32(1),
        Dates.Date,
    ) == [Dates.Date(1900, 01, 01)]
end

read_json_1()
read_json_2()
read_json_3()
read_json_4()
