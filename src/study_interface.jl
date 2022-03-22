@enum BlockDurationMode begin
    FIXED_DURATION
    VARIABLE_DURATION
    HOUR_BLOCK_MAP
end

"""
    RelationType

Possible relation types used in mapping function such as [`get_map`](@ref), [`get_reverse_map`](@ref), etc.

The current possible relation types are:
```julia
RELATION_1_TO_1
RELATION_1_TO_N
RELATION_FROM
RELATION_TO
RELATION_TURBINE_TO
RELATION_SPILL_TO
RELATION_INFILTRATE_TO
RELATION_STORED_ENERGY_DONWSTREAM
RELATION_BACKED
```
"""
@enum RelationType begin
    RELATION_1_TO_1
    RELATION_1_TO_N
    RELATION_FROM
    RELATION_TO
    RELATION_TURBINE_TO
    RELATION_SPILL_TO
    RELATION_INFILTRATE_TO
    RELATION_STORED_ENERGY_DONWSTREAM
    RELATION_BACKED
end

"""
    AbstractData
"""
abstract type AbstractData end

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
    max_elements(data::AbstractData, collection::String)

Returns an `Int32` with the maximum number of elements for a given `collection`.

Example:
```julia
PSRI.max_elements(data, "PSRThermalPlant")
```
"""
function max_elements end

"""
    get_map(
        data::AbstractData,
        lst_from::String,
        lst_to::String;
        allow_empty::Bool = true,
        relation_type::RelationType = RELATION_1_TO_1, # type of the direct relation
    )

Returns a `Vector{Int32}` with the map between collections given a certain [`RelationType`](@ref).

Examples:
```julia
PSRI.get_map(data, "PSRBattery", "PSRSystem")
PSRI.get_map(data, "PSRMaintenanceData", "PSRThermalPlant")

PSRI.get_map(data, "PSRHydroPlant", "PSRHydroPlant", relation_type = PSRI.RELATION_TURBINE_TO)
PSRI.get_map(data, "PSRHydroPlant", "PSRHydroPlant", relation_type = PSRI.RELATION_SPILL_TO)
PSRI.get_map(data, "PSRHydroPlant", "PSRHydroPlant", relation_type = PSRI.RELATION_INFILTRATE_TO)
PSRI.get_map(data, "PSRHydroPlant", "PSRHydroPlant", relation_type = PSRI.RELATION_STORED_ENERGY_DONWSTREAM)

@test PSRI.get_map(data, "PSRInterconnection", "PSRSystem", relation_type = PSRI.RELATION_FROM)
@test PSRI.get_map(data, "PSRInterconnection", "PSRSystem", relation_type = PSRI.RELATION_TO)
```
"""
function get_map end

"""
    get_vector_map
"""
function get_vector_map end

"""
    get_reverse_map
"""
function get_reverse_map end

"""
    get_reverse_vector_map
"""
function get_reverse_vector_map end

"""
    get_parms
"""
function get_parms end

"""
    get_code(data::AbstractData, collection::String)

Returns a `Vector{Int32}` containing the code of each element in `collection`.

Example:
```julia
PSRI.get_code(data, "PSRThermalPlant")
```
"""
function get_code end

"""
    get_name(data::AbstractData, collection::String)

Returns a `Vector{String}` containing the name of each element in `collection`.

Example:
```julia
PSRI.get_name(data, "PSRThermalPlant")
PSRI.get_name(data, "PSRGaugingStation")
```
"""
function get_name end

"""
    mapped_vector
"""
function mapped_vector end

"""
    go_to_stage(data::AbstractData, stage::Integer)

Goes to the `stage` in the `data` time controller. 
"""
function go_to_stage end

"""
    go_to_dimension
"""
function go_to_dimension end

"""
    update_vectors!(data::AbstractData)

Update all mapped vectors according to the time controller inside `data`.
"""
function update_vectors! end

"""
    description
"""
function description end

"""
    total_stages(data::AbstractData)

Returns the total number of stages of the case.

Example:
```
PSRI.total_stages(data)
```
"""
function total_stages end

"""
    total_scenarios(data::AbstractData)

Returns the total number of scenarios of the case.

Example:
```
PSRI.total_scenarios(data)
```
"""
function total_scenarios end

"""
    total_blocks(data::AbstractData)

Returns the total number of blocks of the case.

Example:
```
PSRI.total_blocks(data)
```
"""
function total_blocks end

"""
    total_openings(data::AbstractData)

Returns the total number of openings of the case.

Example:
```
PSRI.total_openings(data)
```
"""
function total_openings end

"""
    total_stages_per_year(data::AbstractData)

Returns the total number of stages per year of the case.

Example:
```
PSRI.total_stages_per_year(data)
```
"""
function total_stages_per_year end

"""
    get_complex_map
"""
function get_complex_map end

"""
    stage_duration(data::AbstractData, t::Int = data.controller_stage)

Returns the duration, in hours, of the stage `t`.

---------

    stage_duration(data::AbstractData, date::Dates.Date)

Returns the duration, in hours, at the stage corresponding to `date`.
"""
function stage_duration end

"""
    block_duration(data::AbstractData, date::Dates.Date, b::Int)

Returns the duration, in hours, of the block `b` at the stage corresponding to `date`.

---------

    block_duration(data::AbstractData, t::Int, b::Int)

Returns the duration, in hours, of the block `b` at stage `t`.

---------

    block_duration(data::AbstractData, b::Int)

Returns the duration, in hours, of the block `b` at the current stage, set by `go_to_stage`.
"""
function block_duration end

"""
    block_from_stage_hour
"""
function block_from_stage_hour end

"""
    get_nonempty_vector
"""
function get_nonempty_vector end

"""
    MainTypes = Union{Float64, Int32, String, Dates.Date}
"""
const MainTypes = Union{Float64, Int32, String, Dates.Date}

"""
    configuration_parameter(
        data::AbstractData,
        name::String,
        default::T
    ) where T <: MainTypes

Returns the required configuration parameter from the case. If the parameter is not registered returns the default value.

Example:
```
PSRI.configuration_parameter(data, "MaximoIteracoes", 0)
PSRI.configuration_parameter(data, "MinOutflowPenalty", 0.0)
```
---------

    configuration_parameter(
        data::Data,
        name::String,
        default::Vector{T}
    ) where T <: MainTypes

Returns the rquired configuration parameters from the case that are vectors that are vectors. If the parameter is not registered returns the default value.

Example:
```
PSRI.configuration_parameter(data, "DeficitCost", [0.0])
```
"""
function configuration_parameter end
