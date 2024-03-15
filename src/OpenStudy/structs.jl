"""
    OpenInterface <: AbstractStudyInterface
"""
struct OpenInterface <: PSRI.AbstractStudyInterface end

mutable struct VectorCache{T}
    dim1_str::String
    dim2_str::String
    dim1::Int
    dim2::Int
    index_str::String
    stage::Int
    vector::Vector{T}
    # date::Vector{Int32}
    # current_date::Int32
    default::T

    function VectorCache(
        dim1_str::Union{String, Nothing},
        dim2_str::Union{String, Nothing},
        dim1::Union{Integer, Nothing},
        dim2::Union{Integer, Nothing},
        index_str::String,
        stage::Integer,
        vector::Vector{T},
        default::T,
    ) where {T}
        return new{T}(
            isnothing(dim1_str) ? "" : dim1_str,
            isnothing(dim2_str) ? "" : dim2_str,
            isnothing(dim1) ? 0 : dim1,
            isnothing(dim2) ? 0 : dim2,
            index_str,
            stage,
            vector,
            default,
        )
    end
end

# TODO: rebuild "raw" stabilizing data types
# TODO fuel consumption updater

mutable struct DataIndex
    # `index` takes a `reference_id` as key and returns a pair
    # containing the collection from which the referenced item
    # belongs but also its index in the vector of instances of
    # the collection.
    index::Dict{Int, Tuple{String, Int}}

    # This is defined as the greatest `reference_id` indexed so
    # far, that is, `maximum(keys(data_index.index))`.
    max_id::Int

    function DataIndex()
        return new(Dict{Int, Tuple{String, Int}}(), 0)
    end
end

Base.@kwdef mutable struct Data{T} <: PSRI.AbstractData
    raw::T
    stage_type::PSRI.StageType

    data_path::String

    duration_mode::PSRI.BlockDurationMode = PSRI.FIXED_DURATION
    number_blocks::Int = 1

    # for variable duration and for hour block map
    variable_duration::Union{Nothing, PSRI.OpenBinary.Reader} = nothing
    hour_to_block::Union{Nothing, PSRI.OpenBinary.Reader} = nothing

    first_year::Int
    first_stage::Int #maybe week or month, day...
    first_date::Dates.Date

    data_struct::Dict{String, Dict{String, Attribute}}
    validate_attributes::Bool
    model_files_added::Set{String}

    log_file::Union{IOStream, Nothing}
    verbose::Bool

    # main time controller
    controller_stage::Int = 1
    controller_stage_changed::Bool = false
    controller_date::Dates.Date
    controller_dim::Dict{String, Int} = Dict{String, Int}()
    controller_block::Int = 1
    controller_scenario::Int = 1

    # cache to only in data reference once (per element)
    map_cache_data_idx::Dict{String, Dict{String, Vector{Int32}}} =
        Dict{String, Dict{String, Vector{Int32}}}()
    # vectors returned to user
    map_cache_real::Dict{String, Dict{String, VectorCache{Float64}}} =
        Dict{String, Dict{String, VectorCache{Float64}}}()
    map_cache_integer::Dict{String, Dict{String, VectorCache{Int32}}} =
        Dict{String, Dict{String, VectorCache{Int32}}}()
    map_cache_date::Dict{String, Dict{String, VectorCache{Dates.Date}}} =
        Dict{String, Dict{String, VectorCache{Dates.Date}}}()

    map_filter_real::Dict{String, Vector{Tuple{String, String}}} =
        Dict{String, Vector{Tuple{String, String}}}()
    map_filter_integer::Dict{String, Vector{Tuple{String, String}}} =
        Dict{String, Vector{Tuple{String, String}}}()

    extra_config::Dict{String, Any} = Dict{String, Any}()

    # TODO: cache importante data

    # Reference Indexing
    data_index::DataIndex = DataIndex()

    # Model Templates 
    model_template::PSRI.PMD.ModelTemplate = PSRI.PMD.ModelTemplate()

    # Relations
    relation_mapper::PSRI.PMD.RelationMapper

    # PSRI.ReaderMapper
    mapper::Union{PSRI.ReaderMapper, Nothing} = nothing
end
