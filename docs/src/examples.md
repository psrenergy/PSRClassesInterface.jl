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
        FILE_PATH;
        use_header=false
    )

@assert all(isapprox.(data_from_file, time_series_data, atol=1E-7))

data_from_file_and_header, header = PSRI.file_to_array_and_header(
        PSRI.OpenBinary.Reader, 
        FILE_PATH;
        use_header=false
    )
@assert all(isapprox.(data_from_file_and_header, time_series_data, atol=1E-7))
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

To choose the agents order use `use_header` and `header`

```@example rw_file
data_from_file = PSRI.file_to_array(
        PSRI.OpenBinary.Reader, 
        FILE_PATH;
        use_header=true,
        header=["Agent 5", "Agent 2", "Agent 3", "Agent 4", "Agent 1"]
    )
@assert all(isapprox.(data_from_file[1, :, :, :], time_series_data[end, :, :, :], atol=1E-7))
@assert all(isapprox.(data_from_file[end, :, :, :], time_series_data[1, :, :, :], atol=1E-7))
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

This example is very similar to "Reading basic thermal generator parameters", but it is necessary to be cautious about the difference between elements. For instance, batteries have different parameters than thermal generators, therefore, our data structure must be defined accordingly:
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
batteries.charge_eff = PSRI.mapped_vector(data, "PSRBattery", "ChargeEffic", Float64)
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
## Determining elasticity and value of demands
In this example we will read demand segments, obtain the value of demands, discover wheter each demand is elastic or inelastic, and then obtain the sums of demands by elasticity. The first step is to read the study data:
```@example demand
import PSRClassesInterface
const PSRI = PSRClassesInterface

PATH_CASE_EXAMPLE_DEM = joinpath(pathof(PSRI) |> dirname |> dirname, "test", "data", "caso1")

data = PSRI.initialize_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_EXAMPLE_DEM
)
```
Whereas the demand varies according to the stage, we must specify the stage by calling `go_to_stage`:
```@example demand
target_stage = 1
PSRI.go_to_stage(data,target_stage)
```
Now, we can read the demand segments and the map between demands and demand segments, and then obtain the value of each demand:
```@example demand
dem_seg = PSRI.mapped_vector(data, "PSRDemandSegment", "Demanda", Float64, "block")

seg2dem = PSRI.get_map(data, "PSRDemandSegment", "PSRDemand", relation_type = PSRI.RELATION_1_TO_1)

dem_size = PSRI.max_elements(data, "PSRDemand")

demand_values = zeros(dem_size)

for demand = 1:dem_size
    demand_values[demand] = sum(dem_seg[i] for i = 1:length(dem_seg) if seg2dem[i] == demand)
end

demand_values
```
We can discover the elasticity of each demand by calling `get_parms` with the parameter `Elastico`:
```@example demand
demands_elasticity = PSRI.get_parms(data, "PSRDemand", "Elastico", Int32)
```
If `demands_elasticity[i] == 0` it means that the demand at index `i` is inelastic, and elastic if `demands_elasticity[i] == 1`.
We can now obtain the total demands of each elasticity:
```@example demand
total_elastic_demand = 0.0
total_inelastic_demand = 0.0

for i = 1:dem_size
    if demands_elasticity[i] == 0
        total_inelastic_demand += demand_values[i]
    else
        total_elastic_demand += demand_values[i]
    end
end
```

### Determining demands values of each bus
Now we have the values of the demands, we can obtain the values of demand for each bus. 
Each demand has a set of loads, which define how much of this demand corresponds to each bus.  We can begin by reading the loads and its relations with demands and buses:
```@example demand
loads = PSRI.mapped_vector(data, "PSRLoad", "P", Float64, "block")
lod2dem = PSRI.get_map(data, "PSRLoad", "PSRDemand", relation_type = PSRI.RELATION_1_TO_1)
lod2bus = PSRI.get_map(data, "PSRLoad", "PSRBus", relation_type = PSRI.RELATION_1_TO_1)
```

The values of the loads are weights in a kind of a weighted arithmetic mean of the buses for each demand. But the loads of each demand don't add up to 1, so they need to be normalized to represent fractions of the total:
```@example demand
total_lod_bydem = zeros(dem_size)
lod_size = PSRI.max_elements(data, "PSRLoad")

for i in 1:lod_size
    total_lod_bydem[lod2dem[i]] += loads[i]
end

for i in 1:lod_size
    if total_lod_bydem[lod2dem[i]] > 0.0
        loads[i] = loads[i]/total_lod_bydem[lod2dem[i]]
    else
        loads[i] = 0.0
    end
