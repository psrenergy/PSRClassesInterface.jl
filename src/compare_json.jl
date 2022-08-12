const ids_uniq = Set(["plant", "bus", "reference_id", "system", "area", "no1", "no2", "demand",
                      "station", "turbinning", "spilling", "filtration", "storedenergy",
                      "fuel", "downstream"]);
const ids_list = Set(["fuels", "usinas", "plants", "batteries", "elements", "reservoirs",
                      "restricao", "reserveGeneration"]); #backed

function compare(path1::String, path2::String)
    data1 = initialize_study(
        OpenInterface(),
        data_path = path1)
    data2 = initialize_study(
        OpenInterface(),
        data_path = path2
    ) 
    
    return compare(data1, data2)
end

function compare(data1::Data, data2::Data)     
    return compare(data1.raw, data2.raw)
end

function compare(data1::Dict, data2::Dict)

    logs = String[]
    ids1 = Dict()
    ids2 = Dict()
    address = "" 
    
    compare!(data1, data2, address, logs, ids1, ids2)
    return logs
end

function compare!(
    d1::Dict,
    d2::Dict,
    address::String,
    logs::Vector{String},
    ids1::Dict,
    ids2::Dict,
    )
    _deal_with_dict!(d1, d2, address, logs, ids1, ids2)
    nothing
end

function compare!(
    d1::Array,
    d2::Array, 
    address::String,
    logs::Vector{String},
    ids1::Dict,
    ids2::Dict,
    )
    _deal_with_list!(d1, d2, address, logs, ids1, ids2)
    nothing
end

function compare!(
    d1,
    d2,
    address::String,
    logs::Vector{String},
    ids1::Dict,
    ids2::Dict,
    )
    _deal_with_value!(d1, d2, address, logs)
    nothing
end

function _deal_with_id_uniq!(
    d1,
    d2,
    key,
    address::String,
    logs::Vector{String},
    ids1::Dict,
    ids2::Dict,
    )

    index1 = haskey(ids1, d1)
    index2 = haskey(ids2, d2)
    if !index1 && !index2 #check if they dont have the key
        ids1[d1] = address * "[$(key)]"
        ids2[d2] = address * "[$(key)]"
    elseif index1 ⊻ index2 #check if JUST one of then have the key
        push!(logs, address * "[$(key)]") 
    elseif ids1[d1] == ids2[d2] #check if they have the same value
        nothing
    else # they dont have the same value
        push!(logs, address * "[$(key)]") 
    end
    nothing
end

function _deal_with_id_list!(
    d1::Array,
    d2::Array,
    address::String,
    logs::Vector{String},
    ids1::Dict,
    ids2::Dict,
    )
    for item in union(eachindex(d1), eachindex(d2)) #loop in array
        if item <= min(length(d1),length(d2)) # check if they have the same index
            _deal_with_id_uniq!(d1[item], d2[item], item, address, logs, ids1, ids2)
        else # check if they have the same index
            push!(logs, address * "[$(item)]") 
        end
    end
    nothing
end

function _deal_with_dict!(
    d1::Dict,
    d2::Dict,
    address::String,
    logs::Vector{String},
    ids1::Dict,
    ids2::Dict,
    )
    for key in union(keys(d1),keys(d2))
        if haskey(d1, key) && haskey(d2, key) #check if both have the key
            if !(key in ids_uniq) && !(key in ids_list)# non id flag
                compare!(d1[key],d2[key], address*"[$key]",logs, ids1, ids2)
            elseif key in ids_uniq #id uniq
                _deal_with_id_uniq!(d1[key], d2[key], key, address, logs, ids1, ids2)
            elseif key in ids_list #id list
                _deal_with_id_list!(d1[key], d2[key], address * "[$key]", logs, ids1, ids2)
            else
                error("You should not be here!")
            end
        else #they dont have the same key
            push!(logs, address * "[$(key)]") 
        end
    end
    nothing
end

function _deal_with_list!(
    d1::Array,
    d2::Array,
    address::String,
    logs::Vector{String},
    ids1::Dict,
    ids2::Dict,
    )
    for item in union(eachindex(d1), eachindex(d2)) #loop in array
        if item <= min(length(d1),length(d2)) # check if they have the same index
            compare!(d1[item],d2[item], address*"[$item]",logs, ids1, ids2)
        else # check if they have the same index
            push!(logs, address * "[$(item)]") 
        end
    end
    nothing
end

function _deal_with_value!(
    d1,
    d2,
    address::String,
    logs::Vector{String},
    )
    if d1 != d2 # check if they have not the same value
        push!(logs, address) 
    else # they have the same value
        nothing
    end
    nothing
end