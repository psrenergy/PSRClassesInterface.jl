module PSRClassesInterface

import Dates
import JSON
import CSV
import Random

@enum StageType begin
    STAGE_WEEK=1
    STAGE_MONTH=2
    STAGE_DAY=5
end

# "PSR_STAGETYPE_UNKNOWN" => 0,
# "PSR_STAGETYPE_WEEKLY" => 1,
# "PSR_STAGETYPE_MONTHLY" => 2,
# "PSR_STAGETYPE_QUARTERLY" => 3,
# "PSR_STAGETYPE_HOURLY" => 4,
# "PSR_STAGETYPE_DAILY" => 5,
# "PSR_STAGETYPE_13MONTHLY" => 6,
# "PSR_STAGETYPE_BIMONTHLY" => 7,
# "PSR_STAGETYPE_TRIANNUALLY" => 8,
# "PSR_STAGETYPE_SEMIANNUALLY" => 9,
# "PSR_STAGETYPE_YEARLY" => 10,

@static if VERSION < v"1.6"
    error("Julia version $VERSION not supported by PSRClassesInterface, upgrade to 1.6 or later")
end

# simple and generic interface
include("study_interface.jl")
include("reader_writer_interface.jl")
include("reader_mapper.jl")
include("time_series_utils.jl")
include("utils.jl")

# submodules
include("OpenCSV/OpenCSV.jl")
include("PMD/PMD.jl")
include("OpenBinary/OpenBinary.jl")

include("OpenStudy/pmd.jl")
include("OpenStudy/study_openinterface.jl")
include("OpenStudy/duration.jl")
include("OpenStudy/relations.jl")


end