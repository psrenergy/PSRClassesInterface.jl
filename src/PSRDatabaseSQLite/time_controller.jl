abstract type TimeSeriesRequestStatus end

struct TimeSeriesDidNotChange <: TimeSeriesRequestStatus end
struct TimeSeriesChanged <: TimeSeriesRequestStatus end

const CollectionAttribute = Tuple{String, String}

mutable struct TimeControllerCache{T}
    data::Vector{T}
    # Control of dates requested per element in a given pair collection attribute
    closest_previous_date_with_data::Vector{DateTime}
    last_date_requested::DateTime
    closest_next_date_with_data::Vector{DateTime}

    # Private caches with the closest previous and next dates
    # _closest_previous_date_with_data = maximum(closest_previous_date_with_data)
    # _closest_next_date_with_data = minimum(closest_next_date_with_data)
    _closest_previous_date_with_data::DateTime
    _closest_next_date_with_data::DateTime

    # Cache of collection_ids
    _collection_ids::Vector{Int}
end

Base.@kwdef mutable struct TimeController
    cache::Dict{CollectionAttribute, TimeControllerCache} = Dict{CollectionAttribute, TimeControllerCache}()
end

function _collection_attribute(collection_id::String, attribute_id::String)::CollectionAttribute
    return (collection_id, attribute_id)
end

function _closes_previous_date_with_data(
    db,
    attribute::Attribute,
    id::Int,
    date_time::DateTime
)
    # TODO this query could probably be optimized
    # It is reading many things that are not necessary
    # And filtering and sorting in the end
    query = """
    SELECT date_time
    FROM $(attribute.table_where_is_located)
    WHERE $(attribute.id) IS NOT NULL AND DATE(date_time) < DATE('$date_time') AND id = '$id'
    ORDER BY date_time DESC
    LIMIT 1
    """
    result = DBInterface.execute(db.sqlite_db, query)
    # See how to get the query without the need to convert into DataFrame
    # If it is empty what should we return?
    return result
end

function _closes_next_date_with_data(
    db,
    attribute::Attribute,
    id::Int,
    date_time::DateTime
)
    # TODO this query could probably be optimized
    # It is reading many things that are not necessary
    # And filtering and sorting in the end
    query = """
    SELECT date_time
    FROM $(attribute.table_where_is_located)
    WHERE $(attribute.id) IS NOT NULL AND DATE(date_time) > DATE('$date_time') AND id = '$id'
    ORDER BY date_time ASC
    LIMIT 1
    """
    result = DBInterface.execute(db.sqlite_db, query)
    # See how to get the query without the need to convert into DataFrame
    # If it is empty what should we return?
    return result
end

function _update_global_closest_dates_with_data!(
    cache::TimeControllerCache
)
    cache._closest_previous_date_with_data = maximum(closest_previous_date_with_data)
    cache._closest_next_date_with_data = minimum(closest_next_date_with_data)
end

function _start_time_controller_cache(
    db,
    attribute::Attribute,
    date_time::DateTime
)
    ids = read_scalar_parameters(db, attribute.parent_collection, "id")
    closest_previous_date_with_data = Vector{DateTime}(undef, length(ids))
    closest_next_date_with_data = Vector{DateTime}(undef, length(ids))
    for (i, id) in enumerate(ids)
        closest_previous_date_with_data[i] = _closes_previous_date_with_data(db, attribute, id, date_time)
        closest_next_date_with_data[i] = _closes_next_date_with_data(db, attribute, id, date_time)
        _collection_ids[i] = id
    end
    _closest_previous_date_with_data = maximum(closest_previous_date_with_data)
    _closest_next_date_with_data = minimum(closest_next_date_with_data)
    
    # Query the data for the first time
    for (i, id) in enumerate(ids)
        data = _request_time_series_data_for_time_controller_cache(db, attribute, id, closest_previous_date_with_data[i])
        cache.data[i] = data
    end

    return TimeControllerCache(
        data,
        closest_previous_date_with_data,
        date_time,
        closest_next_date_with_data,
        _closest_previous_date_with_data,
        _closest_next_date_with_data,
        _collection_ids,
    )
end

function _request_time_series_data_for_time_controller_cache(
    db,
    attribute::Attribute,
    id::Int,
    date_time::DateTime
)
    query = """
    SELECT $(attribute.id)
    FROM $(attribute.table_where_is_located)
    WHERE id = $id AND date_time = $date_time
    """
    result = DBInterface.execute(db.sqlite_db, query)
    # See how to get the query without the need to convert into DataFrame
    # If it is empty what should we return?
    return result
end

function _update_time_controller_cache!(
    cache::TimeControllerCache,
    db,
    date_time::DateTime
)
    cache.last_date_requested = date_time
    for (i, id) in enumerate(cache._collection_ids)
        # If date is whitin the range we do not need to update anything
        if cache.closest_previous_date_with_data[i] < date_time < cache.closest_previous_date_with_data[i]
            continue
        end
        cache.closest_previous_date_with_data[i] = _closes_previous_date_with_data(db, attribute, id, date_time)
        cache.closest_next_date_with_data[i] = _closes_next_date_with_data(db, attribute, id, date_time)
        cache.data[i] = _request_time_series_data_for_time_controller_cache(db, attribute, id, closest_previous_date_with_data[i])
    end
    _update_global_closest_dates_with_data!(cache)
    return nothing
end

function read_mapped_timeseries(
    db,
    collection_id::String,
    attribute_id::String;
    date_time::DateTime
)
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
        db._time_controller.cache[collection_attribute] = _start_time_controller_cache(db, attribute, date_time)
    end
    cache = db._time_controller.cache[collection_attribute]
    # If we don`t need to update anything we just return the data
    if cache._closest_previous_date_with_data < date_time < cache._closest_next_date_with_data
        cache.last_date_requested = date_time
        return cache.data
    end
    # If we need to update the cache we update the dates and the data
    _update_time_controller_cache!(cache, db, date_time)
    return cache.data
end