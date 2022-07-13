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
    PSRI.get_vector(
        data::Data,
        collection::String,
        attribute::String,
        index::Integer,
        ::Type{T};
        default::T = _default_value(T),
    ) where T

Returns a `Vector{T}` of entries of the `attribute` of `collection` at the
element with index `index`.

Example:
```
PSRI.get_vector(data, "PSRGaugingStation", "Vazao", 1, Float64)
PSRI.get_vector(data, "PSRGaugingStation", "Data", 1, Dates.Date)
```
"""
function get_vector end

"""
    PSRI.get_vector_1d(
        data::Data,
        collection::String,
        attribute::String,
        index::Integer,
        ::Type{T};
        default::T = _default_value(T),
    ) where T

Returns a `Vector{Vector{T}}` of entries of the `attribute` of `collection` at the
element with index `index`.
The outer vector contains one entry per index in dimension 1, while the inner
vector is sized according to the main vector index which is tipicaaly time.

Example:
```
PSRI.get_vector_1d(data, "PSRArea", "Export", 1, Float64)
PSRI.get_vector_1d(data, "PSRLoad", "P", 1, Float64)
```
"""
function get_vector_1d end

"""
    PSRI.get_vector_2d(
        data::Data,
        collection::String,
        attribute::String,
        index::Integer,
        ::Type{T};
        default::T = _default_value(T),
    ) where T

Returns a `Matrix{Vector{T}}` of entries of the `attribute` of `collection` at the
element with index `index`.
The outer matrix contains one entry per index in dimension 1 and dimension 2,
while the inner
vector is sized according to the main vector index which is tipicaaly time.

Example:
```
PSRI.get_vector_2d(data, "PSRThermalPlant", "CEsp", 1, Float64)
PSRI.get_vector_2d(data, "PSRFuelConsumption", "CEsp", 1, Float64)
```
"""
function get_vector_2d end

"""
    PSRI.get_vectors(
        data::Data,
        collection::String,
        attribute::String,
        ::Type{T};
        default::T = _default_value(T),
    ) where T

Returns a `Vector{Vector{T}}` of entries of the `attribute` of `collection`.
Each entry of the outer vector corresponding to an element of the collection.

Example:
```
PSRI.get_vectors(data, "PSRGaugingStation", "Vazao", Float64)
PSRI.get_vectors(data, "PSRGaugingStation", "Data", Dates.Date)
```
"""
function get_vectors(
    data::AbstractData,
    collection::String,
    attribute::String,
    ::Type{T};
    default::T = _default_value(T),
) where T
    n = max_elements(data, collection)
    out = Vector{T}[]
    sizehint!(out, n)
    for i in 1:n
        push!(out, get_vector(data, collection, attribute, i, T, default = default))
    end
    return out
end

"""
    PSRI.get_vectors_1d(
        data::Data,
        collection::String,
        attribute::String,
        ::Type{T},
    ) where T

Returns a `Vector{Vector{Vector{T}}}` of entries of the `attribute` of `collection`.
Each entry of the outer vector corresponding to an element of the collection.
For the containt of the 2 inner vectors see `get_vector_1d`.

Example:
```
PSRI.get_vectors_1d(data, "PSRArea", "Export", Float64)
PSRI.get_vectors_1d(data, "PSRLoad", "P", Float64)
```
"""
function get_vectors_1d(
    data::AbstractData,
    collection::String,
    attribute::String,
    ::Type{T};
    default::T = _default_value(T),
) where T
    n = max_elements(data, collection)
    out =  Vector{Vector{T}}[]
    sizehint!(out, n)
    for i in 1:n
        push!(out, get_vector_1d(data, collection, attribute, i, T, default = default))
    end
    return out
end

"""
    PSRI.get_vectors_2d(
        data::Data,
        collection::String,
        attribute::String,
        ::Type{T},
    ) where T

Returns a `Vector{Matrix{Vector{T}}}` of entries of the `attribute` of `collection`.
Each entry of the outer vector corresponding to an element of the collection.
For the containt of the `Matrix{Vector{T}}` see `get_vector_2d`.

Example:
```
PSRI.get_vectors_2d(data, "PSRThermalPlant", "CEsp", Float64)
PSRI.get_vectors_2d(data, "PSRFuelConsumption", "CEsp", Float64)
```
"""
function get_vectors_2d(
    data::AbstractData,
    collection::String,
    attribute::String,
    ::Type{T};
    default::T = _default_value(T),
) where T
    n = max_elements(data, collection)
    out = Matrix{Vector{T}}[]
    sizehint!(out, n)
    for i in 1:n
        push!(out, get_vector_2d(data, collection, attribute, i, T, default = default))
    end
    return out
end

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
    get_parm(
        data::AbstractData,
        collection::String,
        attribute::String,
        index::Integer,
        ::Type{T};
        default::T = _default_value(T),
    ) where T

Returns a `T` containing the the value from `attribute` of `collection`.
This function is used to get data from collections that don't vary over time.

Example:
```julia
PSRI.get_parms(data, "PSRBattery", "Einic", Float64, 1)
PSRI.get_parms(data, "PSRBattery", "ChargeRamp", Float64, 1)
PSRI.get_parms(data, "PSRBattery", "DischargeRamp", Float64, 1)
```
"""
function get_parm end

