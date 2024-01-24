"""
    Attribute

Abstract type for attributes, the building blocks of collections.
"""
abstract type Attribute end

abstract type ScalarAttribute <: Attribute end
abstract type VectorialAttribute <: Attribute end
abstract type ReferenceToFileAttribute <: Attribute end

mutable struct ScalarParameter{T} <: ScalarAttribute
    name::String
    type::Type{T}
    default_value::Union{Missing, T}
    not_null::Bool
    parent_collection::String
    table_where_is_located::String
end

mutable struct ScalarRelationship{T} <: ScalarAttribute
    name::String
    type::Type{T}
    default_value::Union{Missing, T}
    not_null::Bool
    parent_collection::String
    relation_collection::String
    relation_type::String
    table_where_is_located::String
end

mutable struct VectorialParameter{T} <: VectorialAttribute
    name::String
    type::Type{T}
    default_value::Union{Missing, T}
    not_null::Bool
    group::String
    parent_collection::String
    table_where_is_located::String
end

mutable struct VectorialRelationship{T} <: VectorialAttribute
    name::String
    type::Type{T}
    default_value::Union{Missing, T}
    not_null::Bool
    group::String
    parent_collection::String
    relation_collection::String
    relation_type::String
    table_where_is_located::String
end

mutable struct TimeSeriesFile <: ReferenceToFileAttribute
    name::String
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
    scalar_relationships::OrderedDict{String, ScalarRelationship}
    vectorial_parameters::OrderedDict{String, VectorialParameter}
    vectorial_relationships::OrderedDict{String, VectorialRelationship}
    time_series_files::OrderedDict{String, TimeSeriesFile}
end

# TODO write more documentations for all functions

# Dictionary storing the collections map for the database
# TODO if we have multiple databases we should have a dictionary of dictionaries
# two models working with the same dependency would not work.
const COLLECTION_DATABASE_MAP = OrderedDict{String, Collection}()

function _save_collections_database_map(db::SQLite.DB)
    _create_collections_database_map!(COLLECTION_DATABASE_MAP, db)
    return nothing
end

function _collection_exists(collection_name::String)
    return haskey(COLLECTION_DATABASE_MAP, collection_name)
end
function _attribute_exists(collection_name::String, attribute_name::String)
    if _is_scalar_parameter(collection_name, attribute_name)
        return true
    elseif _is_scalar_relationship(collection_name, attribute_name)
        return true
    elseif _is_vectorial_parameter(collection_name, attribute_name)
        return true
    elseif _is_vectorial_relationship(collection_name, attribute_name)
        return true
    elseif _is_time_series_file(collection_name, attribute_name)
        return true
    end
    return false
end

function _scalar_relation_exists(
    collection_from::String,
    collection_to::String,
    relation_type::String,
)
    collection = COLLECTION_DATABASE_MAP[collection_from]
    for (_, scalar_relationship) in collection.scalar_relationships
        if scalar_relationship.relation_collection == collection_to &&
           scalar_relationship.relation_type == relation_type
            return true
        end
    end
    return false
end

function _vectorial_relation_exists(
    collection_from::String,
    collection_to::String,
    relation_type::String,
)
    collection = COLLECTION_DATABASE_MAP[collection_from]
    for (_, vector_relationship) in collection.vectorial_relationships
        if vector_relationship.relation_collection == collection_to &&
           vector_relationship.relation_type == relation_type
            return true
        end
    end
    return false
end

function _list_of_relation_types(collection_from::String, collection_to::String)
    collection = COLLECTION_DATABASE_MAP[collection_from]
    relation_types = Set{String}()
    for (_, scalar_relationship) in collection.scalar_relationships
        if scalar_relationship.relation_collection == collection_to
            push!(relation_types, scalar_relationship.relation_type)
        end
    end
    for (_, vector_relationship) in collection.vectorial_relationships
        if vector_relationship.relation_collection == collection_to
            push!(relation_types, vector_relationship.relation_type)
        end
    end
    return collect(relation_types)
end

function _get_attribute_names(collection_name::String)
    collection = COLLECTION_DATABASE_MAP[collection_name]
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

