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
    file_to_array
"""
function file_to_array end

"""
    file_to_array_and_header
"""
function file_to_array_and_header end

"""
    PSRI.open(reader::Type{<:AbstractReader}, path::String; kwargs...)

Method of `open` function for opening file and reading study result.
Returns updated `AbstractReader` instance. Arguments:
* `reader`: `AbstractReader` instance to be used for opening file.
* `path`: path to file.

kwargs:
* `reader`: `AbstractReader` instance to be used for opening file.
* `path`: path to file.
* `is_hourly`: if data to be read is hourly, other than blockly.
* `stage_type`: how the data is temporally staged, defaults to monthly stages.
* `header`: if file has a header with metadata.
* `use_header`: if data from header should be retrieved.
* `first_stage`: stage at which start reading.
* `verbose_header`: if data from header should be displayed during execution.

---------

    open(::Type{Writer}, path::String; kwargs...)

Method of `open` function for opening file and registering study results.
If specified file doesn't exist, the method will create it, otherwise, the previous one will be overwritten.
Returns updated `Writer` instance. Arguments:
* `writer`: `Writer` instance to be used for opening file.
* `path`: path to file.

Examples: 
 * [Opening CSV file, registering study data, and then closing it](@ref)
"""
function open end

"""
    is_hourly
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
    array_to_file
"""
function array_to_file end
