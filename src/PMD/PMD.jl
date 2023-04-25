module PMD

import Dates
import JSON

"""
```
struct Attribute
    name::String
    is_vector::Bool
    type::DataType
    dim::Int
    index::String
end
```
"""
struct Attribute
    name::String
    is_vector::Bool
    type::DataType
    dim::Int
    index::String
    # interval::String
end

const DataStruct = Dict{String, Dict{String, Attribute}}

include("model_template.jl")
include("relation_mapper.jl")

const _PMDS_BASE_PATH = joinpath(@__DIR__(), "pmds")

const PMD_MODEL_TEMPLATES_PATH =
    joinpath(@__DIR__(), "..", "json_metadata", "modeltemplates.sddp.json")

function _is_vector(str)
    if str == "VECTOR" || str == "VETOR" # TODO: comentar no cnaal do classes
        return true
    elseif str == "PARM"
        return false
    else
        error("data type $str not known")
    end
end

function _get_type(str)
    if str == "INTEGER"
        return Int32
    elseif str == "REAL"
        return Float64
    elseif str == "STRING"
        return String
    elseif str == "DATE"
        return Dates.Date
    elseif str == "REFERENCE"
        return Ptr{Nothing}
    else
        error("Type $str no known")
    end
end

include("parser/parser.jl")

function _load_model!(
    data_struct::DataStruct,
    filepath::AbstractString,
    loaded_files::Set{String},
    model_template::ModelTemplate,
    relation_mapper::RelationMapper,
)
    if !isfile(filepath)
        error("'$filepath' is not a valid file")
    end

    if last(splitext(filepath)) != ".pmd"
        error("'$filepath' should contain a .pmd extension")
    end

    filename = basename(filepath)

    if !in(filename, loaded_files)
        parse!(filepath, data_struct, relation_mapper, model_template)

        push!(loaded_files, filename)
    end

    return nothing
end

function _load_model!(
    data_struct::DataStruct,
    path_pmds::AbstractString,
    files::Vector{String},
    loaded_files::Set{String},
    model_template::ModelTemplate,
    relation_mapper::RelationMapper,
)
    if !isempty(files)
        for filepath in files
            _load_model!(data_struct, filepath, loaded_files, model_template, relation_mapper)
        end
    else
        if !isdir(path_pmds)
            error("'$path_pmds' is not a valid directory")
        end

        for filepath in readdir(path_pmds; join = true)
            if isfile(filepath) && last(splitext(filepath)) == ".pmd"
                _load_model!(data_struct, filepath, loaded_files, model_template, relation_mapper)
            end
        end
    end

    return nothing
end

function load_model(
    path_pmds::AbstractString,
    files::Vector{String},
    model_template::ModelTemplate,
    relation_mapper::RelationMapper,
)
    data_struct = DataStruct()
    loaded_files = Set{String}()

    _load_model!(data_struct, path_pmds, files, loaded_files, model_template, relation_mapper)

    return data_struct, loaded_files
end

end
