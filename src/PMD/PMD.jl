module PMD

import PSRClassesInterface
const PSRI = PSRClassesInterface

import Dates
import JSON

"""
```
struct Attribute
    name::String
    is_vector::Bool
    type::DataType
    dim::Int
    index::String
end
```
"""
struct Attribute
    name::String
    is_vector::Bool
    type::DataType
    dim::Int
    index::String
    # interval::String
end

const DataStruct = Dict{String, Dict{String, Attribute}}

# TODO non portable
const _PMDS_BASE_PATH = joinpath(@__DIR__(), "pmds")

# TODO non portable
const PMD_MODEL_TEMPLATES_PATH =
    joinpath(@__DIR__(), "..", "json_metadata", "modeltemplates.sddp.json")

include("model_template.jl")
include("relation_mapper.jl")
include("pmd_interface.jl")
include("utils.jl")
include("parser/parser.jl")

end
