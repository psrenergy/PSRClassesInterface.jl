module PSRClassesInterface

import Dates
import JSON
import JSONSchema

@static if VERSION < v"1.6"
    error("Julia version $VERSION not supported by PSRClassesInterface, upgrade to 1.6 or later")
end

# submodules
include("PMD/PMD.jl")
const Attribute = PMD.Attribute
const DataStruct = PMD.DataStruct

# simple and generic interface
include("study_interface.jl")
include("reader_writer_interface.jl")

# utilities
include("reader_mapper.jl")
include("time_series_utils.jl")
include("utils.jl")

# main interface
include("OpenBinary/OpenBinary.jl")
include("OpenStudy/study_openinterface.jl")
include("OpenStudy/validation.jl")
include("OpenStudy/vector_map.jl")
include("OpenStudy/duration.jl")
include("OpenStudy/relations.jl")

# modification API
include("modification_api.jl")

end