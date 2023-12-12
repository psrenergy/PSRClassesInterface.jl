function _raw_stage_duration(data::Data, date::Dates.Date)::Int
    if data.stage_type == PSRI.STAGE_WEEK
        return 168.0
    elseif data.stage_type == PSRI.STAGE_DAY
        return 24.0
    end
    return PSRI.DAYS_IN_MONTH[Dates.month(date)] * 24.0
end

function _raw_stage_duration(data::Data, t::Int)::Int
    if data.stage_type == PSRI.STAGE_WEEK
        return 168.0
    elseif data.stage_type == PSRI.STAGE_DAY
        return 24.0
    end
    return PSRI.DAYS_IN_MONTH[Dates.month(
        PSRI._date_from_stage(t, data.stage_type, data.first_date))] * 24.0
end

function PSRI.stage_duration(data::Data, date::Dates.Date)
    if data.duration_mode != PSRI.VARIABLE_DURATION
        return _raw_stage_duration(data, date)
    end
    t = PSRI._stage_from_date(date, data.stage_type, data.first_date)
    return _variable_stage_duration(data, t)
end

function PSRI.stage_duration(data::Data, t::Int = data.controller_stage)
    if data.duration_mode != PSRI.VARIABLE_DURATION
        return _raw_stage_duration(data, t)
    end
    return _variable_stage_duration(data, t)
end

function PSRI.block_duration(data::Data, date::Dates.Date, b::Int)
    if !(1 <= b <= data.number_blocks)
        error(
            "Blocks is expected to be larger than 1 and smaller than the number of blocks in the study $(data.number_blocks)",
        )
    end
    if data.duration_mode == PSRI.FIXED_DURATION
        raw = _raw(data)
        percent = raw["PSRStudy"][1]["Duracao($b)"] / 100.0
        return percent * _raw_stage_duration(data, date)
    end# elseif data.duration_mode == PSRI.VARIABLE_DURATION # OR PSRI.HOUR_BLOCK_MAP
    t = PSRI._stage_from_date(date, data.stage_type, data.first_date)
    return _variable_stage_duration(data, t, b)
end

function PSRI.block_duration(data::Data, b::Int)
    return PSRI.block_duration(data, data.controller_stage, b)
end

function PSRI.block_duration(data::Data, t::Int, b::Int)
    if !(1 <= b <= data.number_blocks)
        error(
            "Blocks is expected to be larger than 1 and smaller than the number of blocks in the study $(data.number_blocks)",
        )
    end
    if data.duration_mode == PSRI.FIXED_DURATION
        raw = _raw(data)
        percent = raw["PSRStudy"][1]["Duracao($b)"] / 100.0
        return percent * _raw_stage_duration(data, t)
    end# elseif data.duration_mode == PSRI.VARIABLE_DURATION # OR PSRI.HOUR_BLOCK_MAP
    return _variable_stage_duration(data, t, b)
end

function PSRI.block_from_stage_hour(data::Data, t::Int, h::Int)
    if data.duration_mode != PSRI.HOUR_BLOCK_MAP
        error("Cannot query block from study with duration mode: $(data.duration_mode)")
    end
    PSRI.goto(data.hour_to_block, t, 1, h)
    return data.hour_to_block[]
end

function PSRI.block_from_stage_hour(data::Data, date::Dates.Date, h::Int)
    t = PSRI._stage_from_date(date, data.stage_type, data.first_date)
    return PSRI.block_from_stage_hour(data, t, h)
end

#=
    Fixed Duration
=#

#=
    Variable Duration
=#

function _variable_stage_duration(data::Data, t::Int)
    val = 0.0
    PSRI.goto(data.variable_duration, t)
    for b in 1:data.number_blocks
        val += data.variable_duration[b]
    end
    return val
end

function _variable_stage_duration(data::Data, t::Int, b::Int)
    val = 0.0
    PSRI.goto(data.variable_duration, t)
    return data.variable_duration[b]
end

