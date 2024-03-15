module OpenBinary

import PSRClassesInterface
import Dates
import Encodings

const PSRI = PSRClassesInterface

include("reader.jl")
include("writer.jl")

function PSRI.convert_file(
    ::Type{Reader},
    ::Type{Writer},
    path_from::String;
    path_to::String = "",
)
    return error("Conversion with OpenBinary.Reader and OpenBinary.Writer is a no op.")
end

end
