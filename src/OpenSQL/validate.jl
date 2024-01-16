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
    !isnothing(match(r"^(?:[A-Z][a-z]*)+_timeseries", table))

_is_valid_table_relation_name(table::String) =
    !isnothing(
        match(
            r"^(?:[A-Z][a-z]*)+_relation_(?:[A-Z][a-z]*)+$",
            table,
        ),
    )

_is_valid_time_series_attribute_value(value::String) =
    !isnothing(
        match(r"^[a-zA-Z][a-zA-Z0-9]*(?:_{1}[a-zA-Z0-9]+)*(?:\.[a-z]+){0,1}$", value),
    )

function _validate_time_series_attribute_value(value::String)
    if !_is_valid_time_series_attribute_value(value)
        error(
            """Invalid time series file name: $value. \nThe valid time series attribute name format is: \n
          - name_of_attribute123\n
          - name_of_attribute.extension\n
          OBS: It must be the name of the file, not the path.
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
        error("Table $table does not have an \"id\" column.")
    end
    if !("idx" in attributes)
        error("Table $table does not have an \"idx\" column.")
    end
    if !(get_vector_attribute_name(table) in attributes)
        error("Table $table does not have a column with the name of the vector attribute.")
    end
    if setdiff(attributes, ["id", "idx", get_vector_attribute_name(table)]) != []
        error(
            "Table $table should only have the following columns: \"id\", \"idx\", \"$(get_vector_attribute_name(table))\".",
        )
    end
end

function _validate_relation_table(db::SQLite.DB, table::String)
    attributes = column_names(db, table)
    if !("source_id" in attributes)
        error("Table $table does not have a \"source_id\" column.")
    end
    if !("target_id" in attributes)
        error("Table $table does not have a \"target_id\" column.")
    end
    if !("relation_type" in attributes)
        error("Table $table does not have a \"relation_type\" column.")
    end
    if setdiff(attributes, ["relation_type", "source_id", "target_id"]) != []
        error(
            "Table $table should only have the following columns: \"relation_type\", \"source_id\", \"target_id\".",
        )
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

function validate_database(db::SQLite.DB)
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
        elseif _is_valid_table_relation_name(table)
            _validate_relation_table(db, table)
        else
            error("""
                Invalid table name: $table.\nValid table name formats are: \n
                - Collections: NameOfCollection\n
                - Vector attributes: NameOfCollection_vector_name_of_attribute\n
                - Time series: NameOfCollection_timeseries\n
                - Relations: NameOfCollection_relation_NameOfOtherCollection
                """)
        end
    end
end

# Dictionary storing tables and columns of the current db loaded
# in the load_db function
const DB_TABLES_AND_COLUMNS = Dict{String, Vector{String}}()
# Constant to enable or disable sanity checks
const SANITY_CHECKS_ENABLED = Ref{Bool}(true)

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

function _save_db_tables_and_columns(db::SQLite.DB)
    tables = table_names(db)
    for table in tables
        DB_TABLES_AND_COLUMNS[table] = column_names(db, table)
    end
    return nothing
end

function _enable_sanity_checks(val::Bool)
    SANITY_CHECKS_ENABLED[] = val
    return val
end

function _sanity_check_enabled()
    return SANITY_CHECKS_ENABLED[]
end

function column_exist_in_table(table::String, column::String)
    cols = DB_TABLES_AND_COLUMNS[table]
    return column in cols
end

function table_exist_in_db(table::String)
    return haskey(DB_TABLES_AND_COLUMNS, table)
end

function check_if_column_exists(table::String, column::String)
    if !column_exist_in_table(table, column)
        # TODO we could make a suggestion on the closest string and give an error like
        # Did you mean xxxx?
        error("column $column does not exist in table $table.")
    end
    return nothing
end

function check_if_table_exists(table::String)
    if !table_exist_in_db(table)
        # TODO we could make a suggestion on the closest string and give an error like
        # Did you mean xxxx?
        error("table $table does not exist in database.")
    end
    return nothing
end

function sanity_check(table::String, column::String)
    !_sanity_check_enabled() && return nothing
    check_if_table_exists(table)
    check_if_column_exists(table, column)
    return nothing
end

function sanity_check(table::String, columns::Vector{String})
    !_sanity_check_enabled() && return nothing
    check_if_table_exists(table)
    for column in columns
        check_if_column_exists(table, column)
    end
    return nothing
end
