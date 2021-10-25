# Examples

## Opening CSV file, registering study data, and then closing it

This example will be using the `open`, `write_registry` and `close` methods for handling CSV files.

```julia


import PSRClassesInterface
const PSRI = PSRClassesInterface

#Creates dummy data
n_blocks = 3
n_scenarios = 1000
n_stages = 10
n_elements = 4
#Data is an (n_stages*n_scenarios*n_blocks) X n_elements ordered numeric structure
data = rand(Float64, (n_stages*n_scenarios*n_blocks, n_elements))

#Sets CSV file path
FILE_PATH = joinpath(".", "example")

#Opens or creates file and writes header
iow = PSRI.open(
    PSRI.OpenCSV.Writer,
    FILE_PATH,
    blocks = n_blocks,
    scenarios = n_scenarios,
    stages = n_stages,
    agents = ["Element 1", "Element 2", "Element 3", "Element 4"],
    unit = "MW",
    initial_stage = 1,
    initial_year = 2006,
)

#Data registry loop
row = 1
for stage = 1:10, scenario = 1:1000, block = 1:3
    
    #Writes row to CSV file opened at iow instance
    PSRI.write_registry(
        iow,
        data[row,:],
        stage,
        scenario,
        block
    )
    row += 1
end

#Closes file
PSRI.close(iow)
```

## Opening CSV file, reading study data, and then closing it

This example will be using the `open`, `next_registry` and `close` methods for handling CSV files.

```julia
import PSRClassesInterface
const PSRI = PSRClassesInterface

#Sets CSV file path
FILE_PATH = joinpath(".", "example")

#Creates Reader instance
ior = PSRI.OpenCSV.Reader

#Opens file
ior = PSRI.open(ocr, FILE_PATH)

#Creates data destination structure according to metadata stored in the Reader
n_rows = ior.stages*ior.scenarios*ior.blocks
data = zeros(Float64, (n_rows, ior.num_agents))

#Data reading loop
for row = 1:n_rows
    
    #Reads CSV row into data structure
    PSRI.next_registry(ior)
    data[row,:] = ior.data
end

#Closes file
PSRI.close(ior)
```