Base.@kwdef mutable struct Writer <: PSRI.AbstractWriter

    io::IOStream

    stage_total::Int
    scenario_total::Int
    # scenario_exist::Bool
    block_total::Int # max in hours
    # block_total_current::Int # for hourly cases
    # block_exist::Bool
    blocks_per_stage::Vector{Int}
    blocks_until_stage::Vector{Int}
    is_hourly::Bool

    # _block_type::Int

    # first_year::Int
    initial_stage::Int
    # first_relative_stage::Int
    stage_type::PSRI.StageType

    # name_length::Int
    agents_total::Int
    # agent_names::Vector{String}
    # unit::String

    # data_buffer::Vector{Float32}

    # index::Vector{Int} # header ordering
    # data::Vector{Float64} # float cache

    stage_current::Int = 0
    scenario_current::Int = 0
    block_current::Int = 0 # or hour

    is_open::Bool
    reopen_mode::Bool
    FILE_PATH::String

    # relative_stage_skip::Int

end

function PSRI.open(
    ::Type{Writer},
    path::String;
    # mandatory
    blocks::Integer = 0,
    scenarios::Integer = 0,
    stages::Integer = 0,
    agents::Vector{String} = String[],
    unit::Union{Nothing, String} = nothing,
    # optional
    is_hourly::Bool = false,
    name_length::Integer = 24,
    block_type::Integer = 1,
    scenarios_type::Integer = 1,
    stage_type::PSRI.StageType = PSRI.STAGE_MONTH, # important for header
    initial_stage::Integer = 1, #month or week
    initial_year::Integer = 1900,
    sequential_model::Bool = false,
    # addtional
    allow_unsafe_name_length::Bool = false,
    # pre_ext::String = "", for part-bin
    reopen_mode::Bool = false,
    verbose_hour_block_check::Bool = true,
    single_binary::Bool = false
)

    if !allow_unsafe_name_length
        if name_length != 24 && name_length != 12
            error("name_length should be either 24 or 11. " *
                "To use a different value at your own risk enable: " *
                "allow_unsafe_name_length = true.")
        end
    end
    if !(0 <= block_type <= 3)
        error("block_type must be between 0 and 3, got $block_type")
    end
    if block_type == 0 && blocks != 1
        error("block_type = 0, requires blocks = 1, got blocks = $blocks")
    end
    if !(0 <= scenarios_type <= 1)
        error("scenarios_type must be between 0 and 1, got $scenarios_type")
    end
    if scenarios_type == 0 && scenarios != 1
        error("scenarios_type = 0, requires scenarios = 1, got scenarios = $scenarios")
    end
    if unit === nothing
        error("Please provide a unit string: unit = \"MW\"")
    end
    if !(0 < initial_stage <= PSRI.STAGES_IN_YEAR[stage_type])
        error("initial_stage must be between 1 and $(PSRI.STAGES_IN_YEAR[stage_type]) for $stage_type files, got: $initial_stage")
    end
    if !(0 < initial_year <= 1_000_000_000)
        error("initial_year must be a positive integer, got: $initial_year")
    end
    if is_hourly
        if block_type == 0
            error("Hourly files cannot have block_type == 0")
        end
        if 0 < blocks && verbose_hour_block_check
            println("Hourly files will ignore block dimension")
        end
    else
        if !(0 < blocks < 1_000_000)
            error("blocks must be a positive integer, got: $blocks")
        end
    end
    if !(0 < scenarios < 1_000_000_000)
        error("scenarios must be a positive integer, got: $scenarios")
    end
    if !(0 < stages < 1_000_000_000)
        error("stages must be a positive integer, got: $stages")
    end
    if isempty(agents)
        error("empty agents vector")
    else
        for ag in agents
            if length(ag) > name_length
                error("Agent name $ag is larger than name_length = $name_length")
            end
        end
    end
    if !allunique(agents)
        error("agents must be unique.")
    end

    dir = dirname(path)
    if !isdir(dir)
        error("Directory $dir does not exist.")
    end

    if !isempty(splitext(path)[2])
        error("file path must be provided with no extension")
    end

    if single_binary
        PATH_BIN = path * ".bin"
        PSRI._delete_or_error(PATH_BIN)
        ioh = open(PATH_BIN, "w")
    else
        PATH_HDR = path * ".hdr"
        PSRI._delete_or_error(PATH_HDR)
        PATH_BIN = path * ".bin"
        PSRI._delete_or_error(PATH_BIN)
        ioh = open(PATH_HDR, "w")
    end

    write(ioh, Int32(0))
    write(ioh, Int32(2)) # version
    write(ioh, Int32(0))
    write(ioh, Int32(0))
    first_relative_stage = 1 # TODO
    write(ioh, Int32(first_relative_stage)) # relative stage
    write(ioh, Int32(stages))
    write(ioh, Int32(scenarios))
    write(ioh, Int32(length(agents)))
    write(ioh, Int32(scenarios_type))
    write(ioh, Int32(block_type))
    write(ioh, Int32(is_hourly ? 1 : 0))
    # const PSR_STAGETYPE_UNKNOWN = 0
    # const PSR_STAGETYPE_WEEKLY = 1
    # const PSR_STAGETYPE_MONTHLY = 2
    # const PSR_STAGETYPE_QUARTERLY = 3
    # const PSR_STAGETYPE_HOURLY = 4
    # const PSR_STAGETYPE_DAILY = 5
    # const PSR_STAGETYPE_13MONTHLY = 6
    # const PSR_STAGETYPE_BIMONTHLY = 7
    # const PSR_STAGETYPE_TRIANNUALLY = 8
    # const PSR_STAGETYPE_SEMIANNUALLY = 9
    # const PSR_STAGETYPE_YEARLY = 10
    write(ioh, Int32(stage_type))
    write(ioh, Int32(initial_stage))
    write(ioh, Int32(initial_year))
    if unit === nothing
        for i in 1:7
            write(ioh, Char(0))
        end
    else
        len = length(unit)
        if len > 7
            error("unit")
        end
        for i in 1:7
            if i <= len
                write(ioh, unit[i])
            else
                write(ioh, ' ')
            end
        end
    end
    write(ioh, Int32(name_length))

    blocks_per_stage = Int[]
    blocks_until_stage = Int[]
    if !is_hourly
        write(ioh, Int32(0))
        write(ioh, Int32(0))
        write(ioh, Int32(0)) #offset1
        write(ioh, Int32(blocks)) #offset2 -> block_total = offset2 - offset1
        for i in first_relative_stage:stages-1
            write(ioh, Int32(0))
        end
    else
        write(ioh, Int32(0))
        write(ioh, Int32(0))
        # try start with 0 the other option sis star with current duration
        write(ioh, Int32(0))
        acc = Int32(0)
        blocks = 0
        for t in first_relative_stage:stages
            # TODO wirte hourly files
            b = PSRI.blocks_in_stage(is_hourly, stage_type, initial_stage, t)
            blocks = max(blocks, b)
            push!(blocks_until_stage, acc) # TODO check
            acc += Int32(b)
            write(ioh, Int32(acc))
            push!(blocks_per_stage, b)
        end
    end
    for ag in agents
        skip(ioh, 4)
        skip(ioh, 4)
        len = length(ag)
        for i in 1:name_length
            if i <= len
                write(ioh, ag[i])
            else
                write(ioh, ' ')
            end
        end
    end

    if single_binary
        io = ioh
    else
        close(ioh)
        io = open(PATH_BIN, "w")
        if reopen_mode
            close(io)
        end
    end

    return Writer(
        io = io,
        stage_total = stages,
        scenario_total = scenarios,
        block_total = blocks,
        blocks_per_stage = blocks_per_stage,
        blocks_until_stage = blocks_until_stage,
        is_hourly = is_hourly,
        initial_stage = initial_stage,
        stage_type = stage_type,
        agents_total = length(agents),
        reopen_mode = reopen_mode,
        FILE_PATH = PATH_BIN,
        is_open = !reopen_mode,
    )
