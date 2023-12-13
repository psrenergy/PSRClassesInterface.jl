module PSRClassesInterface

import Dates
import JSON
import Tables

@static if VERSION < v"1.6"
    error(
        "Julia version $VERSION not supported by PSRClassesInterface, upgrade to 1.6 or later",
    )
end

const JSON_METADATA_PATH = joinpath(@__DIR__, "json_metadata")

const PSRCLASSES_DEFAULTS_PATH = joinpath(JSON_METADATA_PATH, "psrclasses.default.json")
const PSRCLASSES_DEFAULTS_CTIME = [ctime(PSRCLASSES_DEFAULTS_PATH)]
const PSRCLASSES_DEFAULTS = JSON.parsefile(PSRCLASSES_DEFAULTS_PATH)

# submodules

# simple and generic interface
include("study_interface.jl")
include("reader_writer_interface.jl")

# Tables.jl API
include("tables/interface.jl")

# utilities
include("reader_mapper.jl")
include("time_series_utils.jl")
include("utils.jl")

# main interface
include("PMD/PMD.jl")
const Attribute = PMD.Attribute
const DataStruct = PMD.DataStruct

include("OpenBinary/OpenBinary.jl")
include("OpenStudy/OpenStudy.jl")
const OpenInterface = OpenStudy.OpenInterface

include("OpenSQL/OpenSQL.jl")
const SQLInterface = OpenSQL.SQLInterface

end
