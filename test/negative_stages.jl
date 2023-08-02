function test_negative_stages()
    @testset "Negative Stages" begin
        path = joinpath(@__DIR__, "data", "case_negative", "inflow")
        graf = PSRI.open(PSRI.OpenBinary.Reader, path; use_header = false)

        PSRI.goto(graf, -1, 1, 1); @test true
        PSRI.goto(graf, -5, 1, 1); @test true
        @test_throws AssertionError PSRI.goto(graf, -6, 1, 1)
    end

    return nothing
end

test_negative_stages()
