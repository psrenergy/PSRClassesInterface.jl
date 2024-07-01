Base.@kwdef mutable struct DatabaseSQLite
    sqlite_db::SQLite.DB
    collections_map::OrderedDict{String, Collection}
    read_only::Bool = false
    # TimeController is a cache that allows PSRDatabaseSQLite to
    # store information about the last timeseries query. This is useful for avoiding to
    # re-query the database when the same query is made multiple times.
    # The TimeController is a private behaviour and whenever it is used
    # it changes the database mode to read-only.
    _time_controller::TimeController = TimeController()
end

_is_read_only(db::DatabaseSQLite) = db.read_only

function _set_default_pragmas!(db::SQLite.DB)
    _set_foreign_keys_on!(db)
    _set_busy_timeout!(db, 5000)
    return nothing
end

function _set_foreign_keys_on!(db::SQLite.DB)
    # https://www.sqlite.org/foreignkeys.html#fk_enable
    # Foreign keys are enabled per connection, they are not something 
    # that can be stored in the database itself like user_version.
    # This is needed to ensure that the foreign keys are enabled
    # behaviours like cascade delete and update are enabled.
    DBInterface.execute(db, "PRAGMA foreign_keys = ON;")
    return nothing
end

function _set_busy_timeout!(db::SQLite.DB, timeout::Int)
    # https://www.sqlite.org/pragma.html#pragma_busy_timeout
    DBInterface.execute(db, "PRAGMA busy_timeout = $timeout;")
    return nothing
end

function DatabaseSQLite_from_schema(
    database_path::String;
    path_schema::String = "",
)
    sqlite_db = SQLite.DB(database_path)

    _set_default_pragmas!(sqlite_db)

    collections_map = try
        execute_statements(sqlite_db, path_schema)
        _validate_database(sqlite_db)
        _create_collections_map(sqlite_db)
    catch e
        SQLite.close(sqlite_db)
        rethrow(e)
    end

    db = DatabaseSQLite(;
        sqlite_db,
        collections_map,
    )

    return db
end

function DatabaseSQLite_from_migrations(
    database_path::String;
    path_migrations::String = "",
)
    sqlite_db = SQLite.DB(database_path)

    _set_default_pragmas!(sqlite_db)

    collections_map = try
        current_version = get_user_version(sqlite_db)
        most_recent_version = get_last_user_version(path_migrations)
        # before applying the migrations we should make a backup of the database
        apply_migrations!(
            sqlite_db,
            path_migrations,
            current_version,
            most_recent_version,
            :up,
        )
        _validate_database(sqlite_db)
        _create_collections_map(sqlite_db)
    catch e
        SQLite.close(sqlite_db)
        rethrow(e)
    end

    db = DatabaseSQLite(;
        sqlite_db,
        collections_map,
    )

    return db
end

function DatabaseSQLite(
    database_path::String;
    read_only::Bool = false,
)
    sqlite_db =
        # read_only ? SQLite.DB("file:" * database_path * "?mode=ro&immutable=1") :
        SQLite.DB(database_path)

    _set_default_pragmas!(sqlite_db)

    collections_map = try
        _validate_database(sqlite_db)
        _create_collections_map(sqlite_db)
    catch e
        SQLite.close(sqlite_db)
        rethrow(e)
    end

    db = DatabaseSQLite(;
        sqlite_db,
        collections_map,
        read_only
    )
    return db
end

function _is_scalar_parameter(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
)
    collection = _get_collection(db, collection_id)
    return haskey(collection.scalar_parameters, attribute_id)
end

function _is_vector_parameter(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
)
    collection = _get_collection(db, collection_id)
    return haskey(collection.vector_parameters, attribute_id)
end

function _is_scalar_relation(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
)
    collection = _get_collection(db, collection_id)
    return haskey(collection.scalar_relations, attribute_id)
end

function _is_vector_relation(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
)
    collection = _get_collection(db, collection_id)
    return haskey(collection.vector_relations, attribute_id)
