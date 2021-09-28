"""
    convert_file
"""
function convert_file(
    from::Type{R},
    to::Type{W},
    path_from::String;
    path_to::String = "",
) where {
    R <: AbstractReader,
    W <: AbstractWriter,
}

    if isempty(path_to)
        path_to = path_from
    end

    reader = open(
        R,
        path_from,
        use_header = false
    )

    # currently ignores block and scenarios type
    stages = max_stages(reader)
    scenarios = max_scenarios(reader)
    blocks = max_blocks(reader)
    agents = agent_names(reader)
    name_length = maximum(length.(agents))
    if name_length <= 12
        name_length = 12
    elseif name_length <= 24
        name_length = 24
    end
    n_agents = length(agents)

    writer = open(
        W,
        path_to,
        blocks = blocks,
        scenarios = scenarios,
        stages = stages,
        agents = agents,
        unit = data_unit(reader),
        # optional:
        is_hourly = is_hourly(reader),
        name_length = name_length,
        # block_type = 
        # scenarios_type = 
        stage_type = stage_type(reader),
        initial_stage = initial_stage(reader),
        initial_year = initial_year(reader),
    )

    cache = zeros(Float64, n_agents)
    for t = 1:stages
        for s = 1:scenarios
            for b = 1:blocks_in_stage(reader, t)
                # @test current_stage(ior) == estagio
                # @test current_scenario(ior) == serie
                # @test current_block(ior) == bloco

                for agent in 1:n_agents
                    cache[agent] = reader[agent]
                end
                write_registry(
                    writer,
                    cache,
                    t,
                    s,
                    b
                )
                next_registry(reader)
            end
        end
    end
    close(reader)
    close(writer)

    return nothing
end

"""
    array_to_file
"""
function array_to_file(
    ::Type{T},
    path::String,
    data::Array{Float64,4}; #[a,b,s,t]
    # mandatory
    agents::Vector{String} = String[],
    unit::Union{Nothing, String} = nothing,
    # optional
    # is_hourly::Bool = false,
    name_length::Integer = 24,
    block_type::Integer = 1,
    scenarios_type::Integer = 1,
    stage_type::StageType = STAGE_MONTH, # important for header
    initial_stage::Integer = 1, #month or week
    initial_year::Integer = 1900,
    # addtional
    allow_unsafe_name_length::Bool = false,
) where T <: AbstractWriter
    (nagents, blocks, scenarios, stages) = size(data)
    if isempty(agents)
        agents = String["$i" for i in 1:nagents]
    end
    if length(agents) != nagents
        error("agents names for header do not mathc with the first dimentsion of data vector")
    end
    writer = open(
        T,
        path,
        # mandatory
        blocks = blocks,
        scenarios = scenarios,
        stages = stages,
        agents = agents,
        unit = unit,
        # optional
        name_length = name_length,
        block_type = block_type,
        scenarios_type = scenarios_type,
        stage_type = stage_type,
        initial_stage = initial_stage, #month or week
        initial_year = initial_year,
        # addtional
        allow_unsafe_name_length = allow_unsafe_name_length,
    )

    cache = zeros(Float64, nagents)
    for t in 1:stages, s in 1:scenarios, b in 1:blocks
        for i in 1:nagents
            cache[i] = data[i, b, s, t]
        end
        write_registry(
            writer,
            cache,
            t,
            s,
            b
        )
    end

    close(writer)

    return nothing
end

"""
    file_to_array
"""
function file_to_array(
    ::Type{T},
    path::String,
) where T <: AbstractReader
    return file_to_array_and_header(T, path)[1]
end

"""
    file_to_array_and_header
"""
function file_to_array_and_header(
    ::Type{T},
    path::String,
) where T <: AbstractReader
    io = open(
        T,
        path,
        use_header = false,
    )
    stages = max_stages(io)
    scenarios = max_scenarios(io)
    blocks = max_blocks(io)
    agents = max_agents(io)
    out = zeros(agents, blocks, scenarios, stages)
    for t in 1:stages, s in 1:scenarios, b in 1:blocks
        if b > blocks_in_stage(io, t)
            # leave a zero for ignored hours
            continue
        end
        for a in 1:agents
            out[a, b, s, t] = io[a]
        end
        next_registry(io)
    end
    names = copy(agent_names(io)) # hold data after close
    close(io)
    return out, names
end