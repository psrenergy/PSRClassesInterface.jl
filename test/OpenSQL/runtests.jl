using Test

function test_modules(dir::AbstractString)
    result = String[]
    for (root, dirs, files) in walkdir(dir)
        append!(result, filter!(f -> occursin(r"test_(.)+\.jl", f), joinpath.(root, files)))
    end
    return result
end

for file in test_modules(@__DIR__)
    @testset "$(basename(file))" begin
        include(file)
    end
end