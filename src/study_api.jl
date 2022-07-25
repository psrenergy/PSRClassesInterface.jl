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
    raw_data = _raw(data)

    @assert raw_data isa Dict{String,<:Any}

    if !haskey(raw_data, name)
        error("PSR Class '$name' is not available for this study")
    end

    objects = raw_data[name]

    @assert objects isa Vector{<:Any}

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
    raw_data = _raw(data)

    @assert raw_data isa Dict{String,<:Any}

    if !haskey(raw_data, name)
        error("PSR Class '$name' is not available for this study")
    end

    # ~ Gathers a list containing all instances of the class referenced above.
    objects = raw_data[name]

    @assert objects isa Vector{<:Any}

    if !(1 <= index <= length(objects))
        error("Invalid index '$index' out of bounds [1, $(length(objects))]")
    end

    element = objects[index]

    # ~ Stronger validation can be achieved by using JSONSchema.jl-like tools.
    @assert element isa Dict{String,<:Any}

    return element
end

function set_parm!(
    data::Data,
    name::String,
    index::Integer,
    attr::String,
    value::T,
) where {T<:MainTypes}
    @assert haskey(data.data_struct, name)

    class_struct = data.data_struct[name]

    @assert haskey(class_struct, attr)

    attr_data = class_struct[attr]::Attribute

    @assert !attr_data.is_vector

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

    element[attr] = value::attr_data.type

    nothing
end

function get_vector(
    data::Data,
    name::String,
    index::Integer,
    attr::String,
    type::Union{Type{<:T}, Nothing} = nothing,
) where T <: MainTypes
    @assert haskey(data.data_struct, name)

    class_struct = data.data_struct[name]

    @assert haskey(class_struct, attr)

    attr_data = class_struct[attr]::Attribute

    @assert attr_data.is_vector

    element = _get_element(data, name, index)

    if !haskey(element, attr)
        error("Invalid attribute '$attr' for object of type '$name'")
    end

    vector = element[attr]

    if isnothing(type)
        copy(vector)
    else
        Vector{type}(vector)
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

    attr_type = (data.data_struct[name][attr]).type

    # ~ Modify data in-place
    for i = eachindex(buffer)
        buffer[i] = vector[i]::attr_type
    end

    nothing
end