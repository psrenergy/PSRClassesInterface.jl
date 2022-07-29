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
    initialize_study(::AbstractStudyInterface; kwargs...)

Initialize all data structures of the study.

!!! note "Differences between the OpenInterface and ClassicInterface"
    Each study interface has its own set of `kwargs...` The easiest way to inspect the current
    available options is searching for this function on the Github repo of the desired interface.

Example:
```julia
data = PSRI.initialize_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_EXAMPLE_BATTERIES
)
```
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
    get_vector_map(
        data::Data,
        collection_from::String,
        collection_to::String;
        relation_type::RelationType = RELATION_1_TO_N,
    )

Returns a `Vector{Vector{Int32}}` to represent the relation between each element
of `collection_from` to multiple elements of `collection_to`.

Since multiple relations might be available one might need to specify
`relation_type`.

Example:
```
PSRI.get_vector_map(data, "PSRInterconnectionSumData", "PSRInterconnection")
PSRI.get_vector_map(data, "PSRReserveGenerationConstraintData", "PSRHydroPlant")
PSRI.get_vector_map(data, "PSRReserveGenerationConstraintData", "PSRThermalPlant", relation_type = PSRI.RELATION_BACKED)
```
"""
function get_vector_map end

"""
    get_reverse_map(
        data::AbstractData,
        lst_from::String,
        lst_to::String;
        original_relation_type::RelationType = RELATION_1_TO_1,
    )

Obtains the relation between `lst_from` and `lst_to` though `original_relation_type`.
But returns a `Vector{Int32}` with the relation reversed.
Some relations cannot be reversed this way since they are not bijections,
in this case use `get_reverse_vector_map`.

See also `get_map`, `get_vector_map`, `get_reverse_vector_map`.

Example:

```
PSRI.get_reverse_map(data, "PSRMaintenanceData", "PSRHydroPlant")
# which is te reverse of
PSRI.get_map(data, "PSRMaintenanceData", "PSRHydroPlant")


PSRI.get_reverse_map(data, "PSRGenerator", "PSRThermalPlant")
# which is the reverse of
PSRI.get_map(data, "PSRGenerator", "PSRThermalPlant")
``` 
"""
function get_reverse_map end

"""
    get_reverse_vector_map(
        data::AbstractData,
        lst_from::String,
        lst_to::String;
        original_relation_type::RelationType = RELATION_1_TO_N,
    )

Obtains the relation between `lst_from` and `lst_to` though `original_relation_type`.
But returns a `Vector{Vector{Int32}}` with the relation reversed.

Some relations are bijections, in these cases it is also possible to use
use `get_reverse_map`.

See also `get_map`, `get_vector_map`, `get_reverse_vector_map`.

Example:

```
# upstream turbining hydros
PSRI.get_reverse_vector_map(data, "PSRHydroPlant", "PSRHydroPlant", original_relation_type = PSRI.RELATION_TURBINE_TO)
# which is the reverse of
PSRI.get_map(data, "PSRHydroPlant", "PSRHydroPlant", relation_type = PSRI.RELATION_TURBINE_TO)

PSRI.get_reverse_vector_map(data, "PSRGenerator", "PSRBus", original_relation_type = PSRI.RELATION_1_TO_1)
# which is the reverse of
PSRI.get_map(data, "PSRGenerator", "PSRBus")
```
"""
function get_reverse_vector_map end

"""
    get_parms(
        data::AbstractData,
        col::String,
        name::String,
        ::Type{T};
        check_type::Bool = true,
        check_parm::Bool = true,
        ignore::Bool = false,
        default::T = _default_value(T),
    ) where T

Returns a `Vector{T}` containing the elements in `col` to a vector in julia. This function is
used to get data from collections that don't vary over time

Example:
```julia
PSRI.get_parms(data, "PSRBattery", "Einic", Float64)
PSRI.get_parms(data, "PSRBattery", "ChargeRamp", Float64)
PSRI.get_parms(data, "PSRBattery", "DischargeRamp", Float64)
```
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
    mapped_vector(
        data::AbstractData,
        col::String,
        name::String,
        ::Type{T},
        dim1::String="",
        dim2::String="";
        ignore::Bool=false,
        map_key = col, # reference for PSRMap pointer, if empty use class name
        filters = String[], # for calling just within a subset instead of the full call
    ) where T

Maps a `Vector{T}` containing the elements in `col` to a vector in julia. When the function [`update_vectors!`](@ref) 
is called the elements of the vector will be updated to the according elements registered at the current `data.time_controller`.

Example:
```julia
existing = PSRI.mapped_vector(data, "PSRThermalPlant", "Existing", Int32)
pot_inst = PSRI.mapped_vector(data, "PSRThermalPlant", "PotInst", Float64)
```

For more information please read the example [Reading basic thermal generator parameters](@ref)

!!! note "Differences between the OpenInterface and ClassicInterface"
    When using `mapped_vector` in the `OpenInterface` mode the vector will be mapped 
    with the correct values at first hand. When using `mapped_vector` in the 
    `ClassicInterface` mode you should call [`update_vectors!`](@ref) to get the 
    good values for the collection, otherwise you might only get a vector of zeros.
"""
function mapped_vector end

"""
    go_to_stage(data::AbstractData, stage::Integer)

Goes to the `stage` in the `data` time controller. 
"""
function go_to_stage end

"""
    go_to_dimension(data::Data, name::String, value::Integer)

Moves time controller reference of vectors indexed by dimension `name` to the
index `value`.

