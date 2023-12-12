
function PSRI.delete_relation!(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    target_index::Integer,
)
    relations_as_source, _ = _get_element_related(data, source, source_index)

    source_element = _get_element(data, source, source_index)
    target_element = _get_element(data, target, target_index)

    if haskey(relations_as_source, target)
        for (relation_attribute, _) in relations_as_source[target]
            if source_element[relation_attribute] == target_element["reference_id"]
                delete!(source_element, relation_attribute)
            end
        end
    else
        error(
            "Relation between element from '$source'(Source) with element from '$target'(Target) does not exist",
        )
    end

    return nothing
end

function PSRI.delete_vector_relation!(
    data::Data,
    source::String,
    target::String,
    source_index::Integer,
    target_indices::Vector{Int},
)
    relations_as_source, _ = _get_element_related(data, source, source_index)

    source_element = _get_element(data, source, source_index)
    targets_ref_id = [
        _get_element(data, target, target_index)["reference_id"] for
        target_index in target_indices
    ]

    if haskey(relations_as_source, target)
        for (relation_attribute, _) in relations_as_source[target]
            if sort(source_element[relation_attribute]) == sort(targets_ref_id)
                delete!(source_element, relation_attribute)
            end
        end
    else
        error(
            "Relation between element from '$source'(Source) with element from '$target'(Target) does not exist",
        )
    end

    return nothing
end

function PSRI.delete_element!(data::Data, collection::String, index::Int)
    if !PSRI.has_relations(data, collection, index)
        elements = _get_elements(data, collection)

        element_id = elements[index]["reference_id"]

        # Remove element reference from data_index by its id
        delete!(data.data_index.index, element_id)

        # Remove element from collection vector by its index
        deleteat!(elements, index)
    else
        error(
            "Element $collection cannot be deleted because it has relations with other elements",
        )
    end
    return nothing
end
