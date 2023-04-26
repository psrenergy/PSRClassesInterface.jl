include("states.jl")

mutable struct Parser
    # io pointer to read from
    io::IO

    # original pmd path and current line number, used to
    # compose better error/warning messages
    path::String
    lineno::Int

    # current parser state
    state::Vector{Any}

    # items to be merged
    merge::Dict{String, Vector{Any}}

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
            0,                          # lineno
            [],                         # state
            Dict{String, Vector{Any}}(), # merge
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
    return error("Syntax Error in '$(parser.path):$(parser.lineno)': $msg")
end

function _syntax_warning(
    parser::Parser,
    msg::AbstractString,
)
    if parser.verbose
        @warn("In '$(parser.path):$(parser.lineno)': $msg")
    end
end

function _cache_merge!(parser::Parser, collection::String, model_name::String)
    if !haskey(parser.merge, collection)
        parser.merge[collection] = []
    end

    push!(parser.merge[collection], parser.model_template.inv[model_name])

    return nothing
end

function _apply_tag!(
    parser::Parser,
    collection::String,
    attribute::String,
    tag::AbstractString,
)
    if tag == "@id"
        _syntax_warning(
            parser,
            "Unhandled '$tag' tag for '$(attribute)' within '$(collection)' definition",
        )
    elseif tag == "@hourly_dense"
        _syntax_warning(
            parser,
            "Unhandled '$tag' tag for '$(attribute)' within '$(collection)' definition",
        )
    else
        _syntax_error(
            parser,
            "Unknown tag '$tag' for '$(attribute)' within '$(collection)'",
        )
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
        parser.lineno += 1

        # remove comments & trailing spaces
        m = match(r"^\s*(.*?)\s*(\/\/.*)?$", line)

        if (m === nothing) || isempty(m[1])
            continue # comment or empty line
        end

        _parse_line!(parser, m[1], _get_state(parser))
    end

    if !(_get_state(parser) isa PMD_IDLE)
        _syntax_error(parser, "Unexpected EOF")
    end

    # apply merges
    for collection in keys(parser.merge)
        _apply_merge!(parser, collection)
    end

    return nothing
end

function _parse_line!(parser::Parser, line::AbstractString, ::PMD_IDLE)
    # Look for model definition block
    m = match(r"DEFINE_MODEL\s+(MODL:)?(\S+)", line)

    if m !== nothing
        model_name = String(m[2])

        if _hasinv(parser.model_template, model_name)
            collection = parser.model_template.inv[model_name]
        else
            _syntax_warning(parser, "Unknown model '$(model_name)'")

            # By setting the collection to 'nothing', we are telling
            # the parser to ignore the block and its contents
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

    if m !== nothing
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

    if m !== nothing
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

    if _parse_attribute!(parser, line, state)
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

    if m !== nothing
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

    if m !== nothing
        src_model = String(m[2])
        dst_model = String(m[4])

        _syntax_warning(
            parser,
            "Unhandled 'SUB_MODEL' statement from $(src_model) to $(dst_model) within $(state.collection)",
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

    if m !== nothing
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

    if m !== nothing
        kind = String(m[1])
        name = String(m[3])
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

        rel = Relation(rel_type, name)

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
        r"(PARM|VECTOR|VETOR)\s+(INTEGER|REAL|DATE|STRING)\s+(\S+)(\s+DIM\((\S+(,\S+)*)\))?(\s+INDEX\s+(\S+))?(\s+(\@\S+))?",
        line,
    )

    if m !== nothing
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
            (dims === nothing) ? 0 : count(",", dims) + 1,
            (index === nothing) ? "" : index,
        )

        if tag !== nothing
            _apply_tag!(parser, state.collection, name, tag)
        end

        return true
    else
        return false
    end
end

function _apply_merge!(parser::Parser, target::String)
    _apply_merge!(parser, target, Set{String}([target]))

    return nothing
end

function _apply_merge!(parser::Parser, target::String, merge_path::Set{String})
    data = parser.data_struct[target]

    for source in parser.merge[target]
        if source in merge_path
            error("Circular merge between '$target' and '$source'")
        end

        _merge_path = deepcopy(merge_path)

        push!(_merge_path, source)

        if haskey(parser.merge, source)
            _apply_merge!(parser, source, _merge_path)
        end

        for (k, v) in parser.data_struct[source]
            if k in ("name", "code", "AVId") # we are already enforcing these
                continue
            end

            if haskey(data, k)
                error(
                    "Collection '$target' already has attribute '$k' being merged from '$source'",
                )
            end

            data[k] = v
        end
    end

    delete!(parser.merge, target)

    return nothing
end
