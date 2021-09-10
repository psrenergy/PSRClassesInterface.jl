struct OpenCSV <: AbstractFileType end

mutable struct OpenCSVWriter <: AbstractWriter
    io::IOStream
    stages::Int
    scenarios::Int
    blocks::Int
    agents::Int
    isopen::Bool
    is_hourly::Bool
    path::String
    stage_type::StageType
    initial_stage::Int
    initial_year::Int
end

function _build_agents_str(agents::Vector{String})
    agents_str = ""
    for ag in agents
        agents_str *= ag * ','
    end
    agents_str = chop(agents_str; tail = 1)
    return agents_str
end

function write(
    ::OpenCSV,
    path::String;
    # mandatory
    blocks::Integer = 0,
    scenarios::Integer = 0,
    stages::Integer = 0,
    agents::Vector{String} = String[],
    unit::Union{Nothing, String} = nothing,
    # optional
    is_hourly::Bool = false,
    block_type::Integer = 1,
    scenarios_type::Integer = 1,
    stage_type::StageType = STAGE_MONTH, # important for header
    initial_stage::Integer = 1, #month or week
    initial_year::Integer = 1900,
    sequential_model::Bool = true,
)
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
    if stage_type == STAGE_MONTH
        if !(0 < initial_stage <= 12)
            error("initial_stage must be between 1 and 12 for monthly files, got: $initial_stage")
        end
    elseif stage_type == STAGE_WEEK
        if !(0 < initial_stage <= 52)
            error("initial_stage must be between 1 and 52 for monthly files, got: $initial_stage")
        end
    else
        error("Unknown stage_type")
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
    end

    dir = dirname(path)
    if !isdir(dir)
        error("Directory $dir does not exist.")
    end

    if !isempty(splitext(path)[2])
        error("file path must be provided with no extension")
    end

    # delete previous file or error if its open
    _delete_or_error(path)

    # Inicia gravacao do resultado
    FILE_PATH = normpath(path)

    # agents with name_length
    agents_with_name_length = _build_agents_str(agents)
    # save header
    io = open(FILE_PATH * ".csv", "w")
    Base.write(io, "Varies per block?       ,$block_type,Unit,$unit,$initial_stage,$initial_year\n")
    Base.write(io, "Varies per sequence?    ,$scenarios_type\n")
    Base.write(io, "# of agents             ,$(length(agents))\n")
    Base.write(io, "Stag,Seq.,Blck,$agents_with_name_length\n")
    
    return OpenCSVWriter(
        io,
        stages,
        scenarios,
        blocks,
        length(agents),
        true,
        is_hourly,
        path,
        stage_type,
        initial_stage,
        initial_year
    )
end

function write_registry(
    opencsvwriter::OpenCSVWriter,
    data::Vector{Float64},
    stage::Integer,
    scenario::Integer = 1,
    block::Integer = 1,
) where T

    if !opencsvwriter.isopen
        error("File is not in open state.")
    end

    if !(1 <= stage <= opencsvwriter.stages)
        error("stage should be between 1 and $(io.stages)")
    end
    if !(1 <= scenario <= opencsvwriter.scenarios)
        error("scenarios should be between 1 and $(opencsvwriter.scenarios)")
    end
    if !(1 <= block <= blocks_in_stage(opencsvwriter, stage))
        error("block should be between 1 and $(opencsvwriter.blocks)")
    end
    if length(data) != opencsvwriter.agents
        error("data vector has length $(length(data)) and expected was $(opencsvwriter.agents)")
    end
    str = ""
    str *= string(stage) * ','
    str *= string(scenario) * ','
    str *= string(block) * ','
    for d in data
        str *= string(d) * ','
    end
    str = chop(str; tail = 1) # remove last comma
    str *= '\n'
    Base.write(opencsvwriter.io, str)
    return nothing
end

function close(opencsvwriter::OpenCSVWriter)
    Base.close(opencsvwriter.io)
    opencsvwriter.isopen = false
    return nothing
end

mutable struct OpenCSVReader

    rows_iterator::CSV.Rows
    current_row::CSV.Row2
    current_row_state

    stages::Int
    scenarios::Int
    blocks::Int
    unit::String
    initial_stage::Int
    initial_year::Int

    current_stage::Int
    current_scenario::Int
    current_block::Int

    agent_names::Vector{String}
    num_agents::Int
    data::Vector{Float64}

    stage_type::StageType
    is_hourly::Bool
end

function _init_load(::OpenCSV, path::String)
    PATH_CSV = path
    if path[end-3:end] != ".csv"
        PATH_CSV *= ".csv"
    end
    if !isfile(PATH_CSV)
        error("file not found: $PATH_CSV")
    end
    return PATH_CSV
end

