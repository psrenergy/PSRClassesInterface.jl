abstract type TimeSeriesRequestStatus end

struct TimeSeriesDidNotChange <: TimeSeriesRequestStatus end
struct TimeSeriesChanged <: TimeSeriesRequestStatus end

const CollectionAttribute = Tuple{String, String}

const DATETIME_FORMAT = "yyyy-mm-dd HH:MM:SS"

mutable struct TimeControllerCache{T}
    data::Vector{T}
    # Control of dates requested per element in a given pair collection attribute
    closest_previous_date_with_data::Vector{DateTime}
    last_date_requested::DateTime
    closest_next_date_with_data::Vector{DateTime}

    # Private caches with the closest previous and next dates
    # _closest_previous_date_with_data = maximum(closest_previous_date_with_data)
    # _closest_next_date_with_data = minimum(closest_next_date_with_data)
    _closest_global_previous_date_with_data::DateTime
    _closest_global_next_date_with_data::DateTime

    # Cache of collection_ids
    _collection_ids::Vector{Int}
end

Base.@kwdef mutable struct TimeController
    cache::Dict{CollectionAttribute, TimeControllerCache} = Dict{CollectionAttribute, TimeControllerCache}()
end

function _collection_attribute(collection_id::String, attribute_id::String)::CollectionAttribute
    return (collection_id, attribute_id)
end

function _closest_previous_date_with_data(
    db,
    attribute::Attribute,
    id::Int,
    date_time::DateTime
)::DateTime
    # TODO this query could probably be optimized
    # It is reading many things that are not necessary
    # And filtering and sorting in the end
    query = """
    SELECT MAX(DATETIME(date_time))
    FROM $(attribute.table_where_is_located)
    WHERE $(attribute.id) IS NOT NULL AND DATETIME(date_time) <= DATETIME('$date_time') AND id = '$id'
    """
    result = DBInterface.execute(db.sqlite_db, query)
    for row in result
        answer = row[1]
        if ismissing(answer)
            return typemin(DateTime)
        end
        return DateTime(answer, DATETIME_FORMAT)
    end
end

function _closest_next_date_with_data(
    db,
    attribute::Attribute,
    id::Int,
    date_time::DateTime
)::DateTime
    # TODO this query could probably be optimized
    # It is reading many things that are not necessary
    # And filtering and sorting in the end
    query = """
    SELECT MIN(DATETIME(date_time))
    FROM $(attribute.table_where_is_located)
    WHERE $(attribute.id) IS NOT NULL AND DATETIME(date_time) > DATETIME('$date_time') AND id = '$id'
    """
    result = DBInterface.execute(db.sqlite_db, query)
    for row in result
        answer = row[1]
        if ismissing(answer)
            return typemax(DateTime)
        end
        return DateTime(answer, DATETIME_FORMAT)
    end
end

function _update_global_closest_dates_with_data!(
    cache::TimeControllerCache
)
    cache._closest_global_previous_date_with_data = maximum(cache.closest_previous_date_with_data)
    cache._closest_global_next_date_with_data = minimum(cache.closest_next_date_with_data)
end

function _no_need_to_query_any_id(
    cache::TimeControllerCache,
    date_time::DateTime
)::Bool
    return cache._closest_global_previous_date_with_data <= date_time < cache._closest_global_next_date_with_data
end

function _start_time_controller_cache(
    db,
    attribute::Attribute,
    date_time::DateTime,
    ::Type{T}
) where T
    _collection_ids = read_scalar_parameters(db, attribute.parent_collection, "id")
    data = Vector{T}(undef, length(_collection_ids))
    closest_previous_date_with_data = Vector{DateTime}(undef, length(_collection_ids))
    closest_next_date_with_data = Vector{DateTime}(undef, length(_collection_ids))
    for (i, id) in enumerate(_collection_ids)
        closest_previous_date_with_data[i] = _closest_previous_date_with_data(db, attribute, id, date_time)
        closest_next_date_with_data[i] = _closest_next_date_with_data(db, attribute, id, date_time)
    end
    _closest_global_previous_date_with_data = maximum(closest_previous_date_with_data)
    _closest_global_next_date_with_data = minimum(closest_next_date_with_data)
    
    # Query the data for the first time
    for (i, id) in enumerate(_collection_ids)
        data[i] = _request_time_series_data_for_time_controller_cache(db, attribute, id, closest_previous_date_with_data[i], T)
    end

    return TimeControllerCache{T}(
        data,
        closest_previous_date_with_data,
        date_time,
        closest_next_date_with_data,
        _closest_global_previous_date_with_data,
        _closest_global_next_date_with_data,
        _collection_ids,
    )
end

function _request_time_series_data_for_time_controller_cache(
    db,
    attribute::Attribute,
    id::Int,
    date_time::DateTime,
    ::Type{T}
) where T
    query = """
    SELECT $(attribute.id)
    FROM $(attribute.table_where_is_located)
    WHERE id = $id AND DATETIME(date_time) = DATETIME('$date_time')
    """
    result = DBInterface.execute(db.sqlite_db, query)
    for row in result
        return T(row[1])
    end
    return _psrdatabasesqlite_null_value(T)
end

function _update_time_controller_cache!(
    cache::TimeControllerCache,
    db,
    attribute::Attribute,
    date_time::DateTime,
    ::Type{T}
) where T
    cache.last_date_requested = date_time
    for (i, id) in enumerate(cache._collection_ids)
        # If date is whitin the range we do not need to update anything
        if cache.closest_previous_date_with_data[i] <= date_time < cache.closest_previous_date_with_data[i]
            continue
        end
        cache.closest_previous_date_with_data[i] = _closest_previous_date_with_data(db, attribute, id, date_time)
        cache.closest_next_date_with_data[i] = _closest_next_date_with_data(db, attribute, id, date_time)
        cache.data[i] = _request_time_series_data_for_time_controller_cache(db, attribute, id, cache.closest_previous_date_with_data[i], T)
    end
    _update_global_closest_dates_with_data!(cache)
    return nothing
end

function read_mapped_timeseries(
    db,
    collection_id::String,
    attribute_id::String,
    type::Type{T};
    date_time::DateTime
) where T 
    _throw_if_attribute_is_not_time_series(
        db,
        collection_id,
        attribute_id,
        :read,
    )
    @assert _is_read_only(db) "Time series mapping only works in read only databases"
    collection_attribute = _collection_attribute(collection_id, attribute_id)
    attribute = _get_attribute(db, collection_id, attribute_id)
    if !haskey(db._time_controller.cache, collection_attribute)
        db._time_controller.cache[collection_attribute] = _start_time_controller_cache(db, attribute, date_time, type)
    end
    cache = db._time_controller.cache[collection_attribute]
    # If we don`t need to update anything we just return the data
    if _no_need_to_query_any_id(cache, date_time)
        cache.last_date_requested = date_time
        return cache.data
    end
    # If we need to update the cache we update the dates and the data
    _update_time_controller_cache!(cache, db,  attribute, date_time, T)
    return cache.data
end