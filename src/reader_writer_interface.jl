"""
    AbstractReader
"""
abstract type AbstractReader end

"""
    AbstractWriter
"""
abstract type AbstractWriter end

# Reader functions

"""
    file_to_array(::Type{T}, path::String) where T <: AbstractReader

Write a file to an array
"""
function file_to_array end

"""
    file_to_array_and_header
"""
function file_to_array_and_header end

"""
    open(::Type{<:AbstractWriter}, path::String; kwargs...)

Method for opening file and registering time series data.
If specified file doesn't exist, the method will create it, otherwise, the previous one will be overwritten.
Returns updated `AbstractWriter` instance. 

### Arguments:

- `writer`: `AbstractWriter` instance to be used for opening file.

- `path`: path to file.

### Keyword arguments:

- `blocks`: case's number of blocks.

- `scenarios`: case's number of scenarios.

- `stages`: case's number of stages.

- `agents`: list of element names.

- `unit`: dimension of the elements' data.

- `is_hourly`: if data is hourly. If yes, block dimension will be ignored.

- `name_length`: length of element names.

- `block_type`: case's type of block.

- `scenarios_type`: case's type of scenario.

- `stage_type`: case's type of stage.

- `initial_stage`: stage at which to start registry.

- `initial_year`: year at which to start registry.

- `allow_unsafe_name_length`: allow element names outside safety bounds.

Examples: 
 * [Writing and reading a time series into a file](@ref)

 ---------

    PSRI.open(reader::Type{<:AbstractReader}, path::String; kwargs...)

Method for opening file and reading time series data.
Returns updated `AbstractReader` instance.

### Arguments:

- `reader::Type{<:AbstractReader}`: `AbstractReader` instance to be used for opening file.

- `path::String`: path to file.

### Keyword arguments:

- `is_hourly::Bool`: if data to be read is hourly, other than blockly.

- `stage_type::PSRI.StageType`: the [`PSRI.StageType`](@ref) of the data, defaults to `PSRI.STAGE_MONTH`.

- `header::Vector{String}`: if file has a header with metadata.

- `use_header::Bool`: if data from header should be retrieved.

- `first_stage::Dates.Date`: stage at which start reading.

- `verbose_header::Bool`: if data from header should be displayed during execution.
"""
function open end

"""
    is_hourly

1+1+1
"""
function is_hourly end

"""
    max_stages
"""
function max_stages end

"""
    max_scenarios
"""
function max_scenarios end

"""
    max_blocks
"""
function max_blocks end

"""
    max_blocks_current
"""
function max_blocks_current end

"""
    max_blocks_stage
"""
function max_blocks_stage end

"""
    max_agents
"""
function max_agents end

"""
    stage_type
"""
function stage_type end

"""
    initial_stage
"""
function initial_stage end

"""
    initial_year
"""
function initial_year end

"""
    data_unit
"""
function data_unit end

"""
    current_stage
"""
function current_stage end

"""
    current_scenario
"""
function current_scenario end

"""
    current_block
"""
function current_block end

"""
    agent_names
"""
function agent_names end

"""
    goto
"""
function goto end

"""

    next_registry(reader::Reader)

Method for reading data row into opened file through `Reader` instance.
`Reader` from input is updated inplace.
"""
function next_registry end

"""

    close(reader::Reader)

Closes file from `Reader` instance.

-------

    close(writer::Writer)

Closes CSV file from `Writer` instance.
"""
function close end

"""
    convert_file
"""
function convert_file end

"""
    convert
"""
function convert end

"""
    add_reader!
"""
function add_reader! end

# Write methods

"""

    write_registry(
        writer::Writer,
        data::Vector{Float64},
        stage::Integer,
        scenario::Integer = 1,
        block::Integer = 1,
    )

Method for writing data row into opened file through `Writer` instance.
Returns updated `Writer`. Arguments:
* `writer`: `Writer` instance to be used for accessing file.
* `data`: elements data to be written in the row.
* `stage`: stage at row to be written.
* `scenario`: at which scenario the row belongs to.
* `block`: at which block the row belongs to.
"""
function write_registry end

"""
    PSRI.array_to_file

    function array_to_file(
        ::Type{T},
        path::String,
        data::Array{Float64,4}; #[a,b,s,t]
        # mandatory
        agents::Vector{String} = String[],
        unit::Union{Nothing, String} = nothing,
        # optional
        # is_hourly::Bool = false,
        name_length::Integer = 24,
        block_type::Integer = 1,
        scenarios_type::Integer = 1,
        stage_type::StageType = STAGE_MONTH, # important for header
        initial_stage::Integer = 1, #month or week
        initial_year::Integer = 1900,
        # addtional
        allow_unsafe_name_length::Bool = false,
    ) where T <: AbstractWriter
"""
function array_to_file end