end

function _is_time_series(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
)
    collection = _get_collection(db, collection_id)
    return haskey(collection.time_series, attribute_id)
end

function _is_timeseries_group(
    db::DatabaseSQLite,
    collection_id::String,
    group_id::String,
)
    collection = _get_collection(db, collection_id)
    for (_, attribute) in collection.time_series
        if attribute.group_id == group_id
            return true
        end
    end
    return false
end

function _is_time_series_file(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
)
    collection = _get_collection(db, collection_id)
    return haskey(collection.time_series_files, attribute_id)
end

_id(attribute::Attribute) = attribute.id
_type(attribute::Attribute) = attribute.type
_default_value(attribute::Attribute) = attribute.default_value
_not_null(attribute::Attribute) = attribute.not_null
_parent_collection(attribute::Attribute) = attribute.parent_collection
_table_where_is_located(attribute::Attribute) = attribute.table_where_is_located

function _get_collection(db::DatabaseSQLite, collection_id::String)
    return db.collections_map[collection_id]
end

function _get_attribute(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
)
    collection = _get_collection(db, collection_id)
    if _is_scalar_parameter(db, collection_id, attribute_id)
        return collection.scalar_parameters[attribute_id]
    elseif _is_vector_parameter(db, collection_id, attribute_id)
        return collection.vector_parameters[attribute_id]
    elseif _is_scalar_relation(db, collection_id, attribute_id)
        return collection.scalar_relations[attribute_id]
    elseif _is_vector_relation(db, collection_id, attribute_id)
        return collection.vector_relations[attribute_id]
    elseif _is_time_series(db, collection_id, attribute_id)
        return collection.time_series[attribute_id]
    elseif _is_time_series_file(db, collection_id, attribute_id)
        return collection.time_series_files[attribute_id]
    else
        error(
            """
            Attribute \"$attribute_id\" not found in collection \"$collection_id\". 
            "This is the list of available attributes: $(_string_of_attributes(db, collection_id))
            """,
        )
    end
end

function _string_for_composite_types(composite_type::Type)
    if composite_type <: ScalarParameter
        return "scalar parameter"
    elseif composite_type <: ScalarRelation
        return "scalar relation"
    elseif composite_type <: VectorParameter
        return "vector parameter"
    elseif composite_type <: VectorRelation
        return "vector relation"
    elseif composite_type <: TimeSeriesFile
        return "time series file"
    else
        error("Something went wrong. Unknown composite type: $composite_type")
    end
end

function _attribute_composite_type(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
)
    attribute = _get_attribute(db, collection_id, attribute_id)
    return typeof(attribute)
end

function _collection_exists(db::DatabaseSQLite, collection_id::String)
    return haskey(db.collections_map, collection_id)
end
function _attribute_exists(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
)
    return _is_scalar_parameter(db, collection_id, attribute_id) ||
           _is_vector_parameter(db, collection_id, attribute_id) ||
           _is_scalar_relation(db, collection_id, attribute_id) ||
           _is_vector_relation(db, collection_id, attribute_id) ||
           _is_time_series(db, collection_id, attribute_id) ||
           _is_time_series_file(db, collection_id, attribute_id)
end

function _map_of_groups_to_vector_attributes(
    db::DatabaseSQLite,
    collection_id::String,
)
    collection = _get_collection(db, collection_id)
    groups = Set{String}()
    for (_, attribute) in collection.vector_parameters
        push!(groups, attribute.group_id)
    end
    for (_, attribute) in collection.vector_relations
        push!(groups, attribute.group_id)
    end

    map_of_groups_to_vector_attributes = Dict{String, Vector{String}}()
    for group in groups
        map_of_groups_to_vector_attributes[group] = Vector{String}(undef, 0)
        for (_, attribute) in collection.vector_parameters
            if attribute.group_id == group
                push!(map_of_groups_to_vector_attributes[group], attribute.id)
            end
        end
        for (_, attribute) in collection.vector_relations
            if attribute.group_id == group
                push!(map_of_groups_to_vector_attributes[group], attribute.id)
            end
        end
    end

    return map_of_groups_to_vector_attributes
