# Graf Files

## Motivation

The data relative to a Study is usually stored in a JSON file, where, if previously specified, an attribute can have its data indexed by time intervals. An example is presented below, where `ShortTermMarketPrice` is indexed by `InitialDateMarketPrice`:

```json
"InitialDateMarketPrice": [  
    "2021-08-31 00:00",
    "2021-08-31 00:30",
    "2021-08-31 01:00",
    "2021-08-31 01:30"
],
"ShortTermMarketPrice": [
    70.62,
    58.17,
    43.85,
    26.28
]
```

However, a time series can be too large to be stored in a JSON for some Studies. For these cases, we save the data in a Graf file. When an attribute has its information in a Graf file, there's an entry in the regular JSON file specifying it. 

In the following example, each `PSRDemandSegment` object will have its attribute `HourDemand` data associated with a time series, saved in the files `hourdemand.hdr` and `hourdemand.bin`. Objects are distinguished by the `parmid` attribute, which in this case has the `AVId` value of each `PSRDemandSegment` element. 


```json
"PSRDemandSegment": [
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
        "classname": "PSRDemandSegment",
        "parmid": "AVId",
        "vector": "HourDemand",
        "binary": [ "hourdemand.hdr", "hourdemand.bin" ]
    }
]
```


## Graf file format

A Graf file composed of a header and a table with the following elements:

- Stage 
- Sequence 
- Block
- Agents

### Graf Table

Using the previous example with `PSRDemandSegment` objects, the `HourDemand` for each object will be displayed in the Agents columns, that will take the name of the `AVId` attribute, resulting on the following:

| **Stg** | **Seq** | **Block** | **Agent 1** | **Agent 2** | **Agent 3** |
|:-----:|:-----:|:-----:|:-----------:|:-----------:|-------------|
|   1   |   1   |   1   |    1.0      |     5.0     |    10.0     |
|   2   |   1   |   1   |    1.5      |     6.5     |    11.5     |
| 3     | 1     | 1     |    2.0      |     7.0     |    12.0     |
| ...   | ...   | ...   |    ...      |     ...     |     ...     |

### Graf Header

A Graf file header contains data about the time series contents. Some important information are whether the time series varies per block and/or per sequence, the number of agents, the unit of measurement and on which stage it should start. 


## Writing a time series into a Graf file

In this example we will demonstrate how to save a time series into a csv or binary file. 
First, we create a random array which has the data for a time series:

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
    path = FILE_PATH,
    data = time_series_data,
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
## Reading a time series from a file

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

rm(FILE_PATH; force = true)
```
