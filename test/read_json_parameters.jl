data = PSRI.initialize_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_0
)

@test 0.0 == PSRI.configuration_parameter(data, "TaxaDesconto", 0.0)
@test 10 == PSRI.configuration_parameter(data, "MaximoIteracoes", 0)
@test 10 == PSRI.configuration_parameter(data, "MaximoIteracoes", 0)
@test 5000.0 == PSRI.configuration_parameter(data, "MinOutflowPenalty", 0.0)
@test_broken 0 == PSRI.configuration_parameter(data, "BMAP", 1)
@test_broken 1 == PSRI.configuration_parameter(data, "VALE", 0)
@test_broken 0 == PSRI.configuration_parameter(data, "MNIT", 10)

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
# fcs: thermCost = PSRI.mapped_vector(data, "PSRThermalPlant", "O&MCost", Float64) # remove list?
# thermCTransp = PSRI.mapped_vector(data, "PSRThermalPlant", "CTransp", Float64) # remove list?
# TODO: add fuel consumption updater
# @show thermCVaria = PSRI.mapped_vector(data, "PSRFuelConsumption", "CEsp", Float64, "segment", "block") # remove list?
thermCVaria = PSRI.mapped_vector(data, "PSRThermalPlant", "CEsp", Float64, "segment", "block") # remove list?
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
for stage = 1:5, block = 1:number_blocks 
    println(string("Configuracao: ", stage, " bloco: ", block))
    
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
            #   thermCost[iterm], " ",
                thermCVaria[iterm], " ",
            # thermCTransp[iterm]
            ))
    end
end