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
    STAGE_WEEK => 52,
    STAGE_MONTH => 12,
    STAGE_DAY => 365,
)

const HOURS_IN_STAGE = Dict{StageType, Int}(
    STAGE_WEEK => 168,
    # STAGE_MONTH => 744,
    STAGE_DAY => 24,
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

function blocks_in_stage(is_hourly, stage_type, initial_stage, t)::Int
    if is_hourly
        if stage_type == STAGE_MONTH
            return DAYS_IN_MONTH[mod1(t - 1 + initial_stage, 12)] * 24
        else
            return HOURS_IN_STAGE[stage_type]
        end
    end
    return io.blocks
end
function blocks_in_stage(io, t)::Int
    if is_hourly(io)
        if stage_type(io) == STAGE_MONTH
            return DAYS_IN_MONTH[mod1(t - 1 + initial_stage(io), 12)] * 24
        else
            return HOURS_IN_STAGE[stage_type(io)]
        end
    end
    return max_blocks(io)
end

function _date_from_stage(t::Int, stage_type::StageType, first_date::Dates.Date)
    date = if stage_type == STAGE_MONTH
        first_date + Dates.Month(t-1)
    elseif stage_type == STAGE_WEEK
        y = 0
        if t >= 52
            y, t = divrem(t, 52)
            t += 1
        end
        first_date + Dates.Week(t-1) + Dates.Year(y)
    elseif stage_type == STAGE_DAY
        y = 0
        if t >= 365
            y, t = divrem(t, 365)
            t += 1
        end
        current_date = first_date + Dates.Day(t-1) + Dates.Year(y)
        if (Dates.isleapyear(first_date) &&
            first_date <= Dates.Date(Dates.year(first_date), 2, 28) &&
            current_date >= Dates.Date(Dates.year(first_date), 2, 29)
            )
            current_date += Dates.Day(1)
        elseif (Dates.isleapyear(current_date) &&
            first_date <= Dates.Date(Dates.year(current_date), 2, 28) &&
            current_date >= Dates.Date(Dates.year(current_date), 2, 29)
            )
            current_date += Dates.Day(1)
        end
        return current_date
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
    w = div(Dates.dayofyear(Date.Date(2002, m, d)) - 1, 7) + 1
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

function _stage_distance(year1, stage1, year2, stage2, cycle)
    # current(1) = reference(2)
    abs_stage1 = (year1 - 1) * cycle + stage1
    abs_stage2 = (year2 - 1) * cycle + stage2
    return abs_stage1 - abs_stage2
end

function _stage_from_date(
    date::Dates.Date,
    stage_type::StageType,
    first_date::Dates.Date
)
    if stage_type == STAGE_MONTH
        fy, fm = Dates.yearmonth(first_date)
        y, m = Dates.yearmonth(date)
        return _stage_distance(y, m, fy, fm, 12) + 1
    elseif stage_type == STAGE_WEEK
        fy, fw = _year_week(first_date)
        y, w = _year_week(date)
        return _stage_distance(y, w, fy, fw, 52) + 1
    elseif stage_type == STAGE_DAY
        fy, fd = _year_day(first_date)
        y, d = _year_day(date)
        return _stage_distance(y, d, fy, fd, 365) + 1
    end
    error("Undefined stage_type")
end