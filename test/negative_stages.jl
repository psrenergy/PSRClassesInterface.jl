function test_negative_stages()
    @testset "Negative Stages" begin
        path = joinpath(@__DIR__, "data", "case_negative", "inflow")
        graf = PSRI.open(PSRI.OpenBinary.Reader, path; use_header = false)

        @test PSRI.goto(graf, -5, 1, 1) === nothing

        @test_throws AssertionError PSRI.goto(graf, -6, 1, 1)

        src_table = CSV.read(
            "$path.csv", DataFrames.DataFrame;
            header = 4,
            skipto = 5,
        )

        dst_table = DataFrames.DataFrame(PSRI.GrafTable{Float64}(path; use_header = false))

        @test Matrix(src_table[1:10, :]) ≈ Matrix(dst_table[1:10, :])
    end

    return nothing
end

test_negative_stages()
