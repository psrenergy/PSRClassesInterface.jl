abstract type TimeSeriesRequestStatus end

struct TimeSeriesDidNotChange <: TimeSeriesRequestStatus end
struct TimeSeriesChanged <: TimeSeriesRequestStatus end

const CollectionAttribute = Tuple{String, String}

# Some comments
# TODO we can further optimize the time controller with a few strategies
# 1 - We can try to ask for the data in the same query that we ask for the dates. I just don`t know how to write the good query for that
# 2 - We can use prepared statements for the queries 
# 3 - Avoid querying the data for every id in the attribute. Currently we fill the cache of dates before making the query and use it to inform which date each id should query. This is quite inneficient
# The best way of optimizing it would be to solve 1 and 2.

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

function _update_time_controller_cache!(
    cache::TimeControllerCache,
    db,
    attribute::Attribute,
    date_time::DateTime,
)
    _update_time_controller_cache_dates!(cache, db, attribute, date_time)

    for (i, id) in enumerate(cache._collection_ids)
        cache.data[i] =
            _request_time_series_data_for_time_controller_cache(db, attribute, id, cache.closest_previous_date_with_data[i])
    end

    return nothing
end

function _request_time_series_data_for_time_controller_cache(
    db,
    attribute::Attribute,
    id::Int,
    date_time::DateTime,
)
    query = """
    SELECT $(attribute.id)
    FROM $(attribute.table_where_is_located)
    WHERE id = $id AND DATETIME(date_time) = DATETIME('$date_time')
    """
    result = DBInterface.execute(db.sqlite_db, query)

    T = attribute.type

    for row in result
        return T(row[1])
    end
    return _psrdatabasesqlite_null_value(T)
end

function _update_time_controller_cache_dates!(
    cache::TimeControllerCache,
    db,
    attribute::Attribute,
    date_time::DateTime,
)
    cache.last_date_requested = date_time
    query = """
    SELECT 
        id, 
        MAX(CASE WHEN DATETIME(date_time) <= DATETIME('$date_time') THEN date_time ELSE NULL END) AS closest_previous_date_with_data,
        MIN(CASE WHEN DATETIME(date_time) > DATETIME('$date_time') THEN date_time ELSE NULL END) AS closest_next_date_with_data
    FROM $(attribute.table_where_is_located)
    WHERE $(attribute.id) IS NOT NULL
    GROUP BY id
    ORDER BY id
    """
    result = DBInterface.execute(db.sqlite_db, query)
    for (i, row) in enumerate(result)
        id = row[1]
        @assert id == cache._collection_ids[i] "The id in the database is different from the one in the cache"
        closest_previous_date_with_data = row[2]
        closest_next_date_with_data = row[3]
        if ismissing(closest_previous_date_with_data)
            cache.closest_previous_date_with_data[i] = typemin(DateTime)
        else
            cache.closest_previous_date_with_data[i] = DateTime(closest_previous_date_with_data)
        end
        if ismissing(closest_next_date_with_data)
            cache.closest_next_date_with_data[i] = typemax(DateTime)
        else
            cache.closest_next_date_with_data[i] = DateTime(closest_next_date_with_data)
        end
    end
    cache._closest_global_previous_date_with_data = maximum(cache.closest_previous_date_with_data)
    cache._closest_global_next_date_with_data = minimum(cache.closest_next_date_with_data)
    return cache
end

function _no_need_to_query_any_id(
    cache::TimeControllerCache,
    date_time::DateTime,
)::Bool
    return cache._closest_global_previous_date_with_data <= date_time < cache._closest_global_next_date_with_data
end

function _start_time_controller_cache(
    db,
    attribute::Attribute,
    date_time::DateTime,
    ::Type{T},
) where {T}
    _collection_ids = read_scalar_parameters(db, attribute.parent_collection, "id")
    data = fill(_psrdatabasesqlite_null_value(T), length(_collection_ids))
    closest_previous_date_with_data = fill(typemin(DateTime), length(_collection_ids))
    closest_next_date_with_data = fill(typemax(DateTime), length(_collection_ids))
    _closest_global_previous_date_with_data = maximum(closest_previous_date_with_data)
    _closest_global_next_date_with_data = minimum(closest_next_date_with_data)

    cache = TimeControllerCache{T}(
        data,
        closest_previous_date_with_data,
        date_time,
        closest_next_date_with_data,
        _closest_global_previous_date_with_data,
        _closest_global_next_date_with_data,
        _collection_ids,
    )

    _update_time_controller_cache!(cache, db, attribute, date_time)

    return cache
end
