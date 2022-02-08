Base.@kwdef mutable struct Reader <: PSRI.AbstractReader

    io::IOStream

    hs::Int # Header Size

    stage_total::Int
    scenario_total::Int
    scenario_exist::Bool
    block_total::Int # max in hours
    block_total_current::Int # for hourly cases
    block_exist::Bool
    blocks_per_stage::Vector{Int}
    blocks_until_stage::Vector{Int}
    hours_exist::Bool

    _block_type::Int

    first_year::Int
    first_stage::Int
    first_relative_stage::Int
    stage_type::PSRI.StageType

    name_length::Int
    agents_total::Int
    agent_names::Vector{String}
    unit::String

    data_buffer::Vector{Float32}

    index::Vector{Int} # header ordering
    data::Vector{Float64} # float cache

    stage_current::Int = 0
    scenario_current::Int = 0
    block_current::Int = 0 # or hour

    is_open::Bool = true

    relative_stage_skip::Int

end
function Base.show(io::IO, ptr::Reader)
    println(io, "Reader:")
    println(io, "   Stages = $(ptr.stage_total)")
    println(io, "   Scenarios = $(ptr.scenario_total)")
    println(io, "   Max Blocks = $(ptr.block_total)")
    println(io, "   Is Hourly = $(ptr.hours_exist)")
    println(io, "   Agents = $(length(ptr.agent_names))")
    println(io, "   Unit = $(ptr.unit)")
    print(io, "   Data File = $(ptr.io.name)")
end

