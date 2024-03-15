function create_parameters!(
    db::SQLite.DB,
    table::String,
    parameters,
)
    columns = string.(keys(parameters))
    sanity_check(table, columns)

    cols = join(keys(parameters), ", ")
    vals = join(values(parameters), "', '")

    DBInterface.execute(db, "INSERT INTO $table ($cols) VALUES ('$vals')")
    return nothing
end

function create_vector!(
    db::SQLite.DB,
    table::String,
    id::Integer,
    vector_name::String,
    values::V,
) where {V <: AbstractVector}
    if !_is_valid_column_name(vector_name)
        error("""
            Invalid vector name: $vector_name.\nValid format is: name_of_attribute.
        """)
    end
    table_name = _vector_table_name(table, vector_name)
    sanity_check(table_name, vector_name)
    num_values = length(values)
    ids = fill(id, num_values)
    idx = collect(1:num_values)
    tbl = Tables.table([ids idx values]; header = [:id, :idx, vector_name])
    SQLite.load!(tbl, db, table_name)
    return nothing
end

function create_vectors!(db::SQLite.DB, table::String, id::Integer, vectors)
    for (vector_name, values) in vectors
        create_vector!(db, table, id, string(vector_name), values)
    end
    return nothing
end

function create_element!(
    db::SQLite.DB,
    table::String;
    kwargs...,
)
    if !_is_valid_table_name(table)
        error("Invalid table name: $table")
    end
    @assert !isempty(kwargs)
    dict_parameters = Dict()
    dict_vectors = Dict()

    for (key, value) in kwargs
        if isa(value, AbstractVector)
            dict_vectors[key] = value
        else
            dict_parameters[key] = value
        end
    end

    create_parameters!(db, table, dict_parameters)

    if !isempty(dict_vectors)
        id = get(dict_parameters, :id, _get_id(db, table, dict_parameters[:label]))
        create_vectors!(db, table, id, dict_vectors)
    end

    return nothing
end
