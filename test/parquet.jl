#=
# package installation -- only needed once
using Pkg
Pkg.add("Parquet2")
Pkg.add("PSRClassesInterface")
=#

#=
    Library loading
=#
import Parquet2
import PSRClassesInterface

#=
    File to convert
=#
file_path = pwd()
file_names = String["gerter"]

#=
    Function to convert a single bin into parquet
=#
function psrbin_to_parquet(FILE_PATH::String, FILE_NAME::String)
    #=
        Constants definition
    =#
    PSRI = PSRClassesInterface
    STAGE_REF = 1
    SCENARIO_REF = 2
    BLOCK_REF = 3
    NAMES_REF = [:stage, :scenario, :block]

    #=
        Open PSR's binary file
    =#
    bin_input = PSRI.open(
        PSRI.OpenBinary.Reader,
        joinpath(FILE_PATH, FILE_NAME);
        use_header = false
    )

    #=
        Metadata reading
    =#

    @assert !PSRI.is_hourly(bin_input)

    n_stages = PSRI.max_stages(bin_input)
    n_scenarios = PSRI.max_scenarios(bin_input)
    n_blocks = PSRI.max_blocks(bin_input)
    n_agents = PSRI.max_agents(bin_input)

    # For hourly files
    # PSRI.max_blocks_stage
    # PSRI.max_blocks_current

    initial_stage = PSRI.initial_stage(bin_input)
    initial_year = PSRI.initial_year(bin_input)
    data_unit = PSRI.data_unit(bin_input)

    agent_names = deepcopy(PSRI.agent_names(bin_input))

    #=
        Allocate table like data
    =#

    data_from_file = [zeros(n_blocks * n_scenarios * n_stages) for i in 1:n_agents]
    ref_from_file = [zeros(n_blocks * n_scenarios * n_stages) for i in 1:3]

    #=
        Read data
    =#
    global line = 0
    for stage = 1:n_stages, scenario = 1:n_scenarios, block = 1:n_blocks
        PSRI.goto(bin_input, stage, scenario, block)
        # PSRI.next_registry(bin_input)
        global line += 1
        ref_from_file[STAGE_REF][line] = stage
        ref_from_file[SCENARIO_REF][line] = scenario
        ref_from_file[BLOCK_REF][line] = block
        for agent in 1:n_agents
            data_from_file[agent][line] = bin_input.data[agent]
        end
    end
    @assert line == n_blocks * n_scenarios * n_stages

    #=
        Finalize reader
    =#
    PSRI.close(bin_input)

    #=
        Build tables
    =#
    table = Dict{Symbol, Vector{Float64}}()
    for col in 1:3
        table[NAMES_REF[col]] = ref_from_file[col]
    end
    for agent in 1:n_agents
        table[Symbol(agent_names[agent])] = data_from_file[agent]
    end

    #=
        Build metadata
    =#
    metadata = Dict(
        "initial_stage" => "$initial_stage",
        "initial_year" => "$initial_year",
        "data_unit" => data_unit,
    )

    #=
        Write Parquet file
    =#
    ret = Parquet2.writefile(
        joinpath(FILE_PATH, FILE_NAME * ".parq"),
        table;
        # npages=2,  # number of pages per column
        compression_codec = :snappy, # Dict("A" => :zstd, "B" => :snappy),  # compression codec per column
        # column_metadata = "A" => Dict("frank" => "reynolds"),  # per column auxiliary metadata
        metadata = metadata,  # file wide metadata
        )

    #=
        remove original files
    =#
    # rm(joinpath(FILE_PATH, FILE_NAME * ".bin"); force = true)
    # rm(joinpath(FILE_PATH, FILE_NAME * ".hdr"); force = true)
    return ret
end

#=
    Function to convert multiple bin into multiple parquet
=#
function psrbin_to_parquet(FILE_PATH::String, FILE_NAMES::Vector{String})
    for i in eachindex(FILE_NAMES)
        psrbin_to_parquet(FILE_PATH, FILE_NAMES[i])
    end
    return
end

#=
    Call to multiple converter
=#
psrbin_to_parquet(file_path, file_names)


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

#=
    Example file writer for experimentation
=#
function example_file_writer(FILE_PATH::String, FILE_NAME::String)
    n_blocks = 21
    n_scenarios = 2000
    n_stages = 60
    n_agents = 100

    time_series_data = rand(Float64, n_agents, n_blocks, n_scenarios, n_stages);

    FILE_PATH = joinpath(FILE_PATH, FILE_NAME)

    PSRI.array_to_file(
        PSRI.OpenBinary.Writer,
        FILE_PATH,
        time_series_data,
        agents = ["Agent $(i)" for i in 1:n_agents],
        unit = "MW";
        initial_stage = 3,
        initial_year = 2006,
    );
    return
end

#=
    Example file writer call
=#
# example_file_writer(file_path, file_names[1])

#=
    Simple load of PSR bin into julia
=#
# data_from_file = PSRI.file_to_array(
#     PSRI.OpenBinary.Reader,
#     joinpath(FILE_PATH, FILE_NAME);
#     use_header=false
# )
