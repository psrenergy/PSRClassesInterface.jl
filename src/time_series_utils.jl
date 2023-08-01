function convert_file(
    ::Type{R},
    ::Type{W},
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
        path_from;
        use_header = false,
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
        path_to;
        blocks = blocks,
        scenarios = scenarios,
        stages = stages,
        agents = agents,
        unit = data_unit(reader),
        is_hourly = is_hourly(reader),
        name_length = name_length,
        stage_type = stage_type(reader),
        initial_stage = initial_stage(reader),
        initial_year = initial_year(reader),
    )

    cache = zeros(Float64, n_agents)
    for t in 1:stages, s in 1:scenarios, b in 1:blocks_in_stage(reader, t)
        for agent in 1:n_agents
            cache[agent] = reader[agent]
        end
        write_registry(
            writer,
            cache,
            t,
            s,
            b,
        )
        next_registry(reader)
    end
    close(reader)
    close(writer)

    return nothing
end

function array_to_file(
    ::Type{T},
    path::String,
    data::Array{Float64, 4}; #[a,b,s,t]
    # mandatory
    agents::Vector{String} = String[],
    unit::Union{Nothing, String} = nothing,
    # optional
    is_hourly::Bool = false,
    name_length::Integer = 24,
    block_type::Integer = 1,
    scenarios_type::Integer = 1,
    stage_type::StageType = STAGE_MONTH, # important for header
    initial_stage::Integer = 1, #month or week
    initial_year::Integer = 1900,
    # addtional
    allow_unsafe_name_length::Bool = false,
    kwargs...,
) where {T <: AbstractWriter}
    (nagents, blocks, scenarios, stages) = size(data)
    if isempty(agents)
        agents = String["$i" for i in 1:nagents]
    end
    if length(agents) != nagents
        error(
            "agents names for header do not mathc with the first dimentsion of data vector",
        )
    end
    writer = open(
        T,
        path;
        # mandatory
        blocks = blocks,
        scenarios = scenarios,
        stages = stages,
        agents = agents,
        unit = unit,
        # optional
        is_hourly = is_hourly,
        name_length = name_length,
        block_type = block_type,
        scenarios_type = scenarios_type,
        stage_type = stage_type,
        initial_stage = initial_stage, #month or week
        initial_year = initial_year,
        # addtional
        allow_unsafe_name_length = allow_unsafe_name_length,
        kwargs...,
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
            b,
        )
    end

    close(writer)

    return nothing
end

function file_to_array(
    ::Type{T},
    path::String;
    use_header::Bool = true,
    header::Vector{String} = String[],
) where {T <: AbstractReader}
    return file_to_array_and_header(T, path; use_header = use_header, header = header)[1]
end

function file_to_array_and_header(
    ::Type{T},
    path::String;
    use_header::Bool = true,
    header::Vector{String} = String[],
) where {T <: AbstractReader}
    io = open(
        T,
        path;
        use_header = use_header,
        header = header,
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

function is_equal(
    ior1::T1,
    ior2::T2;
    atol::Real = 1e-5,
    rtol::Real = 1e-4,
) where {T1 <: AbstractReader, T2 <: AbstractReader}
    str = ""
    # Assert have the same stage_type and is_hourly
    str *=
        is_hourly(ior1) == is_hourly(ior2) ? "" :
        "is_hourly assertion error, file 1: $(is_hourly(ior1)), file 2: $(is_hourly(ior2))\n"

    str *=
        stage_type(ior1) == stage_type(ior2) ? "" :
        "stage_type assertion error, file 1: $(stage_type(ior1)), file 2: $(stage_type(ior2))\n"

    # Assert same initial_year and initial_stage
    str *=
        initial_stage(ior1) == initial_stage(ior2) ? "" :
        "initial_stage assertion error, file 1: $(initial_stage(ior1)), file 2: $(initial_stage(ior2))\n"
    str *=
        initial_year(ior1) == initial_year(ior2) ? "" :
        "initial_year assertion error, file 1: $(initial_year(ior1)), file 2: $(initial_year(ior2))\n"

    # Assert same unit
    str *=
        data_unit(ior1) == data_unit(ior2) ? "" :
        "data_unit assertion error, file 1: $(data_unit(ior1)), file 2: $(data_unit(ior2))\n"

    # Assert dimensions
    str *=
        max_stages(ior1) == max_stages(ior2) ? "" :
        "max_stages assertion error, file 1: $(max_stages(ior1)), file 2: $(max_stages(ior2))\n"
    str *=
        max_scenarios(ior1) == max_scenarios(ior2) ? "" :
        "max_scenarios assertion error, file 1: $(max_scenarios(ior1)), file 2: $(max_scenarios(ior2))\n"
    str *=
        max_blocks(ior1) == max_blocks(ior2) ? "" :
        "max_blocks assertion error, file 1: $(max_blocks(ior1)), file 2: $(max_blocks(ior2))\n"

    # Assert the agents are the same in both files
    str *=
        agent_names(ior1) == agent_names(ior2) ? "" :
        "agent_names assertion error, file 1: $(agent_names(ior1)), file 2: $(agent_names(ior2))\n"

    !isempty(str) && error("The files are not equal:\n" * str)

    for est in 1:max_stages(ior1), scen in 1:max_scenarios(ior1),
        blk in 1:max_blocks_current(ior1)

        if ior1[:] != ior2[:]
            error("Different values on stage $est, scenario: $scen, block: $blk")
        end
        next_registry(ior1)
        next_registry(ior2)
    end

    return true
end
