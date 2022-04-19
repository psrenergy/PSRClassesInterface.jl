# Examples

## Writing and reading a time series into a file

In this example we will demonstrate how to save a time series into a csv or binary file. 
The first step is to obtain the data that you wish to save

```@example rw_file
import PSRClassesInterface
const PSRI = PSRClassesInterface

#Creates dummy data
n_blocks = 2
n_scenarios = 3
n_stages = 4
n_agents = 5

time_series_data = rand(Float64, n_agents, n_blocks, n_scenarios, n_stages)

nothing #hide
```

There are two ways of saving the data to a file, save the data in the file directly or iteratively.
To save the data directly use the function [`PSRI.array_to_file`](@ref) by calling:
```@example rw_file
FILE_PATH = joinpath(".", "example")

PSRI.array_to_file(
    PSRI.OpenBinary.Writer,
    FILE_PATH,
    time_series_data,
    agents = ["Agent 1", "Agent 2", "Agent 3", "Agent 4", "Agent 5"],
    unit = "MW";
    initial_stage = 3,
    initial_year = 2006,
)
```

To save the data iteractively use the function [`PSRI.open`](@ref) to create an [`PSRI.AbstractWriter`](@ref).
Save the data of each registry to the file using the function [`PSRI.write_registry`](@ref) and then close the data stream
calling the function [`PSRI.close`](@ref).

```@example rw_file 
iow = PSRI.open(
    PSRI.OpenBinary.Writer,
    FILE_PATH,
    blocks = n_blocks,
    scenarios = n_scenarios,
    stages = n_stages,
    agents = ["Agent 1", "Agent 2", "Agent 3", "Agent 4", "Agent 5"],
    unit = "MW",
    initial_stage = 1,
    initial_year = 2006,
)

for stage = 1:n_stages, scenario = 1:n_scenarios, block = 1:n_blocks
    PSRI.write_registry(
        iow,
        time_series_data[:, block, scenario, stage],
        stage,
        scenario,
        block
    )
end

PSRI.close(iow)
```

A similar logic can be used to read the data from a file. You can read it directly or iteratively.
To read the data directly use the function [`PSRI.file_to_array`](@ref) or [`PSRI.file_to_array_and_header`](@ref)
```@example rw_file
data_from_file = PSRI.file_to_array(
        PSRI.OpenBinary.Reader, 
        FILE_PATH
    )

@assert data_from_file_and_header == time_series_data

data_from_file_and_header, header = PSRI.file_to_array_and_header(
        PSRI.OpenBinary.Reader, 
        FILE_PATH
    )

@assert data_from_file_and_header == time_series_data
```

To read the data iteractively use the function [`PSRI.open`](@ref) to create an [`PSRI.AbstractReader`](@ref) and
read each registry iteratively. At the end you should close the [`PSRI.AbstractReader`](@ref) by calling [`PSRI.close`](@ref)
```@example rw_file
ior = PSRI.open(
    PSRI.OpenBinary.Reader, 
    FILE_PATH;
    use_header = false
)

data_from_file = zeros(n_agents, n_blocks, n_scenarios, n_stages)

for stage = 1:n_stages, scenario = 1:n_scenarios, block = 1:n_blocks
    PSRI.next_registry(ior)
    data_from_file[:, block, scenario, stage] = ior.data
end

PSRI.close(ior)

rm(FILE_PATH; force = true)
```

## Reading configuration parameters 

Most cases have configuration parameters such as the maximum number of iterations, the discount rate, the deficit cost etc. The
function [`PSRI.configuration_parameter`](@ref) reads all the parameters from the cases.

```@example thermal_gens_pars
import PSRClassesInterface
const PSRI = PSRClassesInterface

PATH_CASE_EXAMPLE_CONFIGS = joinpath(pathof(PSRI) |> dirname |> dirname, "test", "data", "caso0")

data = PSRI.initialize_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_EXAMPLE_CONFIGS
)

PSRI.configuration_parameter(data, "TaxaDesconto", 0.0)
PSRI.configuration_parameter(data, "MaximoIteracoes", 0)
PSRI.configuration_parameter(data, "MaximoIteracoes", 0)
PSRI.configuration_parameter(data, "MinOutflowPenalty", 0.0)
PSRI.configuration_parameter(data, "DeficitCost", [0.0])
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
```

