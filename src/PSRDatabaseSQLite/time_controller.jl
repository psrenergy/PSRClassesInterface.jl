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
    _closest_global_previous_date_with_data::DateTime
    _closest_global_next_date_with_data::DateTime

    # Cache of collection_ids
    _collection_ids::Vector{Int}

    # Cache prepared statement for querying the data
    _prepared_statement::SQLite.Stmt
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
    date_time::DateTime
)
    cache.last_date_requested = date_time
    query = """
        SELECT 
            id, 
            MAX(CASE WHEN DATETIME(date_time) <= DATETIME('$date_time') THEN date_time ELSE NULL END) AS closest_previous_date_with_data,
            MIN(CASE WHEN DATETIME(date_time) > DATETIME('$date_time') THEN date_time ELSE NULL END) AS closest_next_date_with_data,
            $(attribute.id)
        FROM $(attribute.table_where_is_located)
        WHERE $(attribute.id) IS NOT NULL
        GROUP BY id
        ORDER BY id
    """
    result = DBInterface.execute(db.sqlite_db, query)
    # @show result
    for (i, row) in enumerate(result)
        id = row[1]
        @assert id == cache._collection_ids[i] "The id in the database is different from the one in the cache"
        closest_previous_date_with_data = row[2]
        closest_next_date_with_data = row[3]
        data = row[4]
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
        if ismissing(data)
            cache.data[i] = _psrdatabasesqlite_null_value(eltype(cache.data))
        else
            cache.data[i] = data
        end
    end
    cache._closest_global_previous_date_with_data = maximum(cache.closest_previous_date_with_data)
    cache._closest_global_next_date_with_data = minimum(cache.closest_next_date_with_data)
    return cache
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
    data = fill(_psrdatabasesqlite_null_value(T), length(_collection_ids))
    closest_previous_date_with_data = fill(typemin(DateTime), length(_collection_ids))
    closest_next_date_with_data = fill(typemax(DateTime), length(_collection_ids))
    _closest_global_previous_date_with_data = maximum(closest_previous_date_with_data)
    _closest_global_next_date_with_data = minimum(closest_next_date_with_data)

    _prepared_statement = SQLite.Stmt(db.sqlite_db, """
        SELECT 
            id, 
            MAX(CASE WHEN DATETIME(date_time) <= DATETIME(':date_time') THEN date_time ELSE NULL END) AS closest_previous_date_with_data,
            MIN(CASE WHEN DATETIME(date_time) > DATETIME(':date_time') THEN date_time ELSE NULL END) AS closest_next_date_with_data,
            $(attribute.id)
        FROM $(attribute.table_where_is_located)
        WHERE $(attribute.id) IS NOT NULL
        GROUP BY id
        ORDER BY id
    """)

    cache = TimeControllerCache{T}(
        data,
        closest_previous_date_with_data,
        date_time,
        closest_next_date_with_data,
        _closest_global_previous_date_with_data,
        _closest_global_next_date_with_data,
        _collection_ids,
        _prepared_statement
    )

    _update_time_controller_cache!(cache, db, attribute, date_time)

    return cache
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
    _update_time_controller_cache!(cache, db, attribute, date_time)
    return cache.data
end