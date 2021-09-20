module PSRClassesInterface

using Dates
using JSON
using CSV

@enum StageType STAGE_MONTH=2 STAGE_WEEK=1

@static if VERSION < v"1.6"
    error("Julia version $VERSION not supported by PSRClassesInterface, upgrade to 1.6 or later")
end

# simple and generic interface
include("study_interface.jl")
include("reader_writer_interface.jl")
include("reader_mapper.jl")
include("utils.jl")

include("OpenStudy/study_openinterface.jl")
include("OpenStudy/relations.jl")

# submodules
include("OpenCSV/OpenCSV.jl")
include("OpenBinary/OpenBinary.jl")
include("PMD/PMD.jl")

end