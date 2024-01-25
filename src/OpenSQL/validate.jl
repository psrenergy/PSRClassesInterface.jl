# just for reference this are the main regexes
# the functions not commented implement combinations of them
# with other reserved words such as vector, relation and timeseries.
# _regex_table_name() = Regex("(?:[A-Z][a-z]*)+")
# _regex_column_name() = Regex("[a-z][a-z0-9]*(?:_{1}[a-z0-9]+)*")

_is_valid_table_name(table::String) =
    !isnothing(match(r"^(?:[A-Z][a-z]*)+$", table))

_is_valid_column_name(column::String) =
    !isnothing(match(r"^[a-z][a-z0-9]*(?:_{1}[a-z0-9]+)*$", column))

_is_valid_table_vector_name(table::String) =
    !isnothing(
        match(
            r"^(?:[A-Z][a-z]*)+_vector_[a-z][a-z0-9]*(?:_{1}[a-z0-9]+)*$",
            table,
        ),
    )

_is_valid_table_timeseries_name(table::String) =
    !isnothing(match(r"^(?:[A-Z][a-z]*)+_timeseriesfiles", table))

_is_valid_time_series_attribute_value(value::String) =
    !isnothing(
        match(r"^[a-zA-Z][a-zA-Z0-9]*(?:_{1}[a-zA-Z0-9]+)*(?:\.[a-z]+){0,1}$", value),
    )

function _validate_time_series_attribute_value(value::String)
    if !_is_valid_time_series_attribute_value(value)
        error(
            """
            Invalid time series file name: $value. 
            The valid time series attribute name format is:
            - name_of_attribute123
            - name_of_attribute.extension
            It must be the name of the file, not the path.
            """,
        )
    end
end

function _validate_table(db::SQLite.DB, table::String)
    attributes = column_names(db, table)
    if !("id" in attributes)
        error("Table $table does not have an \"id\" column.")
    end
    for attribute in attributes
        _validate_column_name(table, attribute)
    end
end

function _validate_timeseries_table(db::SQLite.DB, table::String)
    attributes = column_names(db, table)
    if ("id" in attributes)
        error("Table $table should not have an \"id\" column.")
    end
    for attribute in attributes
        _validate_column_name(table, attribute)
    end
end

function _validate_vector_table(db::SQLite.DB, table::String)
    attributes = column_names(db, table)
    if !("id" in attributes)
        error("Table $table is a vector table and does not have an \"id\" column.")
    end
    if !("vector_index" in attributes)
        error("Table $table is a vector table and does not have an \"vector_index\" column.")
    end
end

function _validate_column_name(column::String)
    if !_is_valid_column_name(column)
        error("""
            Invalid column name: $column. \nThe valid column name format is: \n
            - name_of_attribute (may contain numerals but must start with a letter)
            """)
    end
end

function _validate_column_name(table::String, column::String)
    if !_is_valid_column_name(column)
        error(
            """
          Invalid column name: $column for table $table. \nThe valid column name format is: \n
          - name_of_attribute (may contain numerals but must start with a letter)
          """,
        )
    end
end

function _validate_database(db::SQLite.DB)
    tables = table_names(db)
    if !("Configuration" in tables)
        error("Database does not have a \"Configuration\" table.")
    end
    _validate_database_pragmas(db)
    _set_default_pragmas!(db)
    for table in tables
        if table == "sqlite_sequence"
            continue
        end
        if _is_valid_table_name(table)
            _validate_table(db, table)
        elseif _is_valid_table_timeseries_name(table)
            _validate_timeseries_table(db, table)
        elseif _is_valid_table_vector_name(table)
            _validate_vector_table(db, table)
        else
            error("""
                Invalid table name: $table.
                Valid table name formats are:
                - Collections: NameOfCollection
                - Vector attributes: NameOfCollection_vector_group_id
                - Time series: NameOfCollection_timeseries
                """)
        end
    end
