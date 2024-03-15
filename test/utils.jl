function test_merge()
    dict1 = Dict{String, Any}(
        "PSR_1" => Dict{String, Any}(
            "PSR_1_1" => Dict{String, Any}(
                "value" => 10,
                "another" => 9,
            ),
        ),
        "PSR_2" => Dict{String, Any}(
            "test" => 5,
        ),
    )

    dict2 = Dict{String, Any}(
        "PSR_1" => Dict{String, Any}(
            "PSR_1_1" => Dict{String, Any}(
                "value" => 3,
            ),
        ),
    )

    result = Dict{String, Any}(
        "PSR_1" => Dict{String, Any}(
            "PSR_1_1" => Dict{String, Any}(
                "value" => 3,
                "another" => 9,
            ),
        ),
        "PSR_2" => Dict{String, Any}(
            "test" => 5,
        ),
    )

    PSRI.merge_defaults!(dict1, dict2)

    @test result == dict1
end

test_merge()
