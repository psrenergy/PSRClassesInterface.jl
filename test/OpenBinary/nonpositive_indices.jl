function test_nonpositive_indices()
    case_path = joinpath(@__DIR__, "..", "data", "case5", "inflow")

    ior = PSRI.open(
        PSRI.OpenBinary.Reader,
        case_path;
        use_header = false,
    )

    @test ior isa PSRI.OpenBinary.Reader
    @test ior.first_stage == 1
    @test ior.first_relative_stage == -5
    @test ior.relative_stage_skip == 0
    @test PSRI.OpenBinary._get_position(
        ior,
        ior.first_relative_stage,
        1,
        1,
    ) == 0

    return nothing
end

test_nonpositive_indices()
