"""
    Attribute

Abstract type for attributes, the building blocks of collections.
"""
abstract type Attribute end

abstract type ScalarAttribute <: Attribute end
abstract type VectorialAttribute <: Attribute end

# TODO remove {T}
mutable struct ScalarParameter{T} <: ScalarAttribute
    name::String
    type::Type{T}
    parent_collection::String
    table_where_is_located::String
end

mutable struct ScalarRelationship <: ScalarAttribute
    name::String
    parent_collection::String
    relation_collection::String
    table_where_is_located::String
end

# TODO remove {T}
mutable struct VectorialParameter{T} <: VectorialAttribute
    name::String
    type::Type{T}
    # Some vectors must have the same size per definition. 
    # These vectors should be grouped together.
    group::String
    parent_collection::String
    table_where_is_located::String
end

mutable struct VectorialRelationship <: VectorialAttribute
    name::String
    # Some vectors must have the same size per definition. 
    # These vectors should be grouped together.
    group::String
    parent_collection::String
    relation_collection::String
    table_where_is_located::String
end

mutable struct TimeSeriesIds <: ScalarAttribute
    name::String
    table_where_is_located::String
end

"""
    Collection

This struct stores the definition of a collection
"""
mutable struct Collection
    name::String
    scalar_parameters::Vector{ScalarParameter}
    scalar_relationships::Vector{ScalarRelationship}
    vectorial_parameters::Vector{VectorialParameter}
    vectorial_relationships::Vector{VectorialRelationship}
    time_series::Vector{TimeSeriesIds}
end

# Dictionary storing the collections map for the database
const COLLECTION_DATABASE_MAP = OrderedDict{String, Collection}()

function _save_collections_database_map(db::SQLite.DB)
    _create_collections_database_map!(COLLECTION_DATABASE_MAP, db)
    _no_circular_references(COLLECTION_DATABASE_MAP)
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
    end
    return false
end

function _field_of_attribute(collection_name::String, attribute_name::String)
    if _is_scalar_parameter(collection_name, attribute_name)
        return :scalar_parameters
    elseif _is_scalar_relationship(collection_name, attribute_name)
        return :scalar_relationships
    elseif _is_vectorial_parameter(collection_name, attribute_name)
        return :vectorial_parameters
    elseif _is_vectorial_relationship(collection_name, attribute_name)
        return :vectorial_relationships
    else
        error("Attribute $attribute_name in collection $collection_name does not exist.")
    end
end

function _table_where_attribute_is_located(collection_name::String, attribute_name::String)
    field_name = _field_of_attribute(collection_name, attribute_name)
    collection = COLLECTION_DATABASE_MAP[collection_name]
    for attribute in getfield(collection, field_name)
        if attribute.name == attribute_name
            return attribute.table_where_is_located
        end
    end
end

function _attribute_composite_type(collection_name::String, attribute_name::String)
    if _is_scalar_parameter(collection_name, attribute_name)
        return ScalarParameter
    elseif _is_scalar_relationship(collection_name, attribute_name)
        return ScalarRelationship
    elseif _is_vectorial_parameter(collection_name, attribute_name)
        return VectorialParameter
    elseif _is_vectorial_relationship(collection_name, attribute_name)
        return VectorialRelationship
    else
        error("Something went wrong.")
    end
end

function _string_for_composite_types(composite_type::Type)
    if composite_type == ScalarParameter
        return "scalar parameter"
    elseif composite_type == ScalarRelationship
        return "scalar relationship"
    elseif composite_type == VectorialParameter
        return "vectorial parameter"
    elseif composite_type == VectorialRelationship
        return "vectorial relationship"
    else
        error("Something went wrong. Unknown composite type: $composite_type")
    end
end

function _is_scalar_parameter(collection_name::String, attribute_name::String)
    collection = COLLECTION_DATABASE_MAP[collection_name]
    for attribute in collection.scalar_parameters
        if attribute.name == attribute_name
            return true
        end
    end
    return false
end

function _is_scalar_relationship(collection_name::String, attribute_name::String)
    collection = COLLECTION_DATABASE_MAP[collection_name]
    for attribute in collection.scalar_relationships
        if attribute.name == attribute_name
            return true
        end
    end
    return false
end

