import PSRClassesInterface
using Test
const PSRI = PSRClassesInterface

PATH_CASE_0 = joinpath(".", "data", "caso0")

@testset "PSRClassesInterface" begin
    @testset "Read json parameters" begin
        @time include("read_json_parameters.jl")
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
            @time include("OpenBinary/read_and_write_monthly.jl")
        end
        @testset "Read and write with hourlydata" begin
            @time include("OpenBinary/read_and_write_hourly.jl")
        end
    end
end