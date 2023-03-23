Base.@kwdef mutable struct Reader <: PSRI.AbstractReader
    io::IOStream

    stage_total::Int
    scenario_total::Int
    scenario_exist::Bool
    block_total::Int # max in hours
    block_total_current::Int # for hourly cases
    block_exist::Bool
    blocks_per_stage::Vector{Int}
    blocks_until_stage::Vector{Int}
    hours_exist::Bool
    hour_discretization::Int

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
    offset::Int = 0 # Header size

    single_binary::Bool = false
end

function Base.show(io::IO, ptr::Reader)
    return println(
        io,
        """
        Reader:
           Stages = $(ptr.stage_total)
           Scenarios = $(ptr.scenario_total)
           Max Blocks = $(ptr.block_total)
           Is Hourly = $(ptr.hours_exist)
           Hour Discretization = $(ptr.hour_discretization)
           Agents = $(length(ptr.agent_names))
           Unit = $(ptr.unit)
           Data File = $(ptr.io.name)
        """
    )
end

function PSRI.open(
    ::Type{Reader},
    path::String;
    is_hourly::Union{Bool,Nothing} = nothing,
    stage_type::Union{PSRI.StageType,Nothing} = nothing,
    header::Vector{String} = String[],
    use_header::Bool = true,
    allow_empty::Bool = false,
    first_stage::Dates.Date = Dates.Date(1900, 1, 1),
    verbose_header::Bool = false,
    single_binary::Bool = false,
)
    # TODO: support 'is_hourly' and 'stage_type'
    if !isnothing(is_hourly) || !isnothing(stage_type)
        error("'is_hourly' and 'stage_type' are not supported by 'OpenBinary' yet")
    end

    header_size = 0

    if single_binary
        bin_path = "$(path).dat"

        if !isfile(bin_path)
            error("File not found: $(bin_path)")
        end

        ioh = open(bin_path, "r")
    else
        hdr_path = "$(path).hdr"
        bin_path = "$(path).bin"

        if !isfile(bin_path)
            error("File not found: $(bin_path)")
        end
        
        if !isfile(hdr_path)
            error("File not found: $(hdr_path)")
        end
        
        ioh = open(hdr_path, "r")
    end

    skip(ioh, 4)

    version = read(ioh, Int32)

    if verbose_header
        @show(version)
    end

    @assert 1 <= version <= 9

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
        stage_type = PSRI.StageType(read(ioh, Int32))
        _first_stage = read(ioh, Int32) #month or week
        first_year = read(ioh, Int32) # year
        #
        unit_buffer = Vector{Cchar}(undef, 7)
        read!(ioh, unit_buffer)
        unit_str = strip(join(unit_buffer))
        #
        name_length = read(ioh, Int32)

        ##
        variable_by_hour = 0
        number_blocks = Int32[]
    else
        skip(ioh, 4)
        skip(ioh, 4)

        first_relative_stage = read(ioh, Int32)
        stage_total = read(ioh, Int32)
        scenario_total = read(ioh, Int32)
        total_agents = read(ioh, Int32)
        variable_by_series = read(ioh, Int32)
        variable_by_block = read(ioh, Int32)
        variable_by_hour = read(ioh, Int32)
        stage_type = PSRI.StageType(read(ioh, Int32))
        _first_stage = read(ioh, Int32) #month or week
        first_year = read(ioh, Int32) # year
        #
        unit_buffer = Vector{Cchar}(undef, 7)
        read!(ioh, unit_buffer)
        unit_str = strip(join(Char.(unit_buffer)))
        #
        name_length = read(ioh, Int32)

        hour_discretization = 1

        if variable_by_hour == 0
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
            
            for i in first_relative_stage:(stage_total+1)
                let offset = read(ioh, Int32)
                    offsets[i-first_relative_stage+1] = offset
                    
                    if i > first_relative_stage
                        number_blocks[i-first_relative_stage] = offset - offsets[i-first_relative_stage]
                    end
                end
            end
            
            block_total = maximum(number_blocks)

            hour_discretization = _get_hour_discretization(stage_type, block_total)

            if verbose_header
                @show(block_total, length(number_blocks), number_blocks)
            end
        else
            error("'variable_by_hour' must be either '0' or '1', not '$(variable_by_hour)'")
        end
    end

    agent_names = String[]
    agent_name_buffer = Vector{Cchar}(undef, name_length)

    for _ in 1:total_agents
        skip(ioh, 4)
        skip(ioh, 4)

        read!(ioh, agent_name_buffer)
        agent_name = strip(join(Char.(agent_name_buffer)))
        push!(agent_names, agent_name)
    end
    if verbose_header
        @show(agent_names)
    end

    if single_binary
        # nothing
    else
        close(ioh)
    end

    BAD = "Bad header: "

    @assert stage_total > 0
    @assert first_relative_stage == 1 # todo improve this
    @assert stage_total - first_relative_stage >= 0

    if variable_by_series == 0
        # previous versions of the file simply leave the number of scenarios
        # as the number of scenarios in the study
        scenario_total = 1
    end
    if !(0 <= variable_by_series <= 1)
        println(BAD * "variable_by_series = $variable_by_series, expected 0 or 1")
    end
    @assert scenario_total > 0
    scenario_exist = variable_by_series == 1

    if !(0 <= variable_by_block <= 3)
        println(BAD * "variable_by_block = $variable_by_block, expected 0, 1, 2 or 3")
    end
    if variable_by_block == 0 && block_total > 1
        println(BAD * "variable_by_block == 0 but block_total = $block_total")
    end
    @assert block_total > 0
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
        _date = if stage_type == PSRI.STAGE_MONTH
            @assert 1 <= _first_stage <= 12
            Dates.Date(_year, 1, 1) + Dates.Month(_first_stage-1)
        elseif stage_type == PSRI.STAGE_WEEK
            @assert 1 <= _first_stage <= 52
            Dates.Date(_year, 1, 1) + Dates.Week(_first_stage-1)
        elseif stage_type == PSRI.STAGE_DAY
            @assert 1 <= _first_stage <= 365
            ret = Dates.Date(_year, 1, 1) + Dates.Day(_first_stage-1)
            if Dates.isleapyear(_year) && _first_stage > 24 * (31 + 28)
                ret += Dates.Day(1)
            end
            ret
        else
            error("stage Type $stage_type not currently supported")
        end
        relative_first_stage = PSRI._stage_from_date(first_stage, stage_type, _date)
        if relative_first_stage < 1
            error("first_stage = $first_stage is earlier than file initial stage = $_date")
        end
        relative_stage_skip = relative_first_stage - 1
    else
        relative_stage_skip = 0
    end

    if single_binary
        skip(ioh, 4)
        io = ioh
        header_size = position(io)
    else
        io = open(bin_path, "r")
    end

    ret = Reader(;
        stage_total = Int(stage_total),
        scenario_total = Int(scenario_total),
        scenario_exist = scenario_exist,
        block_total = Int(block_total), # max in hours
        block_total_current = Int(0), # for hourly cases
        block_exist = block_exist,
        blocks_per_stage = number_blocks,
        blocks_until_stage = cumsum(vcat(Int[0], number_blocks)),
        hours_exist = hours_exist,
        hour_discretization = hour_discretization,
        _block_type = Int(variable_by_block),
        first_year = Int(first_year),
        first_stage = Int(_first_stage),
        first_relative_stage = Int(first_relative_stage),
        stage_type = stage_type,
        agents_total = total_agents,
        name_length = Int(name_length),
        agent_names = agent_names,
        unit = unit_str,
        data_buffer = data_buffer,
        index = index, # header ordering
        data = data, # float cache
        relative_stage_skip = relative_stage_skip,
        io = io,
        offset = header_size,
        single_binary = single_binary,
    )

    finalizer(ret) do ptr
        if ptr.is_open
            Base.close(ptr.io)
        end

        return ptr
    end

    # check total file size
    _check_bin_size(ret)

    # Go back to the beginning and initialize
    # i.e. sync file and reader cursors
    seek(ret.io, ret.offset)
    PSRI.goto(ret, 1, 1, 1)

    return ret
