abstract type TimeSeriesRequestStatus end

struct TimeSeriesDidNotChange <: TimeSeriesRequestStatus end
struct TimeSeriesChanged <: TimeSeriesRequestStatus end

const CollectionAttribute = Tuple{String, String}

# Some comments
# TODO we can further optimize the time controller with a few strategies
# 1 - We can use prepared statements for the queries 

mutable struct TimeControllerCache{T}
    data::Vector{T}
    # Control of dates requested per element in a given pair collection attribute
    closest_previous_date_with_data::Vector{DateTime}
    last_date_requested::DateTime
    closest_next_date_with_data::Vector{DateTime}

    # Private caches with the closest previous and next dates
    _closest_global_previous_date_with_data::DateTime
    _closest_global_next_date_with_data::DateTime

    # Cache of collection_ids, these are the ids of elements in a specific collection
    _collection_ids::Vector{Int}
end

Base.@kwdef mutable struct TimeController
    cache::Dict{CollectionAttribute, TimeControllerCache} = Dict{CollectionAttribute, TimeControllerCache}()

    # Upon initialization the time controller will ask if a certain 
    # collection has any elements, if the collection has any elements it 
    # will be added to this cache. This cache will be used to avoid querying
    # multiple times if a certain collection has any elements.
    # This relies on the fact that the Time Controller only works in 
    # read only databases.
    collection_has_any_data::Dict{String, Bool} = Dict{String, Bool}()
end

function _collection_attribute(collection_id::String, attribute_id::String)::CollectionAttribute
    return (collection_id, attribute_id)
end

function _time_controller_collection_has_any_data(db, collection_id::String)::Bool
    if haskey(db._time_controller.collection_has_any_data, collection_id)
        return db._time_controller.collection_has_any_data[collection_id]
    else
        db._time_controller.collection_has_any_data[collection_id] = number_of_elements(db, collection_id) > 0
        return db._time_controller.collection_has_any_data[collection_id]
    end
end

function _update_time_controller_cache!(
    cache::TimeControllerCache,
    db,
    attribute::Attribute,
    date_time::DateTime,
)
    _update_time_controller_cache_dates!(cache, db, attribute, date_time)
    _request_time_series_data_for_time_controller_cache(cache, db, attribute)

    return nothing
end

function _request_time_series_data_for_time_controller_cache(
    cache::TimeControllerCache,
    db,
    attribute::Attribute,
)
    query = "SELECT id, $(attribute.id) FROM $(attribute.table_where_is_located) WHERE "
    set = ""
    for (i, id) in enumerate(cache._collection_ids)
        current_set = "($id, DATETIME('$(cache.closest_previous_date_with_data[i])'))"
        if i < length(cache._collection_ids)
            set *= "$current_set, "
        else
            set *= "$current_set"
        end
    end
    query *= "(id, DATETIME(date_time)) in ($set) ORDER BY id;"

    df = DBInterface.execute(db.sqlite_db, query) |> DataFrame

    _psrdatabasesqlite_null_value(attribute.type)
    for (i, id) in enumerate(cache._collection_ids)
        index = searchsorted(df.id, id)
        if isempty(index)
            cache.data[i] = _psrdatabasesqlite_null_value(attribute.type)
        else
            cache.data[i] = df[index[1], 2]
        end
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
        MAX(CASE WHEN DATE(date_time) <= DATE('$date_time') AND $(attribute.id) IS NOT NULL THEN DATE(date_time) ELSE NULL END) AS closest_previous_date_with_data,
        MIN(CASE WHEN DATE(date_time) > DATE('$date_time')  AND $(attribute.id) IS NOT NULL THEN DATE(date_time) ELSE NULL END) AS closest_next_date_with_data
    FROM $(attribute.table_where_is_located)
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
