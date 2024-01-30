"""
    Attribute

Abstract type for attributes, the building blocks of collections.
"""
abstract type Attribute end

abstract type ScalarAttribute <: Attribute end
abstract type VectorAttribute <: Attribute end
abstract type ReferenceToFileAttribute <: Attribute end

mutable struct ScalarParameter{T} <: ScalarAttribute
    name::String
    type::Type{T}
    default_value::Union{Missing, T}
    not_null::Bool
    parent_collection::String
    table_where_is_located::String
end

mutable struct ScalarRelation{T} <: ScalarAttribute
    name::String
    type::Type{T}
    default_value::Union{Missing, T}
    not_null::Bool
    parent_collection::String
    relation_collection::String
    relation_type::String
    table_where_is_located::String

    function ScalarRelation(
        name::String,
        type::Type{T},
        default_value::Union{Missing, T},
        not_null::Bool,
        parent_collection::String,
        relation_collection::String,
        relation_type::String,
        table_where_is_located::String,
    ) where {T}
        _check_valid_relation_name(name, relation_collection)
        return new{T}(
            name,
            type,
            default_value,
            not_null,
            parent_collection,
            relation_collection,
            relation_type,
            table_where_is_located,
        )
    end
end

mutable struct VectorParameter{T} <: VectorAttribute
    name::String
    type::Type{T}
    default_value::Union{Missing, T}
    not_null::Bool
    group::String
    parent_collection::String
    table_where_is_located::String
end

mutable struct VectorRelation{T} <: VectorAttribute
    name::String
    type::Type{T}
    default_value::Union{Missing, T}
    not_null::Bool
    group::String
    parent_collection::String
    relation_collection::String
    relation_type::String
    table_where_is_located::String

    function VectorRelation(
        name::String,
        type::Type{T},
        default_value::Union{Missing, T},
        not_null::Bool,
        group::String,
        parent_collection::String,
        relation_collection::String,
        relation_type::String,
        table_where_is_located::String,
    ) where {T}
        _check_valid_relation_name(name, relation_collection)
        return new{T}(
            name,
            type,
            default_value,
            not_null,
            group,
            parent_collection,
            relation_collection,
            relation_type,
            table_where_is_located,
        )
    end
end

mutable struct TimeSeriesFile{T} <: ReferenceToFileAttribute
    name::String
    type::Type{T}
    default_value::Union{Missing, T}
    not_null::Bool
    parent_collection::String
    table_where_is_located::String
end

"""
    Collection

This struct stores the definition of a collection
"""
mutable struct Collection
    name::String
    # The key of every ordered dict is the name of the attribute
    scalar_parameters::OrderedDict{String, ScalarParameter}
    scalar_relations::OrderedDict{String, ScalarRelation}
    vector_parameters::OrderedDict{String, VectorParameter}
    vector_relations::OrderedDict{String, VectorRelation}
    time_series_files::OrderedDict{String, TimeSeriesFile}
end

mutable struct PSRDBSQLite
    sqlite_db::SQLite.DB
    collections_map::OrderedDict{String, Collection}
    path_migrations_directory::String

    function PSRDBSQLite(
        database_path::String;
        path_migrations_directory::String = "",
        path_schema::String = "",
        force::Bool = false,
    )
        if !isempty(path_schema) && !isempty(path_migrations_directory)
            error(
                "User must define wither a `path_schema` or a `path_migrations_directory`. Not both.",
            )
        end
        if !isempty(path_schema) || !isempty(path_migrations_directory)
            # Creating a database from a schema or migrations
            _throw_if_file_exists(database_path, force)
        end

        sqlite_db = SQLite.DB(database_path)

        collections_map = try
            if !isempty(path_schema)
                execute_statements(sqlite_db, path_schema)
            elseif !isempty(path_migrations_directory)
                _apply_all_up_migrations(sqlite_db, path_migrations_directory)
            end
            _validate_database(sqlite_db)
            # as this is the last line of the block it is equivalent to 
            # collections_map = _create_collections_map(sqlite_db)
            _create_collections_map(sqlite_db)
        catch e
            SQLite.close(sqlite_db)
            rethrow(e)
        end

        db = new(
            sqlite_db,
            collections_map,
            path_migrations_directory,
        )

        return db
    end
