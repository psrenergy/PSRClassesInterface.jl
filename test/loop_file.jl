PATH_CASE_0 = joinpath(@__DIR__, "data", "case0")

data = PSRI.load_study(
    PSRI.OpenInterface();
    data_path = PATH_CASE_0,
)

data_bin = PSRI.load_study(
    PSRI.OpenInterface();
    data_path = PATH_CASE_0,
)

collections = PSRI.get_collections(data)

verbose = false

function _fixed_get_name(data, col)
    if col == "PSRDemandSegment"
        dem_name = PSRI.get_name(data, "PSRDemand")
        rel = PSRI.get_map(data, "PSRDemandSegment", "PSRDemand")
        count_dems = zeros(Int, length(dem_name))
        names = String[]
        for i in rel
            count_dems[i] += 1
            push!(names, dem_name[i] * "_s$(count_dems[i])")
        end
        return strip.(names)
    end
    return strip.(PSRI.get_name(data, col))
end

for col in collections
    if verbose
        println("Collection: $col")
    end
    n = PSRI.max_elements(data, col)
    names = _fixed_get_name(data, col)
    @assert length(names) == n
    @assert allunique(names)

    names_bin = _fixed_get_name(data_bin, col)
    @assert allunique(names_bin)

    n_bin = length(names_bin)
    if n_bin != n
        error("number of elementos in collection $col inconsistent (json=$n, bin=$n_bin)")
    end

    json_to_bin = Int[]
    for i in eachindex(names)
        name = names[i]
        j = findfirst(isequal(name), names_bin)
        if j === nothing
            error("Element $(name) of json no foun in bin ($(names_bin))")
        end
        push!(json_to_bin, j)
    end
    if verbose
        @show(json_to_bin)
    end
    attributes = PSRI.get_attributes(data, col)
    for attr in attributes
        if verbose
            println("    Attribute: $attr")
        end
        if attr == "AVId"
            if verbose
                println("    * skiping AVId")
            end
            continue
        end
        attribute_struct = PSRI.get_attribute_struct(data, col, attr)
        type = attribute_struct.type
        dim = attribute_struct.dim
        index = attribute_struct.index
        if !attribute_struct.is_vector
            if dim == 0
                parm_json = PSRI.get_parms(data, col, attr, type)[json_to_bin]
                parm_bin = PSRI.get_parms(data_bin, col, attr, type)
                @assert parm_json == parm_bin
            elseif dim == 1
                parm_json = PSRI.get_parms_1d(data, col, attr, type)[json_to_bin]
                parm_bin = PSRI.get_parms_1d(data_bin, col, attr, type)
                @assert parm_json == parm_bin
            elseif dim == 2
                parm_json = PSRI.get_parms_2d(data, col, attr, type)[json_to_bin]
                parm_bin = PSRI.get_parms_2d(data_bin, col, attr, type)
                @assert parm_json == parm_bin
            elseif verbose
                println("$col-$attr (parm) has dim = $dim")
            end
        else
            if dim == 0
                parm_json = PSRI.get_vectors(data, col, attr, type)[json_to_bin]
                parm_bin = PSRI.get_vectors(data_bin, col, attr, type)
                @assert parm_json == parm_bin
            elseif dim == 1
                parm_json = PSRI.get_vectors_1d(data, col, attr, type)[json_to_bin]
                parm_bin = PSRI.get_vectors_1d(data_bin, col, attr, type)
                @assert parm_json == parm_bin
            elseif dim == 2
                parm_json = PSRI.get_vectors_2d(data, col, attr, type)[json_to_bin]
                parm_bin = PSRI.get_vectors_2d(data_bin, col, attr, type)
                @assert parm_json == parm_bin
            elseif verbose
                println("$col-$attr (vector) has dim = $dim")
            end
        end
    end

    relations = PSRI.get_relations(data, col)

    for (target, relations_dict) in relations
        for relation in values(relations_dict)
            if verbose
                println("Relation: ($col)-($target) of type $(relation.type)")
            end
            if PSRI.is_vector_relation(relation.type)
                parm_json =
                    PSRI.get_vector_map(data, col, target; relation_type = relation.type)[json_to_bin]
                parm_bin = PSRI.get_vector_map(
                    data_bin,
                    col,
                    target;
                    relation_type = relation.type,
                )
                @assert parm_json == parm_bin
            else
                parm_json =
                    PSRI.get_map(data, col, target; relation_type = relation.type)[json_to_bin]
                parm_bin =
                    PSRI.get_map(data_bin, col, target; relation_type = relation.type)
                @assert parm_json == parm_bin
            end
        end
    end
end
