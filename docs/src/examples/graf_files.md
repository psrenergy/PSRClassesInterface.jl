# Graf Files and Time Series

## Time Series

Some attributes in a Study represent a time series indexed by another attribute. Here we will be setting a time series for the attribute `EmissionCost`, from `PSRGasEmission`, which is indexed by `DateEmissionCost`.

First we create a Dict with `EmissionCost` and `DateEmissionCost` data.

```@example rw_file
using Dates

series = Dict{String,Vector}(
    "DateEmissionCost" => [
        Dates.Date("1900-01-01"),
        Dates.Date("2013-01-01"),
        Dates.Date("2013-02-01")
    ],
    "EmissionCost" => [0.0,3.0,3.0]
    )
```

Then, we save the time series to the study using the function [`PSRI.set_series!`](@ref). Notice that when we are saving this time series, we are specifying the element from the collection that has this series, using its index.

```@example rw_file
temp_path = joinpath(tempdir(), "PSRI")

data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)

PSRI.create_element!(data, "PSRGasEmission")

PSRI.set_series!(
    data, 
    "PSRGasEmission", 
    "DateEmissionCost",
    1, # element index in collection
    series
    )
```

### Using a SeriesTable

We can later retrieve the series for the element in the collection with [`PSRI.get_series`](@ref), which will return a `SeriesTable` object. It can be later displayed as a table in your terminal.

When using this function, we need the collection, the element index and the attribute that indexes the elements.


```@example rw_file
using DataFrames
series_table = PSRI.get_series(
    data, 
    "PSRGasEmission", 
    "DateEmissionCost", 
    1 # element index in collection
    )

DataFrame(series_table)
```


## Graf files
The data relative to a Study is usually stored in a JSON file, where an attribute can have its data indexed by time intervals, as presented earlier.

However, when a time series attribute is multidimensional, it can be too large to be stored in a JSON. For these cases, we save the data in a separate file. We will refer to such file as Graf file. When an attribute has its information in a Graf file, there's an entry in the regular JSON file specifying it. 

In the following example, each `PSRDemand` object will have its attribute `Duracao` data associated with a time series, saved in the files `duracao.hdr` and `duracao.bin`. Objects are distinguished by the `parmid` attribute, which in this case has the `AVId` value of each `PSRDemand` element. 

A Graf file stores the values of an attribute for every element in a collection. So for this example, all values for the attribute `Duracao` will be store in the Graf file.


```json
"PSRGasEmission": [
    {
        "AVId": "Agent 1"
        "name": "psr_name"
    },
    {
        "AVId": "Agent 2"
        "name": "psr_name2"
    },
    {
        "AVId": "Agent 3"
        "name": "psr_name3"
    }
],
"GrafScenarios": [
    {
        "classname": "PSRDemand",
        "parmid": "AVId",
        "vector": "Duracao",
        "binary": [ "duracao.hdr", "duracao.bin" ]
    }
]
```


## Graf file format

A Graf file composed of a header and a table with the following elements:

- Stage 
- Scenario 
- Block
- Agents (one entry for each agent)

Each agent represents an element from the collection the graf file is linked to.

### Visual example of a graf file

Using the previous example with `PSRDemand` objects, the `Duracao` for each object will be displayed in the Agents columns, that will take the name of the `AVId` attribute, resulting on the following:

| **Stg** | **Sce** | **Block** | **Agent 1** | **Agent 2** | **Agent 3** |
|:-----:|:-----:|:-----:|:-----------:|:-----------:|-------------|
|   1   |   1   |   1   |    1.0      |     5.0     |    10.0     |
|   1   |   1   |   2   |    1.5      |     6.5     |    11.5     |
|   1   |   1   |   3   |    2.0      |     7.0     |    12.0     |
| ...   | ...   | ...   |    ...      |     ...     |     ...     |

### Graf Header

A Graf file header contains data about the time series contents. Some important information are whether the time series varies per block and/or per Scenario, the number of agents, the unit of measurement and on which stage it should start. 


## Writing a time series into a Graf file

