dict1 = Dict("a"=>1,"b"=>[Dict("reference_id" => 3), 2, 3], "fuels" => [3, 3]);
dict2 = Dict("a"=>3,"b"=>[Dict("reference_id" => 2), 2, 1, 4], "c" => true, "fuels" => [2, 3]);
logs = PSRI.compare(dict1, dict2);
@test logs ==  ["[fuels][2]", "[c]", "[b][3]", "[b][4]", "[a]"]

data_path1 = joinpath(".", "data", "caso1")
data_path2 = joinpath(".", "data", "caso2")

logs = PSRI.compare(data_path1, data_path2)

@test logs[1:11] == [ "[PSRFuelConsumption][1][CEsp(1,1)][1]",
                      "[PSRFuelConsumption][2][fuel]",        
                      "[PSRFuelConsumption][2][CEsp(1,1)][1]",
                      "[PSRFuelConsumption][3][CEsp(1,1)][1]",
                      "[PSRFuelConsumption][4]",
                      "[PSRFuelConsumption][5]",
                      "[PSRGndGaugingStation]",
                      "[PSRInterconnection]",
                      "[PSRDemand][1][name]",
                      "[PSRDemand][1][generic_id]",
                      "[PSRFuel][1][UComb]"]
                    
@test logs[end-9:end] == ["[PSRSystem][1][TipoUnidadeReservaGeracao]",
                           "[PSRSystem][1][generic_id]",
                           "[PSRSystem][1][TipoInfoReservaGeracao]",
                           "[PSRSystem][1][TipoUnidadeManutencaoHidro]",
                           "[PSRSystem][1][MOD:Resultados]",
                           "[PSRSystem][1][restricao]",
                           "[PSRSystem][1][reserveGeneration]",
                           "[PSRSystem][2]",
                           "[PSRReservoirSet]",
                           "[PSRTransformer]"]