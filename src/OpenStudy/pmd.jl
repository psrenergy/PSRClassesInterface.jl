# Parse pmd accoring to OpenInterface structs

function _parse_pmd!(data_struct, FILE)
    # PSRThermalPlant => GerMax => Attr
    @assert FILE[end-3:end] == ".pmd"
    if !isfile(FILE)
        error("File not found: $FILE")
    end
    inside_model = false
    current_class = ""
    for line in readlines(FILE)
        clean_line = strip(replace(line, '\t' => ' '))
        if startswith(clean_line ,"//") || isempty(clean_line)
            continue
        end
        if inside_model
            if startswith(clean_line ,"END_MODEL")
                inside_model = false
                current_class = ""
                continue
            end
            words = split(clean_line)
            if length(words) >= 3
                if words[1] == "PARM" || words[1] == "VECTOR" || words[1] == "VETOR"
                    # _is_vector(words[1])
                    # _get_type(words[2])
                    name = words[3]
                    dim = 0
                    index = ""
                    interval = "" # TODO: parse "INTERVAL"
                    if length(words) >= 4
                        if startswith(words[4], "DIM") # assume no space inside DIM
                            dim = length(split(words[4], ','))
                        end
                        if startswith(words[4], "INDEX")
                            if length(words) >= 5
                                index = words[5]
                            else
                                error("no index after INDEX key at $name in $current_class")
                            end
                        end
                    end
                    if length(words) >= 5
                        if startswith(words[5], "INDEX")
                            if length(words) >= 6
                                index = words[6]
                            else
                                error("no index after INDEX key at $name in $current_class")
                            end
                        end
                    end
                    data_struct[current_class][name] = Attribute(
                        name,
                        PMD._is_vector(words[1]),
                        PMD._get_type(words[2]),
                        dim,
                        index,
                        # interval,
                    )
                end
            end
        else
            BEGIN = "DEFINE_MODEL MODL:"
            if startswith(clean_line, BEGIN)
                clean_line
                model_name = strip(clean_line[(length(BEGIN)+1):end])
                if haskey(PMD._MODEL_TO_CLASS, model_name)
                    current_class = PMD._MODEL_TO_CLASS[model_name]
                    inside_model = true
                    data_struct[current_class] = Dict{String, Attribute}()
                    # default attributes tha belong to "all classes"
                    data_struct[current_class]["name"] = Attribute(
                        "name", false, String, 0, "")
                    data_struct[current_class]["code"] = Attribute(
                        "code", false, Int32, 0, "")
                    data_struct[current_class]["AVId"] = Attribute(
                        "code", false, String, 0, "")
                    continue
                end
            end
        end
    end
    return data_struct
end

function _load_mask_or_model(path_pmds, data_struct, files, FILES_ADDED)
    str = "Model"
    ext = "pmd"
    if !isempty(files)
        for file in files
            if !isfile(file)
                error("$str $file not found")
            end
            name = basename(file)
            if splitext(name)[2] != ".$ext"
                error("$str $file should contain a .$ext extension")
            end
            if !in(name, FILES_ADDED)
                _parse_pmd!(data_struct, file)
                push!(FILES_ADDED, name)
            end
        end
    else
        names = readdir(path_pmds)
        # names should be basename'd
        for name in names
            if splitext(name)[2] == ".$ext"
                if !in(name, FILES_ADDED)
                    file = joinpath(path_pmds, name)
                    _parse_pmd!(data_struct, file)
                    push!(FILES_ADDED, name)
                end
            end
        end
    end
    return nothing
end