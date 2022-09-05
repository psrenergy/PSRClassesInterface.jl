"""
    ReaderMapper{T}
"""
Base.@kwdef mutable struct ReaderMapper{T}
    list::Vector{T} = T[]
    default::Vector{Int} = Int[]
    name::Dict{String, Int} = Dict{String, Int}()
    dict::Dict{String, Vector{Int}} = Dict{String, Vector{Int}}()
    first_date::Dates.Date = Dates.Date(1900, 1, 1)
    blocks::Int = 0
    scenarios::Int = 0
    stages::Int = 0
    skip_hourly_goto::Bool = true
    stage_type::Union{Nothing, StageType} = nothing
end

function ReaderMapper(
    ::Type{T},
    first_date::Dates.Date;
    stage_type = nothing
) where T <: AbstractReader
    out = ReaderMapper{T}()
    out.first_date = first_date
    out.stage_type = stage_type
    return out
end

function add_reader!(
    mapper::ReaderMapper{T},
    path::String,
    header::Vector{String},
    filter::Vector{String} = String[];
    default::Bool = true,
    name = "",
) where T

    if !isempty(name) && haskey(mapper.name, name)
        error("Name $name is already taken.")
    end

    graf = open(
        T,
        path,
        header = header,
        first_stage = mapper.first_date
    )

    push!(mapper.list, graf)

    current = length(mapper.list)

    if default
        if mapper.skip_hourly_goto && is_hourly(graf)
            if isempty(filter)
                error("Hour maps do not move with default goto. Added map to hourly file with no filter, path = $path")
            end
        else
            push!(mapper.default, current)
        end
    end
    for key in filter
        if haskey(mapper.dict, key)
            push!(mapper.dict[key], current)
        else
            mapper.dict[key] = Int[current]
        end
    end

    if mapper.stage_type !== nothing && mapper.stage_type != stage_type(graf)
        println("Expected stage_type $(mapper.stage_type), got $(stage_type(graf))")
    end

    if mapper.stages > 0 && mapper.stages > max_stages(graf)
        println("Total stages $(mapper.stages) > file $(max_stages(graf))")
    end

    if mapper.blocks > 0 && graf.block_exist && mapper.blocks != max_blocks(graf)
        println("Total blocks $(mapper.blocks) != file $(max_blocks(graf))")
    end

    if mapper.scenarios > 0 &&graf.scenario_exist && mapper.scenarios != max_scenarios(graf)
        println("Total scenario $(mapper.scenarios) != file $(max_scenarios(graf))")
    end

    if !isempty(name)
        mapper.name[name] = Int(current)
    end

    return graf.data
end

function Base.getindex(mapper::ReaderMapper, name::String)
    return mapper.list[mapper.name[name]].data
end

function goto(mapper::ReaderMapper, t::Int, s::Int = 1, b::Int = 1)
    for i in mapper.default
        goto(mapper.list[i], t, s, b)
    end
    return nothing
end

function goto(mapper::ReaderMapper, key::String, t::Int, s::Int = 1, b::Int = 1)
    if haskey(mapper.dict, key)
        for ind in mapper.dict[key]
            goto(mapper.list[ind], t, s, b)
        end
    end
    if haskey(mapper.name, key)
        goto(mapper.list[mapper.name[key]], t, s, b)
    end
    return nothing
end

function close(mapper::ReaderMapper)
    for graf in mapper.list
        close(graf)
    end
    empty(mapper.list)
    empty(mapper.default)
    empty(mapper.dict)
    empty(mapper.name)
    return nothing
end