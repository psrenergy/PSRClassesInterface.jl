function create_parameters!(
    db::SQLite.DB,
    table::String,
    parameters,
)
    columns = string.(keys(parameters))
    sanity_check(db, table, columns)

    cols = join(keys(parameters), ", ")
    vals = join(values(parameters), "', '")
    DBInterface.execute(db, "INSERT INTO $table ($cols) VALUES ('$vals')")
    return nothing
end

function create_vector!(
    db::SQLite.DB,
    table::String,
    id::String,
    vector_name::String,
    values::V,
) where {V <: AbstractVector}
    table_name = "_" * table * "_" * vector_name
    sanity_check(db, table_name, vector_name)
    num_values = length(values)
    ids = fill(id, num_values)
    idx = collect(1:num_values)
    tbl = Tables.table([ids idx values]; header = [:id, :idx, vector_name])
    SQLite.load!(tbl, db, table_name)
    return nothing
end

function create_vectors!(db::SQLite.DB, table::String, id::String, vectors)
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

    if !haskey(dict_parameters, :id)
        error("A new object requires an \"id\".")
    end
    id = dict_parameters[:id]

    # TODO a gente deveria ter algum esquema de transactions aqui
    # se um for bem sucedido e o outro não, deveriamos dar rollback para 
    # antes de começar a salvar esse cara.
    create_parameters!(db, table, dict_parameters)
    create_vectors!(db, table, id, dict_vectors)

    return nothing
end

function create_related_time_series!(
    db::SQLite.DB,
    table::String;
    kwargs...,
)
    table_name = "_" * table * "_TimeSeries"
    dict_time_series = Dict()
    for (key, value) in kwargs
        @assert isa(value, String)
        # TODO we could validate if the path exists
        dict_time_series[key] = [value]
    end
    df = DataFrame(dict_time_series)
    SQLite.load!(df, db, table_name)
    return nothing
end

function set_related!(
    db::SQLite.DB,
    table1::String,
    table2::String,
    id_1::String,
    id_2::String,
)
    id_parameter_on_table_1 = lowercase(table2) * "_id"
    SQLite.execute(
        db,
        "UPDATE $table1 SET $id_parameter_on_table_1 = '$id_2' WHERE id = '$id_1'",
    )
    return nothing
end
