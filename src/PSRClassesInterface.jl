module PSRClassesInterface

using Dates
using JSON
using CSV

@enum StageType STAGE_MONTH=2 STAGE_WEEK=1

# simple and generic interface
include("study_interface.jl")
include("reader_writer_interface.jl")
include("utils.jl")

include("OpenStudy/study_openinterface.jl")

# submodules
include("OpenCSV/OpenCSV.jl")
include("OpenBinary/OpenBinary.jl")
include("PMD/PMD.jl")

# symbol exporter
# exports all function from standard PSRClasses usage except breaking names
# const _EXCLUDE_SYMBOLS = [Symbol(@__MODULE__), :eval, :include, :error]
# for sym in names(@__MODULE__, all=true)
#     sym_string = string(sym)
#     if sym in _EXCLUDE_SYMBOLS || startswith(sym_string, "_") ||
#         startswith(sym_string, "initialize")
#         continue
#     end
#     if !(Base.isidentifier(sym) || (startswith(sym_string, "@") &&
#          Base.isidentifier(sym_string[2:end])))
#        continue
#     end
#     @eval export $sym
# end

end