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

_is_valid_time_series_name(table::String) =
    !isnothing(
        match(
            r"^(?:[A-Z][a-z]*)+_timeseries_[a-z][a-z0-9]*(?:_{1}[a-z0-9]+)*$",
            table,
        ),
    )

_is_valid_table_timeseriesfiles_name(table::String) =
    !isnothing(match(r"^(?:[A-Z][a-z]*)+_timeseriesfiles", table))

_is_valid_time_series_attribute_value(value::String) =
    !isnothing(
        match(r"^[a-zA-Z][a-zA-Z0-9]*(?:_{1}[a-zA-Z0-9]+)*(?:\.[a-z]+){0,1}$", value),
    )

function _validate_time_series_attribute_value(value::String)
    if !_is_valid_time_series_attribute_value(value)
        psr_database_sqlite_error(
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
    num_errors = 0
    if !("id" in attributes)
        @error("Table $table does not have an \"id\" column.")
        num_errors += 1
    end
    if ("label" in attributes)
        if !_is_column_unique(db, table, "label")
            @error("Table $table has a non-unique \"label\" column.")
            num_errors += 1
        end
        if !_is_column_not_null(db, table, "label")
            @error("Table $table has a nullable \"label\" column.")
            num_errors += 1
        end
        if !_check_column_type(db, table, "label", "TEXT")
            @error("Table $table has a non-text \"label\" column.")
            num_errors += 1
        end
    end
    for attribute in attributes
        num_errors += _validate_column_name(table, attribute)
    end
    return num_errors
end

function _validate_timeseries_table(db::SQLite.DB, table::String)
    attributes = column_names(db, table)
    num_errors = 0
    if !("id" in attributes)
        @error("Table $table is a timeseries table and does not have an \"id\" column.")
        num_errors += 1
    end
    if !("date_time" in attributes)
        @error(
            "Table $table is a timeseries table and does not have an \"date_time\" column.",
        )
        num_errors += 1
    end
    return num_errors
end

function _validate_timeseriesfiles_table(db::SQLite.DB, table::String)
    attributes = column_names(db, table)
    num_errors = 0
    if ("id" in attributes)
        @error("Table $table should not have an \"id\" column.")
        num_errors += 1
    end
    for attribute in attributes
        num_errors += _validate_column_name(table, attribute)
    end
    return num_errors
end

function _validate_vector_table(db::SQLite.DB, table::String)
    attributes = column_names(db, table)
    num_errors = 0
    if !("id" in attributes)
        @error("Table $table is a vector table and does not have an \"id\" column.")
        num_errors += 1
    end
    if !("vector_index" in attributes)
        @error(
            "Table $table is a vector table and does not have an \"vector_index\" column.",
        )
        num_errors += 1
    end
    return num_errors
end

function _validate_column_name(table::String, column::String)
    num_errors = 0
    if !_is_valid_column_name(column)
        @error(
            """
          Invalid column name: $column for table $table. \nThe valid column name format is: \n
          - name_of_attribute (may contain numerals but must start with a letter)
          """,
        )
        num_errors += 1
    end
    return num_errors
end

function _validate_database(db::SQLite.DB)
    tables = table_names(db)
    if !("Configuration" in tables)
        psr_database_sqlite_error("Database does not have a \"Configuration\" table.")
    end
    _validate_database_pragmas(db)
    _set_default_pragmas!(db)
    num_errors = 0
    for table in tables
        if table == "sqlite_sequence"
            continue
        end
        if _is_valid_table_name(table)
            num_errors += _validate_table(db, table)
        elseif _is_valid_table_timeseriesfiles_name(table)
            num_errors += _validate_timeseriesfiles_table(db, table)
        elseif _is_valid_time_series_name(table)
            num_errors += _validate_timeseries_table(db, table)
        elseif _is_valid_table_vector_name(table)
            num_errors += _validate_vector_table(db, table)
        else
            @error("""
                Invalid table name: $table.
                Valid table name formats are:
                - Collections: NameOfCollection
                - Vector attributes: NameOfCollection_vector_group_id
                - Time series: NameOfCollection_timeseries_group_id
                - Time series files: NameOfCollection_timeseriesfiles
                """)
            num_errors += 1
        end
    end
    if num_errors > 0
        psr_database_sqlite_error(
            "Database has $num_errors errors. Please fix them before continuing.",
        )
    end
    return nothing
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
        psr_database_sqlite_error("Invalid action: $action")
    end
end

function _throw_if_attribute_is_not_scalar_parameter(
    db::DatabaseSQLite,
    collection::String,
    attribute::String,
    action::Symbol,
)
    _throw_if_collection_or_attribute_do_not_exist(db, collection, attribute)

    if !_is_scalar_parameter(db, collection, attribute)
        correct_composity_type =
            _attribute_composite_type(db, collection, attribute)
        string_of_composite_types = _string_for_composite_types(correct_composity_type)
        correct_method_to_use = _get_correct_method_to_use(correct_composity_type, action)
        psr_database_sqlite_error(
            "Attribute \"$attribute\" is not a scalar parameter. It is a $string_of_composite_types. Use `$correct_method_to_use` instead.",
        )
    end
    return nothing
end

function _throw_if_attribute_is_not_vector_parameter(
    db::DatabaseSQLite,
    collection::String,
    attribute::String,
    action::Symbol,
)
    _throw_if_collection_or_attribute_do_not_exist(db, collection, attribute)

    if !_is_vector_parameter(db, collection, attribute)
        correct_composity_type =
            _attribute_composite_type(db, collection, attribute)
        string_of_composite_types = _string_for_composite_types(correct_composity_type)
        correct_method_to_use = _get_correct_method_to_use(correct_composity_type, action)
        psr_database_sqlite_error(
            "Attribute \"$attribute\" is not a vector parameter. It is a $string_of_composite_types. Use `$correct_method_to_use` instead.",
        )
    end
    return nothing
end

function _throw_if_attribute_is_not_scalar_relation(
    db::DatabaseSQLite,
    collection::String,
    attribute::String,
    action::Symbol,
)
    _throw_if_collection_or_attribute_do_not_exist(db, collection, attribute)

    if !_is_scalar_relation(db, collection, attribute)
        correct_composity_type =
            _attribute_composite_type(db, collection, attribute)
        string_of_composite_types = _string_for_composite_types(correct_composity_type)
        correct_method_to_use = _get_correct_method_to_use(correct_composity_type, action)
        psr_database_sqlite_error(
            "Attribute \"$attribute\" is not a scalar relation. It is a $string_of_composite_types. Use `$correct_method_to_use` instead.",
        )
    end
    return nothing
end

function _throw_if_attribute_is_not_vector_relation(
    db::DatabaseSQLite,
    collection::String,
    attribute::String,
    action::Symbol,
)
    _throw_if_collection_or_attribute_do_not_exist(db, collection, attribute)

    if !_is_vector_relation(db, collection, attribute)
        correct_composity_type =
            _attribute_composite_type(db, collection, attribute)
        string_of_composite_types = _string_for_composite_types(correct_composity_type)
        correct_method_to_use = _get_correct_method_to_use(correct_composity_type, action)
        psr_database_sqlite_error(
            "Attribute \"$attribute\" is not a vector relation. It is a $string_of_composite_types. Use `$correct_method_to_use` instead.",
        )
    end
    return nothing
end

function _throw_if_attribute_is_not_time_series(
    db::DatabaseSQLite,
    collection::String,
    attribute::String,
    action::Symbol,
)
    _throw_if_collection_or_attribute_do_not_exist(db, collection, attribute)

    if !_is_time_series(db, collection, attribute)
        correct_composity_type =
            _attribute_composite_type(db, collection, attribute)
        string_of_composite_types = _string_for_composite_types(correct_composity_type)
        correct_method_to_use = _get_correct_method_to_use(correct_composity_type, action)
        psr_database_sqlite_error(
            "Attribute \"$attribute\" is not a time series. It is a $string_of_composite_types. Use `$correct_method_to_use` instead.",
        )
    end
    return nothing

end

function _throw_if_attribute_is_not_time_series_file(
    db::DatabaseSQLite,
    collection::String,
    attribute::String,
    action::Symbol,
)
    _throw_if_collection_or_attribute_do_not_exist(db, collection, attribute)

    if !_is_time_series_file(db, collection, attribute)
        correct_composity_type =
            _attribute_composite_type(db, collection, attribute)
        string_of_composite_types = _string_for_composite_types(correct_composity_type)
        correct_method_to_use = _get_correct_method_to_use(correct_composity_type, action)
        psr_database_sqlite_error(
            "Attribute \"$attribute\" is not a time series file. It is a $string_of_composite_types. Use `$correct_method_to_use` instead.",
        )
    end
    return nothing
end

function _throw_if_not_scalar_attribute(
    db::DatabaseSQLite,
    collection::String,
    attribute::String,
)
    _throw_if_collection_or_attribute_do_not_exist(db, collection, attribute)

    if _is_vector_parameter(db, collection, attribute) ||
       _is_vector_relation(db, collection, attribute)
        psr_database_sqlite_error(
            "Attribute \"$attribute\" is not a scalar attribute. You must input a vector for this attribute.",
        )
    end

    return nothing
end

function _throw_if_not_vector_attribute(
    db::DatabaseSQLite,
    collection::String,
    attribute::String,
)
    _throw_if_collection_or_attribute_do_not_exist(db, collection, attribute)

    if _is_scalar_parameter(db, collection, attribute) ||
       _is_scalar_relation(db, collection, attribute)
        psr_database_sqlite_error(
            "Attribute \"$attribute\" is not a vector attribute. You must input a scalar for this attribute.",
        )
    end

    return nothing
end

function _throw_if_not_timeseries_group(
    db::DatabaseSQLite,
    collection::String,
    group::String,
)
    if !_is_timeseries_group(db, collection, group)
        psr_database_sqlite_error(
            "Group \"$group\" is not a time series group. "
        )
    end
    return nothing
end 

function _throw_if_is_time_series_file(
    db::DatabaseSQLite,
    collection::String,
    attribute::String,
)
    if _is_time_series_file(db, collection, attribute)
        psr_database_sqlite_error(
            "Attribute \"$attribute\" is a time series file. " *
            "You must use the function `set_time_series_file!` to create or update it.",
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
    db::DatabaseSQLite,
    collection_id::String,
    label_or_id::Union{Integer, String},
    dict_scalar_attributes::AbstractDict,
    dict_vector_attributes::AbstractDict,
)
    for (key, value) in dict_scalar_attributes
        attribute = _get_attribute(db, collection_id, string(key))
        if isa(attribute, ScalarRelation)
            _validate_scalar_relation_type(attribute, label_or_id, value)
        else
            _validate_scalar_parameter_type(attribute, label_or_id, value)
        end
    end
    for (key, value) in dict_vector_attributes
        attribute = _get_attribute(db, collection_id, string(key))
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
        psr_database_sqlite_error(
            "The value of the attribute \"$(attribute.id)\" in element \"$label_or_id\" " *
            "of collection \"$(attribute.parent_collection)\" should be of type $(attribute.type). User inputed $(typeof(value)): $value.",
        )
    end
end

function _validate_scalar_relation_type(
    attribute::ScalarRelation,
    label_or_id::Union{Integer, String},
    value,
)
    if !isa(value, String) && !isa(value, Int64)
        psr_database_sqlite_error(
            "The value of the attribute \"$(attribute.id)\" in element \"$label_or_id\" " *
            "of collection \"$(attribute.parent_collection)\" should be of type String or Int64. User inputed $(typeof(value)): $value.",
        )
    end
end

function _validate_vector_parameter_type(
    attribute::VectorParameter,
    label_or_id::Union{Integer, String},
    values::Vector{<:Any},
)
    if !isa(values, Vector{attribute.type})
        psr_database_sqlite_error(
            "The value of the attribute \"$(attribute.id)\" in element \"$label_or_id\" " *
            "of collection \"$(attribute.parent_collection)\" should be of type Vector{$(attribute.type)}. User inputed $(typeof(values)): $values.",
        )
    end
end

function _validate_vector_relation_type(
    attribute::VectorRelation,
    label_or_id::Union{Integer, String},
    values::Vector{<:Any},
)
    if !isa(values, Vector{String}) && !isa(values, Vector{Int64})
        psr_database_sqlite_error(
            "The value of the attribute \"$(attribute.id)\" in element \"$label_or_id\" " *
            "of collection \"$(attribute.parent_collection)\" should be of type Vector{String} or Vector{Int64}. User inputed $(typeof(values)): $values.",
        )
    end
end

function _validate_time_series_dimensions(
    collection_id::String, 
    attribute::Attribute, 
    dimensions...
)
    for dim_name in keys(dimensions...)
        if !(string(dim_name) in attribute.dimension_names)
            psr_database_sqlite_error(
                "The dimension \"$dim_name\" is not defined in the time series attribute \"$(attribute.id)\" of collection \"$collection_id\". " *
                "The available dimensions are: $(attribute.dimension_names).",
            )
        end
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
        psr_database_sqlite_error(
            "User version not defined or set to zero in the database. Please add 'PRAGMA user_version = \"your version\";' to your .sql file.",
        )
    end
    return nothing
end

function _throw_if_collection_or_attribute_do_not_exist(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
)
    _throw_if_collection_does_not_exist(db, collection_id)
    _throw_if_attribute_does_not_exist(db, collection_id, attribute_id)
    return nothing
end

function _throw_if_collection_or_attribute_do_not_exist(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_ids::Vector{String},
)
    _throw_if_collection_does_not_exist(db, collection_id)
    for attribute_id in attribute_ids
        _throw_if_attribute_does_not_exist(db, collection_id, attribute_id)
    end
    return nothing
end

function _throw_if_collection_does_not_exist(
    db::DatabaseSQLite,
    collection_id::String,
)
    if !_collection_exists(db, collection_id)
        psr_database_sqlite_error(
            "Collection \"$collection_id\" does not exist. " *
            "This is the list of available collections: " *
            "$(_string_of_collections(db))",
        )
    end
end

function _throw_if_attribute_does_not_exist(
    db::DatabaseSQLite,
    collection_id::String,
    attribute_id::String,
)
    if !_attribute_exists(db, collection_id, attribute_id)
        psr_database_sqlite_error(
            "Attribute \"$attribute_id\" does not exist in collection \"$collection_id\". " *
            "This is the list of available attributes: $(_string_of_attributes(db, collection_id))",
        )
    end
end

function _string_of_collections(db::DatabaseSQLite)
    string_of_collections = ""
    for collection in _get_collection_ids(db)
        string_of_collections *= "\n - $collection"
    end
    return string_of_collections
end
function _string_of_attributes(
    db::DatabaseSQLite,
    collection_id::String,
)
    attribute_ids = _get_attribute_ids(db, collection_id)
    string_of_attributes_names = ""
    for attribute_id in attribute_ids
        string_of_attributes_names *= "\n - $attribute_id"
    end
    return string_of_attributes_names
end