In this example we will demonstrate how to save a time series into a csv or binary file. 
First, we create a random array which has the data for a time series:

```@example rw_file
import PSRClassesInterface
const PSRI = PSRClassesInterface

#Creates dummy data
n_blocks = 3
n_scenarios = 1
n_stages = 1
n_agents = 1

time_series_data = rand(Float64, n_agents, n_blocks, n_scenarios, n_stages)

nothing #hide
```

There are two ways of saving the data to a file, save the data in the file directly or iteratively.
To save the data directly use the function [`PSRI.array_to_file`](@ref) by calling:
```@example rw_file
FILE_PATH = joinpath(tempdir(), "example")

PSRI.array_to_file(
    PSRI.OpenBinary.Writer,
    FILE_PATH,
    time_series_data,
    agents = ["Agent 1", "Agent 2", "Agent 3", "Agent 4", "Agent 5"],
    unit = "H";
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
    unit = "H",
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
## Reading a time series from a graf file

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

To choose the agents order set `use_header` to `true` and label the agents in `header`.

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

```

## Using Graf files in a study

As presented earlier, an attribute for a collection can have its data stored in a Graf file, all that being specified in the `GrafScenarios` entry of the study JSON. 

If you have a Graf file that should be linked to a study, you can use the function [`PSRI.link_series_to_file`](@ref) to do so.

```@example rw_file
PSRI.create_element!(data, "PSRDemand", "AVId" => "Agent 1")
PSRI.create_element!(data, "PSRDemand", "AVId" => "Agent 2")
PSRI.create_element!(data, "PSRDemand", "AVId" => "Agent 3")
PSRI.create_element!(data, "PSRDemand", "AVId" => "Agent 4")
PSRI.create_element!(data, "PSRDemand", "AVId" => "Agent 5")

PSRI.link_series_to_file(
        data, 
        "PSRDemand", 
        "Duracao", 
        "AVId",
        FILE_PATH
    )
```

### Using a GrafTable

We can retrieve the data stored in a Graf file using the [`PSRI.get_graf_series`](@ref) function. This function returns a `GrafTable` object. 

When using this function, we need the collection and its attribute that is linked to a Graf file.

```@example rw_file
graf_table = PSRI.get_graf_series(
        data,
        "PSRDemand",
        "Duracao";
        use_header = false
    )
```

Once you have a GrafTable object, you can display it as a table in your terminal

```@example rw_file
using DataFrames

DataFrame(graf_table)
```

### Vector from graf file

You can get a vector that corresponds to a row in a Graf file with the values for the agents correspoding to the current `stage`, `scenario` and `block`.

For that, we will have to use the function [`PSRI.mapped_vector`](@ref). 

```@example rw_file
vec = PSRI.mapped_vector(
        data, 
        "PSRDemand", 
        "Duracao",
        Float64
    )
```
The parameters that were used to retrieve the row value in the Graf table can be changed with the following functions:
- [`PSRI.go_to_stage`](@ref)
- [`PSRI.go_to_scenario`](@ref)
- [`PSRI.go_to_block`](@ref)

These methods don't automatically update the vector. For that, we use the function [`PSRI.update_vectors!`](@ref), which update all vectors from our Study.

```@example rw_file
PSRI.update_vectors!(data)
```

However, it might be interesting to update only one or a group of vectors. To be able to do that, we will have to set a filter tag when we create them.

```@example rw_file
vec2 = PSRI.mapped_vector(
        data, 
        "PSRDemand", 
        "Duracao",
        Float64,
        filters = ["test_filter"]
    )
```

Then, when we run:
```@example rw_file
PSRI.update_vectors!(data, "test_filter")
```


## Comparison between a GrafTable and a SeriesTable

In this section we have introduced some new concepts about table-like types.
That being said, let's review the main differences between GrafTables and SeriesTables:

- SeriesTable
    - Is linked to a single element from a collection
    - It can have time series of different attributes that are indexed to a single attribute (all belonging to the same element)
    
- GrafTable
    - Is linked to the whole collection. So for an attribute, every element in the collection will have an entry in the graf file
    - It has the time series for only one attribute
    
