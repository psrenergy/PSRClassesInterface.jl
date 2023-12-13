function _insert_element!(data::Data, collection::String, element::Any)
    _check_collection_in_study(data, collection)

    elements = _get_elements!(data, collection)

    push!(elements, element)

    return length(elements)
end

function _set_index!(
    data_index::DataIndex,
    reference_id::Integer,
    collection::String,
    index::Integer,
)
    if haskey(data_index.index, reference_id)
        previous_collection, _ = _get_index(data_index, reference_id)

        @warn """
        Replacing reference_id = '$reference_id' from '$previous_collection' to '$collection'
        """
    else
        data_index.max_id = max(data_index.max_id, reference_id)
    end

    data_index.index[reference_id] = (collection, index)

    return nothing
end

function _merge_psr_transformer_and_psr_serie!(data::Data)
    raw = _raw(data)

    if haskey(raw, "PSRSerie") && haskey(raw, "PSRTransformer")
        append!(raw["PSRSerie"], raw["PSRTransformer"])
        delete!(raw, "PSRTransformer")
    elseif haskey(raw, "PSRTransformer")
        raw["PSRSerie"] = raw["PSRTransformer"]
        delete!(raw, "PSRTransformer")
    end

    return nothing
end

# Vector map

function _update_dates!(data::Data, collection, date_ref::Vector{Int32}, index::String)
    current = data.controller_date
    for (idx, el) in enumerate(collection)
        date_ref[idx] = _findfirst_date(current, el[index])
    end
    return nothing
end

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
        val = el[query_name][date_ref[idx]]
        if val === nothing
            cache.vector[idx] = cache.default
        else
            cache.vector[idx] = val
        end
    end
    return nothing
end

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

function _update_graf_vectors!(data::Data)
    return PSRI.goto(
        data.mapper,
        data.controller_stage,
        data.controller_scenario,
        data.controller_block,
    )
end

function _update_graf_vectors!(data::Data, filter::String)
    return PSRI.goto(
        data.mapper,
        filter,
        data.controller_stage,
        data.controller_scenario,
        data.controller_block,
    )
end
