const DAYS_IN_MONTH = Int[
    31, # jan
    28, # feb - always 28
    31, # mar
    30, # apr
    31, # may
    30, # jun
    31, # jul
    31, # ago
    30, # sep
    31, # out
    30, # nov
    31, # dez
]

const STAGES_IN_YEAR = Dict{StageType, Int}(
    STAGE_HOUR => 8760,
    STAGE_DAY => 365,
    STAGE_WEEK => 52,
    STAGE_MONTH => 12,
    STAGE_YEAR => 1,
)

const HOURS_IN_STAGE = Dict{StageType, Int}(
    STAGE_HOUR => 1,
    STAGE_DAY => 24,
    STAGE_WEEK => 168,
    # STAGE_MONTH => 744,
    STAGE_YEAR => 8760,
)

function _delete_or_error(path::AbstractString)
    if isfile(path)
        try
            rm(path)
        catch
            error("Could not delete file $path it might be open in other process")
        end
    end
    return
end

function blocks_in_stage(is_hourly, hour_discretization, stage_type, initial_stage, t)::Int
    if is_hourly
        if stage_type == STAGE_MONTH
            return hour_discretization * DAYS_IN_MONTH[mod1(t - 1 + initial_stage, 12)] * 24
        else
            return hour_discretization * HOURS_IN_STAGE[stage_type]
        end
    end
    return io.blocks
end

function blocks_in_stage(io, t)::Int
    if is_hourly(io)
        if stage_type(io) == STAGE_MONTH
            return hour_discretization(io) *
                   DAYS_IN_MONTH[mod1(t - 1 + initial_stage(io), 12)] * 24
        else
            return hour_discretization(io) * HOURS_IN_STAGE[stage_type(io)]
        end
    end
    return max_blocks(io)
end

function _date_from_stage(t::Int, stage_type::StageType, first_date::Dates.Date)
    date = if stage_type == STAGE_MONTH
        first_date + Dates.Month(t - 1)
    elseif stage_type == STAGE_WEEK
        y = 0
        if t >= 52
            y, t = divrem(t, 52)
            t += 1
        end
        first_date + Dates.Week(t - 1) + Dates.Year(y)
    elseif stage_type == STAGE_DAY
        y = 0
        if t >= 365
            y, t = divrem(t, 365)
            t += 1
        end
        current_date = first_date + Dates.Day(t - 1) + Dates.Year(y)
        if (
            Dates.isleapyear(first_date) &&
            first_date <= Dates.Date(Dates.year(first_date), 2, 28) &&
            current_date >= Dates.Date(Dates.year(first_date), 2, 29)
        )
            current_date += Dates.Day(1)
        elseif (
            Dates.isleapyear(current_date) &&
            first_date <= Dates.Date(Dates.year(current_date), 2, 28) &&
            current_date >= Dates.Date(Dates.year(current_date), 2, 29)
        )
            current_date += Dates.Day(1)
        end
        return current_date
    else
        error("Stage type $stage_type not currently supported")
    end
    return date
end

function _year_week(date::Dates.Date, go_back_if_needed = false)
    y, m, d = Dates.yearmonthday(date)
    # invalid dates for weekly model
    if m == 2 && d >= 29
        if go_back_if_needed
            d = 28
        else
            error("29th of February is not valid for weekly stages")
        end
    elseif m == 12 && d == 31
        if go_back_if_needed
            d = 30
        else
            error("31st of December is not valid for weekly stages")
        end
    end
    # use a non-leap year as ref
    w = div(Dates.dayofyear(Dates.Date(2002, m, d)) - 1, 7) + 1
    @assert 1 <= w <= 52
    return y, w
end

function _year_day(date::Dates.Date, go_back_if_needed = false)
    y, m, d = Dates.yearmonthday(date)
    # invalid dates for weekly model
    dd = Dates.dayofyear(date)
    if Dates.isleapyear(date)
        if m >= 3
            dd -= 1
        elseif m == 2 && d == 29
            if go_back_if_needed
                dd -= 1
            else
                error("29th of February is not valid for daily stages")
            end
        end
    end
    @assert 1 <= dd <= 365
    return y, dd
end

function _year_month(date::Dates.Date)
    return Dates.yearmonth(date)
end

function _stage_distance(year1, stage1, year2, stage2, cycle)
    # current(1) = reference(2)
    abs_stage1 = (year1 - 1) * cycle + stage1
    abs_stage2 = (year2 - 1) * cycle + stage2
    return abs_stage1 - abs_stage2
end

function _stage_from_date(
    date::Dates.Date,
    stage_type::StageType,
    first_date::Dates.Date,
)
    fy, fm = _year_stage(first_date, stage_type)
    y, m = _year_stage(date, stage_type)
    return _stage_distance(y, m, fy, fm, STAGES_IN_YEAR[stage_type]) + 1
end

function _year_stage(
    date::Dates.Date,
    stage_type::StageType,
)
    if stage_type == STAGE_MONTH
        return _year_month(date)
    elseif stage_type == STAGE_WEEK
        return _year_week(date)
    elseif stage_type == STAGE_DAY
        return _year_day(date)
    else
        error("Stage type $stage_type not currently supported")
    end
end

function _trim_multidimensional_attribute(attribute::String)
    regex_attr = r"([a-zA-Z_]+-*[<,>]*-*)"
    regex_dim = r"\((([0-9],*)+)\)"

    attr = match(regex_attr, attribute)
    dim = match(regex_dim, attribute)

    if isnothing(dim)
        return attribute, nothing
    else
        dim = [parse(Int32, i) for i in dim[1] if i != ',']
        return attr[1], dim
    end
end

function _get_dim_from_attribute_name(attribute::String)
    attr, dim = _trim_multidimensional_attribute(attribute)
    if isnothing(dim)
        return 0
    end
    return length(dim)
end

function _load_json_data!(
    path::AbstractString,
    data::Union{Dict{String, Any}, Vector{Any}},
    data_ctime::Vector{Float64},
)
    if data_ctime[] != ctime(path)
        data_ctime[] = ctime(path)
        copy!(data, JSON.parsefile(path))
    end

    return data
end

_load_defaults!() = _load_json_data!(
    PSRCLASSES_DEFAULTS_PATH,
    PSRCLASSES_DEFAULTS,
    PSRCLASSES_DEFAULTS_CTIME,
)

function _has_inner_dicts(dict::Dict{String, Any})
    for (key, value) in dict
        if isa(value, Dict{String, Any})
            return true
        end
    end
    return false
end

function merge_defaults!(dst::Dict{String, Any}, src::Dict{String, Any})
    for (key, value) in src
        if haskey(dst, key)
            if _has_inner_dicts(value)
                merge_defaults!(dst[key], value)
            else
                merge!(dst[key], value)
            end
        else
            dst[key] = value
        end
    end
end
