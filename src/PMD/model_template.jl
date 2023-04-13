using JSON

struct ModelTemplate
    map::Dict{String, Set{String}}
    inv::Dict{String, String}

    ModelTemplate() = new(Dict{String, Set{String}}(), Dict{String, String}())
end

function Base.push!(mt::ModelTemplate, ps::Pair{String, String}...)
    for (k, v) in ps
        if !haskey(mt.map, k)
            mt.map[k] = Set{String}()
        end

        push!(mt.map[k], v)

        mt.inv[v] = k
    end

    return mt
end

Base.iterate(mt::ModelTemplate) = iterate(mt.map)
Base.iterate(mt::ModelTemplate, i::Integer) = iterate(mt.map, i)

_hasmap(mt::ModelTemplate, k::AbstractString) = haskey(mt.map, string(k))
_hasinv(mt::ModelTemplate, v::AbstractString) = haskey(mt.inv, string(v))

function dump_model_template(path::String, model_template::ModelTemplate)
    list = []

    for (collection, models) in model_template
        push!(
            list,
            Dict{String, Any}(
                "classname" => collection,
                "models" => collect(models),
            ),
        )
    end

    Base.open(path, "w") do io
        return JSON.print(io, list)
    end

    return nothing
end

function load_model_template(path::AbstractString)
    model_template = ModelTemplate()

    load_model_template!(path, model_template)

    return model_template
end

function load_model_template!(path::AbstractString, model_template::ModelTemplate)
    raw_struct = JSON.parsefile(path)

    for item in raw_struct
        collection = item["classname"]
        models = item["models"]

        for model in models
            push!(model_template, Pair(collection, model))
            # model_template[collection] = model
        end
    end

    return nothing
end
