function mapped_graf_vector(
    data::Data,
    mapper::ReaderMapper,
    collection::String,
    attribute::String,
    header::Vector{String},
    filter::Vector{String} = String[], 
)

    graf_file = _get_graf_filename(data, collection, attribute)

    graf_vector = add_reader!(mapper, graf_file, header, filter) 

    return graf_vector
end

