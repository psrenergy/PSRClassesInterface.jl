import PSRClassesInterface
import Dates
import GrafCSV
import JSON
using Test
const PSRI = PSRClassesInterface

PATH_CASE_0 = joinpath(".", "data", "caso0")

@testset "PSRClassesInterface" begin
    @testset "Read json parameters" begin
        @time include("read_json_parameters.jl")
    end
    @testset "Read json relations" begin
        @time include("read_json2.jl")
        @time include("read_json_relations_3.jl")
    end
    @testset "Read json durations" begin
        @time include("duration.jl")
    end
    @testset "OpenBinary file format" begin
        @testset "Read and write with monthly data" begin
            @time include("OpenBinary/read_and_write_blocks.jl")
        end
        @testset "Read and write with hourly data" begin
            @time include("OpenBinary/read_and_write_hourly.jl")
        end
        @testset "Read hourly data from psrclasses c++" begin
            @time include("OpenBinary/read_hourly.jl")
        end
        
    end
    @testset "ReaderMapper" begin
        @time include("reader_mapper.jl")
    end
    @testset "TS Utils" begin
        @time include("time_series_utils.jl")
    end

    @testset "Study API" begin
        @time include("study_api.jl")
    end
end
