abstract type AbstractReader end
abstract type AbstractWriter end
abstract type AbstractReaderMapper end
abstract type AbstractFileType end

# Reader functions
function file_to_array end
function file_to_array_and_header end
function read end
function is_hourly end
function max_stages end
function max_scenarios end
function max_blocks end
function max_blocks_current end
function max_blocks_stage end
function max_agents end
function stage_type end
function initial_stage end
function initial_year end
function data_unit end
function current_stage end
function current_scenario end
function current_block end
function agent_names end
function goto end
function next_registry end
function close end
function convert_file end
function convert end
function add_reader! end

# Write methods
function write_registry end
function write end
function array_to_file end
function configuration_parameter end