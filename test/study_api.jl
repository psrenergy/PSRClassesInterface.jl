function test_api(data_path::String)
    temp_path = joinpath(tempdir(), "PSRCI")
    json_path = joinpath(temp_path, "psrclasses.json")

    mkpath(temp_path)

    src_data = PSRI.initialize_study(PSRI.OpenInterface(); data_path=data_path)
    raw_data = PSRI._raw(src_data)::Dict{String,<:Any}

    open(json_path, "w") do io
        JSON.print(io, raw_data)
    end
    
    dest_data = PSRI.initialize_study(PSRI.OpenInterface(); data_path=temp_path)

    @test PSRI._raw(src_data) == PSRI._raw(dest_data)
end

test_api(PATH_CASE_0)