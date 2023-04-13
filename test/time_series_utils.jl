function rm_bin_hdr(file::String)
    rm(file * ".bin")
    return rm(file * ".hdr")
end

# TODO: add conver tes from bin do single bin and vice versa

function create_time_series(
    filename::String;
    blocks::Int = 3,
    scenarios::Int = 10,
    stages::Int = 12,
    unit::String = "MW",
    initial_stage::Int = 1,
    initial_year::Int = 2006,
    agents::Vector{String} = ["X", "Y", "Z"],
    offset::Real = 0,
)
    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        filename;
        blocks = blocks,
        scenarios = scenarios,
        stages = stages,
        agents = agents,
        unit = unit,
        # optional:
        initial_stage = initial_stage,
        initial_year = initial_year,
    )

    n_agents = length(agents)
    registry_data = collect(1:n_agents) .+ offset

    for estagio in 1:stages, serie in 1:scenarios, bloco in 1:blocks
        PSRI.write_registry(
            iow,
            registry_data,
            estagio,
            serie,
            bloco,
        )
    end
    PSRI.close(iow)
    return filename
end

function test_is_equal()
    # Case of equal time series
    file_1 = create_time_series(joinpath(".", "test_isequal_1"))
    file_2 = create_time_series(joinpath(".", "test_isequal_2"))
    ior1 = PSRI.open(PSRI.OpenBinary.Reader, file_1; use_header = false)
    ior2 = PSRI.open(PSRI.OpenBinary.Reader, file_2; use_header = false)
    @test PSRI.is_equal(ior1, ior2)
    PSRI.close(ior1)
    PSRI.close(ior2)
    rm_bin_hdr(file_1)
    rm_bin_hdr(file_2)

    # Cases with different sizes
    file_1 = create_time_series(joinpath(".", "test_isequal_1"); stages = 10)
    file_2 = create_time_series(joinpath(".", "test_isequal_2"); stages = 9)
    ior1 = PSRI.open(PSRI.OpenBinary.Reader, file_1; use_header = false)
    ior2 = PSRI.open(PSRI.OpenBinary.Reader, file_2; use_header = false)
    @test_throws ErrorException PSRI.is_equal(ior1, ior2)
    PSRI.close(ior1)
    PSRI.close(ior2)
    rm_bin_hdr(file_1)
    rm_bin_hdr(file_2)

    file_1 = create_time_series(joinpath(".", "test_isequal_1"); blocks = 3)
    file_2 = create_time_series(joinpath(".", "test_isequal_2"); blocks = 5)
    ior1 = PSRI.open(PSRI.OpenBinary.Reader, file_1; use_header = false)
    ior2 = PSRI.open(PSRI.OpenBinary.Reader, file_2; use_header = false)
    @test_throws ErrorException PSRI.is_equal(ior1, ior2)
    PSRI.close(ior1)
    PSRI.close(ior2)
    rm_bin_hdr(file_1)
    rm_bin_hdr(file_2)

    # Case with different units
    file_1 = create_time_series(joinpath(".", "test_isequal_1"); unit = "MW")
    file_2 = create_time_series(joinpath(".", "test_isequal_2"); unit = "MWm")
    ior1 = PSRI.open(PSRI.OpenBinary.Reader, file_1; use_header = false)
    ior2 = PSRI.open(PSRI.OpenBinary.Reader, file_2; use_header = false)
    @test_throws ErrorException PSRI.is_equal(ior1, ior2)
    PSRI.close(ior1)
    PSRI.close(ior2)
    rm_bin_hdr(file_1)
    rm_bin_hdr(file_2)

    # Case with different agents
    file_1 =
        create_time_series(joinpath(".", "test_isequal_1"); agents = ["W", "X", "Y", "Z"])
    file_2 = create_time_series(joinpath(".", "test_isequal_2"))
    ior1 = PSRI.open(PSRI.OpenBinary.Reader, file_1; use_header = false)
    ior2 = PSRI.open(PSRI.OpenBinary.Reader, file_2; use_header = false)
    @test_throws ErrorException PSRI.is_equal(ior1, ior2)
    PSRI.close(ior1)
    PSRI.close(ior2)
    rm_bin_hdr(file_1)
    rm_bin_hdr(file_2)

    # Case with different initial stages
    file_1 = create_time_series(joinpath(".", "test_isequal_1"); initial_stage = 1)
    file_2 = create_time_series(joinpath(".", "test_isequal_2"); initial_stage = 2)
    ior1 = PSRI.open(PSRI.OpenBinary.Reader, file_1; use_header = false)
    ior2 = PSRI.open(PSRI.OpenBinary.Reader, file_2; use_header = false)
    @test_throws ErrorException PSRI.is_equal(ior1, ior2)
    PSRI.close(ior1)
    PSRI.close(ior2)
    rm_bin_hdr(file_1)
    rm_bin_hdr(file_2)

    # Case with different initial years
    file_1 = create_time_series(joinpath(".", "test_isequal_1"); initial_stage = 1)
    file_2 = create_time_series(joinpath(".", "test_isequal_2"); initial_stage = 2)
    ior1 = PSRI.open(PSRI.OpenBinary.Reader, file_1; use_header = false)
    ior2 = PSRI.open(PSRI.OpenBinary.Reader, file_2; use_header = false)
    @test_throws ErrorException PSRI.is_equal(ior1, ior2)
    PSRI.close(ior1)
    PSRI.close(ior2)
    rm_bin_hdr(file_1)
    rm_bin_hdr(file_2)

    # Case with different data
    file_1 = create_time_series(joinpath(".", "test_isequal_1"); offset = 0)
    file_2 = create_time_series(joinpath(".", "test_isequal_2"); offset = 1)
    ior1 = PSRI.open(PSRI.OpenBinary.Reader, file_1; use_header = false)
    ior2 = PSRI.open(PSRI.OpenBinary.Reader, file_2; use_header = false)
    @test_throws ErrorException PSRI.is_equal(ior1, ior2)
    PSRI.close(ior1)
    PSRI.close(ior2)
    rm_bin_hdr(file_1)
    return rm_bin_hdr(file_2)
