import PSRClassesInterface
import Dates
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
    @testset "OpenCSV file format" begin
        @testset "Read and write with monthlydata" begin
            @time include("OpenCSV/read_and_write_monthly.jl")
        end
        @testset "Read and write with hourlydata" begin
            @time include("OpenCSV/read_and_write_hourly.jl")
        end
    end
    @testset "OpenBinary file format" begin
        @testset "Read and write with monthlydata" begin
            @time include("OpenBinary/read_and_write_blocks.jl")
        end
        @testset "Read and write with hourlydata" begin
            @time include("OpenBinary/read_and_write_hourly.jl")
        end
    end
    @testset "ReaderMapper" begin
        @time include("reader_mapper.jl")
    end
    @testset "TS Utils" begin
        @time include("time_series_utils.jl")
    end
end