end

PSRI.is_hourly(graf::Writer) = graf.is_hourly
PSRI.stage_type(graf::Writer) = graf.stage_type
PSRI.max_blocks(graf::Writer) = graf.block_total
PSRI.initial_stage(graf::Writer) = graf.initial_stage

function PSRI.write_registry(
    io::Writer,
    data::Vector{T},
    stage::Integer,
    scenario::Integer = 1,
    block::Integer = 1,
) where T <: Real

    _reopen_pre_write(io)

    if !io.is_open
        error("File is not in open state.")
    end

    if !(1 <= stage <= io.stage_total)
        error("stage should be between 1 and $(io.stage_total)")
    end
    if !(1 <= scenario <= io.scenario_total)
        error("scenarios should be between 1 and $(io.scenario_total)")
    end
    if !(1 <= block <= PSRI.blocks_in_stage(io, stage)) # io.blocks
        error("block should be between 1 and $(PSRI.blocks_in_stage(io, stage))")
    end
    if length(data) != io.agents_total
        error("data vector has length $(length(data)) and expected was $(io.agents_total)")
    end

    current = position(io.io)
    next = _get_position(io, stage, scenario, block)

    if current != next
        seek(io.io, next)
    end
    for i in eachindex(data)
        @inbounds write(io.io, Float32(data[i]))
    end

    _reopen_pos_write(io)

    return nothing
end

function _reopen_pre_write(io::Writer)
    if io.reopen_mode
        io.io = Base.open(io.FILE_PATH, "a")
        io.is_open = true
    end
    return nothing
end
function _reopen_pos_write(io::Writer)
    if io.reopen_mode
        Base.close(io.io)
        io.is_open = false
    end
    return nothing
end

function PSRI.close(io::Writer)
    io.is_open = false
    io.reopen_mode = false # so that it wont try to reopen
    seekend(io.io)
    current = position(io.io)
    last = _get_position(
        io,
        io.stage_total,
        io.scenario_total,
        io.is_hourly ? io.blocks_per_stage[end] : io.block_total
        ) + 4 * io.agents_total
    if current != last
        seek(io.io, last - 4 * io.agents_total)
        write(io.io, Float32(0))
        println("File not writen completely. Expected $(div(last, 4)) registries, got $(div(current, 4))")
    end

    Base.close(io.io)
    return nothing
end