PATH_CASE_0 = joinpath(@__DIR__, "data", "caso0")

data = PSRI.initialize_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_0
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
thermCVaria = PSRI.mapped_vector(data, "PSRThermalPlant", "CEsp", Float64, "segment", "block") # remove list?
@test thermCVaria == [[10], [15], [12.5]]

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
for stage = 1:5, block = 1:number_blocks 
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

    for iterm = 1:nthermal
        println(string(
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
            ))
    end
end

@test PSRI.get_nonempty_vector(data, "PSRThermalPlant", "ChroGerMin") == Bool[0, 0, 0]
@test PSRI.get_nonempty_vector(data, "PSRThermalPlant", "SpinningReserve") == Bool[0, 0, 0]

vazao = PSRI.get_vector(data, "PSRGaugingStation", "Vazao", 1, Float64)
@test vazao[2] == 35.01

vazao = PSRI.get_vectors(data, "PSRGaugingStation", "Vazao", Float64)
@test vazao[1][2] == 35.01
@test vazao[2][2] == 0.0

fi_6 = PSRI.get_vector(data, "PSRGaugingStation", "Fi", 2, Float64, dim1 = 6)
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
@test cesp[1,1][1] == 12.5
@test cesp[2,1][1] == 0.0
@test cesp[3,1][1] == 0.0

cesp = PSRI.get_vectors_2d(data, "PSRThermalPlant", "CEsp", Float64)
@test cesp[3][1,1][1] == 12.5
@test cesp[3][2,1][1] == 0.0
@test cesp[3][3,1][1] == 0.0
@test cesp[2][1,1][1] == 15.0
@test cesp[2][2,1][1] == 0.0
@test cesp[2][3,1][1] == 0.0


@test PSRI.get_parm(data, "PSRThermalPlant", "ComT", 2, Int32) == 0
@test PSRI.get_parm(data, "PSRThermalPlant", "RampUp", 2, Float64, default = 3.6) == 3.6

@test PSRI.get_parms(data, "PSRThermalPlant", "ComT", Int32) == zeros(Int32, 3)

@test PSRI.get_parm_1d(data, "PSRHydroPlant", "FP", 1, Float64) ==  [0.0, 0.0, 0.0, 0.0, 0.0]
@test PSRI.get_parm_1d(data, "PSRHydroPlant", "FP.VOL", 1, Float64) == [0.0, 0.0, 0.0, 0.0, 0.0]

@test PSRI.get_parms_1d(data, "PSRHydroPlant", "FP", Float64) ==  [[0.0, 0.0, 0.0, 0.0, 0.0]]