end

function _get_correct_method_to_use(correct_composite_type::Type, action::Symbol)
    if action == :read
        for (key, value) in READ_METHODS_BY_CLASS_OF_ATTRIBUTE
            if correct_composite_type <: key 
                return value
            end
        end
    elseif action == :update
        for (key, value) in UPDATE_METHODS_BY_CLASS_OF_ATTRIBUTE
            if correct_composite_type <: key 
                return value
            end
        end
    else
        error()
    end
end

function _throw_if_attribute_is_not_scalar_parameter(
    opensql_db::OpenSQLDataBase,
    collection::String,
    attribute::String,
    action::Symbol,
)
    _throw_if_collection_or_attribute_do_not_exist(opensql_db, collection, attribute)

    if !_is_scalar_parameter(opensql_db, collection, attribute)
        correct_composity_type = _attribute_composite_type(opensql_db, collection, attribute)
        string_of_composite_types = _string_for_composite_types(correct_composity_type)
        correct_method_to_use = _get_correct_method_to_use(correct_composity_type, action)
        error("Attribute \"$attribute\" is not a scalar parameter. It is a $string_of_composite_types. Use `$correct_method_to_use` instead.")
    end
    return nothing
end

function _throw_if_attribute_is_not_vector_parameter(
    opensql_db::OpenSQLDataBase,
    collection::String,
    attribute::String,
    action::Symbol,
)
    _throw_if_collection_or_attribute_do_not_exist(opensql_db, collection, attribute)

    if !_is_vector_parameter(opensql_db, collection, attribute)
        correct_composity_type = _attribute_composite_type(opensql_db, collection, attribute)
        string_of_composite_types = _string_for_composite_types(correct_composity_type)
        correct_method_to_use = _get_correct_method_to_use(correct_composity_type, action)
        error("Attribute \"$attribute\" is not a vector parameter. It is a $string_of_composite_types. Use `$correct_method_to_use` instead.")
    end
    return nothing
end

function _throw_if_attribute_is_not_scalar_relation(
    opensql_db::OpenSQLDataBase,
    collection::String, 
    attribute::String,
    action::Symbol,
)
    _throw_if_collection_or_attribute_do_not_exist(opensql_db, collection, attribute)

    if !_is_scalar_relation(opensql_db, collection, attribute)
        correct_composity_type = _attribute_composite_type(opensql_db, collection, attribute)
        string_of_composite_types = _string_for_composite_types(correct_composity_type)
        correct_method_to_use = _get_correct_method_to_use(correct_composity_type, action)
        error("Attribute \"$attribute\" is not a scalar relation. It is a $string_of_composite_types. Use `$correct_method_to_use` instead.")
    end
    return nothing
end

function _throw_if_attribute_is_not_vector_relation(
    opensql_db::OpenSQLDataBase,
    collection::String, 
    attribute::String,
    action::Symbol,
)
    _throw_if_collection_or_attribute_do_not_exist(opensql_db, collection, attribute)

    if !_is_vector_relation(opensql_db, collection, attribute)
        correct_composity_type = _attribute_composite_type(opensql_db, collection, attribute)
        string_of_composite_types = _string_for_composite_types(correct_composity_type)
        correct_method_to_use = _get_correct_method_to_use(correct_composity_type, action)
        error("Attribute \"$attribute\" is not a vector relation. It is a $string_of_composite_types. Use `$correct_method_to_use` instead.")
    end
    return nothing
end

function _throw_if_attribute_is_not_time_series_file(
    opensql_db::OpenSQLDataBase,
    collection::String, 
    attribute::String,
    action::Symbol,
)
    _throw_if_collection_or_attribute_do_not_exist(opensql_db, collection, attribute)

    if !_is_time_series_file(opensql_db, collection, attribute)
        correct_composity_type = _attribute_composite_type(opensql_db, collection, attribute)
        string_of_composite_types = _string_for_composite_types(correct_composity_type)
        correct_method_to_use = _get_correct_method_to_use(correct_composity_type, action)
        error("Attribute \"$attribute\" is not a time series file. It is a $string_of_composite_types. Use `$correct_method_to_use` instead.")
    end
    return nothing
