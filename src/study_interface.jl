"""
    AbstractStudyInterface
"""
abstract type AbstractStudyInterface end

"""
    initialize_study
"""
function initialize_study end

"""
    get_vector
"""
function get_vector end

"""
    max_elements
"""
function max_elements end

"""
    get_map
"""
function get_map end

"""
    get_map
"""
function get_vector_map end

"""
    get_reverse_map
"""
function get_reverse_map end

"""
    get_reverse_map
"""
function get_reverse_vector_map end

"""
    get_parms
"""
function get_parms end

"""
    get_code
"""
function get_code end

"""
    get_name
"""
function get_name end

"""
    mapped_vector
"""
function mapped_vector end

"""
    go_to_stage
"""
function go_to_stage end

"""
    go_to_dimension
"""
function go_to_dimension end

"""
    update_vectors!
"""
function update_vectors! end

"""
    description
"""
function description end

"""
    total_stages
"""
function total_stages end

"""
    total_scenarios
"""
function total_scenarios end

"""
    total_blocks
"""
function total_blocks end

"""
    total_openings
"""
function total_openings end

"""
    total_stages_per_year
"""
function total_stages_per_year end

"""
    get_complex_map
"""
function get_complex_map end

"""
    stage_duration
"""
function stage_duration end

"""
    block_duration
"""
function block_duration end

"""
    get_nonempty_vector
"""
function get_nonempty_vector end

"""
    MainTypes = Union{Float64, Int32, String, Dates.Date}
"""
const MainTypes = Union{Float64, Int32, String, Dates.Date}

"""
    configuration_parameter
"""
function configuration_parameter end