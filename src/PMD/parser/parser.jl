include("states.jl")

mutable struct Parser
    # io pointer to read from
    io::IO

    # original pmd path and current line number, used to
    # compose better error/warning messages
    path::String
    line::Int

    # current parser state
    state::Vector{Any}
    merge_index::Int

    # whether to display warnings
    verbose::Bool

    # Study info
    data_struct::DataStruct
    relation_mapper::RelationMapper
    model_template::ModelTemplate

    function Parser(
        io::IO,
        path::AbstractString,
        data_struct::DataStruct,
        relation_mapper::RelationMapper,
        model_template::ModelTemplate;
        verbose::Bool = false,
    )
        return new(
            io,
            path,
            0,  # line
            [], # state
            1,  # merge_index
            verbose,
            data_struct,
            relation_mapper,
            model_template,
        )
    end
end

function _get_state(parser::Parser)
    if isempty(parser.state)
        return PMD_IDLE()
    else
        return parser.state[end]
    end
end

function _push_state!(parser::Parser, state::ParserState)
    push!(parser.state, state)

    return nothing
end

function _pop_state!(parser::Parser)
    if isempty(parser.state)
        error("Empty parser state stack")
    else
        return pop!(parser.state)
    end
end

function _syntax_error(
    parser::Parser,
    msg::AbstractString,
)
    return error("Syntax Error in '$(parser.path):$(parser.line)': $msg")
end

function _syntax_warning(
    parser::Parser,
    msg::AbstractString,
)
    if parser.verbose
        @warn("In '$(parser.path):$(parser.line)': $msg")
    end
end

function _cache_merge!(parser::Parser, collection::String, model_name::String)
    name = parser.model_template.inv[model_name]

    attribute = Attribute(name, false, DataType, 0, "")

    parser.data_struct[collection]["_MERGE_$(parser.merge_index)"] = attribute

    parser.merge_index += 1

    return nothing
end

function _apply_tag!(
    parser::Parser,
    tag::String,
    state::S,
) where {S <: Union{PMD_DEF_MODEL, PMD_DEF_CLASS}}
    if tag == "@id"
        _syntax_warning(
            parser,
            "Unhandled '$tag' tag found within '$(state.collection)' definition",
        )
    elseif tag == "@hourly_dense"
        _syntax_warning(
            parser,
            "Unhandled '$tag' tag found within '$(state.collection)' definition",
        )
    else
        _syntax_error(parser, "Unknown tag '$tag' within '$(state.collection)'")
    end
end

"""
    parse(
        filepath::AbstractString,
        model_template::ModelTemplate;
        verbose::Bool = false,
    )

Parses a PMD file with as little context as possible.
Besides the file path, only the model template is necessary.
It is intended to be useful when writing tests for the parser.
"""
function parse end

function parse(
    filepath::AbstractString,
    model_template::ModelTemplate;
    verbose::Bool = false,
)
    data_struct = DataStruct()
    relation_mapper = RelationMapper()

    return parse!(filepath, data_struct, relation_mapper, model_template; verbose)
end

function parse!(
    filepath::AbstractString,
    data_struct::DataStruct,
    relation_mapper::RelationMapper,
    model_template::ModelTemplate;
    verbose::Bool = false,
)
    if !isfile(filepath) || !endswith(filepath, ".pmd")
        error("'$filepath' is not a valid .pmd file")
    end

    open(filepath, "r") do io
        parser = Parser(io, filepath, data_struct, relation_mapper, model_template; verbose)

        return parse!(parser)
    end

    return data_struct
end

function parse!(parser::Parser)
    for line in readlines(parser.io)
        parser.line += 1

        # TODO: Remove comments properly
        line = strip(line)

        if isempty(line) || startswith(line, "//")
            continue # comment or empty line
        end

        _parse_line!(parser, line, _get_state(parser))
    end

    if !(_get_state(parser) isa PMD_IDLE)
        _syntax_error(parser, "Unexpected EOF")
    end

    # apply merges
    for collection in keys(parser.data_struct)
        _apply_merge!(parser, collection, String[collection])
    end

    # delete temporary classes (starting with "_")
    for collection in keys(parser.data_struct)
        if startswith(collection, "_MERGE")
            delete!(parser.data_struct, collection)
        end
    end

    return nothing
