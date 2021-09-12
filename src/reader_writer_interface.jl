abstract type AbstractReader end
abstract type AbstractWriter end
abstract type AbstractReaderMapper end
abstract type AbstractFileType end

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
    open
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
    next_registry
"""
function next_registry end

"""
    close
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
    write_registry
"""
function write_registry end

"""
    array_to_file
"""
function array_to_file end