function _parse_unit(header)
    first_line_splitted = split(header[1], ',')
    return first_line_splitted[4]
end
function _parse_initial_stage(header)
    first_line_splitted = split(header[1], ',')
    return parse(Int, first_line_splitted[5])
end
function _parse_initial_year(header)
    first_line_splitted = split(header[1], ',')
    return parse(Int, first_line_splitted[6])
end
function _parse_stages(last_line)
    last_line_splitted = split(last_line, ',')
    return parse(Int, last_line_splitted[1])
end
function _parse_scenarios(last_line)
    last_line_splitted = split(last_line, ',')
    return parse(Int, last_line_splitted[2])
end
function _parse_blocks(last_line, stages::Int, is_hourly::Bool, stage_type::StageType, initial_stage::Int)
    if is_hourly
        if stage_type == STAGE_WEEK
            return 168
        elseif stage_type == STAGE_MONTH
            blocks = 0
            for t in initial_stage:initial_stage + stages
                blocks_month = DAYS_IN_MONTH[mod1(t - 1 + initial_stage, 12)] * 24
                if blocks_month > blocks
                    blocks = blocks_month
                end
            end
            return blocks
        else
            error("Unknown stage_type = $(io.stage_type)")
        end
    end
    last_line_splitted = split(last_line, ',')
    return parse(Int, last_line_splitted[3])
end
function _read_last_line(file)
    open(file) do io
        seekend(io)
        seek(io, position(io) - 2)
        while Char(peek(io)) != '\n'
            seek(io, position(io) - 1)
        end
        Base.read(io, Char)
        Base.read(io, String)
    end
end

function read(
    file_type::OpenCSV, 
    path::String;
    is_hourly::Bool = false,
    stage_type::StageType = STAGE_MONTH)

    PATH_CSV = _init_load(file_type, path)
    rows_iterator = CSV.Rows(PATH_CSV; header = 4)
    agent_names = string.(rows_iterator.names)[4:end]
    num_agents = length(agent_names)
    current_row, current_row_state = iterate(rows_iterator)

    data = Vector{Float64}(undef, num_agents)
    for i in 1:num_agents
        data[i] = parse(Float64, current_row[i+3])
    end

    header = readuntil(PATH_CSV, "Stag") |> x -> split(x, "\n")
    unit = _parse_unit(header)
    initial_stage = _parse_initial_stage(header)
    initial_year = _parse_initial_year(header)
    last_line = _read_last_line(PATH_CSV)
    stages = _parse_stages(last_line)
    scenarios = _parse_scenarios(last_line)
    blocks = _parse_blocks(last_line, stages, is_hourly, stage_type, initial_stage)

    io = OpenCSVReader(
        rows_iterator,
        current_row,
        (current_row_state),
        stages,
        scenarios,
        blocks,
        unit,
        initial_stage,
        initial_year,
        1,
        1,
        1,
        agent_names,
        num_agents,
        data,
        stage_type,
        is_hourly
    )

    return io
end

function Base.getindex(opencsvreader::OpenCSVReader, args...)
    return Base.getindex(opencsvreader.data, args...)
end

function next_registry(ocr::OpenCSVReader)
    next = iterate(ocr.rows_iterator, ocr.current_row_state)
    if next === nothing
        return nothing
    end
    ocr.current_row, ocr.current_row_state = next
    for i in 1:ocr.num_agents
        ocr.data[i] = parse(Float64, ocr.current_row[i+3])
    end
    ocr.current_stage = parse(Int64, ocr.current_row[1])
    ocr.current_scenario = parse(Int64, ocr.current_row[2])
    ocr.current_block = parse(Int64, ocr.current_row[3])
    return nothing
end

max_stages(opencsvreader::OpenCSVReader) = opencsvreader.stages
max_scenarios(opencsvreader::OpenCSVReader) = opencsvreader.scenarios
max_blocks(opencsvreader::OpenCSVReader) = opencsvreader.blocks
max_agents(opencsvreader::OpenCSVReader) = length(opencsvreader.agent_names)

initial_stage(opencsvreader::OpenCSVReader) = opencsvreader.initial_stage
initial_year(opencsvreader::OpenCSVReader) = opencsvreader.initial_year

data_unit(opencsvreader::OpenCSVReader) = opencsvreader.unit

current_stage(opencsvreader::OpenCSVReader) = opencsvreader.current_stage
current_scenario(opencsvreader::OpenCSVReader) = opencsvreader.current_scenario
current_block(opencsvreader::OpenCSVReader) = opencsvreader.current_block
stage_type(opencsvreader::OpenCSVReader) = opencsvreader.stage_type

function agent_names(opencsvreader::OpenCSVReader)
    return opencsvreader.agent_names
end

function close(opencsvreader::OpenCSVReader)
    return nothing
end