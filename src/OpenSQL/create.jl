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
    table_name = _vector_table_name(table, vector_name)
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