function _get_collection_names()
    return keys(COLLECTION_DATABASE_MAP)
end

function _get_attribute(collection_name::String, attribute_name::String)::Attribute
    collection = COLLECTION_DATABASE_MAP[collection_name]
    if _is_scalar_parameter(collection_name, attribute_name)
        return collection.scalar_parameters[attribute_name]
    elseif _is_scalar_relationship(collection_name, attribute_name)
        return collection.scalar_relationships[attribute_name]
    elseif _is_vectorial_parameter(collection_name, attribute_name)
        return collection.vectorial_parameters[attribute_name]
    elseif _is_vectorial_relationship(collection_name, attribute_name)
        return collection.vectorial_relationships[attribute_name]
    elseif _is_time_series_file(collection_name, attribute_name)
        return collection.time_series_files[attribute_name]
    else
        error("Attribute $attribute_name in collection $collection_name does not exist.")
    end
end

function _get_scalar_relationship(
    collection_name::String,
    attribute_name::String,
)
    return COLLECTION_DATABASE_MAP[collection_name].scalar_relationships[attribute_name]
end

function _get_vectorial_relationship(
    collection_name::String,
    attribute_name::String,
)
    return COLLECTION_DATABASE_MAP[collection_name].vectorial_relationships[attribute_name]
end

function _get_time_series_files(collection_name::String)
    collection = COLLECTION_DATABASE_MAP[collection_name]
    time_series_files = Vector{String}(undef, 0)
    for (name, _) in collection.time_series_files
        push!(time_series_files, name)
    end
    return time_series_files
end

function _table_where_attribute_is_located(collection_name::String, attribute_name::String)
    attribute = _get_attribute(collection_name, attribute_name)
    return attribute.table_where_is_located
end

function _type_of_attribute(collection_name::String, attribute_name::String)
    attribute = _get_attribute(collection_name, attribute_name)
    return attribute.type
end

function _attribute_composite_type(collection_name::String, attribute_name::String)
    attribute = _get_attribute(collection_name, attribute_name)
    return typeof(attribute)
end

function _string_for_composite_types(composite_type::Type)
    if composite_type <: ScalarParameter
        return "scalar parameter"
    elseif composite_type <: ScalarRelationship
        return "scalar relationship"
    elseif composite_type <: VectorialParameter
        return "vectorial parameter"
    elseif composite_type <: VectorialRelationship
        return "vectorial relationship"
    elseif composite_type <: TimeSeriesFile
        return "time series file"
    else
        error("Something went wrong. Unknown composite type: $composite_type")
    end
end

function _is_scalar_parameter(collection_name::String, attribute_name::String)
    collection = COLLECTION_DATABASE_MAP[collection_name]
    return haskey(collection.scalar_parameters, attribute_name)
end

function _is_scalar_relationship(collection_name::String, attribute_name::String)
    collection = COLLECTION_DATABASE_MAP[collection_name]
    return haskey(collection.scalar_relationships, attribute_name)
end

function _is_vectorial_parameter(collection_name::String, attribute_name::String)
    collection = COLLECTION_DATABASE_MAP[collection_name]
    return haskey(collection.vectorial_parameters, attribute_name)
end

function _is_vectorial_relationship(collection_name::String, attribute_name::String)
    collection = COLLECTION_DATABASE_MAP[collection_name]
    return haskey(collection.vectorial_relationships, attribute_name)
end

function _is_time_series_file(collection_name::String, attribute_name::String)
    collection = COLLECTION_DATABASE_MAP[collection_name]
    return haskey(collection.time_series_files, attribute_name)
end

function _map_of_groups_to_vector_attributes(collection_name::String)
    collection = COLLECTION_DATABASE_MAP[collection_name]
    groups = Set{String}()
    for (_, attribute) in collection.vectorial_parameters
        push!(groups, attribute.group)
    end
    for (_, attribute) in collection.vectorial_relationships
        push!(groups, attribute.group)
    end

    map_of_groups_to_vector_attributes = Dict{String, Vector{String}}()
    for group in groups
        map_of_groups_to_vector_attributes[group] = Vector{String}(undef, 0)
        for (_, attribute) in collection.vectorial_parameters
            if attribute.group == group
                push!(map_of_groups_to_vector_attributes[group], attribute.name)
            end
        end
        for (_, attribute) in collection.vectorial_relationships
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