end

function _is_scalar_parameter(
    db::PSRDBSQLite,
    collection_name::String,
    attribute_name::String,
)
    collection = _get_collection(db, collection_name)
    return haskey(collection.scalar_parameters, attribute_name)
end

function _is_vector_parameter(
    db::PSRDBSQLite,
    collection_name::String,
    attribute_name::String,
)
    collection = _get_collection(db, collection_name)
    return haskey(collection.vector_parameters, attribute_name)
end

function _is_scalar_relation(
    db::PSRDBSQLite,
    collection_name::String,
    attribute_name::String,
)
    collection = _get_collection(db, collection_name)
    return haskey(collection.scalar_relations, attribute_name)
end

function _is_vector_relation(
    db::PSRDBSQLite,
    collection_name::String,
    attribute_name::String,
)
    collection = _get_collection(db, collection_name)
    return haskey(collection.vector_relations, attribute_name)
end

function _is_time_series_file(
    db::PSRDBSQLite,
    collection_name::String,
    attribute_name::String,
)
    collection = _get_collection(db, collection_name)
    return haskey(collection.time_series_files, attribute_name)
end

_name(attribute::Attribute) = attribute.name
_type(attribute::Attribute) = attribute.type
_default_value(attribute::Attribute) = attribute.default_value
_not_null(attribute::Attribute) = attribute.not_null
_parent_collection(attribute::Attribute) = attribute.parent_collection
_table_where_is_located(attribute::Attribute) = attribute.table_where_is_located

function _get_collection(db::PSRDBSQLite, collection_name::String)
    return db.collections_map[collection_name]
end

