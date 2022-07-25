const PSRCLASSES_DEFAULTS = JSON.parsefile(joinpath(@__DIR__, "JSON", "psrclasses.defaults.json"))

function create_element!(
    data::Data,
    name::String,
)
    if !haskey(PSRCLASSES_DEFAULTS, name)
        error("Unknown PSR Class '$name'")
    end

    element = deepcopy(PSRCLASSES_DEFAULTS[name])

    index = _insert_element!(data, name, element)

    return index
end

function _insert_element!(
    data::Data,
    name::String,
    element::Any,
)
    raw_data = _raw(data)::Dict{String,<:Any}

    if !haskey(raw_data, name)
        error("PSR Class '$name' is not available for this study")
    end

    objects = raw_data[name]::Vector

    push!(objects, element)

    return length(objects)
end

function _get_element(
    data::Data,
    name::String, # classe
    index::Integer,
)

    # ~ Retrieves raw JSON-like dict, i.e. `Dict{String, Any}`.
    # ~ `_raw(data)` is a safe interface for `data.raw`.
    # ~ This dictionary was created by reading a JSON file.
    raw_data = _raw(data)::Dict{String,<:Any}

    if !haskey(raw_data, name)
        error("PSR Class '$name' is not available for this study")
    end

    # ~ Gathers a list containing all instances of the class referenced above.
    objects = raw_data[name]::Vector

    if !(1 <= index <= length(objects))
        error("Invalid index '$index' out of bounds [1, $(length(objects))]")
    end

    element = objects[index]::Dict{String,<:Any}

    return element
end

function set_parm!(
    data::Data,
    name::String,
    index::Integer,
    attr::String,
    value::T,
) where {T<:MainTypes}
    if !haskey(data.data_struct, name)
        error("PSR Class '$name' is not available for this study")
    end

    class_struct = data.data_struct[name]

    if !haskey(class_struct, attr)
        error("PSR Class '$name' has no attribute '$attr'")
    end

    attr_data = class_struct[attr]::Attribute

    if attr_data.is_vector
        error(
            """
            Attribute '$attr' PSR Class '$name' is a vector, not a scalar parameter.
            Consider using `PSRI.set_vector!` instead
            """
        )
    end

    attr_type = attr_data.type

    # ~ This is assumed to be a mutable dictionary.
    element = _get_element(data, name, index)

    # ~ In fact, all attributes must be set beforehand.
    # ~ Schema validation would be useful here, since there would be no need
    #   to check for existing keys and `get_element` could handle all necessary
    #   consistency-related work.
    # ~ This could even be done at loading time or if something is modified by
    #   methods like `set_parm!`.
    if !haskey(element, attr)
        error("Invalid attribute '$attr' for object of type '$name'")
    end

    element[attr] = value::attr_type

    nothing
end

function get_vector(
    data::Data,
    name::String,
    index::Integer,
    attr::String,
    type::Union{Type{<:T},Nothing}=nothing,
) where {T<:MainTypes}
    if !haskey(data.data_struct, name)
        error("PSR Class '$name' is not available for this study")
    end

    class_struct = data.data_struct[name]

    if !haskey(class_struct, attr)
        error("PSR Class '$name' has no attribute '$attr'")
    end

    attr_data = class_struct[attr]::Attribute

    if !attr_data.is_vector
        error(
            """
            Attribute '$attr' PSR Class '$name' is a scalar parameter, not a vector.
            Consider using `PSRI.set_parm!` instead
            """
        )
    end

    element = _get_element(data, name, index)

    if !haskey(element, attr)
        error("Invalid attribute '$attr' for object of type '$name'")
    end

    vector = element[attr]

    if isnothing(type)
        return Vector(vector)
    else
        return Vector{type}(vector)
    end
end

function set_vector!(
    data::Data,
    name::String,
    index::Integer,
    attr::String,
    vector::Vector{T}
) where {T<:MainTypes}
    buffer = get_vector(data, name, index, attr)

    if length(vector) != length(buffer)
        error(
            """
            Vector length change from $(length(buffer)) to $(length(vector)) is not allowed.
            Use `PSRI.set_series!` instead.
            """
        )
    end

    # ~ Validation on `name` & `attr` already happened during `get_vector`
    attr_data = data.data_struct[name][attr]
    attr_type = attr_data.type

    # ~ Modify data in-place
    for i = eachindex(buffer)
        buffer[i] = vector[i]::attr_type
    end

    nothing
end