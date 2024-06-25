"""
    Attribute

Abstract type for attributes, the building blocks of collections.
"""
abstract type Attribute end

abstract type ScalarAttribute <: Attribute end
abstract type VectorAttribute <: Attribute end
abstract type ReferenceToFileAttribute <: Attribute end

mutable struct ScalarParameter{T} <: ScalarAttribute
    id::String
    type::Type{T}
    default_value::Union{Missing, T}
    not_null::Bool
    parent_collection::String
    table_where_is_located::String
end

mutable struct ScalarRelation{T} <: ScalarAttribute
    id::String
    type::Type{T}
    default_value::Union{Missing, T}
    not_null::Bool
    parent_collection::String
    relation_collection::String
    relation_type::String
    table_where_is_located::String

    function ScalarRelation(
        id::String,
        type::Type{T},
        default_value::Union{Missing, T},
        not_null::Bool,
        parent_collection::String,
        relation_collection::String,
        relation_type::String,
        table_where_is_located::String,
    ) where {T}
        _check_valid_relation_name(id, relation_collection)
        return new{T}(
            id,
            type,
            default_value,
            not_null,
            parent_collection,
            relation_collection,
            relation_type,
            table_where_is_located,
        )
    end
end

mutable struct VectorParameter{T} <: VectorAttribute
    id::String
    type::Type{T}
    default_value::Union{Missing, T}
    not_null::Bool
    group_id::String
    parent_collection::String
    table_where_is_located::String
end

mutable struct VectorRelation{T} <: VectorAttribute
    id::String
    type::Type{T}
    default_value::Union{Missing, T}
    not_null::Bool
    group_id::String
    parent_collection::String
    relation_collection::String
    relation_type::String
    table_where_is_located::String

    function VectorRelation(
        id::String,
        type::Type{T},
        default_value::Union{Missing, T},
        not_null::Bool,
        group_id::String,
        parent_collection::String,
        relation_collection::String,
        relation_type::String,
        table_where_is_located::String,
    ) where {T}
        _check_valid_relation_name(id, relation_collection)
        return new{T}(
            id,
            type,
            default_value,
            not_null,
            group_id,
            parent_collection,
            relation_collection,
            relation_type,
            table_where_is_located,
        )
    end
end

mutable struct TimeSeries{T} <: VectorAttribute
    id::String
    type::Type{T}
    default_value::Union{Missing, T}
    not_null::Bool
    group_id::String
    parent_collection::String
    table_where_is_located::String
    dimension_names::Vector{String}
end

mutable struct TimeSeriesFile{T} <: ReferenceToFileAttribute
    id::String
    type::Type{T}
    default_value::Union{Missing, T}
    not_null::Bool
    parent_collection::String
    table_where_is_located::String
end

function _get_related_collection_from_attribute_id(attribute_id::String)
    name_separated_by_underscore = split(attribute_id, "_")
    return lowercase(name_separated_by_underscore[1])
end

function _check_valid_relation_name(attribute_id::String, related_collection::String)
    related_collection_from_attribute_id =
        _get_related_collection_from_attribute_id(attribute_id)
    if related_collection_from_attribute_id != lowercase(related_collection)
        psr_database_sqlite_error(
            """
            Attribute \"$attribute_id\" is not a valid relation name. It is related to collection \"$related_collection\" so its name must start with \"$(lowercase(related_collection))_\".
            """,
        )
    end
    return nothing
end