function PSRI.open(
    ::Type{Reader},
    path::String;
    is_hourly::Union{Bool, Nothing} = nothing, 
    stage_type::Union{PSRI.StageType, Nothing} = nothing,
    header::Vector{String} = String[],
    use_header::Bool = true,
    allow_empty::Bool = false,
    first_stage::Dates.Date = Dates.Date(1900, 1, 1),
    verbose_header = false,
)

    # TODO
    if !isnothing(is_hourly) || !isnothing(stage_type)
        error("is_hourly and stage_type are not supported by SingleBinary.")
    end


    PATH_BIN = path * ".bin"

    if !isfile(PATH_BIN)
        error("file not found: $PATH_BIN")
    end

    ioh = open(PATH_BIN, "r")

    hs = Int(read(ioh, Int32)) # Header Size

    skip(ioh, 4)

    version = read(ioh, Int32)

    if verbose_header
        @show version
    end

    @assert 1 <= version <= 9 "version = $version"

    if version == 1
        skip(ioh, 4)
        skip(ioh, 4)
        first_relative_stage = read(ioh, Int32)
        stage_total = read(ioh, Int32)
        scenario_total = read(ioh, Int32)
        block_total = read(ioh, Int32)
        total_agents = read(ioh, Int32)
        variable_by_series = read(ioh, Int32)
        variable_by_block = read(ioh, Int32)
        stage_type = read(ioh, Int32)
        _first_stage = read(ioh, Int32) #month or week
        first_year = read(ioh, Int32) # year
        #
        unit_buffer = Vector{Char}(undef, 7)
        read!(ioh, unit_buffer)
        unit_str = strip(join(unit_buffer))
        #
        name_length = read(ioh, Int32)

        
        variable_by_hour = 0
        number_blocks = Int32[]
    else
        skip(ioh, 4)
        skip(ioh, 4)
        first_relative_stage = read(ioh, Int32)
        stage_total = read(ioh, Int32)    # stages
        scenario_total = read(ioh, Int32) # scenarios
        total_agents = read(ioh, Int32)   # num_agents
        variable_by_series = read(ioh, Int32) # scenarios_type
        variable_by_block = read(ioh, Int32)  # block_type
        variable_by_hour = read(ioh, Int32)   # is_hourly
        stage_type = read(ioh, Int32)    
        _first_stage = read(ioh, Int32) # initial_stage (month or week)
        first_year = read(ioh, Int32)   # initial_year
        #
        unit_buffer = Vector{Int32}(undef, 7)
        read!(ioh, unit_buffer)
        unit_str = strip(join(Char.(unit_buffer)))

        name_length = read(ioh, Int32)

        if variable_by_hour == 0 # is_hourly
            skip(ioh, 4)
            skip(ioh, 4)
            offset1 = read(ioh, Int32)
            offset2 = read(ioh, Int32)
            block_total = offset2 - offset1
            skip(ioh, 4 * (stage_total - first_relative_stage))
            number_blocks = Int32[]
        elseif variable_by_hour == 1
            skip(ioh, 4)
            skip(ioh, 4)
            number_blocks = zeros(Int32, stage_total + 1 - first_relative_stage)
            offsets = zeros(Int32, 1 + stage_total + 1 - first_relative_stage)
            for i in first_relative_stage:stage_total+1
                offset = read(ioh, Int32)
                offsets[i-first_relative_stage+1] = offset
                if i > first_relative_stage
                    number_blocks[i-first_relative_stage] = offset - offsets[i-first_relative_stage]
                end
            end
            block_total = maximum(number_blocks)
            if verbose_header
                @show block_total, length(number_blocks), number_blocks
            end
        else
            error("variable_by_hour = $variable_by_hour is invalid")
        end
    end

    agent_names = String[]
    agent_name_buffer = Vector{Int32}(undef, name_length)
    for _ in 1:total_agents
        skip(ioh, 4)
        skip(ioh, 4)
        read!(ioh, agent_name_buffer)
        agente_name = strip(join(Char.(agent_name_buffer)))
        push!(agent_names, agente_name)
    end
    
    if verbose_header
        @show agent_names
    end

    close(ioh) # close BIN

    BAD = "Bad header: "

    @assert stage_total > 0
    @assert first_relative_stage == 1 # todo improve this
    @assert stage_total - first_relative_stage >= 0

    if !(0 <= variable_by_series <= 1)
        println(BAD * "variable_by_series = $variable_by_series, expected 0 or 1")
    end
    if variable_by_series == 0 && scenario_total > 1
        println(BAD * "variable_by_series == 0 but scenario_total = $scenario_total")
    end
    @assert scenario_total > 0
    scenario_exist = variable_by_series == 1

    if !(0 <= variable_by_block <= 3)
        println(BAD * "variable_by_block = $variable_by_block, expected 0, 1, 2 or 3")
    end
    if variable_by_block == 0 && block_total > 1
        println(BAD * "variable_by_block == 0 but block_total = $block_total")
    end

    @assert block_total > 0 "block_total = $block_total"

    block_exist = variable_by_block > 0

    if !(0 <= variable_by_hour <= 1)
        println(BAD * "variable_by_hour = $variable_by_hour, expected 0 or 1")
    end
    hours_exist = variable_by_hour == 1

    if total_agents == 0
        println("total_agents == 0, nothing to do")
        # todo
    end
    @assert name_length > 0

    _stage_type = if stage_type == 2#PSR_STAGETYPE_MONTHLY
        PSRI.STAGE_MONTH
    elseif stage_type == 1#PSR_STAGETYPE_WEEKLY
        PSRI.STAGE_WEEK
    elseif stage_type == 5#PSR_STAGETYPE_DAILY
        PSRI.STAGE_DAY
    else
        error("Stage type with code $stage_type is no known")
    end

    if use_header
        if length(header) > total_agents
            error("Header does not match with expected. Header length = $(length(header)), number ofo agents is $(total_agents)")
        end
        index = Int[]
        sizehint!(index, length(header))
        for agent in header
            _agent = strip(agent)
            ret = findfirst(x -> x == _agent, agent_names)
            if ret === nothing
                # println("agent $(_agent) not found in file")
                error("agent $(_agent) not found in file")
            end
            push!(index, ret)
        end
        if !allow_empty && isempty(index)
            error("no agents found" * ifelse(length(header) == 0, ", empty header inserted. If you do not want to pass a header use: use_header = false option.", "."))
        end
    else
        index = collect(1:total_agents)
    end


    data_buffer = zeros(Float32, total_agents)
    data = zeros(Float64, total_agents)

    if first_stage != Dates.Date(1900, 1, 1)
        _year = first_year
        _date = if _stage_type == PSRI.STAGE_MONTH
            @assert 1 <= _first_stage <= 12
            Dates.Date(_year, 1, 1) + Dates.Month(_first_stage-1)
        elseif _stage_type == PSRI.STAGE_WEEK
            @assert 1 <= _first_stage <= 52
            Dates.Date(_year, 1, 1) + Dates.Week(_first_stage-1)
        elseif _stage_type == PSRI.STAGE_DAY
            @assert 1 <= _first_stage <= 365
            ret = Dates.Date(_year, 1, 1) + Dates.Day(_first_stage-1)
            if Dates.isleapyear(_year) && _first_stage > 24 * (31 + 28)
                ret += Dates.Day(1)
            end
            ret
        else
            error("Stage Type $_stage_type not currently supported")
        end
        relative_first_stage = PSRI._stage_from_date(first_stage, _stage_type, _date)
        if relative_first_stage < 1
            error("first_stage = $first_stage is earlier than file initial stage = $_date")
        end
        relative_stage_skip = relative_first_stage - 1
    else
        relative_stage_skip = 0
    end

    ret = Reader(
        stage_total = Int(stage_total),
        scenario_total = Int(scenario_total),
        scenario_exist = scenario_exist,
        block_total = Int(block_total), # max in hours
        block_total_current = Int(0), # for hourly cases
        block_exist = block_exist,
        blocks_per_stage = number_blocks,
        blocks_until_stage = cumsum(vcat(Int[0], number_blocks)),
        hours_exist = hours_exist,

        _block_type = Int(variable_by_block),

        first_year = Int(first_year),
        first_stage = Int(_first_stage),
        first_relative_stage = Int(first_relative_stage),
        stage_type = _stage_type,

        agents_total = total_agents,
        name_length = Int(name_length),
        agent_names = agent_names,
        unit = unit_str,

        data_buffer = data_buffer,

        index = index, # header ordering
        data = data, # float cache

        relative_stage_skip = relative_stage_skip,

        io = open(PATH_BIN, "r"),
        hs = hs
    )

    finalizer(ret) do x
        if x.is_open
            Base.close(x.io)
        end
        x
    end

    # iob = open(PATH_BIN, "r")
    # check total len

    # check total file size
    last = _get_position(
        ret,
        stage_total,
        scenario_total,
        hours_exist ? number_blocks[end] : block_total
        ) + 4 * total_agents

    seekend(ret.io)

    @assert last == position(ret.io)

    # go back to begning and initialize
    seek(ret.io, ret.hs)

    PSRI.goto(ret, 1, 1, 1)

    return ret
