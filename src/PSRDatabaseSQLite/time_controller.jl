abstract type TimeSeriesRequestStatus end

const CollectionAttributeElement = Tuple{String, String, Int}

struct TimeSeriesDidNotChange <: TimeSeriesRequestStatus end
struct TimeSeriesChanged <: TimeSeriesRequestStatus end

# TODOs
# We need to write a query function that will return a certain data for all ids
# If an id does not exist it will simply return missing. The query must return 
# the closest previous date for each id.

mutable struct TimeSeriesElementCache
    # The last date requested by the user
    last_date_requested::DateTime
    # The next available date after the last date requested
    next_date_possible::DateTime
end

mutable struct TimeSeriesCache{T, N}
    # Tell which dimensions were mapped in a given vector
    # This is probably wrong
    dimensions_mapped
    data::Array{T, N} = fill(_psrdatabasesqlite_null_value(T), zeros(Int, N)...)
end

"""
    TimeController

TimeController in PSRDatabaseSQLite is a cache that allows PSRDatabaseSQLite to
store information about the last timeseries query. This is useful for avoiding to 
re-query the database when the same query is made multiple times. TimeController
is a private behaviour and it only exists when querying all labels from a TimeSeries
element.
"""
Base.@kwdef mutable struct TimeController
    # The tuple stores the cache for a given collection id, attribute id and id of the element in a database
    element_cache::Dict{CollectionAttributeElement, TimeSeriesElementCache} = Dict{CollectionAttributeElement, TimeSeriesElementCache}()
end

function closest_previous_date(
    db::DatabaseSQLite,
    attribute::Attribute,
    date_time::DateTime
)::DateTime
    closest_previous_date_query = string(
        "SELECT DISTINCT date_time FROM", 
        attribute.table_where_is_located,
        "WHERE DATE(date_time) <= DATE('", date_time, "') ORDER BY DATE(date_time) DESC LIMIT 1")
    result = DBInterface.execute(db.sqlite_db, closest_previous_date_query)
    
end

function closest_next_date(
    db::DatabaseSQLite,
    attribute::Attribute,
    date_time::DateTime
)::DateTime
    closest_date_query_later = "SELECT DISTINCT date_time FROM $(attribute.table_where_is_located) WHERE DATE(date_time) > DATE('$(date_time)') ORDER BY DATE(date_time) ASC LIMIT 1"
end

function read_mapped_time_series(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
)

end