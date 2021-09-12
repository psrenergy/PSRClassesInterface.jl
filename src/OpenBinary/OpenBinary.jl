module OpenBinary

    import PSRClassesInterface
    import Dates

    const PSRI = PSRClassesInterface

    include("reader.jl")
    include("writer.jl")

end