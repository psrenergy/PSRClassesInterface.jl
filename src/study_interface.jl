@enum BlockDurationMode begin
    FIXED_DURATION
    VARIABLE_DURATION
    HOUR_BLOCK_MAP
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
    load_study(::AbstractStudyInterface; kwargs...)

Initialize all data structures of the study.

!!! note "Differences between the OpenInterface and ClassicInterface"

    Each study interface has its own set of `kwargs...` The easiest way to inspect the current
    available options is searching for this function on the Github repo of the desired interface.

Example:

```julia
data = PSRI.load_study(
    PSRI.OpenInterface();
    data_path = PATH_CASE_EXAMPLE_BATTERIES,
)
```
"""
function load_study end

"""
    PSRI.get_vector(
        data::AbstractData,
        collection::String,
        attribute::String,
        index::Integer,
        ::Type{T};
        default::T = _default_value(T),
    ) where T

Returns a `Vector{T}` of entries of the `attribute` of `collection` at the
element with index `index`.

Example:

```julia
PSRI.get_vector(data, "PSRGaugingStation", "Vazao", 1, Float64)
PSRI.get_vector(data, "PSRGaugingStation", "Data", 1, Dates.Date)
```
"""
function get_vector end

"""
    PSRI.get_vector_1d(
        data::AbstractData,
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

```julia
PSRI.get_vector_1d(data, "PSRArea", "Export", 1, Float64)
PSRI.get_vector_1d(data, "PSRLoad", "P", 1, Float64)
```
"""
function get_vector_1d end

"""
    PSRI.get_vector_2d(
        data::AbstractData,
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

```julia
PSRI.get_vector_2d(data, "PSRThermalPlant", "CEsp", 1, Float64)
PSRI.get_vector_2d(data, "PSRFuelConsumption", "CEsp", 1, Float64)
```
"""
function get_vector_2d end

"""
    PSRI.get_vectors(
        data::AbstractData,
        collection::String,
        attribute::String,
        ::Type{T};
        default::T = _default_value(T),
    ) where T

Returns a `Vector{Vector{T}}` of entries of the `attribute` of `collection`.
Each entry of the outer vector corresponding to an element of the collection.

Example:

```julia
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
) where {T}
    n = max_elements(data, collection)
    out = Vector{Vector{T}}(undef, n)
    for i in 1:n
        out[i] = get_vector(data, collection, attribute, i, T; default = default)
    end
    return out
end

"""
    PSRI.get_vectors_1d(
        data::AbstractData,
        collection::String,
        attribute::String,
        ::Type{T},
    ) where T

Returns a `Vector{Vector{Vector{T}}}` of entries of the `attribute` of `collection`.
Each entry of the outer vector corresponding to an element of the collection.
For the containt of the 2 inner vectors see `get_vector_1d`.

Example:

```julia
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
) where {T}
    n = max_elements(data, collection)
    out = Vector{Vector{Vector{T}}}(undef, n)
    for i in 1:n
        out[i] = get_vector_1d(data, collection, attribute, i, T; default = default)
    end
    return out
end

"""
    PSRI.get_vectors_2d(
        data::AbstractData,
        collection::String,
        attribute::String,
        ::Type{T},
    ) where T

Returns a `Vector{Matrix{Vector{T}}}` of entries of the `attribute` of `collection`.
Each entry of the outer vector corresponding to an element of the collection.
For the containt of the `Matrix{Vector{T}}` see `get_vector_2d`.

Example:

```julia
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
) where {T}
    n = max_elements(data, collection)
    out = Vector{Matrix{Vector{T}}}(undef, n)
    for i in 1:n
        out[i] = get_vector_2d(data, collection, attribute, i, T; default = default)
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

PSRI.get_map(
    data,
    "PSRHydroPlant",
    "PSRHydroPlant";
    relation_type = PSRI.PMD.RELATION_TURBINE_TO,
)
PSRI.get_map(
    data,
    "PSRHydroPlant",
    "PSRHydroPlant";
    relation_type = PSRI.PMD.RELATION_SPILL_TO,
)
PSRI.get_map(
    data,
    "PSRHydroPlant",
    "PSRHydroPlant";
    relation_type = PSRI.PMD.RELATION_INFILTRATE_TO,
)
PSRI.get_map(
    data,
    "PSRHydroPlant",
    "PSRHydroPlant";
    relation_type = PSRI.PMD.RELATION_STORED_ENERGY_DONWSTREAM,
)
```
"""
function get_map end

"""
    get_vector_map(
        data::AbstractData,
        collection_from::String,
        collection_to::String;
        relation_type::RelationType = RELATION_1_TO_N,
    )

Returns a `Vector{Vector{Int32}}` to represent the relation between each element
of `collection_from` to multiple elements of `collection_to`.

Since multiple relations might be available one might need to specify
`relation_type`.

Example:

```julia
PSRI.get_vector_map(data, "PSRInterconnectionSumData", "PSRInterconnection")
PSRI.get_vector_map(data, "PSRReserveGenerationConstraintData", "PSRHydroPlant")
PSRI.get_vector_map(
    data,
    "PSRReserveGenerationConstraintData",
    "PSRThermalPlant";
    relation_type = PSRI.PMD.RELATION_BACKED,
)
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

```julia
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

```julia
# upstream turbining hydros
PSRI.get_reverse_vector_map(
    data,
    "PSRHydroPlant",
    "PSRHydroPlant";
    original_relation_type = PSRI.PMD.RELATION_TURBINE_TO,
)
# which is the reverse of
PSRI.get_map(
    data,
    "PSRHydroPlant",
    "PSRHydroPlant";
    relation_type = PSRI.PMD.RELATION_TURBINE_TO,
)

PSRI.get_reverse_vector_map(
    data,
    "PSRGenerator",
    "PSRBus";
    original_relation_type = PSRI.PMD.RELATION_1_TO_1,
)
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
PSRI.get_parm(data, "PSRBattery", "Einic", Float64, 1)
PSRI.get_parm(data, "PSRBattery", "ChargeRamp", Float64, 1)
PSRI.get_parm(data, "PSRBattery", "DischargeRamp", Float64, 1)
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

Example: (Warning: a SDDP study does not have a parm attribute with two dimensions)

```julia
PSRI.get_parm_2d(data, "PSRCollection", "AttributeName", Float64, 1)
```
"""
function get_parm_2d end

"""
    get_parms(
        data::AbstractData,
        collection::String,
        attribute::String,
        ::Type{T};
        validate::Bool = true,
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
function get_parms(
    data::AbstractData,
    collection::String,
    attribute::String,
    ::Type{T};
    validate::Bool = true,
    ignore::Bool = false,
    default::T = _default_value(T),
)::Vector{T} where {T}
    if validate
        _check_type_parm(data, collection, attribute, T)
    end
    n = max_elements(data, collection)
    out = Vector{T}(undef, n)
    for i in 1:n
        out[i] = get_parm(data, collection, attribute, i, T; default = default, validate = validate)
    end
    return out
end

"""
    get_parms_1d(
        data::AbstractData,
        collection::String,
        attribute::String,
        ::Type{T};
        validate::Bool = true,
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
function get_parms_1d(
    data::AbstractData,
    collection::String,
    attribute::String,
    ::Type{T};
    validate::Bool = true,
    ignore::Bool = false,
    default::T = _default_value(T),
)::Vector{Vector{T}} where {T}
    if validate
        _check_type_parm(data, collection, attribute, T)
    end

    n = max_elements(data, collection)
    out = Vector{Vector{T}}(undef, n)
    for i in 1:n
        out[i] = get_parm_1d(data, collection, attribute, i, T; default = default, validate = validate)
    end
    return out
end

function _check_type_parm(data, collection, attribute, T)
    attribute_struct = get_attribute_struct(data, collection, attribute)
    _check_type(attribute_struct, T, collection, attribute)
    _check_parm(attribute_struct, collection, attribute)
    return nothing
end

"""
    get_parms_2d(
        data::AbstractData,
        collection::String,
        attribute::String,
        ::Type{T};
        validate::Bool = true,
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
function get_parms_2d(
    data::AbstractData,
    collection::String,
    attribute::String,
    ::Type{T};
    validate::Bool = true,
    ignore::Bool = false,
    default::T = _default_value(T),
)::Vector{Matrix{T}} where {T}
    if validate
        _check_type_parm(data, collection, attribute, T)
    end

    n = max_elements(data, collection)
    out = Vector{Matrix{T}}(undef, n)
    for i in 1:n
        out[i] = get_parm_2d(data, collection, attribute, i, T; default = default, validate = validate)
    end
    return out
end

"""
    get_code(data::AbstractData, collection::String)

Returns a `Vector{Int32}` containing the code of each element in `collection`.

Example:

```julia
PSRI.get_code(data, "PSRThermalPlant")
```
"""
function get_code(data::AbstractData, collection::String)::Vector{Int32}
    return get_parms(data, collection, "code", Int32)
end

"""
    get_name(data::AbstractData, collection::String)

Returns a `Vector{String}` containing the name of each element in `collection`.

Example:

```julia
PSRI.get_name(data, "PSRThermalPlant")
PSRI.get_name(data, "PSRGaugingStation")
```
"""
function get_name(data::AbstractData, collection::String)::Vector{String}
    return get_parms(data, collection, "name", String)
end

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
    go_to_dimension(data::AbstractData, name::String, value::Integer)

Moves time controller reference of vectors indexed by dimension `name` to the
index `value`.

Example:

```julia
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

    update_vectors!(data::AbstractData, filters::Vector{String})

Update filtered classes of mapped vectors according to the time controller inside `data`.
"""
function update_vectors! end

"""
    description(data::AbstractData)

Returns the study description if available.
"""
function description end

"""
    total_stages(data::AbstractData)

Returns the total number of stages of the case.

Example:

```julia
PSRI.total_stages(data)
```
"""
function total_stages end

"""
    total_scenarios(data::AbstractData)

Returns the total number of scenarios of the case.

Example:

```julia
PSRI.total_scenarios(data)
```
"""
function total_scenarios end

"""
    total_blocks(data::AbstractData)

Returns the total number of blocks of the case.

Example:

```julia
PSRI.total_blocks(data)
```
"""
function total_blocks end

"""
    total_openings(data::AbstractData)

Returns the total number of openings of the case.

Example:

```julia
PSRI.total_openings(data)
```
"""
function total_openings end

"""
    total_stages_per_year(data::AbstractData)

Returns the total number of stages per year of the case.

Example:

```julia
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

    stage_duration(data::AbstractData, date::Dates.Date)

Returns the duration, in hours, at the stage corresponding to `date`.
"""
function stage_duration end

"""
    block_duration(data::AbstractData, date::Dates.Date, block::Int)

Returns the duration, in hours, of the `block` at the stage corresponding to `date`.

    block_duration(data::AbstractData, stage::Int, block::Int)

Returns the duration, in hours, of the `block` at `stage`.

    block_duration(data::AbstractData, block::Int)

Returns the duration, in hours, of the `block` at the current stage, set by `go_to_stage`.
"""
function block_duration end

"""
    block_from_stage_hour(data::AbstractData, t::Int, h::Int)

Returns the block `b` associated with hour `h` at stage `t`.

    block_from_stage_hour(data::AbstractData, date::Dates.Date, h::Int)

Returns the block `b` associated with hour `h` at date `date`.
"""
function block_from_stage_hour end

"""
    get_nonempty_vector(
        data::AbstractData,
        colllection::String,
        attribute::String,
    )

Returns a vector of booleans with the number of elements of the collection.
`true` means the vector associated with the given attribute is non-emepty,
`false` means it is empty.

Example:

```julia
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

    configuration_parameter(
        data::AbstractData,
        attribute::String,
        default::Vector{T},
    ) where T <: MainTypes

Returns the rquired configuration parameters from the case that are vectors that are vectors. If the parameter is not registered returns the default value.

## Examples:

```julia
PSRI.configuration_parameter(data, "MaximoIteracoes", 0)
PSRI.configuration_parameter(data, "MinOutflowPenalty", 0.0)
```

```julia
PSRI.configuration_parameter(data, "DeficitCost", [0.0])
```
"""
function configuration_parameter end

"""
    create_element!(
        data::Data,
        collection::String,
        ps::Pair{String,<:Any};
        default::Union{Dict{String,Any},Nothing} = nothing
    )

Creates a new instance of the given `collection` and returns its index.

Example:

```
index = PSRI.create_element!(data, "PSRClass")

PSRI.set_parm!(data, "PSRClass", index, "PSRAttr", value)
```
"""
function create_element! end

"""
delete_element!(
data::Data,
collection::String,
index::Int32
)

Deletes element from `collection` at index `index`.

Example:

```
PSRI.delete_element!(data, "PSRBus", 3)
```
"""
function delete_element! end

"""
    set_parm!(
        data::Data,
        collection::String,
        attribute::String,
        index::Integer,
        value::T,
    ) where {T <: MainTypes}

Defines the value of a scalar parameter.
"""
function set_parm! end

"""
    function set_vector!(
        data::Data,
        collection::String,
        attribute::String,
        index::Int,
        buffer::Vector{T}
    ) where {T<:MainTypes}

Updates a data vector according to the given `buffer`.
*Note:* Modifying current vector length is not allowed: use `set_series!` instead.
"""
function set_vector! end

"""
    function get_series(
        data::Data,
        collection::String,
        indexing_attribute::String,
        index::Int,
    )

Retrieves a SeriesTable object with all attributes from an element that are indexed by `index_attr`.

Example

```
julia> PSRI.get_series(data, "PSRThermalPlant", "Data", 1)
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
function get_graf_series(
data::Data,
collection::String,
attribute::String;
kws...
)

Retrieves a GrafTable object with the values for 'attribute' in all elements in 'collection' from a Graf file.

Example

```
julia> PSRI.get_graf_series(data, "PSRDemand", "Duracao")
```
"""
function get_graf_series end

"""
    function set_series!(
        data::Data,
        collection::String,
        index_attr::String,
        index::Int,
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
```
"""
function set_series! end

"""
    function has_graf_file(data::Data, collection::String, attribute::Union{String, Nothing} = nothing)

Checks if data has a Graf file linked to an attribute(specified or not) from a collection.

Example

```
julia> PSRI.has_graf_file(data, "PSRDemandSegment", "HourDemand")

julia> PSRI.has_graf_file(data, "PSRDemandSegment")
```
"""
function has_graf_file end

"""
    function link_series_to_file(
        data::Data, 
        collection::String,
        attribute::String,
        agent_attribute::String,
        file_name::String
    )

Links Graf file to an attribute from a collection.

Example

```
julia> PSRI.link_series_to_file(
    data, 
    "PSRDemandSegment", 
    "HourDemand", 
    "DataHourDemand",
    path
)
```
"""
function link_series_to_file end

"""
    write_data(data::Data, path::String)

Writes data to file in JSON format.
"""
function write_data end

"""
    get_attribute_dim1(
        data::AbstractData,
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
        data::AbstractData,
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
    get_attribute_struct(data::AbstractData)

Return a struct of type `DataStruct` with collection names (strings) as keys
and maps from attributes names (string) to attributes data definitions
`Attribute`.
"""
function get_data_struct(data::AbstractData)
    return data.data_struct
end

"""
    get_attribute_struct(
        data::AbstractData,
        collection::String,
        attribute::String,
    )

Returns a struct of type `Attribute` with fields:

  - name::String = attribute name
  - is_vector::Bool = true if attribute is a vector (tipically, varies in time)
  - type::DataType = attribute type (tipically: Int32, Float64, String, Dates.Date)
  - dim::Int = number of additional dimensions
  - index::String = if a vector represents the indexing vector (might be empty)
"""
function get_attribute_struct(data::AbstractData, collection::String, attribute::String)
    return get_attribute_struct(get_data_struct(data), collection, attribute)
end

function get_attribute_struct(data::DataStruct, collection::String, attribute::String)
    collection_struct = data[collection]

    attribute, _ = _trim_multidimensional_attribute(attribute)

    if !haskey(collection_struct, attribute)
        error("No information for attribute '$attribute' found in collection '$collection'")
    end

    return collection_struct[attribute]::Attribute
end

"""
    get_attributes(data::AbstractData, collection::String)

Return `Vector{String}` of valid attributes from `collection`.
"""
function get_attributes(data::AbstractData, collection::String)
    return get_attributes(get_data_struct(data), collection)
end

function get_attributes(data::DataStruct, collection::String)
    return sort!(collect(keys(data[collection])))
end

"""
    get_attributes_indexed_by(
        data::AbstractData,
        collection::String,
        indexing_attribute::String
    )

Return `Vector{String}` of valid vector attributes from `collection` that are
indexed by `indexing_attribute`.
"""
function get_attributes_indexed_by(
    data::AbstractData,
    collection::String,
    indexing_attribute::String,
)
    data_struct = get_data_struct(data)
    if !haskey(data_struct, collection)
        error("PSR Class '$collection' is not available for this database.")
    end

    class_struct = data_struct[collection]

    attributes = String[]

    for (attribute, attribute_data) in class_struct
        if attribute_data.index == indexing_attribute
            push!(attributes, attribute)
        end
    end

    sort!(attributes)

    return attributes
end

"""
    get_collections(data::AbstractData)

Return `Vector{String}` of valid collections (depends on loaded pmd files).
"""
function get_collections(data::AbstractData)
    return get_collections(get_data_struct(data))
end

function get_collections(data::DataStruct)
    return sort(collect(keys(data)))
end

"""
    get_relations(data::AbstractData, collection::String)

Returns a `Tuple{String, Vector{PMD.Relation}}` with relating `collection`
and their relation type associated to `collection`.
"""
function get_relations(data::AbstractData, collection::String)
    if has_relations(data, collection)
        return data.relation_mapper[collection]
    end
    return Dict{String, Vector{PMD.Relation}}[]
end

"""
    set_validate_attributes(data::AbstractData, val::Bool)

activates and de-activates attribute validation in getters for both parms and vectors.
"""
function set_validate_attributes(data::AbstractData, val::Bool)
    data.validate_attributes = val
    return nothing
end

"""
    get_validate_attributes(data::AbstractData)

check if attribute validation is active.
"""
function get_validate_attributes(data::AbstractData)
    return data.validate_attributes
end

"""
    get_attribute_dim(attribute_struct::Attribute)
"""
function get_attribute_dim end

"""
    get_related(
        data::AbstractData,
        source::String,
        target::String,
        source_index::Integer,
        relation_type = RELATION_1_TO_1,
    )

Returns the index of the element in collection `target` related to the element
in the collection `source` element indexed by `source_index` according to the
scalar relation `relation_type`.
"""
function get_related end

"""
    set_related!(
        data::AbstractData,
        source::String,
        target::String,
        source_index::Integer,
        target_index::Integer;
        relation_type = RELATION_1_TO_1,
    )

Sets the element `source_index` from collection `source` to be related to
the element `target_index` from collection `target` in the scalar relation
of type `relation_type`.
"""
function set_related! end

"""
    get_vector_related(
        data::AbstractData,
        source::String,
        target::String,
        source_index::Integer,
        relation_type = RELATION_1_TO_N,
    )

Returns the vector of indices of the elements in collection `target` related to
the element in the collection `source` element indexed by `source_index`
according to the scalar relation `relation_type`.
"""
function get_vector_related end

"""
    set_vector_related!(
        data::AbstractData,
        source::String,
        target::String,
        source_index::Integer,
        target_index::Vector{<:Integer};
        relation_type = RELATION_1_TO_N,
    )

Sets the element `source_index` from collection `source` to be related to
the elements in `target_index` from collection `target` in the vector relation
of type `relation_type`.
"""
function set_vector_related! end

"""
    create_study(::AbstractStudyInterface; kwargs...)

Returns the `Data` object of a new study.
"""
function create_study end

"""
    summary(data::Data)
    summary(io::IO, data::Data)

Shows information about all collections in a study.

    summary(data::Data, collection::String)
    summary(io::IO, data::Data, collection::String)

Shows information about all attributes of a collection.

    summary(data::Data, collection::String, attribute::String)
    summary(io::IO, data::Data, collection::String, attribute::String)

Shows information about an attribute of a collection.
"""
function summary end