function _is_vectorial_parameter(collection_name::String, attribute_name::String)
    collection = COLLECTION_DATABASE_MAP[collection_name]
    for attribute in collection.vectorial_parameters
        if attribute.name == attribute_name
            return true
        end
    end
    return false
end

function _is_vectorial_relationship(collection_name::String, attribute_name::String)
    collection = COLLECTION_DATABASE_MAP[collection_name]
    for attribute in collection.vectorial_relationships
        if attribute.name == attribute_name
            return true
        end
    end
    return false
end

function _map_of_groups_to_vector_attributes(collection_name::String)
    collection = COLLECTION_DATABASE_MAP[collection_name]
    groups = Set{String}()
    for attribute in collection.vectorial_parameters
        push!(groups, attribute.group)
    end
    for attribute in collection.vectorial_relationships
        push!(groups, attribute.group)
    end

    map_of_groups_to_vector_attributes = Dict{String, Vector{String}}()
    for group in groups
        map_of_groups_to_vector_attributes[group] = Vector{String}(undef, 0)
        for attribute in collection.vectorial_parameters
            if attribute.group == group
                push!(map_of_groups_to_vector_attributes[group], attribute.name)
            end
        end
        for attribute in collection.vectorial_relationships
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

function _is_collection_tables_name(name::String, collection_name::String)
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
        if _is_collection_tables_name(table_name, collection_name)
            push!(vectorial_parameters_tables, table_name)
        end
    end
    return vectorial_parameters_tables
end

function _name_of_vectorial_group(table_name::String)
    matches = match(r"_vector_(.*)", table_name)
    return string(matches.captures[1])
end

function _create_collections_database_map(db::SQLite.DB)
    database_definition = OrderedDict{String, Collection}()
    return _create_collections_database_map!(database_definition, db)
end
function _create_collections_database_map!(database_definition::OrderedDict{String, Collection}, db::SQLite.DB)
    collection_names = _get_collection_names(db)
    for collection_name in collection_names
        scalar_parameters = _get_collection_scalar_parameters(db, collection_name)
        scalar_relationships = _get_collection_scalar_relationships(db, collection_name)
        vectorial_parameters = _get_collection_vectorial_parameters(db, collection_name)
        vectorial_relationships = _get_collection_vectorial_relationships(db, collection_name)
        time_series = _get_collection_time_series(db, collection_name)
        collection = Collection(
            collection_name,
            scalar_parameters,
            scalar_relationships,
            vectorial_parameters,
            vectorial_relationships,
            time_series,
        )
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

function _sql_type_to_julia_type(sql_type::String)
    if sql_type == "INTEGER"
        return Int
    elseif sql_type == "REAL"
        return Float64
    elseif sql_type == "TEXT"
        return String
    elseif sql_type == "BLOB"
        return Vector{UInt8}
    else
        error("Unknown SQL type: $sql_type")
    end
end

function _warn_if_foreign_keys_does_not_cascade(collection_name::String, foreign_key::DataFrameRow)
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

function _get_collection_scalar_parameters(db::SQLite.DB, collection_name::String)
    scalar_attributes_table = _get_collection_scalar_attribute_tables(db, collection_name)
    df_table_infos = table_info(db, scalar_attributes_table)
    df_foreign_keys_list = foreign_keys_list(db, scalar_attributes_table)
    scalar_parameters = Vector{ScalarParameter}(undef, 0)
    for scalar_attribute in eachrow(df_table_infos)
        name = scalar_attribute.name
        if name in df_foreign_keys_list.from
            # This means that this attribute is a foreign key
            # and therefore it is a ScalarRelationship
            # not a ScalarParameter.
            continue
        end
        type = _sql_type_to_julia_type(scalar_attribute.type)
        parent_collection = collection_name
        table_where_is_located = scalar_attributes_table
        scalar_parameter = ScalarParameter(
            name, 
            type, 
            parent_collection, 
            table_where_is_located
        )
        push!(scalar_parameters, scalar_parameter)
    end
    return scalar_parameters
end

