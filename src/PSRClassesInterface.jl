module PSRClassesInterface

import Dates
import JSON

@static if VERSION < v"1.6"
    error("Julia version $VERSION not supported by PSRClassesInterface, upgrade to 1.6 or later")
end

# simple and generic interface
include("study_interface.jl")
include("reader_writer_interface.jl")

# utilities
include("reader_mapper.jl")
include("time_series_utils.jl")
include("utils.jl")

# submodules
include("PMD/PMD.jl")
include("OpenBinary/OpenBinary.jl")

# main interface
include("OpenStudy/pmd.jl")
include("OpenStudy/study_openinterface.jl")
include("OpenStudy/vector_map.jl")
include("OpenStudy/duration.jl")
include("OpenStudy/relations.jl")

end