The first thing we must do is to initialize the reading procedure with the following commands:
```@example thermal_gens_pars
import PSRClassesInterface
const PSRI = PSRClassesInterface

PATH_CASE_EXAMPLE_THERMALS = joinpath(pathof(PSRI) |> dirname |> dirname, "test", "data", "caso0")

data = PSRI.initialize_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_EXAMPLE_THERMALS
)
```

We can initialize the struct with the parameters of the first stage using the function [`PSRI.mapped_vector`](@ref)
```@example thermal_gens_pars
therm_gen = ThermalGenerators()
therm_gen.names = PSRI.get_name(data, "PSRThermalPlant")
therm_gen.codes = PSRI.get_code(data, "PSRThermalPlant")
therm_gen.generation_capacities = PSRI.mapped_vector(data, "PSRThermalPlant", "PotInst", Float64)
therm_gen.therm2sys = PSRI.get_map(data, "PSRThermalPlant", "PSRSystem")
```

And afterwards we can update the parameters for each stage as follows.
```@example thermal_gens_pars
for stage in 1:PSRI.total_stages(data)
    PSRI.go_to_stage(data, stage)
    PSRI.update_vectors!(data)
    println("Thermal generator 2 generation capacity at stage $stage $(therm_gen.generation_capacities[2])")
end
```

## Reading basic battery parameters

This example is very similar to "Reading basic thermal generator parameters", but it is necessary to be cautious about the diffence between elements. For instance, batteries have different parameters than thermal generators, therefore, our data structure must be defined accordingly:
```@example batteries_pars
Base.@kwdef mutable struct Batteries
    names::Vector{String} = String[]
    codes::Vector{Int32} = Int32[]
    charge_eff::Vector{Float64} = Float64[]
    bat2sys::Vector{Int32} = Int32[]
end
```

Stardard proceadure of reading data from file:
```@example batteries_pars
import PSRClassesInterface
const PSRI = PSRClassesInterface

PATH_CASE_EXAMPLE_BATTERIES = joinpath(pathof(PSRI) |> dirname |> dirname, "test", "data", "caso1")

data = PSRI.initialize_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_EXAMPLE_BATTERIES
)
```

And now the struct may be instantiated by setting its appropriate parameters:
```@example batteries_pars
batteries = Batteries()
batteries.names = PSRI.get_name(data, "PSRBattery")
batteries.codes = PSRI.get_code(data, "PSRBattery")
batteries.charge_eff = PSRI.mapped_vector(data, "PSRBattery", "ChargeEffic", Int32)
batteries.bat2sys = PSRI.get_map(data, "PSRBattery", "PSRSystem")
```

## Determining subsystem from a certain hydro plant

In this example we will demonstrate how to make a simple use of a relationship map. That will be achieved by determining a subsystem from a certain hydro plant through its parameters. The program will initiate by the standard reading procedure:
```@example sys_by_gaug
import PSRClassesInterface
const PSRI = PSRClassesInterface

PATH_CASE_EXAMPLE_GAUGING = joinpath(pathof(PSRI) |> dirname |> dirname, "test", "data", "caso2")

data = PSRI.initialize_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_EXAMPLE_GAUGING
)
```

Next, the maps between hydroplants and systems is retrieved by the `get_map` method:
```@example sys_by_gaug
hyd2sys = PSRI.get_map(data, "PSRHydroPlant","PSRSystem")
```

## Determining buses from a certain thermal plant

This case consists of a more advanced use of a relationship map. We'll determine which buses are linked to a given target thermal plant, while there is no direct relationship between both. Firstly, the study data is read:
```@example the_by_bus
import PSRClassesInterface
const PSRI = PSRClassesInterface

PATH_CASE_EXAMPLE_BUS = joinpath(pathof(PSRI) |> dirname |> dirname, "test", "data", "caso1")

data = PSRI.initialize_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_EXAMPLE_BUS
)
```

Whereas there is no direct link between buses and thermal plants, both are indirectly related through generators. Therefore, we must identify those relationships by calling `get_map` for each:
```@example the_by_bus
gen2thermal = PSRI.get_map(data, "PSRGenerator","PSRThermalPlant")
gen2bus = PSRI.get_map(data, "PSRGenerator", "PSRBus")
```

Next, we can find which generators are linked to our target thermal plant by the indexes of `gen2the`:
```@example the_by_bus
target_thermal = 1
target_generator = findall(isequal(target_thermal), gen2thermal)
```

`target_generator` now holds the indexes of generators that are linked to the buses we are trying to identify. With those at hand, the indexes of the buses are easily identifiable by:
```@example the_by_bus
targetBus = gen2bus[target_generator]
```
