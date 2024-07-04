# You should run the script from the profiling directory

using Profile
using PProf
import Pkg
root_path = dirname(@__DIR__)
Pkg.activate(root_path)
using PSRClassesInterface

include("../script_time_controller.jl")
@profile include("../script_time_controller.jl")
pprof()
