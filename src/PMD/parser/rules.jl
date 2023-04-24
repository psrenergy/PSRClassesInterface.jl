struct PMDT <: Transformer end

@terminal INT(t::PMDT, val) = parse(Int, String(val))
@terminal TYPE(t::PMDT, type) = PMD._get_type(String(type))
@terminal KIND(t::PMDT, name) = String(name) == "VETOR" ? "VECTOR" : String(name)
@terminal NAME(t::PMDT, name) = String(name)
@terminal MODEL_NAME(t::PMDT, name) = first(match(r"MODL:(.+)", String(name)))

struct PMD_AST
    model_list::Vector{Any}
    class_list::Vector{Any}
end

@rule start(t::PMDT, blocks) = begin
    model_list = []
    class_list = []

    for block in blocks
        if block isa PMD_MODEL_DEF
            push!(model_list, block)
        end
    end

    return PMD_AST(model_list, class_list)
end

struct PMD_MODEL_DEF
    name::String
    dimensions::Vector{Any}
    attributes::Vector{Any}
    sub_models::Vector{Any}
    merge_list::Vector{Any}
end

@rule model_args(t::PMDT, args) = args

@inline_rule model_def(t::PMDT, name, args) = begin
    dimensions = []
    attributes = []
    sub_models = []
    merge_list = []

    for item in args
        if item isa PMD.Attribute
            push!(attributes, item)
            continue
        end

        if item isa Lerche.Tree
            if item.data == "model_dimension"
                append!(dimensions, item.children)
                continue
            elseif item.data == "model_sub_model"
                push!(sub_models, tuple(item.children))
                continue
            elseif item.data == "model_merge"
                append!(merge_list, item.children)
            else
                @warn "Ignored: $item"
            end
        end
    end

    return PMD_MODEL_DEF(name, dimensions, attributes, sub_models, merge_list)
end

@rule model_attribute(t::PMDT, args) = begin
    kind, type, name = args[1:3]

    dims = []
    index = ""

    for item in args[4:end]
        if item.data == "model_attr_index"
            index = item.children[]
        elseif item.data == "model_attr_dim"
            dims = item.children
        end
    end

    # NOTE: 'dim', 'index' and 'interval' (args[4:end]) ignored
    return PMD.Attribute(
        name,
        PMD._is_vector(kind),
        type,
        length(dims),
        index,
    )
end
