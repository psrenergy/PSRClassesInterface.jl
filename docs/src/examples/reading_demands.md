# Reading Demands

## Determining elasticity and value of demands
In this example we will read demand segments, obtain the value of demands, discover wheter each demand is elastic or inelastic, and then obtain the sums of demands by elasticity. The first step is to read the study data:
```@example demand
using PSRClassesInterface
const PSRI = PSRClassesInterface

PATH_CASE_EXAMPLE_DEM = joinpath(pathof(PSRI) |> dirname |> dirname, "test", "data", "case1")

data = PSRI.load_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_EXAMPLE_DEM
)
; nothing # hide
```
Whereas the demand varies according to the stage, we must specify the stage by calling `go_to_stage`:
```@example demand
target_stage = 1
PSRI.go_to_stage(data,target_stage)
```
Now, we can read the demand segments and the map between demands and demand segments, and then obtain the value of each demand:
```@example demand
dem_seg = PSRI.mapped_vector(data, "PSRDemandSegment", "Demanda", Float64, "block")

seg2dem = PSRI.get_map(data, "PSRDemandSegment", "PSRDemand", relation_type = PSRI.PMD.RELATION_1_TO_1)

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
; nothing # hide
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

## Determining demands values of each bus
Now we have the values of the demands, we can obtain the values of demand for each bus. 
Each demand has a set of loads, which define how much of this demand corresponds to each bus.  We can begin by reading the loads and its relations with demands and buses:
```@example demand
loads = PSRI.mapped_vector(data, "PSRLoad", "P", Float64, "block")
lod2dem = PSRI.get_map(data, "PSRLoad", "PSRDemand", relation_type = PSRI.PMD.RELATION_1_TO_1)
lod2bus = PSRI.get_map(data, "PSRLoad", "PSRBus", relation_type = PSRI.PMD.RELATION_1_TO_1)
; nothing # hide
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
 
## Calculating the energy prices of each thermal plant
The energy prices in a thermal plant deppends on the  the price of the fuel used, the specific consumption of this fuel and Operation and Maintenance cost. Again, we begin by reading the data:
```@example ther_prices
import PSRClassesInterface
const PSRI = PSRClassesInterface

PATH_CASE_EXAMPLE_THER_PRICES = joinpath(pathof(PSRI) |> dirname |> dirname, "test", "data", "case1")

data = PSRI.load_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_EXAMPLE_THER_PRICES
)
; nothing # hide
```
We discover the necessary infos of the thermal plants indirectly through `PSRFuelConsumption`:
```@example ther_prices
fuelcons2ther = PSRI.get_map(data,"PSRFuelConsumption", "PSRThermalPlant"; relation_type = PSRI.PMD.RELATION_1_TO_1)

ther_size = PSRI.max_elements(data, "PSRThermalPlant")
fuelcons_size = PSRI.max_elements(data, "PSRFuelConsumption")
ther2fuelcons = [[fc for fc = 1:fuelcons_size if fuelcons2ther[fc] == t] for t = 1:ther_size]
; nothing # hide
```
Next, we get the O&M cost, the specific consumption and the relation with fuels of our fuels consumptions. Then we get the cost of each fuel. After calling `mapped_vector` we must call `update_vectors!`.
```@example ther_prices
om_cost = PSRI.mapped_vector(data, "PSRFuelConsumption", "O&MCost", Float64)
spec_consum = PSRI.mapped_vector(data, "PSRFuelConsumption", "CEsp", Float64, "segment", "block")
fuelcons2fuel = PSRI.get_map(data, "PSRFuelConsumption", "PSRFuel"; relation_type = PSRI.PMD.RELATION_1_TO_1)
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