end

function Base.getindex(graf::Reader, args...)
    Base.getindex(graf.data, args...)
end

PSRI.is_hourly(graf::Reader) = graf.hours_exist
PSRI.hour_discretization(graf::Reader) = graf.hour_discretization

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

function unsafe_agent_names(graf::Reader)
    return graf.agent_names
end
function PSRI.agent_names(graf::Reader)
    return deepcopy(unsafe_agent_names(graf))
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

function _get_position(graf, t::Integer, s::Integer, b::Integer)
    if PSRI.is_hourly(graf)
        # hours in weekly = 52 * 168 = 8736
        # hours in monthly = 8760
        pos = 4 * (
            graf.blocks_until_stage[t] * graf.agents_total * graf.scenario_total +
            (s - 1) * graf.agents_total * graf.blocks_per_stage[t] +
            (b - 1) * graf.agents_total)
        return pos + graf.offset
    else
        pos = 4 * (
            (t - 1) * graf.agents_total * graf.block_total * graf.scenario_total +
            (s - 1) * graf.agents_total * graf.block_total +
            (b - 1) * graf.agents_total)
        return pos + graf.offset
    end
end

function _get_hour_discretization(stage_type::PSRI.StageType, block_total::Integer)
    hour_total = if stage_type == PSRI.STAGE_WEEK
        168
    elseif stage_type == PSRI.STAGE_MONTH
        if block_total % 672 == 0
            672
        elseif block_total % 720 == 0
            720
        else
            744
        end
    elseif stage_type == PSRI.STAGE_DAY
        24
    elseif stage_type == PSRI.STAGE_YEAR
        8760
    else
        error("Stage type $(stage_type) is not currently supported")
    end

    return floor(Int, block_total / hour_total)
end

function _get_expected_bin_size(ptr::Reader)
    t = ptr.stage_total
    s = ptr.scenario_total
    b = ptr.hours_exist ? ptr.blocks_per_stage[end] : ptr.block_total
    a = ptr.agents_total

    if ptr.single_binary
        return _get_position(ptr, t, s, b) + 4a 
    else
        return _get_position(ptr, t, s, b) + 4a - ptr.offset
    end
end

function _get_bin_size(ptr::Reader)
    p = position(ptr.io)
    seekend(ptr.io)
    q = position(ptr.io)
    seek(ptr.io, p)

    if ptr.single_binary
        return q
    else
        return q - ptr.offset
    end
end

function _check_bin_size(ptr::Reader)
    size_delta = _get_expected_bin_size(ptr) - _get_bin_size(ptr)

    if size_delta > 0
        error("File is truncated by $(size_delta) bytes")
    elseif size_delta < 0
        @warn "File has $(size_delta) extra bytes"
    end

    return nothing
end

function PSRI.next_registry(graf::Reader)
    if graf.stage_current == graf.stage_total &&
        graf.scenario_current == graf.scenario_total &&
        graf.block_current == graf.block_total
        seek(graf.io, graf.offset)
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