end

function Base.getindex(graf::Reader, args...)
    Base.getindex(graf.data, args...)
end

PSRI.is_hourly(graf::Reader) = graf.hours_exist

PSRI.max_stages(graf::Reader) = graf.stage_total - graf.relative_stage_skip
PSRI.max_scenarios(graf::Reader) = graf.scenario_total
PSRI.max_blocks(graf::Reader) = graf.block_total
PSRI.max_blocks_current(graf::Reader) = graf.block_total_current
PSRI.max_blocks_stage(graf::Reader, t::Integer) = Int(graf.blocks_per_stage[t])
PSRI.max_agents(graf::Reader) = length(graf.index)

PSRI.stage_type(graf::Reader) = graf.stage_type
PSRI.initial_stage(graf::Reader) = graf.first_stage
PSRI.initial_year(graf::Reader) = graf.first_year

PSRI.data_unit(graf::Reader) = graf.unit

PSRI.current_stage(graf::Reader) = graf.stage_current
PSRI.current_scenario(graf::Reader) = graf.scenario_current
PSRI.current_block(graf::Reader) = graf.block_current

function PSRI.agent_names(graf::Reader)
    return graf.agent_names
end

function PSRI.goto(graf::Reader, t::Integer, s::Integer = 1, b::Integer = 1)
    @assert graf.is_open
    tt = t + graf.relative_stage_skip
    block_total_current = graf.block_total_current
    if t != graf.stage_current
        block_total_current = if graf.stage_type == PSRI.STAGE_MONTH
            PSRI.blocks_in_stage(graf, t)
        else
            graf.block_total
        end
    end
    # add option for non-auto cycle
    ss = ifelse(graf.scenario_exist, mod1(s, graf.scenario_total), 1)
    # add option for non-auto ignore
    bb = ifelse(graf.block_exist || graf.hours_exist, b, 1)
    if t != graf.stage_current ||
            ss != graf.scenario_current ||
            bb != graf.block_current
        @assert 1 <= tt <= graf.stage_total
        @assert 1 <= bb <= block_total_current
        # move to position
        current_pos = position(graf.io)
        next_pos = _get_position(graf, tt, ss, bb)
        if next_pos >= current_pos
            skip(graf.io, next_pos - current_pos)
        else
            seek(graf.io, next_pos)
        end
        graf.block_total_current = block_total_current
        graf.stage_current = t # this is different
        graf.scenario_current = ss
        graf.block_current = bb
        read!(graf.io, graf.data_buffer)
        for (index, value) in enumerate(graf.index)
            @inbounds graf.data[index] = graf.data_buffer[value]
        end
    end
    return nothing
end

function PSRI.next_registry(graf::Reader)
    if graf.stage_current == graf.stage_total &&
        graf.scenario_current == graf.scenario_total &&
        graf.block_current == graf.block_total
        seek(graf.io, graf.hs)
    end

    read!(graf.io, graf.data_buffer)
    for (index, value) in enumerate(graf.index)
        @inbounds graf.data[index] = graf.data_buffer[value]
    end

    @assert graf.block_current >= 1

    if graf.block_current < graf.block_total_current
        graf.block_current += 1
    else
        graf.block_current = 1
        @assert graf.scenario_current >= 1
        if graf.scenario_current < graf.scenario_total
            graf.scenario_current += 1
        else
            graf.scenario_current = 1
            @assert graf.stage_current >= 1
            if graf.stage_current < graf.stage_total
                graf.stage_current += 1
                if graf.hours_exist
                    graf.block_total_current = PSRI.blocks_in_stage(graf, graf.stage_current)
                end
            else
                graf.stage_current = 1
                #cycle back
            end
        end
    end
    
    return nothing
end

function PSRI.close(io::Reader)
    Base.close(io.io)
    io.is_open = false
    empty!(io.data)
    empty!(io.data_buffer)
    empty!(io.agent_names)
    io.stage_current = 0
    io.scenario_current = 0 
    io.block_current = 0
    return nothing
end