function _is_collection_vectorial_table_name(name::String, collection_name::String)
    return occursin("$(collection_name)_vector_", name)
end

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

function _get_collection_scalar_attribute_tables(::SQLite.DB, collection_name::String)
    return collection_name
end

function _get_collection_vectorial_attributes_tables(db::SQLite.DB, collection_name::String)
    tables = SQLite.tables(db)
    vectorial_parameters_tables = Vector{String}(undef, 0)
    for table in tables
        table_name = table.name
        if _is_collection_vectorial_table_name(table_name, collection_name)
            push!(vectorial_parameters_tables, table_name)
        end
    end
    return vectorial_parameters_tables
end

function _get_relation_type_from_attribute(attribute_name::String)
    matches = match(r"_(.*)", attribute_name)
    return string(matches.captures[1])
end

function _get_collection_time_series_tables(::SQLite.DB, collection_name::String)
    return string(collection_name, "_timeseriesfiles")
end

function _name_of_vectorial_group(table_name::String)
    matches = match(r"_vector_(.*)", table_name)
    return string(matches.captures[1])
end

function _create_collections_database_map(db::SQLite.DB)
    database_definition = OrderedDict{String, Collection}()
    return _create_collections_database_map!(database_definition, db)
end
function _create_collections_database_map!(
    database_definition::OrderedDict{String, Collection},
    db::SQLite.DB,
)
    collection_names = _get_collection_names(db)
    for collection_name in collection_names
        scalar_parameters = _create_collection_scalar_parameters(db, collection_name)
        scalar_relationships = _create_collection_scalar_relationships(db, collection_name)
        vectorial_parameters = _create_collection_vectorial_parameters(db, collection_name)
        vectorial_relationships =
            _create_collection_vectorial_relationships(db, collection_name)
        time_series = _get_collection_time_series(db, collection_name)
        collection = Collection(
            collection_name,
            scalar_parameters,
            scalar_relationships,
            vectorial_parameters,
            vectorial_relationships,
            time_series,
        )
        _validate_collection(collection)
        database_definition[collection_name] = collection
    end
    return database_definition
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
            # and therefore it is a ScalarRelationship
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

