function test_mt1() 
    temp_path = joinpath(tempdir(), "PSRI_MT1")
    json_path = joinpath(temp_path, "psrclasses.json")

    mkpath(temp_path)

    mt_path = joinpath(@__DIR__, "data", "model_template_test", "modeltemplates.test.json")
    pmd_path = joinpath(@__DIR__, "data", "model_template_test", "test.pmd")

    data = PSRI.create_study(
        PSRI.OpenInterface(), 
        data_path = temp_path,
        pmd_files = [pmd_path],
        model_template_path = mt_path
        )
   
    @test PSRI.create_element!(data, "PSRLoad",use_defaults=false,
        "AVId" => "", 
        "Data" => [Dates.Date(2022,1,1)], 
        "HourP" => [0.0], 
        "P" => [0.0], 
        "code" => Int32(0), 
        "name" => "") == 1
    
end



test_mt1()