end

test_is_equal()

function test_non_unique_agents()
    FILE_PATH = joinpath(".", "example_non_unique_agents")
    @test_throws ErrorException iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        FILE_PATH;
        blocks = 2,
        scenarios = 3,
        stages = 5,
        agents = ["X", "Y", "X"],
        unit = "MW",
        # optional:
        initial_stage = 1,
        initial_year = 2006,
    )
end

test_non_unique_agents()

function test_bin_hdr_array_to_file()
    FILE_PATH = joinpath(".", "test_bin_hdr_array_to_file")
    n_blocks = 2
    n_scenarios = 3
    n_stages = 4
    n_agents = 5

    time_series_data = Array{Float64, 4}(undef, n_agents, n_blocks, n_scenarios, n_stages)
    for t in 1:n_stages, s in 1:n_scenarios, b in 1:n_blocks, a in 1:n_agents
        time_series_data[a, b, s, t] = a + 10 * b + 100 * s + 1000 * t
    end

    PSRI.array_to_file(
        PSRI.OpenBinary.Writer,
        FILE_PATH,
        time_series_data;
        agents = ["Agent 1", "Agent 2", "Agent 3", "Agent 4", "Agent 5"],
        unit = "MW",
        initial_stage = 3,
        initial_year = 2006,
    )

    @test isfile("test_bin_hdr_array_to_file.bin")
    @test isfile("test_bin_hdr_array_to_file.hdr")

    array_from_file = PSRI.file_to_array(
        PSRI.OpenBinary.Reader,
        FILE_PATH;
        use_header = false,
    )

    for t in 1:n_stages, s in 1:n_scenarios, b in 1:n_blocks, a in 1:n_agents
        @test array_from_file[a, b, s, t] == a + 10 * b + 100 * s + 1000 * t
    end

    return rm_bin_hdr("test_bin_hdr_array_to_file")
end

test_bin_hdr_array_to_file()
