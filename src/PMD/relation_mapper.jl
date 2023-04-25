using JSON

const _DEFAULT_RELATIONS_PATH =
    joinpath(@__DIR__(), "..", "json_metadata", "relations.default.json")

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
    RELATION_1_TO_1 = 0
    RELATION_1_TO_N = 1
    RELATION_FROM = 2
    RELATION_TO = 3
    RELATION_TURBINE_TO = 4
    RELATION_SPILL_TO = 5
    RELATION_INFILTRATE_TO = 6
    RELATION_STORED_ENERGY_DONWSTREAM = 7
    RELATION_BACKED = 8
end

"""
    Relation(type::RelationType, attribute::String)
"""
struct Relation
    type::RelationType
    attribute::String
end

const RelationMapper = Dict{String, Dict{String, Vector{Relation}}}

function load_relations_struct!(path::AbstractString, relation_mapper::RelationMapper)
    raw_struct = JSON.parsefile(path)

    for (key, value) in raw_struct
        relation_mapper[key] = Dict{String, Vector{Relation}}()
        for (collection, relations) in value
            relations_vector = [
                Relation(RelationType(relation["type"]), relation["attribute"]) for
                relation in relations
            ]
            relation_mapper[key][collection] = relations_vector
        end
    end
end
