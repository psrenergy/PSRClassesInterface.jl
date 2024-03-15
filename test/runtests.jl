import PSRClassesInterface
import Dates
import CSV
import DataFrames

using Test
const PSRI = PSRClassesInterface

@testset "File Loop" begin
    @time include("loop_file.jl")
end
@testset "PSRClassesInterface" begin
    @testset "PMD Parser" begin
        @time include("pmd_parser.jl")
    end
    @testset "Read json parameters" begin
        @time include("read_json_parameters.jl")
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
        @testset "Read data with Nonpositive Indices" begin
            @time include("OpenBinary/nonpositive_indices.jl")
        end
        @testset "Write file partially" begin
            @time include("OpenBinary/incomplete_file.jl")
        end
    end
    @testset "ReaderMapper" begin
        @time include("reader_mapper.jl")
    end
    @testset "TS Utils" begin
        @time include("time_series_utils.jl")
    end
    @testset "Modification API" begin
        @time include("modification_api.jl")
        @time include("custom_study.jl")
    end
    @testset "Model Template" begin
        @time include("model_template.jl")
    end
    @testset "Relations" begin
        @time include("relations.jl")
    end
    @testset "Graf Files" begin
        @time include("graf_files.jl")
    end
    @testset "Utils" begin
        @time include("utils.jl")
    end
    @testset "OpenSQL" begin
        @time include("OpenSQL/create_case.jl")
        @time include("OpenSQL/time_series.jl")
        @time include("OpenSQL/test_utils.jl")
        @time include("OpenSQL/test_pragmas.jl")
        @time include(
            "OpenSQL/migrations_tests/test_chaining_migrations/test_chaining_migrations.jl",
        )
        @time include(
            "OpenSQL/migrations_tests/test_create_table_migration/test_create_table_migration.jl",
        )
        @time include(
            "OpenSQL/migrations_tests/test_invalid_migrations/test_invalid_migrations.jl",
        )
        @time include(
            "OpenSQL/migrations_tests/test_some_common_errors/test_some_common_errors.jl",
        )
    end
end
