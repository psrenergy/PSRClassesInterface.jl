_is_valid_table_name(table::String) =
    !isnothing(match(r"^(?:[A-Z][a-z]*_{1})*[A-Z][a-z]*$", table))

_is_valid_column_name(column::String) =
    !isnothing(match(r"^[a-z][a-z0-9]*(?:_{1}[a-z0-9]+)*$", column))

_is_valid_table_vector_name(table::String) =
    !isnothing(
        match(
            r"^(?:[A-Z][a-z]*_{1})*[A-Z][a-z]*_vector_[a-z][a-z0-9]*(?:_{1}[a-z0-9]+)*$",
            table,
        ),
    )

_is_valid_table_timeseries_name(table::String) =
    !isnothing(match(r"^(?:[A-Z][a-z]*_{1})*[A-Z][a-z]*_timeseries", table))

_is_valid_table_relation_name(table::String) =
    !isnothing(
        match(
            r"^(?:[A-Z][a-z]*_{1})*[A-Z][a-z]*_relation_(?:[A-Z][a-z]*_{1})*[A-Z][a-z]*$",
            table,
        ),
    )
# ^[a-z]{1}(?:[a-z]*[0-9]*[a-z]*_{1})*[a-z0-9]*$
function _validate_generic_table_name(table::String)
    if _is_not_valid_generic_table_name(table)
        error("""
            Invalid table name: $table.\nValid table name formats are: \n
            - Collections: Name_Of_Collection\n
            - Vector attributes: Name_Of_Collection_vector_name_of_attribute\n
            - Time series: Name_Of_Collection_timeseries\n
            - Relations: Name_Of_Collection_relation_Name_Of_Other_Collection
            """)
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
            - name_of_attribute
            """)
    end
end

function _validate_column_name(table::String, column::String)
    if !_is_valid_column_name(column)
        error(
            """
          Invalid column name: $column for table $table. \nThe valid column name format is: \n
          - name_of_attribute
          """,
        )
    end
end

function validate_database(db::SQLite.DB)
    tables = table_names(db)
    for table in tables
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
                - Collections: Name_Of_Collection\n
                - Vector attributes: Name_Of_Collection_vector_name_of_attribute\n
                - Time series: Name_Of_Collection_timeseries\n
                - Relations: Name_Of_Collection_relation_Name_Of_Other_Collection
                """)
        end
    end
end