function _get_collection_scalar_relationships(db::SQLite.DB, collection_name::String)
    scalar_attributes_table = _get_collection_scalar_attribute_tables(db, collection_name)
    df_foreign_keys_list = foreign_keys_list(db, scalar_attributes_table)
    scalar_relationships = Vector{ScalarRelationship}(undef, 0)
    for foreign_key in eachrow(df_foreign_keys_list)
        _warn_if_foreign_keys_does_not_cascade(collection_name, foreign_key)
        name = foreign_key.from
        parent_collection = collection_name
        relation_collection = foreign_key.table
        table_where_is_located = scalar_attributes_table
        scalar_relationship = ScalarRelationship(
            name, 
            parent_collection, 
            relation_collection,
            table_where_is_located
        )
        push!(scalar_relationships, scalar_relationship)
    end
    return scalar_relationships
end

function _get_collection_vectorial_parameters(db::SQLite.DB, collection_name::String)
    vectorial_attributes_tables = _get_collection_vectorial_attributes_tables(db, collection_name)
    vectorial_parameters = Vector{VectorialParameter}(undef, 0)
    parent_collection = collection_name

    for table_name in vectorial_attributes_tables
        group = _name_of_vectorial_group(table_name)
        table_where_is_located = table_name
        df_table_infos = table_info(db, table_name)
        df_foreign_keys_list = foreign_keys_list(db, table_name)
        for vectorial_attribute in eachrow(df_table_infos)
            name = vectorial_attribute.name
            if name == "id" || name == "idx"
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
            type = _sql_type_to_julia_type(vectorial_attribute.type)
            push!(
                vectorial_parameters, 
                VectorialParameter(
                    name, 
                    type, 
                    group, 
                    parent_collection, 
                    table_where_is_located
                )
            )
        end
    end
    return vectorial_parameters
end

function _get_collection_vectorial_relationships(db::SQLite.DB, collection_name::String)
    vectorial_attributes_tables = _get_collection_vectorial_attributes_tables(db, collection_name)
    vectorial_relationships = Vector{VectorialRelationship}(undef, 0)
    parent_collection = collection_name
    for table_name in vectorial_attributes_tables
        group = _name_of_vectorial_group(table_name)
        table_where_is_located = table_name
        df_foreign_keys_list = foreign_keys_list(db, table_name)
        for foreign_key in eachrow(df_foreign_keys_list)
            _warn_if_foreign_keys_does_not_cascade(collection_name, foreign_key)
            name = foreign_key.from
            if name == "id"
                # This is obligatory for every vector table.
                continue
            end
            relation_collection = foreign_key.table
            table_where_is_located = table_name
            push!(
                vectorial_relationships, 
                VectorialRelationship(
                    name,
                    group,
                    parent_collection,
                    relation_collection,
                    table_where_is_located
                )
            )
        end
    end
    return vectorial_relationships
end

function _get_collection_time_series(db::SQLite.DB, collection_name::String)
    # TODO
    time_series = Vector{TimeSeriesIds}(undef, 0)
    return time_series
end

# validations
function _validate_collection(collection::Collection)
    num_errors = 0
    num_errors += _no_duplicated_attributes(collection)
    num_errors += _all_scalar_parameters_are_in_same_table(collection)
    if num_errors > 0
        error("Collection $(collection.name) has $num_errors definition errors.")
    end
    return nothing
end

function _no_duplicated_attributes(collection::Collection)
    num_errors = 0
    list_of_attributes = Vector{String}(undef, 0)
    for field in fieldnames(collection)
        for attribute in getfield(collection, field)
            if attribute.name in list_of_attributes
                @error("Duplicated attribute $(attribute.name) in collection $(collection.name)")
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
    table_where_first_islocated = scalar_parameters[1].table_where_is_located
    for scalar_parameter in scalar_parameters
        if scalar_parameter.table_where_is_located != table_where_first_islocated
            @error("Scalar parameter $(scalar_parameter.name) in collection $(collection.name) is not in the same table as the other scalar parameters.")
            num_errors += 1
        end
    end
    for scalar_relationship in scalar_relationships
        if scalar_relationship.table_where_is_located != table_where_first_islocated
            @error("Scalar relationship $(scalar_relationship.name) in collection $(collection.name) is not in the same table as the other scalar parameters.")
            num_errors += 1
        end
    end
    return num_errors
end

function _no_circular_references(map_of_collections::OrderedDict{String, Collection})
    # TODO
    # Build a directed graph of relations and check for cycles
    return nothing
end