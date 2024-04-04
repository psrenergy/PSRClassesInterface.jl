mutable struct DatabaseSQLite
    sqlite_db::SQLite.DB
    collections_map::OrderedDict{String, Collection}
end

function DatabaseSQLite_from_schema(
    database_path::String;
    path_schema::String = "",
)
    sqlite_db = SQLite.DB(database_path)

    collections_map = try
        execute_statements(sqlite_db, path_schema)
        _validate_database(sqlite_db)
        _create_collections_map(sqlite_db)
    catch e
        SQLite.close(sqlite_db)
        rethrow(e)
    end

    db = DatabaseSQLite(
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

    db = DatabaseSQLite(
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
        read_only ? SQLite.DB("file:" * database_path * "?mode=ro") :
        SQLite.DB(database_path)

    collections_map = try
        _validate_database(sqlite_db)
        _create_collections_map(sqlite_db)
    catch e
        SQLite.close(sqlite_db)
        rethrow(e)
    end

    db = DatabaseSQLite(
        sqlite_db,
        collections_map,
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

function _vectors_group_table_name(collection_id::String, group::String)
    return string(collection_id, "_vector_", group)
end

function _is_collection_id(name::String)
    # Collections don't have underscores in their names
    return !occursin("_", name)
end

function _is_collection_vector_table_name(name::String, collection_id::String)
    return startswith(name, "$(collection_id)_vector_")
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

function foreign_keys_list(db::SQLite.DB, table_name::String)
    query = "PRAGMA foreign_key_list($table_name);"
    df = DBInterface.execute(db, query) |> DataFrame
    return df
end

close!(db::DatabaseSQLite) = DBInterface.close!(db.sqlite_db)
