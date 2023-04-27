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
    type::RelationType # deprecated ?
    attribute::String
    is_vector::Bool

    function Relation(type::RelationType, attribute::String)
        return new(type, attribute, type == RELATION_1_TO_N || type == RELATION_BACKED)
    end

    function Relation(type::RelationType, attribute::String, is_vector::Bool)
        return new(type, attribute, is_vector)
    end
end

const RelationMapper = Dict{String, Dict{String, Dict{String, Relation}}}

function load_relations_struct!(path::AbstractString, relation_mapper::RelationMapper)
    raw_struct = JSON.parsefile(path)

    for (source, targets) in raw_struct
        relation_mapper[source] = Dict{String, Dict{String, Relation}}()
        for (target, attributes) in targets
            relation_mapper[source][target] = Dict{String, Relation}()
            for (attribute, info) in attributes
                relation = Relation(
                    RelationType(info["type"]),
                    attribute,
                    info["is_vector"],
                )

                relation_mapper[source][target][attribute] = relation
            end
        end
    end

    return nothing
end
