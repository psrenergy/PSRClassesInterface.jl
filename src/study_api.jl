const PSRCLASSES_DEFAULTS = JSON.parsefile(joinpath(@__DIR__, "json_metadata", "psrclasses.defaults.json"))
const DATE_FORMAT_1 = Dates.DateFormat(raw"yyyy-mm-dd")
const DATE_FORMAT_2 = Dates.DateFormat(raw"dd/mm/yyyy")

function list_attributes(
    data::Data,
    name::String,
)
    if !haskey(data.data_struct, name)
        error("PSR Class '$name' is not available for this study")
    end

    class_struct = data.data_struct[name]

    attrs = sort(collect(keys(class_struct)))

    return attrs
end

function list_attributes(
    data::Data,
    name::String,
    index::Int,
)
    element = _get_element(data, name, index)

    attrs = sort(collect(keys(element)))

    return attrs
end

function list_indexed_attributes(
    data::Data,
    name::String,
    index_attr::String,
)
    if !haskey(data.data_struct, name)
        error("PSR Class '$name' is not available for this study")
    end

    class_struct = data.data_struct[name]

    attrs = []

    for (attr, attr_data) in class_struct
        if attr_data.index == index_attr || attr == index_attr
            push!(attrs, attr)
        end
    end

    sort!(attrs)

    return attrs
end

function list_indexed_attributes(
    data::Data,
    name::String,
    index::Int,
    index_attr::String,
)
    element = _get_element(data, name, index)

    class_struct = data.data_struct[name]

    attrs = []

    for (attr, attr_data) in class_struct
        if haskey(element, attr) &&
            (attr_data.index == index_attr || attr == index_attr)
            push!(attrs, attr)
        end
    end

    sort!(attrs)

    return attrs
end

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

"""
    _get_element(
        data::Data,
        name::String,
        index::Integer,
    )

Low-level call to retrieve an element, that is, an instance of a class in the form of a `Dict{String, <:MainTypes}`.
It performs basic checks for bounds and existence of `index` and `name` according to `data`.
"""
function _get_element(
    data::Data,
    name::String, # classe
    index::Integer,   # instance index
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

function _get_attr_data(
    data::Data,
    name::String,
    attr::String,
)
    if !haskey(data.data_struct, name)
        error("PSR Class '$name' is not available for this study")
    end

    class_struct = data.data_struct[name]

    if !haskey(class_struct, attr)
        error("PSR Class '$name' has no attribute '$attr'")
    end

    attr_data = class_struct[attr]::Attribute

    return attr_data
end

@doc raw"""
"""
function _parse_parm end

function _parse_parm(::X, ::T) where {X,T<:MainTypes}
    error("Invalid type '$X' for parsing as '$T'")
end

_parse_parm(::Nothing, ::Type{T}) where {T<:MainTypes} = nothing
_parse_parm(value::T, ::Type{T}) where {T<:MainTypes} = value
_parse_parm(value::Int, ::Type{Int32}) = convert(Int32, value)

function _parse_parm(date::String, ::Type{Dates.Date})
    for date_format in [DATE_FORMAT_1, DATE_FORMAT_2]
        value = tryparse(Dates.Date, date, date_format)

        if !isnothing(value)
            return value
        end
    end

    error("Invalid date format '$date'")
end

function _parse_vector(vector::Vector, ::Type{T}) where {T<:MainTypes}
    return [_parse_parm(entry, T) for entry in vector]
end

function get_parm(
    data::Data,
    name::String,
    index::Int,
    attr::String,
)
    attr_data = _get_attr_data(data, name, attr)

    if attr_data.is_vector
        error(
            """
            Attribute '$attr' PSR Class '$name' is a vector, not a scalar parameter.
            Consider using `PSRI.get_vector` instead
            """
        )
    end

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

    return _parse_parm(element[attr], attr_data.type)
end

function set_parm!(
    data::Data,
    name::String,
    index::Int,
    attr::String,
    value::T,
) where {T<:MainTypes}
    attr_data = _get_attr_data(data, name, attr)

    if attr_data.is_vector
        error(
            """
            Attribute '$attr' PSR Class '$name' is a vector, not a scalar parameter.
            Consider using `PSRI.set_vector!` instead
            """
        )
    end

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

    element[attr] = _parse_parm(value, attr_data.type)

    nothing
end

function _get_vector_ref(
    data::Data,
    name::String,
    index::Int,
    attr::String,
)
    attr_data = _get_attr_data(data, name, attr)

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

    return element[attr]::Vector
end

function get_vector(
    data::Data,
    name::String,
    index::Int,
    attr::String,
    type::Union{Type{<:T},Nothing}=nothing,
) where {T<:MainTypes}
    vector = _get_vector_ref(data, name, index, attr)

    attr_data = _get_attr_data(data, name, attr)

    if isnothing(type)
        return _parse_vector(vector, attr_data.type)
    else
        return _parse_vector(vector, type)
    end
end

function set_vector!(
    data::Data,
    name::String,
    index::Int,
    attr::String,
    buffer::Vector{T}
) where {T<:MainTypes}
    vector = _get_vector_ref(data, name, index, attr)

    if length(buffer) != length(vector)
        error(
            """
            Vector length change from $(length(vector)) to $(length(buffer)) is not allowed.
            Use `PSRI.set_series!` instead.
            """
        )
    end

    # ~ Validation on `name` & `attr` already happened during `_get_vector_ref`
    attr_data = _get_attr_data(data, name, attr)

    # ~ Modify data in-place
    for i = eachindex(vector)
        vector[i] = _parse_parm(buffer[i], attr_data.type)
    end

    nothing
end

function get_series(
    data::Data,
    name::String,
    index::Int,
    index_attr::String,
)
    attrs = list_indexed_attributes(data, name, index, index_attr)

    series = Dict{String,Vector}()

    sizehint!(series, length(attrs))

    for attr in attrs
        series[attr] = get_vector(data, name, index, attr)
    end

    return series
end

function set_series!(
    data::Data,
    name::String,
    index::Int,
    index_attr::String,
    buffer::Dict{String,Vector}
)
    series = get_series(data, name, index, index_attr)

    valid = true

    if length(buffer) != length(series)
        valid = false
    end

    for attr in keys(series)
        if !haskey(buffer, attr)
            valid = false
            break
        end
    end

    if !valid
        missing_attrs = setdiff(keys(series), keys(buffer))
        for attr in missing_attrs
            @error "Missing attribute '$(attr)'"
        end

        invalid_attrs = setdiff(keys(buffer), keys(series))
        for attr in invalid_attrs
            @warn "Invalid attribute '$(attr)'"
        end

        error("Invalid attributes for series indexed by $(index_attr)")
    end

    new_length = nothing

    for vector in values(buffer)
        if isnothing(new_length)
            new_length = length(vector)
        end

        if length(vector) != new_length
            error("All vectors must be of the same length in a series")
        end
    end

    element = _get_element(data, name, index)

    for (attr, vector) in buffer
        element[attr] = vector
    end

    nothing
end

function write_data(data::Data, path::String)
    # ~ Retrieves JSON-like raw data
    raw_data = _raw(data)::Dict{String,<:Any}

    # ~ Writes to file
    Base.open(path, "w") do io
        JSON.print(io, raw_data)
    end

    nothing
end