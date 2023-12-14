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
          - name_of_aTTribute123\n
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
    if !("label" in attributes) && table != "Configuration"
        error("Table $table does not have a \"label\" column.")
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
    if "Configuration" ∉ tables
        error("Database does not have a \"Configuration\" table.")
    end
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

function check_value_type(
    db::SQLite.DB,
    table::String,
    column::String,
    values::V,
) where {V <: AbstractVector}
    valid_types = _column_valid_types(db, table, column)
    if !(eltype(values) <: valid_types)
        error(
            "Value $values is not of type $(valid_types) for column $column in table $table.",
        )
    end
end

function check_value_type(db::SQLite.DB, table::String, column::String, value)
    valid_types = _column_valid_types(db, table, column)
    if !isa(value, valid_types)
        error(
            "Value $value is not of type $(valid_types) for column $column in table $table.",
        )
    end
end

function check_if_column_exists(db::SQLite.DB, table::String, column::String)
    if !column_exist_in_table(db, table, column)
        # TODO we could make a suggestion on the closest string and give an error like
        # Did you mean xxxx?
        error("column $column does not exist in table $table.")
    end
    return nothing
end

function check_if_table_exists(db::SQLite.DB, table::String)
    if !table_exist_in_db(db, table)
        # TODO we could make a suggestion on the closest string and give an error like
        # Did you mean xxxx?
        error("table $table does not exist in database.")
    end
    return nothing
end

function sanity_check(db::SQLite.DB, table::String, column::String, value)
    # TODO We could make an option to disable sanity checks globally.
    check_if_table_exists(db, table)
    check_if_column_exists(db, table, column)
    check_value_type(db, table, column, value)
    return nothing
end

function sanity_check(db::SQLite.DB, table::String, column::String)
    # TODO We could make an option to disable sanity checks globally.
    check_if_table_exists(db, table)
    check_if_column_exists(db, table, column)
    return nothing
end

function sanity_check(db::SQLite.DB, table::String, columns::Vector{String})
    # TODO We could make an option to disable sanity checks globally.
    check_if_table_exists(db, table)
    for column in columns
        check_if_column_exists(db, table, column)
    end
    return nothing
end
