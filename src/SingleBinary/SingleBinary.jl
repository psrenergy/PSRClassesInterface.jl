module SingleBinary

import PSRClassesInterface
import Dates

const PSRI = PSRClassesInterface

include("common.jl")
include("reader.jl")
include("writer.jl")

function PSRI.convert_file(
        ::Type{Reader},
        ::Type{Writer},
        path_from::String;
        path_to::String = "",
    )
    error("Conversion with SingleBinary.Reader and SingleBinary.Writer is a no op.")
end

end