Example:
```
cesp = PSRI.mapped_vector(data, "PSRThermalPlant", "CEsp", Float64, "segment", "block")

PSRI.go_to_stage(data, 1)

PSRI.go_to_dimension(data, "segment", 1)
PSRI.go_to_dimension(data, "block", 1)
```
"""
function go_to_dimension end

"""
    update_vectors!(data::AbstractData)

Update all mapped vectors according to the time controller inside `data`.

---------

    update_vectors!(data::Data, filters::Vector{String})

Update filtered classes of mapped vectors according to the time controller inside `data`.
"""
function update_vectors! end

"""
    description(data::Data)

Returns the study description if available.
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
    block_from_stage_hour(data::Data, t::Int, h::Int)

Returns the block `b` associated with hour `h` at stage `t`.

---------

    block_from_stage_hour(data::Data, date::Dates.Date, h::Int)

Returns the block `b` associated with hour `h` at date `date`.
"""
function block_from_stage_hour end

"""
    get_nonempty_vector(
        data::Data,
        colllection::String,
        attribute::String,
    )

Returns a vector of booleans with the number of elements of the collection.
`true` means the vector associated with the given attribute is non-emepty,
`false` means it is empty.

Example:
```
PSRI.get_nonempty_vector(data, "PSRThermalPlant", "ChroGerMin")
PSRI.get_nonempty_vector(data, "PSRThermalPlant", "SpinningReserve")
```
"""
function get_nonempty_vector end

"""
    MainTypes = Union{Float64, Int32, String, Dates.Date}

All the data from the databases must have one of these types.
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

"""
    create_element(
        data::Data,
        name::String,
    )

Example:
```
element = PSRI.create_element!(data, "PSRClass")
```
"""
function create_element! end

"""
"""
function _insert_element! end

"""
    _get_element(
        data::Data,
        name::String,
        index::Integer,
    )

Low-level call to retrieve an element, that is, an instance of a class in the form of a `Dict{String, <:MainTypes}`.
It performs basic checks for bounds and existence of `index` and `name` according to `data`.
"""
function _get_element end

"""
    get_parm(
        data::Data,
        name::String,
        index::Integer,
        attr::String,
    )

Retrieves the value of a scalar parameter.
"""
function set_parm end

"""
    set_parm!(
        data::Data,
        name::String,
        index::Integer,
        attr::String,
        value::T,
    ) where {T <: MainTypes}

Defines the value of a scalar parameter.
"""
function set_parm! end

"""
    get_vector(
        data::Data,
        name::String,
        index::Integer,
        attr::String,
    )

Retrieves a copy of vectorial data.
"""
function get_vector end

"""
    function set_vector!(
        data::Data,
        name::String,
        index::Int,
        attr::String,
        buffer::Vector{T}
    ) where {T<:MainTypes}

Updates a data vector according to the given `buffer`.
*Note:* Modifying current vector length is not allowed: use `set_series!` instead.
"""
function set_vector! end

"""
    function get_series(
        data::Data,
        name::String,
        index::Int,
        index_attr::String,
    )

Retrieves the series i.e. `Dict{String, Vector}` indexed by `index_attr`.

Example
```
julia> PSRI.get_series(data, "PSRThermalPlant", 1, "Data")
Dict{String, Vector} with 13 entries:
  "GerMin"   => [0.0]    
  "GerMax"   => [888.0]  
  "NGas"     => [nothing]
  "IH"       => [0.0]    
  "ICP"      => [0.0]    
  "Data"     => ["1900-01-01"]
  "CoefE"    => [1.0]
  "PotInst"  => [888.0]
  "Existing" => [0]
  "sfal"     => [0]
  "NAdF"     => [0]
  "Unidades" => [1]
  "StartUp"  => [0.0]
```
"""
function get_series end

"""
    function set_series!(
        data::Data,
        name::String,
        index::Int,
        index_attr::String,
        buffer::Dict{String,Vector}
    )

Updates serial (indexed) data.
All columns must be the same as before.
The series length is allowed to be changed, but all vectors in the new series must have equal length.

```
julia> series = Dict{String, Vector}(     
         "GerMin" => [0.0, 1.0],        
         "GerMax" => [888.0, 777.0],    
         "NGas" => [nothing, nothing],  
         "IH" => [0.0, 0.0],
         "CoefE" => [1.0, 2.0],
         "PotInst" => [888.0, 777.0],   
         "ICP" => [0.0, 0.0],
         "Data" => ["1900-01-01", "1900-01-02"],
         "Existing" => [0, 0],
         "sfal" => [0, 1],
         "NAdF" => [0, 0],
         "Unidades" => [1, 1],
         "StartUp" => [0.0, 2.0]
       );

julia> PSRI.set_series!(data, "PSRThermalPlant", 1, "Data", series)

julia> PSRI.get_series(data, "PSRThermalPlant", 1, "Data")
Dict{String, Vector} with 13 entries:
  "GerMin"   => [0.0, 1.0]
  "GerMax"   => [888.0, 777.0]
  "NGas"     => [nothing, nothing]
  "IH"       => [0.0, 0.0]
  "ICP"      => [0.0, 0.0]
  "Data"     => ["1900-01-01", "1900-01-02"]
  "CoefE"    => [1.0, 2.0]
  "PotInst"  => [888.0, 777.0]
  "Existing" => [0, 0]
  "sfal"     => [0, 1]
  "NAdF"     => [0, 0]
  "Unidades" => [1, 1]
  "StartUp"  => [0.0, 2.0]
```
"""
function set_series! end