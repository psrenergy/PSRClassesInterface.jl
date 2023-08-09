function test_nonpositive_indices()
    path = joinpath(@__DIR__, "..", "data", "case5", "inflow")

    io_r = PSRI.open(PSRI.OpenBinary.Reader, path; use_header = false)

    @test io_r isa PSRI.OpenBinary.Reader
    @test io_r.initial_stage == 5
    @test io_r.first_stage == -5
    @test io_r.relative_stage_skip == 0
    @test PSRI.OpenBinary._get_position(
        io_r,
        io_r.first_stage,
        1,
        1,
    ) == 0

    src_table = CSV.read(
        "$path.csv", DataFrames.DataFrame;
        header = 4,
        skipto = 5,
    )

    dst_table = DataFrames.DataFrame(
        PSRI.GrafTable{Float64}(path; use_header = false),
    )

    @testset "Read" begin
        @test PSRI.goto(io_r, -5, 1, 1) === nothing

        @test_throws AssertionError PSRI.goto(io_r, -6, 1, 1)

        @test size(src_table) == size(dst_table) # Check size first

        @test Matrix(src_table) ≈ Matrix(dst_table)
    end

    temp_path = tempname()

    io_w = PSRI.open(
        PSRI.OpenBinary.Writer,
        temp_path;
        first_stage = -5,
        unit = io_r.unit,
        stages = io_r.stage_total,
        blocks = io_r.block_total,
        scenarios = io_r.scenario_total,
        agents = io_r.agent_names,
    )

    @testset "Write" begin
        @test io_w.first_stage == -5

        for row in eachrow(src_table)
            t, s, b, data... = row

            cache = collect(Float64, data)

            PSRI.write_registry(io_w, cache, t, s, b)
        end
    end

    PSRI.close(io_w)
    PSRI.close(io_r)

    return nothing
end

test_nonpositive_indices()