"""
    get_parm_1d(
        data::AbstractData,
        collection::String,
        attribute::String,
        index::Integer,
        ::Type{T};
        default::T = _default_value(T),
    ) where T

Returns a `T` containing the the value from `attribute` of `collection`.
This function is used to get data from collections that don't vary over time.

Example:
```julia
PSRI.get_parm_1d(data, "PSRHydroPlant", "FP", Float64, 1)
PSRI.get_parm_1d(data, "PSRHydroPlant", "FP.VOL", Float64, 1)
```
"""
function get_parm_1d end

"""
    get_parm_2d(
        data::AbstractData,
        collection::String,
        attribute::String,
        index::Integer,
        ::Type{T};
        default::T = _default_value(T),
    ) where T

Returns a `T` containing the the value from `attribute` of `collection`.
This function is used to get data from collections that don't vary over time.

Example: no available in SDDP data base
```julia
```
"""
function get_parm_2d end

"""
    get_parms(
        data::AbstractData,
        collection::String,
        attribute::String,
        ::Type{T};
        check_type::Bool = true,
        check_parm::Bool = true,
        ignore::Bool = false,
        default::T = _default_value(T),
    ) where T

Returns a `Vector{T}` containing the elements in `collection` to a vector in
julia.
This function is used to get data from collections that don't vary over time

Example:
```julia
PSRI.get_parms(data, "PSRBattery", "Einic", Float64)
PSRI.get_parms(data, "PSRBattery", "ChargeRamp", Float64)
PSRI.get_parms(data, "PSRBattery", "DischargeRamp", Float64)
```
"""
function get_parms end

"""
    get_parms_1d(
        data::AbstractData,
        collection::String,
        attribute::String,
        ::Type{T};
        check_type::Bool = true,
        check_parm::Bool = true,
        ignore::Bool = false,
        default::T = _default_value(T),
    ) where T

Returns a `Vector{T}` containing the elements in `collection` to a vector in
julia.
This function is used to get data from collections that don't vary over time

Example:
```julia
PSRI.get_parm_1d(data, "PSRHydroPlant", "FP", Float64)
PSRI.get_parm_1d(data, "PSRHydroPlant", "FP.VOL", Float64)
```
"""
function get_parms_1d end

"""
    get_parms_2d(
        data::AbstractData,
        collection::String,
        attribute::String,
        ::Type{T};
        check_type::Bool = true,
        check_parm::Bool = true,
        ignore::Bool = false,
        default::T = _default_value(T),
    ) where T

Returns a `Vector{T}` containing the elements in `collection` to a vector in
julia.
This function is used to get data from collections that don't vary over time

Example:
```julia
PSRI.get_parms_2d(data, "PSRBattery", "Einic", Float64)
PSRI.get_parms_2d(data, "PSRBattery", "ChargeRamp", Float64)
PSRI.get_parms_2d(data, "PSRBattery", "DischargeRamp", Float64)
```
"""
function get_parms_2d end

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
        collection::String,
        attribute::String,
        ::Type{T},
        dim1::String="",
        dim2::String="";
        ignore::Bool=false,
        map_key = collection, # reference for PSRMap pointer, if empty use class name
        filters = String[], # for calling just within a subset instead of the full call
    ) where T

Maps a `Vector{T}` containing the elements in `collection` to a vector in julia. When the function [`update_vectors!`](@ref) 
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
    block_duration(data::AbstractData, date::Dates.Date, block::Int)

Returns the duration, in hours, of the `block` at the stage corresponding to `date`.

---------

    block_duration(data::AbstractData, stage::Int, block::Int)

Returns the duration, in hours, of the `block` at `stage`.

---------

    block_duration(data::AbstractData, block::Int)

Returns the duration, in hours, of the `block` at the current stage, set by `go_to_stage`.
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
        attribute::String,
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
        attribute::String,
        default::Vector{T},
    ) where T <: MainTypes

Returns the rquired configuration parameters from the case that are vectors that are vectors. If the parameter is not registered returns the default value.

Example:
```
PSRI.configuration_parameter(data, "DeficitCost", [0.0])
```
"""
function configuration_parameter end

"""
    get_attribute_struct(
        data::AbsttractData,
        collection::String,
        attribute::string,
    )

Return a struct of type `Attribute` with fields:

* name::String = attribute name
* is_vector::Bool = true if attribute is a vector (tipically, varies in time)
* type::DataType = attribute type (tipically: Int32, Float64, String, Dates.Date)
* dim::Int = number of additional dimensions
* index::String = if a vector represents the indexing vector (might be empty)
"""
function get_attribute_struct end


"""
    get_attribute_dim1(
        data::Data,
        collection::String,
        attribute::string,
        index::Integer;
    )

Returns the size of dimension 1 of `attribute` from `collection` at element
`index`.
Errors if attribute has zero dimensions.
"""
function get_attribute_dim1 end

"""
    get_attribute_dim2(
        data::Data,
        collection::String,
        attribute::string,
        index::Integer;
    )

Returns the size of dimension 2 of `attribute` from `collection` at element
`index`.
Errors if attribute has zero or one dimensions.
"""
function get_attribute_dim2 end

"""
    get_attributes(data::Data, collection::String)

Return `Vector{String}` of valid attributes from `collection`.
"""
function get_attributes end

"""
    get_collections(data::Data)

Return `Vector{String}` of valid collections (depends on loaded pmd files).
"""
function get_collections end

"""
    get_relations(data::Data, collection::String)

Returns a `Vector{Tuple{String, RelationType}}` with relating `collection`
and their relation type associated to `collection`.
"""
function get_relations end