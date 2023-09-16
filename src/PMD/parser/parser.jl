include("states.jl")

mutable struct Parser
    # io pointer to read from
    io::IO

    # original pmd path and current line number, used to
    # compose better error/warning messages
    path::String
    line_number::Int

    # current parser state
    state::Vector{Any}

    # items to be merged
    merge::Dict{String, Vector{Any}}

    # whether to display warnings
    verbose::Bool

    # Study info
    # data structure containgin the class and attribute definitions to be filled
    # by the parser
    data_struct::DataStruct
    # contains the relations between the classes obtaned from the json file OR from pmd
    relation_mapper::RelationMapper
    # maps classes like PSRHydroPlant to especific models like MODL:SDDP_V10.2_Bateria
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
            0,                          # line_number
            [],                         # state
            Dict{String, Vector{Any}}(), # merge
            false,
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
    return error("Syntax Error in '$(parser.path):$(parser.line_number)': $msg")
end

function _error(
    parser::Parser,
    msg::AbstractString,
)
    return error("Error in '$(parser.path):$(parser.line_number)': $msg")
end

function _warning(
    parser::Parser,
    msg::AbstractString,
)
    if parser.verbose
        @warn("In '$(parser.path):$(parser.line_number)': $msg")
    end
end

function _cache_merge!(parser::Parser, collection::String, model_name::String)
    if !haskey(parser.merge, collection)
        parser.merge[collection] = []
    end

    if !haskey(parser.model_template.inv, model_name)
        _warning(parser, "'$model_name' not found in model template")
    end

    push!(
        parser.merge[collection],
        get(parser.model_template.inv, model_name, model_name),
    )

    return nothing
end

function _apply_merge!(parser::Parser, target::String)
    _apply_merge!(parser, target, Set{String}([target]))

    return nothing
end

function _apply_merge!(parser::Parser, target::String, merge_path::Set{String})
    data = parser.data_struct[target]

    for source in parser.merge[target]
        if source in merge_path
            _error(parser, "Circular merge between '$target' and '$source'")
        end

        if !haskey(parser.data_struct, source)
            _warning(parser, "Unknown collection '$source' for merging into '$target'")

            continue
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
                _error(
                    parser,
                    "Collection '$target' already has attribute '$k' being merged from '$source'",
                )
            end

            data[k] = v
        end
    end

    delete!(parser.merge, target)

    return nothing
end

function _apply_tag!(
    parser::Parser,
    collection::String,
    attribute::AbstractString,
    tag::AbstractString,
)
    if tag == "@id"
        _warning(
            parser,
            "Unhandled '$tag' tag for '$(attribute)' within '$(collection)' definition",
        )
    elseif tag == "@hourly_dense"
        _warning(
            parser,
            "Unhandled '$tag' tag for '$(attribute)' within '$(collection)' definition",
        )
    elseif tag == "@chronological"
        _warning(
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

It is intended to be useful when **writing tests** for the parser.
Parses a PMD file with as little context as possible.
Besides the file path, only the model template is necessary.
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
        parser.line_number += 1

        # remove comments & trailing spaces
        m = match(r"^\s*(.*?)\s*(\/\/.*)?$", line)

        if (m === nothing) || isempty(m[1])
            continue # comment or empty line
        end

        _parse_line!(parser, m[1], _get_state(parser))
    end

    # after parsing, we should be in the idle state
    if !(_get_state(parser) isa PMD_IDLE)
        _syntax_error(parser, "Unexpected parsing completion")
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

        # obtain the collection (class) linked to a given model in this database
        collection = get(parser.model_template.inv, model_name, model_name)

        _warning(parser, "DEFINE_MODEL '$model_name' for class '$collection'")

        # TODO - verify if already existed? and throw error?
        if haskey(parser.data_struct, collection)
            _warning(parser, "Replacing definition of class '$collection' fwith model '$model_name'")
        end
        parser.data_struct[collection] = Dict{String, Attribute}()

        # default attributes that belong to "all collections"
        parser.data_struct[collection]["name"] = Attribute("name", false, String, 0, "")
        parser.data_struct[collection]["code"] = Attribute("code", false, Int32, 0, "")
        parser.data_struct[collection]["AVId"] = Attribute("AVId", false, String, 0, "")

        # special attributes from specific classes
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

        _warning(parser, "DEFINE_CLASS '$collection'")

        # TODO - verify if already existed? and throw error?
        if haskey(parser.data_struct, collection)
            _warning(parser, "Replacing definition of class '$collection'")
        end
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

        _warning(parser, "MERGE_CLASS to add new attributes from temporary '$model_name' to existing class '$collection'")

        if !haskey(parser.data_struct, collection)
            _error(parser, "Class '$collection no found. Consider changing pmd load order.'")
        end

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

    if _parse_inline_tag!(parser, line, state)
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

    # If collection is nothing, ignore it
    if state.collection === nothing
        return nothing
    end

    if _parse_attribute!(parser, line, state)
        return nothing
    end

    if _parse_merge!(parser, line, state)
        return nothing
    end

    if _parse_dimension!(parser, line, state)
        return nothing
    end

    if _parse_reference!(parser, line, state)
        return nothing
    end

    if _parse_inline_tag!(parser, line, state)
        return nothing
    end

    return _syntax_error(parser, "Invalid input: '$line'")
end

function _parse_line!(
    parser::Parser,
    line::AbstractString,
    state::PMD_MERGE_CLASS,
)
    if startswith(line, "END_CLASS")
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

    if _parse_merge!(parser, line, state)
        return nothing
    end

    if _parse_dimension!(parser, line, state)
        return nothing
    end

    if _parse_reference!(parser, line, state)
        return nothing
    end

    if _parse_inline_tag!(parser, line, state)
        return nothing
    end

    return _syntax_error(parser, "Invalid input: '$line'")
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
    state::S,
) where {S <: Union{PMD_DEF_MODEL, PMD_DEF_CLASS, PMD_MERGE_CLASS}}
    m = match(r"MERGE_MODEL\s+(MODL:)?(\S+)", line)

    if m !== nothing
        model_name = String(m[2])

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

        _warning(
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
        _warning(
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
        attribute = String(m[3])
        target = String(m[4])

        if !haskey(parser.relation_mapper, state.collection)
            parser.relation_mapper[state.collection] =
                Dict{String, Dict{String, Relation}}()
        end

        if !haskey(parser.relation_mapper[state.collection], target)
            parser.relation_mapper[state.collection][target] = Dict{String, Relation}()
        end

        if _is_vector(kind)
            relation_type = RELATION_1_TO_N
        else
            relation_type = RELATION_1_TO_1
        end

        relation = Relation(relation_type, attribute)

        parser.relation_mapper[state.collection][target][attribute] = relation

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

function _parse_inline_tag!(
    parser::Parser,
    line::AbstractString,
    ::S,
) where {S <: Union{PMD_DEF_MODEL, PMD_DEF_CLASS, PMD_MERGE_CLASS}}
    m = match(r"(\@\S+)\s+(\S+)?", line)

    if m !== nothing
        if m[2] !== nothing
            _warning(
                parser,
                "Unhandled inline tag '$(m[1])' with args: '$(m[2])'",
            )
        else
            _warning(
                parser,
                "Unhandled inline tag '$(m[1])' with no args",
            )
        end

        return true
    else
        return false
    end
end
