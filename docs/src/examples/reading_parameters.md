# Reading parameters

## Reading configuration parameters 

Most cases have configuration parameters such as the maximum number of iterations, the discount rate, the deficit cost etc. The
function [`PSRClassesInterface.configuration_parameter`](@ref) reads all the parameters from the cases.

```@example thermal_gens_pars
import PSRClassesInterface
const PSRI = PSRClassesInterface

PATH_CASE_EXAMPLE_CONFIGS = joinpath(pathof(PSRI) |> dirname |> dirname, "test", "data", "case0")

data = PSRI.load_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_EXAMPLE_CONFIGS
)

PSRI.configuration_parameter(data, "TaxaDesconto", 0.0)
PSRI.configuration_parameter(data, "MaximoIteracoes", 0)
PSRI.configuration_parameter(data, "MaximoIteracoes", 0)
PSRI.configuration_parameter(data, "MinOutflowPenalty", 0.0)
PSRI.configuration_parameter(data, "DeficitCost", [0.0])
; nothing # hide
```

## Reading basic thermal generator parameters

In this example we will map parameters of thermal generators at each stage of the study to a struct.
Suppose in this case that our thermal generators has the following attributes:
```@example thermal_gens_pars
Base.@kwdef mutable struct ThermalGenerators
    names::Vector{String} = String[]
    codes::Vector{Int32} = Int32[]
    generation_capacities::Vector{Float64} = Float64[]
    therm2sys::Vector{Int32} = Int32[]
end
; nothing # hide
```

The first thing we must do is to initialize the reading procedure with the following commands:
```@example thermal_gens_pars
import PSRClassesInterface
const PSRI = PSRClassesInterface

PATH_CASE_EXAMPLE_THERMALS = joinpath(pathof(PSRI) |> dirname |> dirname, "test", "data", "case0")

data = PSRI.load_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_EXAMPLE_THERMALS
)
; nothing # hide
```

We can initialize the struct with the parameters of the first stage using the function [`PSRClassesInterface.mapped_vector`](@ref)
```@example thermal_gens_pars
therm_gen = ThermalGenerators()
therm_gen.names = PSRI.get_name(data, "PSRThermalPlant")
therm_gen.codes = PSRI.get_code(data, "PSRThermalPlant")
therm_gen.generation_capacities = PSRI.mapped_vector(data, "PSRThermalPlant", "PotInst", Float64)
therm_gen.therm2sys = PSRI.get_map(data, "PSRThermalPlant", "PSRSystem")
; nothing # hide
```

And afterwards we can update the parameters for each stage as follows.
```@example thermal_gens_pars
for stage in 1:PSRI.total_stages(data)
    PSRI.go_to_stage(data, stage)
    PSRI.update_vectors!(data)
    println("Thermal generator 2 generation capacity at stage $stage $(therm_gen.generation_capacities[2])")
end
; nothing # hide
```

## Reading basic battery parameters

This example is very similar to "Reading basic thermal generator parameters", but it is necessary to be cautious about the difference between elements. For instance, batteries have different parameters than thermal generators, therefore, our data structure must be defined accordingly:
```@example batteries_pars
Base.@kwdef mutable struct Batteries
    names::Vector{String} = String[]
    codes::Vector{Int32} = Int32[]
    charge_eff::Vector{Float64} = Float64[]
    bat2sys::Vector{Int32} = Int32[]
end
; nothing # hide
```

Stardard proceadure of reading data from file:
```@example batteries_pars
import PSRClassesInterface
const PSRI = PSRClassesInterface

PATH_CASE_EXAMPLE_BATTERIES = joinpath(pathof(PSRI) |> dirname |> dirname, "test", "data", "case1")

data = PSRI.load_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_EXAMPLE_BATTERIES
)
; nothing # hide
```

And now the struct may be instantiated by setting its appropriate parameters:
```@example batteries_pars
batteries = Batteries()
batteries.names = PSRI.get_name(data, "PSRBattery")
batteries.codes = PSRI.get_code(data, "PSRBattery")
batteries.charge_eff = PSRI.mapped_vector(data, "PSRBattery", "ChargeEffic", Float64)
batteries.bat2sys = PSRI.get_map(data, "PSRBattery", "PSRSystem")
; nothing # hide
```