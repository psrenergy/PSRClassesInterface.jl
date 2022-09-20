# see main definition
function mapped_vector(
    data::Data,
    collection::String,
    attribute::String,
    ::Type{T},
    dim1::Union{String,Nothing} = nothing,
    dim2::Union{String,Nothing} = nothing;
    ignore::Bool = false,
    map_key = collection, # reference for PSRMap pointer, if empty use class name
    filters = String[], # for calling just within a subset instead of the full call
) where {T} #<: Union{Float64, Int32}
    raw = _raw(data)

    n = max_elements(data, collection)
    
    if n == 0
        return T[]
    end

    attribute_struct = get_attribute_struct(data, collection, attribute)

    _check_type(attribute_struct, T, collection, attribute)
    _check_vector(attribute_struct, collection, attribute)
    _check_dim(attribute_struct, collection, attribute, dim1, dim2)
    
    dim = get_attribute_dim(attribute_struct)

    dim1_val = _add_get_dim_val(data, dim1)
    dim2_val = _add_get_dim_val(data, dim2)

    index = attribute_struct.index
    stage = data.controller_stage

    cache = _get_cache(data, T)

    collection_cache = get!(cache, collection, Dict{String,VectorCache{T}}())

    if haskey(collection_cache, attribute)
        error("Attribute $attribute was already mapped.")
    end

    out = T[_default_value(T) for _ in 1:n] #zeros(T, n)

    date_cache = get!(data.map_cache_data_idx, collection, Dict{String,Vector{Int32}}())

    need_up_dates = false
    if isempty(index)
        error("Vector Attribute is not indexed, cannot be mapped")
    end
    date_ref = if haskey(date_cache, index)
        need_up_dates = false
        date_cache[index]
    else
        need_up_dates = true
        vec = zeros(Int32, n)
        date_cache[index] = vec
        vec
    end

    vector_cache = VectorCache(dim1, dim2, dim1_val, dim2_val, index, stage, out)#, date_ref)
    collection_cache[attribute] = vector_cache

    if need_up_dates
        _update_dates!(data, raw[collection], date_ref, index)
    end
    _update_vector!(data, raw[collection], date_ref, vector_cache, attribute)

    _add_filter(data, map_key, collection, attribute, T)
    for f in filters
        _add_filter(data, f, collection, attribute, T)
    end

    return out
end

"""
"""
function _update_dates!(data::Data, collection, date_ref::Vector{Int32}, index::String)
    current = data.controller_date
    for (idx, el) in enumerate(collection)
        date_ref[idx] = _findfirst_date(current, el[index])
    end
    return nothing
end

"""
"""
function _update_vector!(
    data::Data,
    collection,
    date_ref::Vector{Int32},
    cache::VectorCache{T},
    attr::String,
) where {T}
    if !isempty(cache.dim1_str)
        cache.dim1 = data.controller_dim[cache.dim1_str]
        if !isempty(cache.dim2_str)
            cache.dim2 = data.controller_dim[cache.dim2_str]
        end
    end
    cache.stage = data.controller_stage
    query_name = _build_name(attr, cache)
    for (idx, el) in enumerate(collection)
        cache.vector[idx] = el[query_name][date_ref[idx]]
    end
    return nothing
end

"""
"""
function _get_cache(data, ::Type{Float64})
    return data.map_cache_real
end

function _get_cache(data, ::Type{Int32})
    return data.map_cache_integer
end

function _get_cache(data, ::Type{Dates.Date})
    return data.map_cache_date
end

"""
"""
function _add_get_dim_val(data, axis)
    if !isnothing(axis) && !isempty(axis)
        if !haskey(data.controller_dim, axis)
            data.controller_dim[axis] = 1

            return 1
        else
            return data.controller_dim[axis]
        end
    else
        return 0
    end
end

# see main definition
function go_to_stage(data::Data, stage::Integer)
    if data.controller_stage != stage
        data.controller_stage_changed = true
    end
    data.controller_stage = stage
    data.controller_date = _date_from_stage(data, stage)
    return nothing
end

# see main definition
function go_to_dimension(data::Data, str::String, val::Integer)
    if haskey(data.controller_dim, str)
        data.controller_dim[str] = val
    else
        error("Dimension $str was not created.")
    end
    return nothing
