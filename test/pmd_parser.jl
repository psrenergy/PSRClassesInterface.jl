function test_pmd_parser()
    model_template = PSRI.PMD.load_model_template(
        joinpath(@__DIR__, "..", "src", "json_metadata", "modeltemplates.sddp.json"),
    )

    @testset "SDDP V10.3" begin
        path = joinpath(@__DIR__, "data", "pmd", "Models_SDDP_V10.3.pmd")
        data = PSRI.PMD.parse(path, model_template)

        @test data == PSRI.DataStruct(
            "PSRLoad" => Dict(
                # default
                "AVId" => PSRI.PMD.Attribute("AVId", false, String, 0, ""),
                "name" => PSRI.PMD.Attribute("name", false, String, 0, ""),
                "code" => PSRI.PMD.Attribute("code", false, Int32, 0, ""),
                #parsed
                "P"     => PSRI.PMD.Attribute("P", true, Float64, 1, "Data"),
                "Data"  => PSRI.PMD.Attribute("Data", true, Dates.Date, 0, ""),
                "HourP" => PSRI.PMD.Attribute("HourP", true, Float64, 0, ""),
            ),
        )
    end
end

test_pmd_parser()