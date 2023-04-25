include("states.jl")

mutable struct Parser
    io::IO
    path::String
    line::Int
    data_struct::DataStruct
    model_template::ModelTemplate
    state::Vector{Any}
    merge_index::Int
    verbose::Bool

    function Parser(
        io::IO,
        path::AbstractString,
        data_struct::DataStruct,
        model_template::ModelTemplate;
        verbose::Bool = false,
    )
        return new(io, path, 0, data_struct, model_template, [], 1, verbose)
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
    if !haskey(parser.model_template.inv, model_name)
        @show parser.model_template.inv
        error()
    end

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

function parse end

function parse(filepath::AbstractString, model_template::ModelTemplate)
    data_struct = DataStruct()

    return parse!(filepath, data_struct, model_template)
end

function parse!(
    filepath::AbstractString,
    data_struct::DataStruct,
    model_template::ModelTemplate,
)
    if !isfile(filepath) || !endswith(filepath, ".pmd")
        error("'$filepath' is not a valid .pmd file")
    end

    open(filepath, "r") do io
        parser = Parser(io, filepath, data_struct, model_template)

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
        _merge_class(parser.data_struct, collection, String[collection])
    end

    # delete temporary classes (starting with "_")
    for collection in keys(parser.data_struct)
        if startswith(collection, "_")
            delete!(parser.data_struct, collection)
        end
    end

    return nothing
end

function _parse_line!(parser::Parser, line::AbstractString, ::PMD_IDLE)
    # Look for model definition block
    m = match(r"DEFINE_MODEL\s+MODL:(\S+)", line)

    if !isnothing(m)
        model_name = String(m[1])

        if _hasinv(parser.model_template, model_name)
            collection = parser.model_template.inv[model_name]
        else
            _syntax_warning(parser, "Unknown model '$(model_name)'")

            collection = model_name
            # _push_state!(parser, PMD_DEF_MODEL(nothing))
            
            # return nothing
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
        type = String(m[2])
        ref_src = String(m[3])
        ref_dst = String(m[4])

        _syntax_warning(
            parser,
            "Unhandled '$kind $type' reference ('$ref_src' ⇒ '$ref_dst') within '$(state.collection)'",
        )

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