end

# see main definition
function update_vectors!(data::Data)
    _update_all_dates!(data)

    _update_all_vectors!(data, data.map_cache_real)
    _update_all_vectors!(data, data.map_cache_integer)
    _update_all_vectors!(data, data.map_cache_date)

    return nothing
end

# see main definition
function update_vectors!(data::Data, filter::String)

    # TODO improve this with a DataCache
    _update_all_dates!(data)

    raw = _raw(data)
    no_attr = false
    if haskey(data.map_filter_real, filter)
        for (col_name, attr) in data.map_filter_real[filter]
            vec_cache = data.map_cache_real[col_name][attr]
            collection = raw[col_name]
            col_dates = data.map_cache_data_idx[col_name]
            if _need_update(data, vec_cache)
                date_ref = col_dates[vec_cache.index_str]
                _update_vector!(data, collection, date_ref, vec_cache, attr)
            end
        end
    else
        no_attr = true
    end
    if haskey(data.map_filter_integer, filter)
        for (col_name, attr) in data.map_filter_integer[filter]
            vec_cache = data.map_cache_integer[col_name][attr]
            collection = raw[col_name]
            col_dates = data.map_cache_data_idx[col_name]
            if _need_update(data, vec_cache)
                date_ref = col_dates[vec_cache.index_str]
                _update_vector!(data, collection, date_ref, vec_cache, attr)
            end
        end
    elseif no_attr
        error("Filter $filter not valid")
    end

    return nothing
end

# see main definition
function update_vectors!(data::Data, filters::Vector{String})
    for f in filters
        update_vectors!(data, f)
    end
    return nothing
end

"""
"""
function _update_all_dates!(data::Data)
    raw = _raw(data)
    # update reference vectors
    if data.controller_stage_changed
        for (col_name, dict) in data.map_cache_data_idx
            collection = raw[col_name]
            for (index, vec) in dict
                _update_dates!(data, collection, vec, index)
            end
        end
    end
    data.controller_stage_changed = false
    return nothing
end

"""
"""
function _update_all_vectors!(data::Data, map_cache)
    raw = _raw(data)
    for (col_name, dict) in map_cache
        collection = raw[col_name]
        col_dates = data.map_cache_data_idx[col_name]
        for (attr, vec_cache) in dict
            if _need_update(data, vec_cache)
                date_ref = col_dates[vec_cache.index_str]
                _update_vector!(data, collection, date_ref, vec_cache, attr)
            end
        end
    end
    return nothing
end

"""
"""
function _build_name(name, cache) where {T<:Integer}
    if !isempty(cache.dim1_str)
        if !isempty(cache.dim2_str)
            return string(name, '(', cache.dim1, ',', cache.dim2, ')')
        else
            return string(name, '(', cache.dim1, ')')
        end
    else
        return name
    end
end

"""
"""
function _need_update(data::Data, cache)
    if data.controller_stage != cache.stage
        return true
    elseif !isempty(cache.dim1_str)
        if data.controller_dim[cache.dim1_str] != cache.dim1
            return true
        elseif !isempty(cache.dim2_str)
            if data.controller_dim[cache.dim2_str] != cache.dim2
                return true
            else
                return false
            end
        end
    else
        return false
    end
end

"""
"""
function _add_filter(data, filter, collection, attr, ::Type{Int32})
    if haskey(data.map_filter_integer, filter)
        push!(data.map_filter_integer[filter], (collection, attr))
    else
        data.map_filter_integer[filter] = [(collection, attr)]
    end
    return nothing
end
function _add_filter(data, filter, collection, attr, ::Type{Float64})
    if haskey(data.map_filter_real, filter)
        push!(data.map_filter_real[filter], (collection, attr))
    else
        data.map_filter_real[filter] = [(collection, attr)]
    end
    return nothing
end
function _add_filter(data, filter, collection, attr, ::Type{Dates.Date})
    error("TODO")
    if haskey(data.map_filter_date, filter)
        push!(data.map_filter_date[filter], (collection, attr))
    else
        data.map_filter_date[filter] = [(collection, attr)]
    end
    return nothing
end