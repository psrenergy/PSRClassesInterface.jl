const ids_uniq = ["plant", "bus", "reference_id", "system", "area", "no1", "no2"];
const ids_list = ["fuels"];

function compare(path1::String, path2::String)
    data1 = PSRI.initialize_study(
        PSRI.OpenInterface(),
        data_path = path1)
    data2 = PSRI.initialize_study(
        PSRI.OpenInterface(),
        data_path = path2
    )
    logs, ids = PSRI.compare(data1.raw, data2.raw)
    return logs, ids
end

function compare(d1, d2, adress = "", logs = "", ids = Dict(1 => Dict(), 2 => Dict()))
    if isa(d1,Dict) && isa(d2,Dict)#dict check
        logs, ids = _deal_with_dict(ids, d1, d2, adress, logs)
    elseif isa(d1, Array) && isa(d2, Array) #array check
        logs, ids = _deal_with_list(ids, d1, d2, adress, logs)
    else #just a value
        logs, ids = _deal_with_value(ids, d1, d2, adress, logs)
    end
    return logs, ids
end

function _deal_with_id_uniq(ids, d1, d2, key, adress, logs)
    index1 = haskey(ids[1], d1)
    index2 = haskey(ids[2], d2)

    if !index1 && !index2 #check if they dont have the key
        ids[1][d1] = adress
        ids[2][d2] = adress
    elseif index1 ⊻ index2 #check if JUST one of then have the key
        logs = logs * adress * "[$(key)]\n"
    elseif ids[1][d1] == ids[2][d2] #check if they have the same value
        nothing
    else # they dont have the same value
        logs = logs * adress * "[$(key)]\n"
    end
    return logs, ids
end

function _deal_with_id_list(ids, d1, d2, adress, logs)
    for item in union(eachindex(d1), eachindex(d2)) #loop in array
        if item <= min(length(d1),length(d2)) # check if they have the same index
            logs, ids = _deal_with_id_uniq(ids, d1[item], d2[item], item, adress, logs)
        else # check if they have the same index
            logs = logs * adress * "[$(item)]\n"
        end
    end
    return logs, ids
end

function _deal_with_dict(ids, d1, d2, adress, logs)
    for key in union(keys(d1),keys(d2))
        if haskey(d1, key) && haskey(d2, key) #check if both have the key
            if !(key in ids_uniq)  && !(key in ids_list)# non id flag
                logs, ids = compare(d1[key],d2[key], adress*"[$key]",logs, ids)
            elseif key in ids_uniq #id uniq
                logs, ids = _deal_with_id_uniq(ids, d1[key], d2[key], key, adress, logs)
            elseif key in ids_list #id list
                logs, ids = _deal_with_id_list(ids, d1[key], d2[key], adress * "[$key]", logs)
            else
                error("You should not be here!")
            end
        else #they dont have the same key
            logs = logs * adress * "[$(key)]\n"
        end
    end
    return logs, ids
end

function _deal_with_list(ids, d1, d2, adress, logs)
    for item in union(eachindex(d1), eachindex(d2)) #loop in array
        if item <= min(length(d1),length(d2)) # check if they have the same index
            logs, ids = compare(d1[item],d2[item], adress*"[$item]",logs, ids)
        else # check if they have the same index
            logs = logs * adress * "[$(item)]\n"
        end
    end
    return logs, ids
end

function _deal_with_value(ids, d1, d2, adress, logs)
    if d1 != d2 # check if they have not the same value
        logs = logs * adress * "\n"
    else # they have the same value
        nothing
    end
    return logs, ids
end

# example
# dict1 = Dict("a"=>1,"b"=>[Dict("reference_id" => 3), 2, 3], "fuels" => [3, 3]);
# dict2 = Dict("a"=>3,"b"=>[Dict("reference_id" => 2), 2, 1, 4], "c" => true, "fuels" => [2, 3]);
# logs, ids = compare(dict1, dict2);
# print(logs)