struct SeriesTable <: Tables.AbstractColumns
    attrs::Dict{Symbol,Int}
    types::Vector{Type}
    table::Vector{Vector}

    function SeriesTable(buffer::Dict{String,Vector})
        if !allequal(length(data) for data in values(buffer))
            error("Series columns must have the same length")
        end

        attrs = Dict{Symbol,Int}(attr => i for (i, attr) in enumerate(Symbol.(keys(buffer))))
        types = eltype.(values(buffer))
        table = Vector{Vector}(undef, length(attrs))

        for (attr, data) in buffer
            table[attrs[Symbol(attr)]] = data
        end

        return new(attrs, types, table)
    end
end

# Required AbstractColumns Interface
function Base.getproperty(ts::SeriesTable, name::Symbol)
    if name ∈ fieldnames(typeof(ts))
        return getfield(ts, name)
    else
        return Tables.getcolumn(ts, name)
    end
end

# Retrieve a column by name (String)
function Tables.getcolumn(ts::SeriesTable, col::Symbol)
    return Tables.getcolumn(ts, ts.attrs[col])
end

# Retrieve a column by name (Symbol)
function Tables.getcolumn(ts::SeriesTable, col::String)
    return Tables.getcolumn(ts, Symbol(col))
end

# Retrieve a column by index
function Tables.getcolumn(ts::SeriesTable, i::Int)
    return ts.table[i]
end

function Tables.columnnames(ts::SeriesTable)
    # Return column names for a table as an indexable collection
    return collect(keys(ts.attrs))
end

struct GrafTable{T} <: Tables.AbstractColumns
    src::String
    hdr::String
    bin::String

    domain::Matrix{Int}
    agents::Dict{Symbol,Int}
    matrix::Matrix{T}

    function GrafTable{T}(path::String; kws...) where {T}
        hdr = "$path.hdr"
        bin = "$path.bin"

        # Load
        reader = open(OpenBinary.Reader, path; kws...)
        agents = Dict{Symbol,Int}(Symbol(reader.agent_names[i]) => i for i = 1:reader.agents_total)

        if !isempty(reader.blocks_per_stage)
            n_rows = sum(reader.scenario_total * reader.blocks_per_stage[t] for t = 1:reader.stage_total)
            domain = Matrix{Int}(undef, n_rows, 3)
            matrix = Matrix{T}(undef, n_rows, length(agents))
            
            i = 0

            for t = 1:reader.stage_total, s = 1:reader.scenario_total
                for b in 1:reader.blocks_per_stage[t]
                    i += 1

                    domain[i, :] .= [t, s, b] 

                    for a = 1:reader.agents_total
                        matrix[i, a] = reader[a]
                    end
                    
                    next_registry(reader)
                end
            end
        else
            n_rows = reader.stage_total * reader.block_total * reader.scenario_total
            domain = Matrix{Int}(undef, n_rows, 3)
            matrix = Matrix{T}(undef, n_rows, length(agents))

            i = 0

            for t = 1:reader.stage_total, s = 1:reader.scenario_total, b in 1:reader.block_total
                i += 1

                domain[i, :] .= [t, s, b]

                for a = 1:reader.agents_total
                    matrix[i, a] = reader[a]
                end
                
                next_registry(reader)
            end
        end

        close(reader)

        return new{T}(path, hdr, bin, domain, agents, matrix)
    end
end

function Base.getproperty(ts::GrafTable, name::Symbol)
    if name ∈ fieldnames(typeof(ts))
        return getfield(ts, name)
    else
        return Tables.getcolumn(ts, name)
    end
end

# Required AbstractColumns Interface

# Retrieve a column by name (String)
function Tables.getcolumn(ts::GrafTable, col::Symbol)
    if col === :stage
        return ts.domain[:, 1]
    elseif col === :series
        return ts.domain[:, 2]
    elseif col === :block
        return ts.domain[:, 3]
    else
        return Tables.getcolumn(ts, ts.agents[col])
    end
end

# Retrieve a column by name (Symbol)
function Tables.getcolumn(ts::GrafTable, col::String)
    return Tables.getcolumn(ts, Symbol(col))
end

# Retrieve a column by index
function Tables.getcolumn(ts::GrafTable, i::Int)
    if 1 <= i <= 3
        return ts.domain[:, i]
    elseif i > 3
        return ts.matrix[:, i - 3]
    else
        Base.throw_boundserror(ts, i)
    end
end

function Tables.columnnames(ts::GrafTable)
    # Return column names for a table as an indexable collection
    return collect(Symbol, [[:stage, :series, :block]; collect(keys(ts.agents))])
end