function _variable_duration_to_file!(data::Data)
    dur_model = _raw(data)["PSRStudy"][1]["DurationModel"]
    # dur_model["modeldimensions"][1]["value"] # max block sim
    dates = dur_model["Data"]
    duration = [dur_model["Duracao($b)"] for b in 1:data.number_blocks]

    FILE_NAME = tempname(data.data_path) * string("_", time_ns(), "_psr_temp")

    STAGES = length(dates)

    _year, _stage = PSRI._year_stage(_simple_date(dates[1]), data.stage_type)

    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        FILE_NAME;
        blocks = 1,
        scenarios = 1,
        stages = STAGES,
        agents = ["$b" for b in 1:data.number_blocks],
        unit = "h",
        # optional:
        initial_stage = _stage,
        initial_year = _year,
        stage_type = data.stage_type,
    )
    # TODO check handle time in negative stages

    cache = zeros(data.number_blocks)

    first_date = _findfirst_date(_date_from_stage(data, 1), dates)

    for t in 1:STAGES
        for b in 1:data.number_blocks
            cache[b] = duration[b][t]
        end
        PSRI.write_registry(iow, cache, t, 1, 1)
    end

    PSRI.close(iow)

    ior = PSRI.open(
        PSRI.OpenBinary.Reader,
        FILE_NAME;
        use_header = false,
        initial_stage = data.first_date,
    )

    data.variable_duration = ior

    return
end

#=
    Hour Block Map
=#

# TODO: handle profile mode
function _hour_block_map_to_file!(data::Data)
    study = _raw(data)["PSRStudy"][1]
    dates = study["DataHourBlock"]
    hbmap = study["HourBlockMap"]

    FILE_NAME_DUR = tempname(data.data_path) * string("_", time_ns(), "_psr_temp")
    FILE_NAME_HBM = tempname(data.data_path) * string("_", time_ns(), "_psr_temp")

    _first = _simple_date(dates[1])
    _last = _simple_date(dates[end])

    STAGES = PSRI._stage_from_date(_last, data.stage_type, _first)

    _year, _stage = PSRI._year_stage(_first, data.stage_type)

    io_dur = PSRI.open(
        PSRI.OpenBinary.Writer,
        FILE_NAME_DUR;
        blocks = 1,
        scenarios = 1,
        stages = STAGES,
        agents = ["$b" for b in 1:data.number_blocks],
        unit = "h",
        # optional:
        initial_stage = _stage,
        initial_year = _year,
        stage_type = data.stage_type,
    )
    # TODO check handle time in negative stages
    io_hbm = PSRI.open(
        PSRI.OpenBinary.Writer,
        FILE_NAME_HBM;
        # blocks = 1,
        is_hourly = true,
        scenarios = 1,
        stages = STAGES,
        agents = ["block"],
        unit = "idx",
        # optional:
        initial_stage = _stage,
        initial_year = _year,
        stage_type = data.stage_type,
    )

    cache = zeros(data.number_blocks)
    cache_hbm = zeros(1)

    hour = 0
    last_str = ""
    current_str = ""

    first_date = _findfirst_date(_date_from_stage(data, 1), dates)

    for t in 1:STAGES
        fill!(cache, 0.0)
        for b in 1:PSRI.blocks_in_stage(io_hbm, t)
            hour += 1
            current_str = dates[hour]
            if b == 1
                @assert current_str != last_str
            else
                @assert current_str == last_str
            end
            last_str = current_str
            cache_hbm[] = hbmap[hour]
            @assert 1 <= cache_hbm[] <= data.number_blocks
            PSRI.write_registry(io_hbm, cache_hbm, t, 1, b)
            cache[Int(cache_hbm[])] += 1
        end
        for b in 1:data.number_blocks
            @assert cache[b] > 0
        end
        PSRI.write_registry(io_dur, cache, t, 1, 1)
    end

    PSRI.close(io_dur)
    PSRI.close(io_hbm)

    ior_dur = PSRI.open(
        PSRI.OpenBinary.Reader,
        FILE_NAME_DUR;
        use_header = false,
        initial_stage = data.first_date,
    )
    ior_hbm = PSRI.open(
        PSRI.OpenBinary.Reader,
        FILE_NAME_HBM;
        use_header = false,
        initial_stage = data.first_date,
    )

    data.variable_duration = ior_dur
    data.hour_to_block = ior_hbm

    return
end
