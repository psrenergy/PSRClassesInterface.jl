import PSRClassesInterface
using Test
const PSRI = PSRClassesInterface

PATH_CASE_0 = joinpath(".", "data", "caso0")

@testset "PSRClassesInterface" begin
    @testset "Read json parameters" begin 
        include("read_json_parameters.jl") 
    end
    @testset "Read and write with monthly case using OpenCSV file format" begin 
        include("read_and_write_monthly_csv.jl") 
    end
    @testset "Read and write with hourly case using OpenCSV file format" begin 
        include("read_and_write_hourly_csv.jl") 
    end
end