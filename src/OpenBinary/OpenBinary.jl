module OpenBinary

import PSRClassesInterface
# Load packages defined in the upper module PSRClassesInterface
import PSRClassesInterface.Dates

const PSRI = PSRClassesInterface

include("reader.jl")
include("writer.jl")

function PSRI.convert_file(
    ::Type{Reader},
    ::Type{Writer},
    path_from::String;
    path_to::String = "",
)
    error("Conversion with OpenBinary.Reader and OpenBinary.Writer is a no op.")
end

end