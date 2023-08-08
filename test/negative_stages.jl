function test_negative_stages(; depth = 100)
    @testset "Negative Stages" begin
        path = joinpath(@__DIR__, "data", "case_negative", "inflow")
        io_r = PSRI.open(PSRI.OpenBinary.Reader, path; use_header = false)

        src_table = CSV.read(
            "$path.csv", DataFrames.DataFrame;
            header = 4,
            skipto = 5,
        )

        dst_table = DataFrames.DataFrame(
            PSRI.GrafTable{Float64}(path; use_header = false)
        )

        @testset "Read" begin
            @test PSRI.goto(io_r, -5, 1, 1) === nothing

            @test_throws AssertionError PSRI.goto(io_r, -6, 1, 1)

            # Check size first
            @test size(src_table) == size(dst_table)

            # Compare both ends
            @test Matrix(src_table[begin:depth, :]) ≈ Matrix(dst_table[begin:depth, :])
            @test Matrix(src_table[depth:end, :]) ≈ Matrix(dst_table[depth:end, :])
        end

        temp_path = tempname()

        io_w = PSRI.open(
            PSRI.OpenBinary.Writer,
            temp_path;
            first_relative_stage = -5,
            unit      = io_r.unit,
            stages    = io_r.stage_total,
            blocks    = io_r.block_total,
            scenarios = io_r.scenario_total,
            agents    = io_r.agent_names,
        )
        
        @testset "Write" begin
            @test io_w.first_relative_stage == -5

            for row in eachrow(src_table)
                t, s, b, data... = row

                cache = collect(Float64, data)

                PSRI.write_registry(io_w, cache, t, s, b)
            end
        end

        PSRI.close(io_w)
        PSRI.close(io_r)
    end

    return nothing
end

test_negative_stages()