end

function _parse_line!(parser::Parser, line::AbstractString, ::PMD_IDLE)
    # Look for model definition block
    m = match(r"DEFINE_MODEL\s+(MODL:)?(\S+)", line)

    if !isnothing(m)
        model_name = String(m[2])

        if _hasinv(parser.model_template, model_name)
            collection = parser.model_template.inv[model_name]
        else
            _syntax_warning(parser, "Unknown model '$(model_name)'")

            _push_state!(parser, PMD_DEF_MODEL(nothing))

            return nothing
        end

        parser.data_struct[collection] = Dict{String, Attribute}()

        # default attributes that belong to "all collections"
        parser.data_struct[collection]["name"] = Attribute("name", false, String, 0, "")
        parser.data_struct[collection]["code"] = Attribute("code", false, Int32, 0, "")
        parser.data_struct[collection]["AVId"] = Attribute("AVId", false, String, 0, "")

        if collection == "PSRSystem"
            parser.data_struct[collection]["id"] = Attribute("id", false, String, 0, "")
        end

        _push_state!(parser, PMD_DEF_MODEL(collection))

        return nothing
    end

    # Look for class definition block
    m = match(r"DEFINE_CLASS\s+(\S+)", line)

    if !isnothing(m)
        collection = String(m[1])

        parser.data_struct[collection] = Dict{String, Attribute}()

        # default attributes that belong to "all collections"
        parser.data_struct[collection]["name"] = Attribute("name", false, String, 0, "")
        parser.data_struct[collection]["code"] = Attribute("code", false, Int32, 0, "")
        parser.data_struct[collection]["AVId"] = Attribute("AVId", false, String, 0, "")

        if collection == "PSRSystem"
            parser.data_struct[collection]["id"] = Attribute("id", false, String, 0, "")
        end

        _push_state!(parser, PMD_DEF_CLASS(collection))

        return nothing
    end

    # Look for class merge block
    m = match(r"MERGE_CLASS\s+(\S+)\s+(\S+)", line)

    if !isnothing(m)
        collection = String(m[1])
        model_name = String(m[2])

        _cache_merge!(parser, collection, model_name)

        _push_state!(parser, PMD_MERGE_CLASS(collection))

        return nothing
    end

    return _syntax_error(parser, "Invalid input: '$line'")
end

function _parse_line!(
    parser::Parser,
    line::AbstractString,
    state::PMD_DEF_MODEL,
)
    # End model definition block
    if startswith(line, "END_MODEL")
        _pop_state!(parser)
        return nothing
    end

    # If collection is nothing, ignore it
    if state.collection === nothing
        return nothing
    end

    if _parse_attribute!(parser, line, state)
        return nothing
    end

    # Merge model statement within model block
    if _parse_merge!(parser, line, state)
        return nothing
    end

    if _parse_submodel!(parser, line, state)
        return nothing
    end

    if _parse_dimension!(parser, line, state)
        return nothing
    end

    if _parse_reference!(parser, line, state)
        return nothing
    end

    if startswith(line, "DEFINE_VALIDATION")
        _push_state!(parser, PMD_DEF_VALIDATION())
        return nothing
    end

    if startswith(line, "DEFINE_MATH")
        _push_state!(parser, PMD_DEF_MATH())
        return nothing
    end

    return _syntax_error(parser, "Invalid input: '$line'")
end

function _parse_line!(
    parser::Parser,
    line::AbstractString,
    state::PMD_DEF_CLASS,
)
    if startswith(line, "END_CLASS")
        _pop_state!(parser)
        return nothing
    end

    if _parse_attribute(parser, line, state)
        return nothing
    end

    if _parse_dimension!(parser, line, state)
        return nothing
    end

    if _parse_reference!(parser, line, state)
        return nothing
    end

    return _pmd_syntax_error("Invalid input: '$line'")
end

function _parse_line!(
    parser::Parser,
    line::AbstractString,
    ::PMD_DEF_VALIDATION,
)
    if line == "END_VALIDATION"
        _pop_state!(parser)
        return nothing
    end

    # ignore input within block
    return nothing
end

function _parse_line!(
    parser::Parser,
    line::AbstractString,
    ::PMD_DEF_MATH,
)
    if line == "END"
        _pop_state!(parser)
        return nothing
    end

    # ignore input within block
    return nothing