end

function _throw_if_not_scalar_attribute(
    opensql_db::OpenSQLDataBase,
    collection::String, 
    attribute::String,
)
    _throw_if_collection_or_attribute_do_not_exist(opensql_db, collection, attribute)

    if _is_vector_parameter(opensql_db, collection, attribute) || _is_vector_relation(opensql_db, collection, attribute)
       error("Attribute \"$attribute\" is not a scalar attribute. You must input a vector for this attribute.")
    end

    return nothing
end

function _throw_if_not_vector_attribute(
    opensql_db::OpenSQLDataBase,
    collection::String, 
    attribute::String,
)
    _throw_if_collection_or_attribute_do_not_exist(opensql_db, collection, attribute)

    if _is_scalar_parameter(opensql_db, collection, attribute) || _is_scalar_relation(opensql_db, collection, attribute)
       error("Attribute \"$attribute\" is not a vector attribute. You must input a scalar for this attribute.")
    end

    return nothing
end

function _throw_if_relation_does_not_exist(
    collection_from::String,
    collection_to::String,
    relation_type::String
)
    if !_scalar_relation_exists(collection_from, collection_to, relation_type) && !_vector_relation_exists(collection_from, collection_to, relation_type)
        error(
            "relation `$relation_type` between $collection_from and $collection_to does not exist. \n" * 
            "This is the list of relations that exist: " *
            "$(_show_existing_relation_types(_list_of_relation_types(collection_from, collection_to)))"
        )
    end
end

function _throw_if_is_time_series_file(
    opensql_db::OpenSQLDataBase,
    collection::String,
    attribute::String,
)
    if _is_time_series_file(opensql_db, collection, attribute)
        error(
            "Attribute \"$attribute\" is a time series file. " *
            "You must use the function `set_time_series_file!` to create it."
        )
    end
    return nothing
end

function _show_existing_relation_types(possible_relation_types::Vector{String})
    string_relation_types = ""
    for relation_type in possible_relation_types
        string_relation_types *= "\n - $relation_type"
    end
    if string_relation_types == ""
        string_relation_types = "\n**no relations exist between the collections**"
    end
    return string_relation_types
end

function _validate_attribute_types!(
    opensql_db::OpenSQLDataBase,
    collection_name::String,
    label_or_id::Union{Integer, String},
    dict_scalar_attributes,
    dict_vector_attributes,
)
    for (key, value) in dict_scalar_attributes
        attribute = _get_attribute(opensql_db, collection_name, string(key))
        if isa(attribute, ScalarRelation)
            _validate_scalar_relation_type(attribute, label_or_id, value)
        else
            _validate_scalar_parameter_type(attribute, label_or_id, value)
        end
    end
    for (key, value) in dict_vector_attributes
        attribute = _get_attribute(opensql_db, collection_name, string(key))
        if isa(attribute, VectorRelation) 
            _validate_vector_relation_type(attribute, label_or_id, value)
        else
            _validate_vector_parameter_type(attribute, label_or_id, value)
        end
    end
    return nothing
end

function _validate_scalar_parameter_type(
    attribute::ScalarParameter,
    label_or_id::Union{Integer, String},
    value,
)
    if !isa(value, attribute.type)
        error(
            "The value of the attribute \"$(attribute.name)\" in element \"$label_or_id\" " *
            "of collection \"$(attribute.parent_collection)\" should be of type $(attribute.type). User inputed $(typeof(value)): $value."
        )
    end
end