function _get_attribute(
    db::PSRDBSQLite,
    collection_name::String,
    attribute_name::String,
)
    collection = _get_collection(db, collection_name)
    if _is_scalar_parameter(db, collection_name, attribute_name)
        return collection.scalar_parameters[attribute_name]
    elseif _is_vector_parameter(db, collection_name, attribute_name)
        return collection.vector_parameters[attribute_name]
    elseif _is_scalar_relation(db, collection_name, attribute_name)
        return collection.scalar_relations[attribute_name]
    elseif _is_vector_relation(db, collection_name, attribute_name)
        return collection.vector_relations[attribute_name]
    elseif _is_time_series_file(db, collection_name, attribute_name)
        return collection.time_series_files[attribute_name]
    else
        error(
            """
            Attribute \"$attribute_name\" not found in collection \"$collection_name\". 
            This is the list of attributes in this collection: 
            # TODO
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
    db::PSRDBSQLite,
    collection_name::String,
    attribute_name::String,
)
    attribute = _get_attribute(db, collection_name, attribute_name)
    return typeof(attribute)
end

function _collection_exists(db::PSRDBSQLite, collection_name::String)
    return haskey(db.collections_map, collection_name)
end
function _attribute_exists(
    db::PSRDBSQLite,
    collection_name::String,
    attribute_name::String,
)
    return _is_scalar_parameter(db, collection_name, attribute_name) ||
           _is_vector_parameter(db, collection_name, attribute_name) ||
           _is_scalar_relation(db, collection_name, attribute_name) ||
           _is_vector_relation(db, collection_name, attribute_name) ||
           _is_time_series_file(db, collection_name, attribute_name)
end

function _map_of_groups_to_vector_attributes(
    db::PSRDBSQLite,
    collection_name::String,
)
    collection = _get_collection(db, collection_name)
    groups = Set{String}()
    for (_, attribute) in collection.vector_parameters
        push!(groups, attribute.group)
    end
    for (_, attribute) in collection.vector_relations
        push!(groups, attribute.group)
    end

    map_of_groups_to_vector_attributes = Dict{String, Vector{String}}()
    for group in groups
        map_of_groups_to_vector_attributes[group] = Vector{String}(undef, 0)
        for (_, attribute) in collection.vector_parameters
            if attribute.group == group
                push!(map_of_groups_to_vector_attributes[group], attribute.name)
            end
        end
        for (_, attribute) in collection.vector_relations
            if attribute.group == group
                push!(map_of_groups_to_vector_attributes[group], attribute.name)
            end
        end
    end

    return map_of_groups_to_vector_attributes
end

function _vectors_group_table_name(collection_name::String, group::String)
    return string(collection_name, "_vector_", group)
end

function _is_collection_name(name::String)
    # Collections don't have underscores in their names
    return !occursin("_", name)
end

function _is_collection_vector_table_name(name::String, collection_name::String)
    return occursin("$(collection_name)_vector_", name)
end

_get_collection_names(db::PSRDBSQLite) =
    _get_collection_names(db.sqlite_db)
function _get_collection_names(db::SQLite.DB)
    tables = SQLite.tables(db)
    collection_names = Vector{String}(undef, 0)
    for table in tables
        table_name = table.name
        if _is_collection_name(table_name)
            push!(collection_names, table_name)
        end
    end
    return collection_names
end

function _get_attribute_names(db::PSRDBSQLite, collection_name::String)
    collection = db.collections_map[collection_name]
    attribute_names = Vector{String}(undef, 0)
    for field in fieldnames(Collection)
        attributes = getfield(collection, field)
        if !isa(attributes, OrderedDict{String, <:Attribute})
            continue
        end
        push!(attribute_names, keys(attributes)...)
    end
    return attribute_names
end

function _get_collection_scalar_attribute_tables(::SQLite.DB, collection_name::String)
    return collection_name
end

function _get_collection_vector_attributes_tables(
    sqlite_db::SQLite.DB,
    collection_name::String,
)
    tables = SQLite.tables(sqlite_db)
    vector_parameters_tables = Vector{String}(undef, 0)
    for table in tables
        table_name = table.name
        if _is_collection_vector_table_name(table_name, collection_name)
            push!(vector_parameters_tables, table_name)
        end
    end
    return vector_parameters_tables
end

function _get_relation_type_from_attribute(attribute_name::String)
    matches = match(r"_(.*)", attribute_name)
    return string(matches.captures[1])
end

function _get_collection_time_series_tables(::SQLite.DB, collection_name::String)
    return string(collection_name, "_timeseriesfiles")
end

function _get_related_collection_from_attribute_name(attribute_name::String)
    name_separated_by_underscore = split(attribute_name, "_")
    return lowercase(name_separated_by_underscore[1])
end

function _check_valid_relation_name(attribute_name::String, related_collection::String)
    related_collection_from_attribute_name = _get_related_collection_from_attribute_name(attribute_name)
    if related_collection_from_attribute_name != lowercase(related_collection)
        error(
            """
            Attribute \"$attribute_name\" is not a valid relation name. It is related to collection \"$related_collection\" so its name must start with \"$(lowercase(related_collection))_\".
            """,
        )
    end
    return nothing
end

function _name_of_vector_group(table_name::String)
    matches = match(r"_vector_(.*)", table_name)
    return string(matches.captures[1])
end

function _create_collections_map(db::SQLite.DB)
    collections_map = OrderedDict{String, Collection}()
    return _create_collections_map!(collections_map, db)
end
function _create_collections_map!(
    collections_map::OrderedDict{String, Collection},
    db::SQLite.DB,
)
    collection_names = _get_collection_names(db)
    for collection_name in collection_names
        scalar_parameters = _create_collection_scalar_parameters(db, collection_name)
        scalar_relations = _create_collection_scalar_relations(db, collection_name)
        vector_parameters = _create_collection_vector_parameters(db, collection_name)
        vector_relations = _create_collection_vector_relations(db, collection_name)
        time_series = _get_collection_time_series(db, collection_name)
        collection = Collection(
            collection_name,
            scalar_parameters,
            scalar_relations,
            vector_parameters,
            vector_relations,
            time_series,
        )
        collections_map[collection_name] = collection
    end
    _validate_collections(collections_map)
    return collections_map
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

function _sql_type_to_julia_type(attribute_name::String, sql_type::String)
    if sql_type == "INTEGER"
        return Int
    elseif sql_type == "REAL"
        return Float64
    elseif sql_type == "TEXT"
        if startswith(attribute_name, "date_")
            return DateTime
        else
            return String
        end
    elseif sql_type == "BLOB"
        return Vector{UInt8}
    else
        error("Unknown SQL type: $sql_type")
    end
end

function _try_cast_as_datetime(date::String)
    treated_date = replace(date, "\"" => "")
    return DateTime(treated_date)
end

function _get_default_value(
    ::Type{T},
    default_value::Union{Missing, String},
) where {T}
    try
        if ismissing(default_value)
            return default_value # missing
        elseif T <: Number
            return parse(T, default_value)
        elseif T <: DateTime
            return _try_cast_as_datetime(default_value)
        else
            return default_value
        end
    catch e
        @error("Could not parse default value \"$default_value\" to type $T")
        rethrow(e)
    end
end

function _warn_if_foreign_keys_does_not_cascade(
    collection_name::String,
    foreign_key::DataFrameRow,
)
    foreign_key_name = foreign_key.from
    on_update = foreign_key.on_update
    on_delete = foreign_key.on_delete
    if on_update != "CASCADE" && on_delete != "CASCADE"
        @warn """
        Attribute `$foreign_key_name` in collection `$collection_name` does not cascade on update or on delete. This might cause problems in the future. It is recommended to set both to CASCADE.
        on_update: $on_update
        on_delete: $on_delete
        """
    end
    return nothing
end

function _create_collection_scalar_parameters(db::SQLite.DB, collection_name::String)
    scalar_attributes_table = _get_collection_scalar_attribute_tables(db, collection_name)
    df_table_infos = table_info(db, scalar_attributes_table)
    df_foreign_keys_list = foreign_keys_list(db, scalar_attributes_table)
    scalar_parameters = OrderedDict{String, ScalarParameter}()
    for scalar_attribute in eachrow(df_table_infos)
        name = scalar_attribute.name
        if name in df_foreign_keys_list.from
            # This means that this attribute is a foreign key
            # and therefore it is a ScalarRelation
            # not a ScalarParameter.
            continue
        end
        type = _sql_type_to_julia_type(name, scalar_attribute.type)
        not_null = Bool(scalar_attribute.notnull)
        default_value = _get_default_value(type, scalar_attribute.dflt_value)
        parent_collection = collection_name
        table_where_is_located = scalar_attributes_table
        if haskey(scalar_parameters, name)
            error("Duplicated scalar parameter $name in collection $collection_name")
        end
        scalar_parameters[name] = ScalarParameter(
            name,
            type,
            default_value,
            not_null,
            parent_collection,
            table_where_is_located,
        )
    end
    return scalar_parameters
end

function _create_collection_scalar_relations(db::SQLite.DB, collection_name::String)
    scalar_attributes_table = _get_collection_scalar_attribute_tables(db, collection_name)
    df_foreign_keys_list = foreign_keys_list(db, scalar_attributes_table)
    df_table_infos = table_info(db, scalar_attributes_table)
    scalar_relations = OrderedDict{String, ScalarRelation}()
    for foreign_key in eachrow(df_foreign_keys_list)
        _warn_if_foreign_keys_does_not_cascade(collection_name, foreign_key)
        name = foreign_key.from
        # This is not the optimal way of doing
        # this query but it is fast enough.
        default_value = nothing
        not_null = nothing
        type = nothing
        for scalar_attribute in eachrow(df_table_infos)
            if scalar_attribute.name == name
                type = _sql_type_to_julia_type(name, scalar_attribute.type)
                default_value = _get_default_value(type, scalar_attribute.dflt_value)
                not_null = Bool(scalar_attribute.notnull)
                break
            end
        end
        relation_type = _get_relation_type_from_attribute(name)
        parent_collection = collection_name
        relation_collection = foreign_key.table
        table_where_is_located = scalar_attributes_table
        if haskey(scalar_relations, name)
            error("Duplicated scalar relation $name in collection $collection_name")
        end
        scalar_relations[name] = ScalarRelation(
            name,
            type,
            default_value,
            not_null,
            parent_collection,
            relation_collection,
            relation_type,
            table_where_is_located,
        )
    end
    return scalar_relations
end

function _create_collection_vector_parameters(db::SQLite.DB, collection_name::String)
    vector_attributes_tables = _get_collection_vector_attributes_tables(db, collection_name)
    vector_parameters = OrderedDict{String, VectorParameter}()
    parent_collection = collection_name

    for table_name in vector_attributes_tables
        group = _name_of_vector_group(table_name)
        table_where_is_located = table_name
        df_table_infos = table_info(db, table_name)
        df_foreign_keys_list = foreign_keys_list(db, table_name)
        for vector_attribute in eachrow(df_table_infos)
            name = vector_attribute.name
            if name == "id" || name == "vector_index"
                # These are obligatory for every vector table
                # and have no point in being stored in the database definition.
                continue
            end
            if name in df_foreign_keys_list.from
                # This means that this attribute is a foreign key
                # and therefore it is a VectorRelation
                # not a VectorParameter.
                continue
            end
            type = _sql_type_to_julia_type(name, vector_attribute.type)
            default_value = _get_default_value(type, vector_attribute.dflt_value)
            not_null = Bool(vector_attribute.notnull)
            if haskey(vector_parameters, name)
                error("Duplicated vector parameter \"$name\" in collection \"$collection_name\"")
            end
            vector_parameters[name] = VectorParameter(
                name,
                type,
                default_value,
                not_null,
                group,
                parent_collection,
                table_where_is_located,
            )
        end
    end
    return vector_parameters
end

function _create_collection_vector_relations(db::SQLite.DB, collection_name::String)
    vector_attributes_tables = _get_collection_vector_attributes_tables(db, collection_name)
    vector_relations = OrderedDict{String, VectorRelation}()
    parent_collection = collection_name
    for table_name in vector_attributes_tables
        group = _name_of_vector_group(table_name)
        df_table_infos = table_info(db, table_name)
        df_foreign_keys_list = foreign_keys_list(db, table_name)
        for foreign_key in eachrow(df_foreign_keys_list)
            _warn_if_foreign_keys_does_not_cascade(collection_name, foreign_key)
            name = foreign_key.from
            if name == "id"
                # This is obligatory for every vector table.
                continue
            end
            # This is not the optimal way of doing
            # this query but it is fast enough.
            default_value = nothing
            not_null = nothing
            type = nothing
            for scalar_attribute in eachrow(df_table_infos)
                if scalar_attribute.name == name
                    type = _sql_type_to_julia_type(name, scalar_attribute.type)
                    default_value = _get_default_value(type, scalar_attribute.dflt_value)
                    not_null = Bool(scalar_attribute.notnull)
                    break
                end
            end
            relation_type = _get_relation_type_from_attribute(name)
            relation_collection = foreign_key.table
            table_where_is_located = table_name
            if haskey(vector_relations, name)
                error("Duplicated vector relation \"$name\" in collection \"$collection_name\"")
            end
            vector_relations[name] = VectorRelation(
                name,
                type,
                default_value,
                not_null,
                group,
                parent_collection,
                relation_collection,
                relation_type,
                table_where_is_located,
            )
        end
    end
    return vector_relations
end

function _get_collection_time_series(db::SQLite.DB, collection_name::String)
    time_series_table = _get_collection_time_series_tables(db, collection_name)
    time_series = OrderedDict{String, TimeSeriesFile}()
    df_table_infos = table_info(db, time_series_table)
    for time_series_id in eachrow(df_table_infos)
        name = time_series_id.name
        type = _sql_type_to_julia_type(name, time_series_id.type)
        default_value = _get_default_value(type, time_series_id.dflt_value)
        not_null = Bool(time_series_id.notnull)
        parent_collection = collection_name
        table_where_is_located = time_series_table
        time_series[name] = TimeSeriesFile(
            name,
            type,
            default_value,
            not_null,
            parent_collection,
            table_where_is_located,
        )
    end
    return time_series
end

# validations
function _validate_collections(collections_map::OrderedDict{String, Collection})
    num_errors = 0
    for (_, collection) in collections_map
        num_errors += _no_duplicated_attributes(collection)
        num_errors += _all_scalar_parameters_are_in_same_table(collection)
        num_errors += _relations_do_not_have_null_constraints(collection)
        num_errors += _relations_do_not_have_default_values(collection)
    end
    if num_errors > 0
        error("Database definition has $num_errors errors.")
    end
    return nothing
end

function _no_duplicated_attributes(collection::Collection)
    num_errors = 0
    list_of_attributes = Vector{String}(undef, 0)
    for field in fieldnames(Collection)
        if field == :name
            continue
        end
        attributes = getfield(collection, field)
        for (name, attribute) in attributes
            if name in list_of_attributes
                @error(
                    "Duplicated attribute $(attribute.name) in collection $(collection.name)"
                )
                num_errors += 1
            else
                push!(list_of_attributes, attribute.name)
            end
        end
    end
    return num_errors
end

function _all_scalar_parameters_are_in_same_table(collection::Collection)
    num_errors = 0
    scalar_parameters = collection.scalar_parameters
    scalar_relations = collection.scalar_relations
    first_scalar_parameter = first(scalar_parameters).second
    table_where_first_islocated = first_scalar_parameter.table_where_is_located
    for (_, scalar_parameter) in scalar_parameters
        if scalar_parameter.table_where_is_located != table_where_first_islocated
            @error(
                "Scalar parameter $(scalar_parameter.name) in collection $(collection.name) is not in the same table as the other scalar parameters."
            )
            num_errors += 1
        end
    end
    for (_, scalar_relation) in scalar_relations
        if scalar_relation.table_where_is_located != table_where_first_islocated
            @error(
                "Scalar relation $(scalar_relation.name) in collection $(collection.name) is not in the same table as the other scalar parameters."
            )
            num_errors += 1
        end
    end
    return num_errors
end

function _relations_do_not_have_null_constraints(collection::Collection)
    num_errors = 0
    scalar_relations = collection.scalar_relations
    vector_relations = collection.vector_relations
    for (_, scalar_relation) in scalar_relations
        if scalar_relation.not_null
            @error(
                "Scalar relation $(scalar_relation.name) in collection $(collection.name) has a not null constraint. This is not allowed."
            )
            num_errors += 1
        end
    end
    for (_, vector_relation) in vector_relations
        if vector_relation.not_null
            @error(
                "vector relation $(vector_relation.name) in collection $(collection.name) has a not null constraint. This is not allowed."
            )
            num_errors += 1
        end
    end
    return num_errors
end

function _relations_do_not_have_default_values(collection::Collection)
    num_errors = 0
    scalar_relations = collection.scalar_relations
    vector_relations = collection.vector_relations
    for (_, scalar_relation) in scalar_relations
        if !ismissing(scalar_relation.default_value)
            @error(
                "Scalar relation $(scalar_relation.name) in collection $(collection.name) has a default value."
            )
            num_errors += 1
        end
    end
    for (_, vector_relation) in vector_relations
        if !ismissing(vector_relation.default_value)
            @error(
                "vector relation $(vector_relation.name) in collection $(collection.name) has a default value."
            )
            num_errors += 1
        end
    end
    return num_errors
end

close!(db::PSRDBSQLite) = DBInterface.close!(db.sqlite_db)
