const CollectionAttribute = Tuple{String, String}

# This implementation makes an indexation for every collection, attribute and id.
# For every one of those indexes it will store a cache with a range of dates and the data 
# corresponding to those dates.
struct TimeSeriesCache{T}
    dates::Vector{DateTime}
    data::Vector{T}

    function TimeSeriesCache{T}(
        dates::Vector{DateTime},
        data::Vector{T},
    ) where T
        if length(data) != length(dates)
            throw(ArgumentError("The length of data and dates must be the same"))
        end
        return new{T}(dates, data)
    end
end

mutable struct AttributeTimeSeriesCache{T}
    ids::Vector{Int}
    time_series_cache::Vector{TimeSeriesCache{T}}
    last_resquested_date::DateTime
    cached_data::Vector{T}
end

Base.@kwdef mutable struct TimeController
    cache::Dict{CollectionAttribute, AttributeTimeSeriesCache} = Dict{CollectionAttribute, AttributeTimeSeriesCache}()

    # Upon initialization the time controller will ask if a certain 
    # collection is empty, if the collection is empty it 
    # will be added to this cache. This cache will be used to avoid querying
    # multiple times if a certain collection is empty.
    # This relies on the fact that the Time Controller only works in 
    # read only databases.
    collection_is_empty::Dict{String, Bool} = Dict{String, Bool}()
end

function _collection_attribute(collection_id::String, attribute_id::String)::CollectionAttribute
    return (collection_id, attribute_id)
end

function _time_controller_collection_is_empty(db, collection_id::String)::Bool
    if haskey(db._time_controller.collection_is_empty, collection_id)
        return db._time_controller.collection_is_empty[collection_id]
    else
        db._time_controller.collection_is_empty[collection_id] = number_of_elements(db, collection_id) == 0
        return db._time_controller.collection_is_empty[collection_id]
    end
end

function query_data_in_time_controller(
    attribute_cache::AttributeTimeSeriesCache,
    date_time::DateTime,
)
    if date_time == attribute_cache.last_resquested_date
        return attribute_cache.cached_data
    end

    for (i, id) in enumerate(attribute_cache.ids)
        time_series_cache = attribute_cache.time_series_cache[i]
        attribute_cache.cached_data[i] = search_attribute_id_in_cache(time_series_cache, date_time)
    end

    attribute_cache.last_resquested_date = date_time
    return attribute_cache.cached_data
end

function search_attribute_id_in_cache(
    time_series_cache::TimeSeriesCache{T},
    date_time::DateTime,
) where T
    index = findlast(x -> x <= date_time, time_series_cache.dates)
    if index === nothing
        return _psrdatabasesqlite_null_value(T)
    end
    return time_series_cache.data[index]
end

function _start_time_controller_cache(
    db,
    attribute::Attribute,
    date_time::DateTime,
    ::Type{T},
) where {T}
    _collection_ids = read_scalar_parameters(db, attribute.parent_collection, "id")

    attribute_time_series_cache = AttributeTimeSeriesCache{T}(
        _collection_ids,
        Vector{TimeSeriesCache{T}}(undef, length(_collection_ids)),
        DateTime(-100000),
        fill(_psrdatabasesqlite_null_value(T), length(_collection_ids)),
    )
    # Query the attribute and all of its dimension
    query = string("SELECT ", join(attribute.dimension_names, ",", ", "), ", ", "id", ", ", attribute.id)
    query *= " FROM $(attribute.table_where_is_located)"
    df = DBInterface.execute(db.sqlite_db, query) |> DataFrame
    for (i, id) in enumerate(_collection_ids)
        filtered_df = filter(row -> row.id == id, df)
        dates = Vector{DateTime}(undef, 0)
        data = Vector{T}(undef, 0)
        for (j, row) in enumerate(eachrow(filtered_df))
            if ismissing(row[attribute.id])
                continue
            end
            push!(dates, DateTime(row.date_time))
            push!(data, row[attribute.id])
        end
        time_series_cache = TimeSeriesCache{T}(
            dates,
            data,
        )
        attribute_time_series_cache.time_series_cache[i] = time_series_cache
    end

    return attribute_time_series_cache
end