function _validate_scalar_relation_type(
    attribute::ScalarRelation,
    label_or_id::Union{Integer, String},
    value
)
    if !isa(value, String) && !isa(value, Int64)
        error(
            "The value of the attribute \"$(attribute.name)\" in element \"$label_or_id\" " *
            "of collection \"$(attribute.parent_collection)\" should be of type String or Int64. User inputed $(typeof(value)): $value."
        )
    end
end

function _validate_vector_parameter_type(
    attribute::VectorParameter,
    label_or_id::Union{Integer, String},
    values::Vector{<:Any},
)
    if !isa(values, Vector{attribute.type})
        error(
            "The value of the attribute \"$(attribute.name)\" in element \"$label_or_id\" " *
            "of collection \"$(attribute.parent_collection)\" should be of type Vector{$(attribute.type)}. User inputed $(typeof(values)): $values."
        )
    end
end

function _validate_vector_relation_type(
    attribute::VectorRelation,
    label_or_id::Union{Integer, String},
    values::Vector{<:Any},
)
    if !isa(values, Vector{String}) && !isa(values, Vector{Int64})
        error(
            "The value of the attribute \"$(attribute.name)\" in element \"$label_or_id\" " *
            "of collection \"$(attribute.parent_collection)\" should be of type Vector{String} or Vector{Int64}. User inputed $(typeof(values)): $values."
        )
    end
end

function _set_default_pragmas!(db::SQLite.DB)
    _set_foreign_keys_on!(db)
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

function _validate_database_pragmas(db::SQLite.DB)
    _validate_user_version(db)
    return nothing
end

function _validate_user_version(db::SQLite.DB)
    df = DBInterface.execute(db, "PRAGMA user_version;") |> DataFrame
    if df[!, 1][1] == 0
        error(
            "User version not defined or set to zero in the database. Please add 'PRAGMA user_version = \"your version\";' to your .sql file.",
        )
    end
    return nothing
end

function _throw_if_collection_or_attribute_do_not_exist(
    opensql_db::OpenSQLDataBase, 
    collection_name::String, 
    attribute_name::String
)
    _throw_if_collection_does_not_exist(opensql_db, collection_name)
    _throw_if_attribute_does_not_exist(opensql_db, collection_name, attribute_name)
    return nothing
end

function _throw_if_collection_or_attribute_do_not_exist(
    opensql_db::OpenSQLDataBase, 
    collection_name::String, 
    attribute_names::Vector{String}
)
    _throw_if_collection_does_not_exist(opensql_db, collection_name)
    for attribute_name in attribute_names
        _throw_if_attribute_does_not_exist(opensql_db, collection_name, attribute_name)
    end
    return nothing
end

function _throw_if_collection_does_not_exist(
    opensql_db::OpenSQLDataBase, 
    collection_name::String,
)
    if !_collection_exists(opensql_db, collection_name)
        error(
            "Collection \"$collection_name\" does not exist. "* 
            "This is the list of available collections: " *
            "$(_string_of_collections(opensql_db))"
        )
    end
end

function _throw_if_attribute_does_not_exist(
    opensql_db::OpenSQLDataBase, 
    collection_name::String, 
    attribute_name::String
)
    if !_attribute_exists(opensql_db, collection_name, attribute_name)
        error(
            "Attribute \"$attribute_name\" does not exist in collection \"$collection_name\". " *
            "This is the list of available attributes: $(_string_of_attributes(opensql_db, collection_name))"
        )
    end
end

function _string_of_collections(opensql_db::OpenSQLDataBase)
    string_of_collections = ""
    for collection in _get_collection_names(opensql_db)
        string_of_collections *= "\n - $collection"
    end
    return string_of_collections
end
function _string_of_attributes(
    opensql_db::OpenSQLDataBase,
    collection_name::String
)
    attribute_names = _get_attribute_names(opensql_db, collection_name)
    string_of_attributes_names = ""
    for attribute_name in attribute_names
        string_of_attributes_names *= "\n - $attribute_name"
    end
    return string_of_attributes_names
end