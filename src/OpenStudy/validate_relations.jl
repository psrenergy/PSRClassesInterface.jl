
"""
    _check_relation(data::Data, source::String)

    Returns an error message if there is no relation where collection 'source' is the source element
"""
function validate_relation(data::Data, source::String)
    if !haskey(data.relation_mapper, source)
        error("Collection $(source) is not the source for any relation in this study")
    end
end

"""
    validate_relation(data::Data, source::String, target::String)

    Returns an error message if there is no relation between collections 'source' and 'target'
"""
function validate_relation(data::Data, source::String, target::String)
    validate_relation(data, source)

    if !haskey(data.relation_mapper[source], target)
        if !haskey(data.relation_mapper, target) ||
           !haskey(data.relation_mapper[target], source)
            error("No relation from $source to $target.")
        end
        if haskey(data.relation_mapper, target) &&
           haskey(data.relation_mapper[target], source)
            error(
                "No relation from $source to $target." *
                "There is a reverse relation from $target to $source.",
            )
        end
    end
end

"""
    validate_relation(data::Data, source::String, target::String, relation_type::PSRI.PMD.RelationType)

    Returns an error message if there is no relation between collections 'source' and 'target' with type 'relation_type'
"""
function validate_relation(
    data::Data,
    source::String,
    target::String,
    relation_type::PSRI.PMD.RelationType,
)
    validate_relation(data, source, target)

    if !_has_relation_type(data.relation_mapper[source][target], relation_type)
        if haskey(data.relation_mapper, target) &&
           haskey(data.relation_mapper[target], source)
            if _has_relation_type(data.relation_mapper[target][source], relation_type)
                error(
                    "No relation from $(source) to $(target) with type $(relation_type)." *
                    " The there is a reverse relation from $(target) to " *
                    "$(source)  with type $(relation_type).",
                )
            end
        end
        error(
            "There is no relation with type $(relation_type) between collections $(source) and $(target)",
        )
    end
end

"""
    validate_relation(data::Data, source::String, target::String, relation_attribute::String)

    Returns an error message if there is no relation between collections 'source' and 'target' with attribute 'relation_attribute'
"""
function validate_relation(
    data::Data,
    source::String,
    target::String,
    relation_attribute::String,
)
    validate_relation(data, source, target)

    if !_has_relation_attribute(data.relation_mapper[source][target], relation_attribute)
        if haskey(data.relation_mapper, target) &&
           haskey(data.relation_mapper[target], source)
            if _has_relation_attribute(
                data.relation_mapper[target][source],
                relation_attribute,
            )
                error(
                    "No relation from $(source) to $(target) with attribute $(relation_attribute)." *
                    " The there is a reverse relation from $(target) to " *
                    "$(source)  with attribute $(relation_attribute).",
                )
            end
        end
        error(
            "There is no relation with attribute $(relation_attribute) between collections $(source) and $(target)",
        )
    end
end