end

function _parse_merge!(
    parser::Parser,
    line::AbstractString,
    state::PMD_DEF_MODEL,
)
    m = match(r"MERGE_MODEL\s+MODL:(\S+)", line)

    if !isnothing(m)
        model_name = String(m[1])

        _cache_merge!(parser, state.collection, model_name)

        return true
    else
        return false
    end
end

function _parse_submodel!(
    parser::Parser,
    line::AbstractString,
    state::PMD_DEF_MODEL,
)
    m = match(r"SUB_MODEL\s+(MODL:)?(\S+)\s+(MODL:)?(\S+)", line)

    if !isnothing(m)
        src_model = String(m[2])
        dst_model = String(m[4])

        _syntax_warning(
            parser,
            "Unhandled 'SUB_MODEL' statemente from $(src_model) to $(dst_model) within $(state.collection)",
        )

        return true
    else
        return false
    end
end

function _parse_dimension!(
    parser::Parser,
    line::AbstractString,
    state::S,
) where {S <: Union{PMD_DEF_MODEL, PMD_DEF_CLASS, PMD_MERGE_CLASS}}
    m = match(r"DIMENSION\s+(\S+)", line)

    if !isnothing(m)
        _syntax_warning(
            parser,
            "Unhandled dimension '$(m[1])' within '$(state.collection)'",
        )

        return true
    else
        return false
    end
end

function _parse_reference!(
    parser::Parser,
    line::AbstractString,
    state::S,
) where {S <: Union{PMD_DEF_MODEL, PMD_DEF_CLASS, PMD_MERGE_CLASS}}
    m = match(r"(PARM|VECTOR|VETOR)\s+(REFERENCE)\s+(\S+)\s+(\S+)", line)

    if !isnothing(m)
        kind = String(m[1])
        attribute = String(m[3])
        target = String(m[4])

        if !haskey(parser.relation_mapper, state.collection)
            parser.relation_mapper[state.collection] = Dict{String, Vector{Relation}}()
        end

        if !haskey(parser.relation_mapper[state.collection], target)
            parser.relation_mapper[state.collection][target] = Vector{Relation}()
        end

        if _is_vector(kind)
            rel_type = RELATION_1_TO_N
        else
            rel_type = RELATION_1_TO_1
        end

        rel = Relation(rel_type, attribute)

        push!(parser.relation_mapper[state.collection][target], rel)

        return true
    else
        return false
    end
end

function _parse_attribute!(
    parser::Parser,
    line::AbstractString,
    state::S,
) where {S <: Union{PMD_DEF_MODEL, PMD_DEF_CLASS, PMD_MERGE_CLASS}}
    m = match(
        r"(PARM|VECTOR|VETOR)\s+(\S+)\s+(\S+)(\s+DIM\((\S+(,\S+)*)\))?(\s+INDEX\s+(\S+))?(\s+(\@\S+))?",
        line,
    )

    if !isnothing(m)
        kind = m[1]
        type = m[2]
        name = m[3]
        dims = m[5]
        index = m[8]
        tag = m[10]

        parser.data_struct[state.collection][name] = Attribute(
            name,
            PMD._is_vector(kind),
            PMD._get_type(type),
            isnothing(dims) ? 0 : count(",", dims) + 1,
            something(index, ""),
        )

        if !isnothing(tag)
            _apply_tag!(parser, tag, state)
        end

        return true
    else
        return false
    end
end

function _apply_merge!(parser::Parser, collection::String, merge_path::Vector{String})
    class = parser.data_struct[collection]

    for i in 1:parser.merge_index
        if haskey(class, "_MERGE_$i")
            to_merge = class["_MERGE_$i"].name

            if to_merge in merge_path
                error("merge cycle found")
            end

            _merge_path = deepcopy(merge_path)

            push!(_merge_path, to_merge)

            _apply_merge!(parser, to_merge, _merge_path)

            delete!(class, "_MERGE_$i")

            for (k, v) in parser.data_struct[to_merge]
                if k in ["name", "code", "AVId"] # because we are forcing all these
                    continue
                end

                if haskey(class, k)
                    error(
                        "Class $class already has attribute $k being merged from $to_merge",
                    )
                end

                class[k] = v
            end
        end
    end
    return nothing
end
