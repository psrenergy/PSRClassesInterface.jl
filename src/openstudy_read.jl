function get_series(data::Data, collection::String, indexing_attribute::String, index::Int)
    # TODO: review this. The element should always have all attributes even if
    # they need to be empty. the element creator should assure the data is
    # is complete. or this `get_series` should check existence and the return
    # empty if needed.
    attributes = _get_indexed_attributes(data, collection, index, indexing_attribute)

    buffer = Dict{String, Vector}()

    for attribute in attributes
        buffer[attribute] = get_vector(
            data,
            collection,
            attribute,
            index,
            _get_attribute_type(data, collection, attribute),
        )
    end

    return SeriesTable(buffer)
end

# Get GrafTable stored in a graf file for a collection
function get_graf_series(data::Data, collection::String, attribute::String; kws...)
    if !has_graf_file(data, collection)
        error("No time series file for collection '$collection'")
    end

    graf_files = Vector{String}()

    for graf in data.raw["GrafScenarios"]
        if graf["classname"] == collection && graf["vector"] == attribute
            append!(graf_files, graf["binary"])
        end
    end

    graf_file = first(graf_files)
    graf_path = joinpath(data.data_path, first(splitext(graf_file)))

    graf_table = GrafTable{Float64}(graf_path; kws...)

    return graf_table
end

"""
    _get_elements(data::Data, collection::String)

Gathers a list containing all instances of the referenced collection.
"""
function _get_elements(data::Data, collection::String)
    _check_collection_in_study(data, collection)

    raw_data = _raw(data)

    return raw_data[collection]::Vector
end

"""
    _get_elements!(data::Data, collection::String)

Gathers a list containing all instances of the referenced collection.

!!! info

    If the instance vector is not present but the collection is still expected, an entry for it will be created.
"""
function _get_elements!(data::Data, collection::String)
    _check_collection_in_study(data, collection)

    raw_data = _raw(data)

    if !haskey(raw_data, collection)
        raw_data[collection] = Dict{String, Any}[]
    end

    return raw_data[collection]::Vector
end

"""
    _get_element(
        data::Data,
        collection::String,
        index::Integer,
    )

Low-level call to retrieve an element, that is, an instance of a class in the
form of a `Dict{String, <:MainTypes}`. It performs basic checks for bounds and
existence of `index` and `collection` according to `data`.
"""
function _get_element(data::Data, collection::String, index::Integer)
    _check_element_range(data, collection, index)

    elements = _get_elements(data, collection)

    return elements[index]
end

function get_element(data::Data, reference_id::Integer)
    collection, index = _get_index(data, reference_id)
    return _get_element(data, collection, index)
end

function get_element(data::Data, collection::String, code::Integer)
    _validate_collection(data, collection)
    collection_struct = data.data_struct[collection]
    index = 0
    if haskey(collection_struct, "code")
        index = _get_index_by_code(data, collection, code)
    else
        error("Collection '$collection' does not have a code attribute")
    end

    return _get_element(data, collection, index)
end
