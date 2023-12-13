function _create_study_collection(
    data::Data,
    collection::String,
    defaults::Union{Dict{String, Any}, Nothing},
)
    PSRI.create_element!(data, collection; defaults = defaults)

    return nothing
end