end

loads
```
Now we know the fraction of each demand that corresponds to each bus, and can easily define the total demand by bus:
```@example demand
bus_size = PSRI.max_elements(data, "PSRBus")

dem_bybus = zeros(bus_size)

for lod = 1:lod_size
    fraction = loads[lod]
    dem = lod2dem[lod]
    bus = lod2bus[lod] 
    dem_bybus[bus] += demand_values[dem]*fraction
end

dem_bybus
```
## Determining which buses are connected by each circuit
Each circuit connects two buses, it starts from a bus and goes to another. In this example we'll discover these buses for each circuit and then we'll build an incidence matrix of buses by circuits. The first step is to read the data:
```@example cir_bus
import PSRClassesInterface
const PSRI = PSRClassesInterface

PATH_CASE_EXAMPLE_CIR_BUS = joinpath(pathof(PSRI) |> dirname |> dirname, "test", "data", "caso1")

data = PSRI.initialize_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_EXAMPLE_CIR_BUS
)
```
Next, we get from which bus each circuit starts and which bus it goes to with `get_map`:
```@example cir_bus
cir2bus_to = PSRI.get_map(data, "PSRSerie", "PSRBus"; relation_type = PSRI.RELATION_TO)
cir2bus_from = PSRI.get_map(data, "PSRSerie", "PSRBus"; relation_type = PSRI.RELATION_FROM)
```
Now we can build the incidence matrix. Each row corresponds to a circuit and each column corresponds to a bus. The element at the index (i,j) is -1 if the circuit i starts from the bus j, 1 if it goes to this bus, and 0 if they both have no relation:
```@example cir_bus 
bus_size = PSRI.max_elements(data, "PSRBus")
cir_size = PSRI.max_elements(data, "PSRSerie")
incidence_matrix = zeros(Float64, cir_size, bus_size)
for cir = 1:cir_size
    incidence_matrix[cir, cir2bus_from[cir]] = -1.0
    incidence_matrix[cir, cir2bus_to[cir]] = 1.0
end
incidence_matrix
``` 
## Calculating the energy prices of each thermal plant
The energy prices in a thermal plant deppends on the  the price of the fuel used, the specific consumption of this fuel and Operation and Maintenance cost. Again, we begin by reading the data:
```@example ther_prices
import PSRClassesInterface
const PSRI = PSRClassesInterface

PATH_CASE_EXAMPLE_THER_PRICES = joinpath(pathof(PSRI) |> dirname |> dirname, "test", "data", "caso1")

data = PSRI.initialize_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_EXAMPLE_THER_PRICES
)
```
We discover the necessary infos of the thermal plants indirectly through `PSRFuelConsumption`:
```@example ther_prices
fuelcons2ther = PSRI.get_map(data,"PSRFuelConsumption", "PSRThermalPlant"; relation_type = PSRI.RELATION_1_TO_1)

ther_size = PSRI.max_elements(data, "PSRThermalPlant")
fuelcons_size = PSRI.max_elements(data, "PSRFuelConsumption")
ther2fuelcons = [[fc for fc = 1:fuelcons_size if fuelcons2ther[fc] == t] for t = 1:ther_size]
```
Next, we get the O&M cost, the specific consumption and the relation with fuels of our fuels consumptions. Then we get the cost of each fuel. After calling `mapped_vector` we must call `update_vectors!`.
```@example ther_prices
om_cost = PSRI.mapped_vector(data, "PSRFuelConsumption", "O&MCost", Float64)
spec_consum = PSRI.mapped_vector(data, "PSRFuelConsumption", "CEsp", Float64, "segment", "block")
fuelcons2fuel = PSRI.get_map(data, "PSRFuelConsumption", "PSRFuel"; relation_type = PSRI.RELATION_1_TO_1)
fuel_cost = PSRI.mapped_vector(data, "PSRFuel", "Custo", Float64)

PSRI.update_vectors!(data)
```
Now we can calculate the price of the energy unity of each fuel consumption for each thermal plant:
```@example ther_prices
ther_prices = [zeros(0) for _ = 1:ther_size]
for ther = 1:ther_size
    n_fuelcons = length(ther2fuelcons[ther])
    prices = zeros(n_fuelcons)
    for i = 1:n_fuelcons
        fuelcons = ther2fuelcons[ther][i]
        fuel = fuelcons2fuel[fuelcons]
        prices[i] = om_cost[fuelcons] + spec_consum[fuelcons]*fuel_cost[fuel]
    end
    ther_prices[ther] = prices
end
ther_prices
```