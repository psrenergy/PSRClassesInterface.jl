"""
    Collection

This struct stores the definition of a collection
"""
mutable struct Collection
    id::String
    # The key of every ordered dict is the name of the attribute
    scalar_parameters::OrderedDict{String, ScalarParameter}
    scalar_relations::OrderedDict{String, ScalarRelation}
    vector_parameters::OrderedDict{String, VectorParameter}
    vector_relations::OrderedDict{String, VectorRelation}
    time_series::OrderedDict{String, TimeSeries}
    time_series_files::OrderedDict{String, TimeSeriesFile}
end

function _create_collections_map(db::SQLite.DB)
    collections_map = OrderedDict{String, Collection}()
    return _create_collections_map!(collections_map, db)
end
function _create_collections_map!(
    collections_map::OrderedDict{String, Collection},
    db::SQLite.DB,
)
    collection_ids = _get_collection_ids(db)
    for collection_id in collection_ids
        scalar_parameters = _create_collection_scalar_parameters(db, collection_id)
        scalar_relations = _create_collection_scalar_relations(db, collection_id)
        vector_parameters = _create_collection_vector_parameters(db, collection_id)
        vector_relations = _create_collection_vector_relations(db, collection_id)
        time_series = _create_collection_time_series(db, collection_id)
        time_series_files = _create_collection_time_series_files(db, collection_id)
        collection = Collection(
            collection_id,
            scalar_parameters,
            scalar_relations,
            vector_parameters,
            vector_relations,
            time_series,
            time_series_files,
        )
        collections_map[collection_id] = collection
    end
    _validate_collections(collections_map)
    return collections_map
end

function _create_collection_scalar_parameters(db::SQLite.DB, collection_id::String)
    scalar_attributes_table = _get_collection_scalar_attribute_tables(db, collection_id)
    df_table_infos = table_info(db, scalar_attributes_table)
    df_foreign_keys_list = foreign_keys_list(db, scalar_attributes_table)
    scalar_parameters = OrderedDict{String, ScalarParameter}()
    for scalar_attribute in eachrow(df_table_infos)
        id = scalar_attribute.name
        if id in df_foreign_keys_list.from
            # This means that this attribute is a foreign key
            # and therefore it is a ScalarRelation
            # not a ScalarParameter.
            continue
        end
        type = _sql_type_to_julia_type(id, scalar_attribute.type)
        not_null = Bool(scalar_attribute.notnull)
        default_value = _get_default_value(type, scalar_attribute.dflt_value)
        parent_collection = collection_id
        table_where_is_located = scalar_attributes_table
        if haskey(scalar_parameters, id)
            psr_database_sqlite_error(
                "Duplicated scalar parameter $id incollection $collection_id",
            )
        end
        scalar_parameters[id] = ScalarParameter(
            id,
            type,
            default_value,
            not_null,
            parent_collection,
            table_where_is_located,
        )
    end
    return scalar_parameters
end