end

function _attributes_in_timeseries_group(
    db::DatabaseSQLite,
    collection_id::String,
    group_id::String,
)
    collection = _get_collection(db, collection_id)
    attributes_in_timeseries_group = Vector{String}(undef, 0)
    for (_, attribute) in collection.time_series
        if attribute.group_id == group_id
            push!(attributes_in_timeseries_group, attribute.id)
        end
    end
    return attributes_in_timeseries_group
end

function _vectors_group_table_name(collection_id::String, group::String)
    return string(collection_id, "_vector_", group)
end

function _timeseries_group_table_name(collection_id::String, group::String)
    return string(collection_id, "_timeseries_", group)
end

function _is_collection_id(name::String)
    # Collections don't have underscores in their names
    return !occursin("_", name)
end

function _is_collection_vector_table_name(name::String, collection_id::String)
    return startswith(name, "$(collection_id)_vector_")
end

function _is_collection_time_series_table_name(name::String, collection_id::String)
    return startswith(name, "$(collection_id)_timeseries_")
end

_get_collection_ids(db::DatabaseSQLite) = collect(keys(db.collections_map))
function _get_collection_ids(db::SQLite.DB)
    tables = SQLite.tables(db)
    collection_ids = Vector{String}(undef, 0)
    for table in tables
        table_name = table.name
        if _is_collection_id(table_name)
            push!(collection_ids, table_name)
        end
    end
    return collection_ids
end

function _get_attribute_ids(db::DatabaseSQLite, collection_id::String)
    collection = db.collections_map[collection_id]
    attribute_ids = Vector{String}(undef, 0)
    for field in fieldnames(Collection)
        attributes = getfield(collection, field)
        if !isa(attributes, OrderedDict{String, <:Attribute})
            continue
        end
        push!(attribute_ids, keys(attributes)...)
    end
    return attribute_ids
end

function table_info(db::SQLite.DB, table_name::String)
    query = "PRAGMA table_info($table_name);"
    df = DBInterface.execute(db, query) |> DataFrame
    return df
end

function _check_column_type(
    db::SQLite.DB,
    table_name::String,
    column_name::String,
    expected_type::String,
)
    df = table_info(db, table_name)
    for row in eachrow(df)
        if row.name == column_name
            if row.type != expected_type
                return false
            else
                return true
            end
            return
        end
    end
    return error("Column $column_name not found in table $table_name.")
end

function _is_column_not_null(db::SQLite.DB, table_name::String, column_name::String)
    df = table_info(db, table_name)
    return any(x -> (x.name == column_name && x.notnull == 1), eachrow(df))
end

function _is_column_unique(db::SQLite.DB, table_name::String, column_name::String)
    if !(table_name in table_names(db))
        error("Table $table_name not found in database.")
    end
    if !(column_name in column_names(db, table_name))
        error("Column $column_name not found in table $table_name.")
    end
    query_index_list = "PRAGMA index_list('$(table_name)');"
    index_list = DBInterface.execute(db, query_index_list) |> DataFrame
    if count(x -> x == 1, index_list.unique) == 0
        false
    end
    for row in eachrow(index_list)
        query_index_info = "PRAGMA index_info('$(row.name)');"
        index_info = DBInterface.execute(db, query_index_info) |> DataFrame
        if (index_info.name[1] == column_name)
            return true
        end
    end
    return false
end

function foreign_keys_list(db::SQLite.DB, table_name::String)
    query = "PRAGMA foreign_key_list($table_name);"
    df = DBInterface.execute(db, query) |> DataFrame
    return df
end

close!(db::DatabaseSQLite) = DBInterface.close!(db.sqlite_db)
