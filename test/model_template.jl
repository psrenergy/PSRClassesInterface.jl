function test_model_template1()
    temp_path = joinpath(tempdir(), "PSRI_MT1")
    json_path = joinpath(temp_path, "psrclasses.json")

    mkpath(temp_path)

    mt_path = joinpath(@__DIR__, "data", "model_template_test", "modeltemplates.test.json")
    pmd_path = joinpath(@__DIR__, "data", "model_template_test", "test.pmd")

    data = PSRI.create_study(
        PSRI.OpenInterface();
        data_path = temp_path,
        pmd_files = [pmd_path],
        model_template_path = mt_path,
        study_collection = "NewStudy",
        defaults = Dict{String, Any}(
            "NewStudy" => Dict{String, Any}(
                "Idioma" => Int32(0),
                "AVId" => "id",
                "name" => "very new study",
                "code" => Int32(0),
            ),
        ),
    )

    let index = PSRI.create_element!(
            data,
            "PSRLoad",
            "AVId" => "test",
            "Data" => [Dates.Date(2022, 1, 1)],
            "HourP" => [0.0],
            "P(1)" => [0.0],
            "code" => Int32(5),
            "name" => "";
            defaults = nothing,
        )
        @test index == 1
    end

    PSRI.write_data(data)

    data_struct_path = joinpath(temp_path, "struct.json")

    PSRI.OpenStudy.dump_json_struct(data_struct_path, data)

    mt_copy_path = joinpath(temp_path, "modeltemplate.copy.json")

    # TODO - test resulting file at `mt_copy_path`
    PSRI.PMD.dump_model_template(mt_copy_path, data)

    data_copy = PSRI.load_study(
        PSRI.OpenInterface();
        data_path = temp_path,
        json_struct_path = data_struct_path,
        model_template_path = mt_copy_path,
        study_collection = "NewStudy",
    )

    let element = PSRI.OpenStudy.get_element(data_copy, "PSRLoad", Int32(5))
        @test element["AVId"] == "test"
    end

    let index = PSRI.create_element!(
            data_copy,
            "PSRLoad",
            "AVId" => "test",
            "Data" => [Dates.Date(2022, 1, 1)],
            "HourP" => [0.0],
            "P(1)" => [0.0],
            "code" => Int32(7),
            "name" => "";
            defaults = nothing,
        )
        @test index == 2
    end
end

test_model_template1()