function _create_collection_scalar_relations(db::SQLite.DB, collection_id::String)
    scalar_attributes_table = _get_collection_scalar_attribute_tables(db, collection_id)
    df_foreign_keys_list = foreign_keys_list(db, scalar_attributes_table)
    df_table_infos = table_info(db, scalar_attributes_table)
    scalar_relations = OrderedDict{String, ScalarRelation}()
    for foreign_key in eachrow(df_foreign_keys_list)
        _validate_actions_on_foreign_key(
            collection_id,
            scalar_attributes_table,
            foreign_key,
        )
        id = foreign_key.from
        # This is not the optimal way of doing
        # this query but it is fast enough.
        default_value = nothing
        not_null = nothing
        type = nothing
        for scalar_attribute in eachrow(df_table_infos)
            if scalar_attribute.name == id
                type = _sql_type_to_julia_type(id, scalar_attribute.type)
                default_value = _get_default_value(type, scalar_attribute.dflt_value)
                not_null = Bool(scalar_attribute.notnull)
                break
            end
        end
        relation_type = _get_relation_type_from_attribute_id(id)
        parent_collection = collection_id
        relation_collection = foreign_key.table
        table_where_is_located = scalar_attributes_table
        if haskey(scalar_relations, id)
            psr_database_sqlite_error(
                "Duplicated scalar relation $id incollection $collection_id",
            )
        end
        scalar_relations[id] = ScalarRelation(
            id,
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

function _create_collection_vector_parameters(db::SQLite.DB, collection_id::String)
    vector_attributes_tables = _get_collection_vector_attributes_tables(db, collection_id)
    vector_parameters = OrderedDict{String, VectorParameter}()
    parent_collection = collection_id

    for table_name in vector_attributes_tables
        group_id = _id_of_vector_group(table_name)
        table_where_is_located = table_name
        df_table_infos = table_info(db, table_name)
        df_foreign_keys_list = foreign_keys_list(db, table_name)
        for vector_attribute in eachrow(df_table_infos)
            id = vector_attribute.name
            if id == "id" || id == "vector_index"
                # These are obligatory for every vector table
                # and have no point in being stored in the database definition.
                if vector_attribute.pk == 0
                    psr_database_sqlite_error(
                        "Invalid table \"$(table_name)\" of vector attributes of collection \"$(collection_id)\". " *
                        "The column \"$(vector_attribute.name)\" is not a primary key but it should.",
                    )
                end
                continue
            end
            if id in df_foreign_keys_list.from
                # This means that this attribute is a foreign key
                # and therefore it is a VectorRelation
                # not a VectorParameter.
                continue
            end
            type = _sql_type_to_julia_type(id, vector_attribute.type)
            default_value = _get_default_value(type, vector_attribute.dflt_value)
            not_null = Bool(vector_attribute.notnull)
            if haskey(vector_parameters, id)
                psr_database_sqlite_error(
                    "Duplicated vector parameter \"$id\" in collection \"$collection_id\"",
                )
            end
            vector_parameters[id] = VectorParameter(
                id,
                type,
                default_value,
                not_null,
                group_id,
                parent_collection,
                table_where_is_located,
            )
        end
    end
    return vector_parameters
end

function _create_collection_vector_relations(db::SQLite.DB, collection_id::String)
    vector_attributes_tables = _get_collection_vector_attributes_tables(db, collection_id)
    vector_relations = OrderedDict{String, VectorRelation}()
    parent_collection = collection_id
    for table_name in vector_attributes_tables
        group_id = _id_of_vector_group(table_name)
        df_table_infos = table_info(db, table_name)
        df_foreign_keys_list = foreign_keys_list(db, table_name)
        for foreign_key in eachrow(df_foreign_keys_list)
            _validate_actions_on_foreign_key(collection_id, table_name, foreign_key)
            id = foreign_key.from
            if id == "id" || id == "vector_index"
                # These are obligatory for every vector table
                # and have no point in being stored in the database definition.
                for column in eachrow(df_table_infos)
                    if column.name in ["id", "vector_index"] && column.pk == 0
                        psr_database_sqlite_error(
                            "Invalid table \"$(table_name)\" of vector attributes of collection \"$(collection_id)\". " *
                            "The column \"$(column.name)\" is not a primary key but it should.",
                        )
                    end
                end
                continue
            end
            # This is not the optimal way of doing
            # this query but it is fast enough.
            default_value = nothing
            not_null = nothing
            type = nothing
            for scalar_attribute in eachrow(df_table_infos)
                if scalar_attribute.name == id
                    type = _sql_type_to_julia_type(id, scalar_attribute.type)
                    default_value = _get_default_value(type, scalar_attribute.dflt_value)
                    not_null = Bool(scalar_attribute.notnull)
                    break
                end
            end
            relation_type = _get_relation_type_from_attribute_id(id)
            relation_collection = foreign_key.table
            table_where_is_located = table_name
            if haskey(vector_relations, id)
                psr_database_sqlite_error(
                    "Duplicated vector relation \"$id\" in collection \"$collection_id\"",
                )
            end
            vector_relations[id] = VectorRelation(
                id,
                type,
                default_value,
                not_null,
                group_id,
                parent_collection,
                relation_collection,
                relation_type,
                table_where_is_located,
            )
        end
    end
    return vector_relations
end

function _get_time_series_dimension_names(df_table_infos::DataFrame)
    dimension_names = Vector{String}(undef, 0)
    for time_series_attribute in eachrow(df_table_infos)
        if time_series_attribute.name == "id"
            continue
        end
        if time_series_attribute.pk != 0
            push!(dimension_names, time_series_attribute.name)
        end
    end
    return dimension_names
end

function _create_collection_time_series(db::SQLite.DB, collection_id::String)
    time_series_tables = _get_collection_time_series_tables(db, collection_id)
    time_series = OrderedDict{String, TimeSeries}()
    parent_collection = collection_id
    for table_name in time_series_tables
        group_id = _id_of_time_series_group(table_name)
        table_where_is_located = table_name
        df_table_infos = table_info(db, table_name)
        dimension_names = _get_time_series_dimension_names(df_table_infos)
        for time_series_attribute in eachrow(df_table_infos)
            id = time_series_attribute.name
            if id == "id" || id == "date_time"
                # These are obligatory for every vector table
                # and have no point in being stored in the database definition.
                if time_series_attribute.pk == 0
                    psr_database_sqlite_error(
                        "Invalid table \"$(table_name)\" of time_series attributes of collection \"$(collection_id)\". " *
                        "The column \"$(time_series_attribute.name)\" is not a primary key but it should.",
                    )
                end
                continue
            end
            # There is no point in storing the other primary keys of these tables
            if time_series_attribute.pk != 0
                if _sql_type_to_julia_type(id, time_series_attribute.type) != Int64
                    psr_database_sqlite_error(
                        "Invalid table \"$(table_name)\" of time_series attributes of collection \"$(collection_id)\". " *
                        "The column \"$(time_series_attribute.name)\" is not an integer primary key but it should.",
                    )
                end
                continue
            end
            type = _sql_type_to_julia_type(id, time_series_attribute.type)
            default_value = _get_default_value(type, time_series_attribute.dflt_value)
            not_null = Bool(time_series_attribute.notnull)
            if haskey(time_series, id)
                psr_database_sqlite_error(
                    "Duplicated time_series attribute \"$id\" in collection \"$collection_id\"",
                )
            end
            time_series[id] = TimeSeries(
                id,
                type,
                default_value,
                not_null,
                group_id,
                parent_collection,
                table_where_is_located,
                dimension_names,
                length(dimension_names),
            )
        end
    end
    return time_series
end

function _create_collection_time_series_files(db::SQLite.DB, collection_id::String)
    time_series_table = _get_collection_time_series_files_tables(db, collection_id)
    time_series = OrderedDict{String, TimeSeriesFile}()
    df_table_infos = table_info(db, time_series_table)
    for time_series_id in eachrow(df_table_infos)
        id = time_series_id.name
        type = _sql_type_to_julia_type(id, time_series_id.type)
        default_value = _get_default_value(type, time_series_id.dflt_value)
        not_null = Bool(time_series_id.notnull)
        parent_collection = collection_id
        table_where_is_located = time_series_table
        time_series[id] = TimeSeriesFile(
            id,
            type,
            default_value,
            not_null,
            parent_collection,
            table_where_is_located,
        )
    end
    return time_series
end

function _sql_type_to_julia_type(attribute_id::String, sql_type::String)
    if sql_type == "INTEGER"
        return Int
    elseif sql_type == "REAL"
        return Float64
    elseif sql_type == "TEXT"
        if startswith(attribute_id, "date_")
            return DateTime
        else
            return String
        end
    elseif sql_type == "BLOB"
        return Vector{UInt8}
    else
        psr_database_sqlite_error("Unknown SQL type: $sql_type")
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

function _get_collection_scalar_attribute_tables(::SQLite.DB, collection_id::String)
    return collection_id
end

function _get_collection_vector_attributes_tables(
    sqlite_db::SQLite.DB,
    collection_id::String,
)
    tables = SQLite.tables(sqlite_db)
    vector_parameters_tables = Vector{String}(undef, 0)
    for table in tables
        table_name = table.name
        if _is_collection_vector_table_name(table_name, collection_id)
            push!(vector_parameters_tables, table_name)
        end
    end
    return vector_parameters_tables
end

function _get_relation_type_from_attribute_id(attribute_id::String)
    matches = match(r"_(.*)", attribute_id)
    return string(matches.captures[1])
end

function _id_of_vector_group(table_name::String)
    matches = match(r"_vector_(.*)", table_name)
    return string(matches.captures[1])
end

function _id_of_time_series_group(table_name::String)
    matches = match(r"_time_series_(.*)", table_name)
    return string(matches.captures[1])
end

function _get_collection_time_series_tables(
    sqlite_db::SQLite.DB,
    collection_id::String,
)
    tables = SQLite.tables(sqlite_db)
    time_series_tables = Vector{String}(undef, 0)
    for table in tables
        table_name = table.name
        if _is_collection_time_series_table_name(table_name, collection_id)
            push!(time_series_tables, table_name)
        end
    end
    return time_series_tables
end

function _get_collection_time_series_files_tables(::SQLite.DB, collection_id::String)
    return string(collection_id, "_time_series_files")
end

function _dimensions_of_time_series_group(collection::Collection, group_id::String)
    time_series = collection.time_series
    for (_, time_series_attribute) in time_series
        if time_series_attribute.group_id == group_id
            return time_series_attribute.dimension_names
        end
    end
end

function _validate_actions_on_foreign_key(
    collection_id::String,
    table_name::String,
    foreign_key::DataFrameRow,
)
    foreign_key_name = foreign_key.from
    table = foreign_key.table
    on_update = foreign_key.on_update
    on_delete = foreign_key.on_delete

    num_errors = 0
    if foreign_key_name == "id"
        if table != collection_id
            @error(
                "The foreign key \"id\" in table \"$table_name\" of collection \"$collection_id\" does not reference the collection \"$collection_id\". You must set it to reference the collection \"$collection_id\"."
            )
            num_errors += 1
        end
        if on_delete != "CASCADE"
            @error(
                "The foreign key \"id\" in table \"$table_name\" of collection \"$collection_id\" does not cascade on delete. This might cause problems in the future. You must set it to \"CASCADE\"."
            )
            num_errors += 1
        end
    else
        if on_delete != "SET NULL"
            @error(
                "The foreign key \"$foreign_key_name\" in table \"$table_name\" of collection \"$collection_id\" does not set to null on delete. You must set it to \"SET NULL\"."
            )
            num_errors += 1
        end
    end

    if on_update != "CASCADE"
        @error(
            "The foreign key \"id\" in table \"$table_name\" of collection \"$collection_id\" does not cascade on update. This might cause problems in the future. You must set it to \"CASCADE\"."
        )
        num_errors += 1
    end

    if num_errors > 0
        psr_database_sqlite_error("Database definition has $num_errors errors.")
    end
    return nothing
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
        psr_database_sqlite_error("Database definition has $num_errors errors.")
    end
    return nothing
end

function _no_duplicated_attributes(collection::Collection)
    num_errors = 0
    list_of_attributes = Vector{String}(undef, 0)
    for field in fieldnames(Collection)
        if field == :id
            continue
        end
        attributes = getfield(collection, field)
        for (id, attribute) in attributes
            if id in list_of_attributes
                @error(
                    "Duplicated attribute $(attribute.id) in collection $(collection.id)"
                )
                num_errors += 1
            else
                push!(list_of_attributes, attribute.id)
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
                "Scalar parameter $(scalar_parameter.id) in collection $(collection.id) is not in the same table as the other scalar parameters."
            )
            num_errors += 1
        end
    end
    for (_, scalar_relation) in scalar_relations
        if scalar_relation.table_where_is_located != table_where_first_islocated
            @error(
                "Scalar relation $(scalar_relation.id) in collection $(collection.id) is not in the same table as the other scalar parameters."
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
                "Scalar relation \"$(scalar_relation.id)\" in collection \"$(collection.id)\" has a not null constraint. This is not allowed."
            )
            num_errors += 1
        end
    end
    for (_, vector_relation) in vector_relations
        if vector_relation.not_null
            @error(
                "vector relation \"$(vector_relation.id)\" in collection \"$(collection.id)\" has a not null constraint. This is not allowed."
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
                "Scalar relation \"$(scalar_relation.id)\" in collection \"$(collection.id)\" has a default value."
            )
            num_errors += 1
        end
    end
    for (_, vector_relation) in vector_relations
        if !ismissing(vector_relation.default_value)
            @error(
                "vector relation \"$(vector_relation.id)\" in collection \"$(collection.id)\" has a default value."
            )
            num_errors += 1
        end
    end
    return num_errors
end