function _create_collection_scalar_relationships(db::SQLite.DB, collection_name::String)
    scalar_attributes_table = _get_collection_scalar_attribute_tables(db, collection_name)
    df_foreign_keys_list = foreign_keys_list(db, scalar_attributes_table)
    df_table_infos = table_info(db, scalar_attributes_table)
    scalar_relationships = OrderedDict{String, ScalarRelationship}()
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
        if haskey(scalar_relationships, name)
            error("Duplicated scalar relationship $name in collection $collection_name")
        end
        scalar_relationships[name] = ScalarRelationship(
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
    return scalar_relationships
end

function _create_collection_vectorial_parameters(db::SQLite.DB, collection_name::String)
    vectorial_attributes_tables =
        _get_collection_vectorial_attributes_tables(db, collection_name)
    vectorial_parameters = OrderedDict{String, VectorialParameter}()
    parent_collection = collection_name

    for table_name in vectorial_attributes_tables
        group = _name_of_vectorial_group(table_name)
        table_where_is_located = table_name
        df_table_infos = table_info(db, table_name)
        df_foreign_keys_list = foreign_keys_list(db, table_name)
        for vectorial_attribute in eachrow(df_table_infos)
            name = vectorial_attribute.name
            if name == "id" || name == "vector_index"
                # These are obligatory for every vector table
                # and have no point in being stored in the database definition.
                continue
            end
            if name in df_foreign_keys_list.from
                # This means that this attribute is a foreign key
                # and therefore it is a VectorialRelationship
                # not a VectorialParameter.
                continue
            end
            type = _sql_type_to_julia_type(name, vectorial_attribute.type)
            default_value = _get_default_value(type, vectorial_attribute.dflt_value)
            not_null = Bool(vectorial_attribute.notnull)
            if haskey(vectorial_parameters, name)
                error("Duplicated vectorial parameter $name in collection $collection_name")
            end
            vectorial_parameters[name] = VectorialParameter(
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
    return vectorial_parameters
end

function _create_collection_vectorial_relationships(db::SQLite.DB, collection_name::String)
    vectorial_attributes_tables =
        _get_collection_vectorial_attributes_tables(db, collection_name)
    vectorial_relationships = OrderedDict{String, VectorialRelationship}()
    parent_collection = collection_name
    for table_name in vectorial_attributes_tables
        group = _name_of_vectorial_group(table_name)
        table_where_is_located = table_name
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
            vectorial_relationships[name] = VectorialRelationship(
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
    return vectorial_relationships
end

function _get_collection_time_series(db::SQLite.DB, collection_name::String)
    time_series_table = _get_collection_time_series_tables(db, collection_name)
    time_series = OrderedDict{String, TimeSeriesFile}()
    df_table_infos = table_info(db, time_series_table)
    for time_series_id in eachrow(df_table_infos)
        name = time_series_id.name
        table_where_is_located = time_series_table
        time_series[name] = TimeSeriesFile(name, table_where_is_located)
    end
    return time_series
end

# validations
function _validate_collection(collection::Collection)
    num_errors = 0
    num_errors += _no_duplicated_attributes(collection)
    num_errors += _all_scalar_parameters_are_in_same_table(collection)
    num_errors += _relationships_do_not_have_null_constraints(collection)
    num_errors += _relationships_do_not_have_default_values(collection)
    if num_errors > 0
        error("Collection $(collection.name) has $num_errors definition errors.")
    end
    return nothing
end

function _no_duplicated_attributes(collection::Collection)
    num_errors = 0
    list_of_attributes = Vector{String}(undef, 0)
    for field in fieldnames(Collection)
        attributes = getfield(collection, field)
        if !isa(attributes, Vector{<:Attribute})
            continue
        end
        for attribute in attributes
            if attribute.name in list_of_attributes
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
    scalar_relationships = collection.scalar_relationships
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
    for (_, scalar_relationship) in scalar_relationships
        if scalar_relationship.table_where_is_located != table_where_first_islocated
            @error(
                "Scalar relationship $(scalar_relationship.name) in collection $(collection.name) is not in the same table as the other scalar parameters."
            )
            num_errors += 1
        end
    end
    return num_errors
end

function _relationships_do_not_have_null_constraints(collection::Collection)
    num_errors = 0
    scalar_relationships = collection.scalar_relationships
    vectorial_relationships = collection.vectorial_relationships
    for (_, scalar_relationship) in scalar_relationships
        if scalar_relationship.not_null
            @error(
                "Scalar relationship $(scalar_relationship.name) in collection $(collection.name) has a not null constraint. This is not allowed."
            )
            num_errors += 1
        end
    end
    for (_, vectorial_relationship) in vectorial_relationships
        if vectorial_relationship.not_null
            @error(
                "Vectorial relationship $(vectorial_relationship.name) in collection $(collection.name) has a not null constraint. This is not allowed."
            )
            num_errors += 1
        end
    end
    return num_errors
end

function _relationships_do_not_have_default_values(collection::Collection)
    num_errors = 0
    scalar_relationships = collection.scalar_relationships
    vectorial_relationships = collection.vectorial_relationships
    for (_, scalar_relationship) in scalar_relationships
        if !ismissing(scalar_relationship.default_value)
            @error(
                "Scalar relationship $(scalar_relationship.name) in collection $(collection.name) has a default value."
            )
            num_errors += 1
        end
    end
    for (_, vectorial_relationship) in vectorial_relationships
        if !ismissing(vectorial_relationship.default_value)
            @error(
                "Vectorial relationship $(vectorial_relationship.name) in collection $(collection.name) has a default value."
            )
            num_errors += 1
        end
    end
    return num_errors
end
