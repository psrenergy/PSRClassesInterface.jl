"""
    PSRI.StageType

Possible stage types used in for reading and writing time series files.

The current possible stage types are:
```julia
STAGE_WEEK
STAGE_MONTH
STAGE_DAY
STAGE_YEAR
```
"""
@enum StageType begin
    STAGE_WEEK=1
    STAGE_MONTH=2
    STAGE_DAY=5
    STAGE_YEAR=10
end

# "PSR_STAGETYPE_UNKNOWN" => 0,
# "PSR_STAGETYPE_WEEKLY" => 1,
# "PSR_STAGETYPE_MONTHLY" => 2,
# "PSR_STAGETYPE_QUARTERLY" => 3,
# "PSR_STAGETYPE_HOURLY" => 4,
# "PSR_STAGETYPE_DAILY" => 5,
# "PSR_STAGETYPE_13MONTHLY" => 6,
# "PSR_STAGETYPE_BIMONTHLY" => 7,
# "PSR_STAGETYPE_TRIANNUALLY" => 8,
# "PSR_STAGETYPE_SEMIANNUALLY" => 9,
# "PSR_STAGETYPE_YEARLY" => 10,

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
    PSRI.file_to_array(::Type{T}, path::String; use_header::Bool = true, header::Vector{String} = String[]) where T <: AbstractReader

Write a file to an array
"""
function file_to_array end

"""
    PSRI.file_to_array_and_header(::Type{T}, path::String; use_header::Bool = true, header::Vector{String} = String[]) where T <: AbstractReader

Write a file to an array and header
"""
function file_to_array_and_header end

"""
    PSRI.open(::Type{<:AbstractWriter}, path::String; kwargs...)

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

Examples: 
 * [Writing and reading a time series into a file](@ref)
"""
function open end

"""
    PSRI.close(ior::AbstractReader)

Closes the [`PSRI.AbstractReader`](@ref) instance.

-------

    PSRI.close(iow::AbstractWriter)

Closes the [`PSRI.AbstractWriter`](@ref) instance.
"""
function close end

"""
    PSRI.is_hourly(ior::AbstractReader)

Returns a `Bool` indicating whether the data in the file read by [`PSRI.AbstractReader`](@ref) is hourly.
"""
function is_hourly end

"""
    PSRI.max_stages(ior::AbstractReader)

Returns an `Int` indicating maximum number of stages in the file read by [`PSRI.AbstractReader`](@ref).
"""
function max_stages end

"""
    PSRI.max_scenarios(ior::AbstractReader)

Returns an `Int` indicating maximum number of scenarios in the file read by [`PSRI.AbstractReader`](@ref).
"""
function max_scenarios end

"""
    PSRI.max_blocks(ior::AbstractReader)

Returns an `Int` indicating maximum number of blocks in the file read by [`PSRI.AbstractReader`](@ref).
"""
function max_blocks end

"""
    PSRI.max_blocks_current(ior::AbstractReader)

Returns an `Int` indicating maximum number of blocks in the cuurent stage in the file read by [`PSRI.AbstractReader`](@ref).
"""
function max_blocks_current end

"""
    PSRI.max_blocks_stage(ior::AbstractReader, t::Integer)

Returns an `Int` indicating maximum number of blocks in the stage `t` in the file read by [`PSRI.AbstractReader`](@ref).
"""
function max_blocks_stage end

"""
    PSRI.max_agents(ior::AbstractReader)

Returns an `Int` indicating maximum number of agents in the file read by [`PSRI.AbstractReader`](@ref).
"""
function max_agents end

"""
    stage_type
"""
function stage_type end

"""
    PSRI.initial_stage(ior::AbstractReader)

Returns an `Int` indicating the initial stage in the file read by [`PSRI.AbstractReader`](@ref).
"""
function initial_stage end

"""
    PSRI.initial_year(ior::AbstractReader)

Returns an `Int` indicating the initial year in the file read by [`PSRI.AbstractReader`](@ref).
"""
function initial_year end

"""
    PSRI.data_unit(ior::AbstractReader)

Returns a `String` indicating the unit of the data in the file read by [`PSRI.AbstractReader`](@ref).
"""
function data_unit end

"""
    PSRI.current_stage(ior::AbstractReader)

Returns an `Int` indicating the current stage in the stream of the [`PSRI.AbstractReader`](@ref).
"""
function current_stage end

"""
    PSRI.current_scenario(ior::AbstractReader)

Returns an `Int` indicating the current scenarios in the stream of the [`PSRI.AbstractReader`](@ref).
"""
function current_scenario end

"""
    PSRI.current_block(ior::AbstractReader)

Returns an `Int` indicating the current block in the stream of the [`PSRI.AbstractReader`](@ref).
"""
function current_block end

"""
    PSRI.agent_names(ior::AbstractReader)

Returns a `Vector{String}` with the agent names in the file read by [`PSRI.AbstractReader`](@ref).
"""
function agent_names end

"""
    PSRI.goto(
        ior::AbstractReader, 
        t::Integer, 
        s::Integer = 1, 
        b::Integer = 1
    )

Goes to the registry of the stage `t`, scenario `s` and block `b`.
"""
function goto end

"""
    PSRI.next_registry(ior::AbstractReader)

Goes to the next registry on the [`PSRI.AbstractReader`](@ref).
"""
function next_registry end

"""
    convert_file
"""
function convert_file end

"""
    add_reader!
"""
function add_reader! end

# Write methods

"""
    PSRI.write_registry(
        iow::AbstractWriter,
        data::Vector{T},
        stage::Integer,
        scenario::Integer = 1,
        block::Integer = 1,
    ) where T <: Real

Writes a data row into opened file through [`PSRI.AbstractWriter`](@ref) instance.

### Arguments:

* `iow`: `PSRI.AbstractWriter` instance to be used for accessing file.

* `data`: elements data to be written.

* `stage`: stage of the data to be written.

* `scenario`: scenarios of the data to be written.

* `block`: block of the data to be written.
"""
function write_registry end

"""
    PSRI.array_to_file
"""
function array_to_file end
