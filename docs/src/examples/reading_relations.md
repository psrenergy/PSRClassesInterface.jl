# Reading Relations

## Determining subsystem from a certain hydro plant

In this example we will demonstrate how to make a simple use of a relationship map. That will be achieved by determining a subsystem from a certain hydro plant through its parameters. The program will initiate by the standard reading procedure:
```@example sys_by_gaug
import PSRClassesInterface
const PSRI = PSRClassesInterface

PATH_CASE_EXAMPLE_GAUGING = joinpath(pathof(PSRI) |> dirname |> dirname, "test", "data", "case2")

data = PSRI.initialize_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_EXAMPLE_GAUGING
)
; nothing # hide
```

Next, the maps between hydroplants and systems is retrieved by the `get_map` method:
```@example sys_by_gaug
hyd2sys = PSRI.get_map(data, "PSRHydroPlant","PSRSystem")
; nothing # hide
```

## Determining buses from a certain thermal plant

This case consists of a more advanced use of a relationship map. We'll determine which buses are linked to a given target thermal plant, while there is no direct relationship between both. Firstly, the study data is read:
```@example the_by_bus
import PSRClassesInterface
const PSRI = PSRClassesInterface

PATH_CASE_EXAMPLE_BUS = joinpath(pathof(PSRI) |> dirname |> dirname, "test", "data", "case1")

data = PSRI.initialize_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_EXAMPLE_BUS
)
; nothing # hide
```

Whereas there is no direct link between buses and thermal plants, both are indirectly related through generators. Therefore, we must identify those relationships by calling `get_map` for each:
```@example the_by_bus
gen2thermal = PSRI.get_map(data, "PSRGenerator","PSRThermalPlant")
gen2bus = PSRI.get_map(data, "PSRGenerator", "PSRBus")
; nothing # hide
```

Next, we can find which generators are linked to our target thermal plant by the indexes of `gen2the`:
```@example the_by_bus
target_thermal = 1
target_generator = findall(isequal(target_thermal), gen2thermal)
; nothing # hide
```

`target_generator` now holds the indexes of generators that are linked to the buses we are trying to identify. With those at hand, the indexes of the buses are easily identifiable by:
```@example the_by_bus
targetBus = gen2bus[target_generator]
; nothing # hide
```


## Determining which buses are connected by each circuit
Each circuit connects two buses, it starts from a bus and goes to another. In this example we'll discover these buses for each circuit and then we'll build an incidence matrix of buses by circuits. The first step is to read the data:
```@example cir_bus
import PSRClassesInterface
const PSRI = PSRClassesInterface

PATH_CASE_EXAMPLE_CIR_BUS = joinpath(pathof(PSRI) |> dirname |> dirname, "test", "data", "case1")

data = PSRI.initialize_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_EXAMPLE_CIR_BUS
)
; nothing # hide
```
Next, we get from which bus each circuit starts and which bus it goes to with `get_map`:
```@example cir_bus
cir2bus_to = PSRI.get_map(data, "PSRSerie", "PSRBus"; relation_type = PSRI.RELATION_TO)
cir2bus_from = PSRI.get_map(data, "PSRSerie", "PSRBus"; relation_type = PSRI.RELATION_FROM)
; nothing # hide
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